import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'aes_ecb.dart';
import 'huami_uuids.dart';

enum MiBandState {
  idle,
  scanning,
  connecting,
  connected,
  authenticating,
  authenticated,
  failed,
  disconnected,
}

/// Minimal, self-contained driver for the Mi Band 5 (Huami protocol).
///
/// It handles: scan -> connect -> discover -> authenticate (challenge/response).
/// Data fetching (steps / HR / sleep) is intentionally left as the next step.
class MiBand5 {
  MiBand5({this.onLog});

  /// Optional logger so the UI can show progress.
  final void Function(String message)? onLog;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _authChar;
  StreamSubscription<List<int>>? _authSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  final _stateCtrl = StreamController<MiBandState>.broadcast();
  MiBandState _state = MiBandState.idle;

  Stream<MiBandState> get stateStream => _stateCtrl.stream;
  MiBandState get state => _state;
  BluetoothDevice? get device => _device;

  void _setState(MiBandState s) {
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  void _log(String m) => onLog?.call(m);

  /// Scan for a band by its Bluetooth MAC (the "remote id").
  /// Returns the matching device or null after [timeout].
  Future<BluetoothDevice?> scanFor(
    String macAddress, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _setState(MiBandState.scanning);
    final target = macAddress.toUpperCase();
    BluetoothDevice? found;

    // Stop any previous scan.
    if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();

    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.remoteId.str.toUpperCase() == target) {
          found = r.device;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    // Poll until we find it or the scan ends.
    final deadline = DateTime.now().add(timeout);
    while (found == null && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await FlutterBluePlus.stopScan();
    await sub.cancel();

    if (found == null) {
      _log('Device $macAddress not found');
      _setState(MiBandState.failed);
    } else {
      _log('Found device ${found!.remoteId.str}');
    }
    return found;
  }

  /// Connect to [device] and discover services.
  Future<bool> connect(BluetoothDevice device) async {
    _setState(MiBandState.connecting);
    _device = device;

    try {
      // Band usually disconnects quickly if not authenticated; keep it explicit.
      await device.connect(timeout: const Duration(seconds: 20));

      _connSub?.cancel();
      _connSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          _log('Disconnected');
          _setState(MiBandState.disconnected);
        }
      });

      // Larger MTU makes data transfer much faster (band supports up to ~247).
      try {
        await device.requestMtu(247);
        _log('MTU set to 247');
      } catch (_) {
        _log('MTU request failed, continuing with default');
      }

      await device.discoverServices();
      _log('Services discovered');

      _authChar = await _findCharacteristic(
        device,
        HuamiUuids.serviceAuth,
        HuamiUuids.charAuth,
      );
      if (_authChar == null) {
        _log('AUTH characteristic not found — is this a Mi Band 5?');
        _setState(MiBandState.failed);
        return false;
      }

      _setState(MiBandState.connected);
      return true;
    } catch (e) {
      _log('Connect error: $e');
      _setState(MiBandState.failed);
      return false;
    }
  }

  Future<BluetoothCharacteristic?> _findCharacteristic(
    BluetoothDevice device,
    String serviceUuid,
    String charUuid,
  ) async {
    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid.str128.toLowerCase() == serviceUuid.toLowerCase() ||
          s.uuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
        for (final c in s.characteristics) {
          if (c.uuid.str128.toLowerCase() == charUuid.toLowerCase() ||
              c.uuid.str.toLowerCase() == charUuid.toLowerCase()) {
            return c;
          }
        }
      }
    }
    return null;
  }

  /// Perform the 3-step Huami authentication handshake.
  /// [authKey] must be the 16-byte key obtained from Zepp (via huafetcher).
  Future<bool> authenticate(
    Uint8List authKey, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final authChar = _authChar;
    if (authChar == null) {
      _log('Not connected / no auth characteristic');
      return false;
    }

    _setState(MiBandState.authenticating);
    final done = Completer<bool>();

    _authSub = authChar.onValueReceived.listen((value) {
      if (value.isEmpty || value[0] != HuamiUuids.authResponse) return;
      if (value.length < 3) return;

      final cmd = value[1] & 0x0f; // low nibble = command
      final status = value[2];

      _log('RX ${hexDump(value)}');

      switch (cmd) {
        case HuamiUuids.authSendKey:
          // Band accepted the key -> request the random challenge.
          if (status == HuamiUuids.authSuccess) {
            _writeAuth(authChar, [
              HuamiUuids.authRequestRandom,
              HuamiUuids.authByte,
            ]);
          }
          break;

        case HuamiUuids.authRequestRandom:
          // Band sent 16 random bytes -> encrypt them and send back.
          if (status == HuamiUuids.authSuccess && value.length >= 19) {
            final random = Uint8List.fromList(value.sublist(3, 19));
            final enc = aes128EcbEncrypt(authKey, random);
            final payload = Uint8List(2 + enc.length)
              ..[0] = HuamiUuids.authSendEncrypted
              ..[1] = HuamiUuids.authByte;
            payload.setRange(2, payload.length, enc);
            _writeAuth(authChar, payload);
          }
          break;

        case HuamiUuids.authSendEncrypted:
          if (status == HuamiUuids.authSuccess) {
            if (!done.isCompleted) done.complete(true);
          } else if (status == HuamiUuids.authFail) {
            if (!done.isCompleted) done.complete(false);
          }
          break;
      }
    });

    try {
      await authChar.setNotifyValue(true);
      _log('Notifications enabled on AUTH char');

      // Step 1: send [0x01, 0x08] + key
      final sendKey = Uint8List(2 + authKey.length)
        ..[0] = HuamiUuids.authSendKey
        ..[1] = HuamiUuids.authByte;
      sendKey.setRange(2, sendKey.length, authKey);
      _log('TX ${hexDump(sendKey)}');
      await _writeAuth(authChar, sendKey);

      final ok = await done.future.timeout(
        timeout,
        onTimeout: () => false,
      );

      if (ok) {
        _log('Authenticated ✔');
        _setState(MiBandState.authenticated);
      } else {
        _log('Authentication failed ✘ (wrong key, or try "New Auth Protocol")');
        _setState(MiBandState.failed);
      }
      return ok;
    } catch (e) {
      _log('Auth error: $e');
      _setState(MiBandState.failed);
      return false;
    } finally {
      await _authSub?.cancel();
      _authSub = null;
    }
  }

  /// The AUTH characteristic on the Mi Band 5 typically advertises
  /// write-without-response only. Choose the write mode from its properties,
  /// and fall back gracefully.
  Future<void> _writeAuth(BluetoothCharacteristic c, List<int> data) async {
    final p = c.properties;
    final supportsWithoutResponse = p.writeWithoutResponse;
    final supportsWithResponse = p.write;

    if (supportsWithoutResponse) {
      try {
        await c.write(data, withoutResponse: true);
        return;
      } catch (_) {}
    }
    if (supportsWithResponse) {
      await c.write(data, withoutResponse: false);
      return;
    }
    // Last resort.
    try {
      await c.write(data, withoutResponse: false);
    } catch (_) {
      await c.write(data, withoutResponse: true);
    }
  }

  Future<void> disconnect() async {
    await _authSub?.cancel();
    await _connSub?.cancel();
    try {
      await _device?.disconnect();
    } catch (_) {}
    _setState(MiBandState.disconnected);
  }

  void dispose() {
    _authSub?.cancel();
    _connSub?.cancel();
    _stateCtrl.close();
  }
}
