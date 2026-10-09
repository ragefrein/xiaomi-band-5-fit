import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'huami_protocol.dart';

enum MiBandState {
  idle,
  scanning,
  connecting,
  connected,
  authenticating,
  authenticated,
  fetching,
  failed,
  disconnected,
}

/// Driver Mi Band 5 (protokol Huami): scan -> connect -> auth -> steps.
class MiBand5 {
  MiBand5({this.onLog});

  final void Function(String message)? onLog;
  void _log(String m) => onLog?.call(m);

  BluetoothDevice? _device;
  BluetoothCharacteristic? _authChar;
  BluetoothCharacteristic? _fetchChar;
  BluetoothCharacteristic? _activityChar;
  BluetoothCharacteristic? _realtimeChar;
  BluetoothCharacteristic? _hrChar;
  BluetoothCharacteristic? _hrControlChar;

  StreamSubscription? _connSub;
  StreamSubscription? _realtimeSub;

  final _stateCtrl = StreamController<MiBandState>.broadcast();
  MiBandState _state = MiBandState.idle;
  Stream<MiBandState> get stateStream => _stateCtrl.stream;
  MiBandState get state => _state;

  final _realtimeStepsCtrl = StreamController<int>.broadcast();
  Stream<int> get realtimeSteps => _realtimeStepsCtrl.stream;

  void _setState(MiBandState s) {
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  // ---------------------------------------------------------------- SCAN
  /// Scan BLE sekilas dan kembalikan daftar device (untuk memilih band).
  ///
  /// [timeout] berapa lama scan berjalan. Device yang namanya kosong tetap
  /// dikembalikan supaya band tanpa nama tetap bisa dipilih.
  Future<List<ScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _setState(MiBandState.scanning);
    if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();

    final found = <String, ScanResult>{};
    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        found[r.device.remoteId.str.toUpperCase()] = r;
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await Future.delayed(timeout);
      await FlutterBluePlus.stopScan();
    } catch (e) {
      _log('scan error: $e');
    } finally {
      await sub.cancel();
    }

    final list = found.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi)); // terkuat dulu
    _log('Scan selesai: ${list.length} device');
    if (_state == MiBandState.scanning) _setState(MiBandState.idle);
    return list;
  }

  Future<BluetoothDevice?> scanFor(
    String mac, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _setState(MiBandState.scanning);
    final target = mac.toUpperCase();
    BluetoothDevice? found;

    if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();

    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.remoteId.str.toUpperCase() == target) found = r.device;
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    final deadline = DateTime.now().add(timeout);
    while (found == null && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await FlutterBluePlus.stopScan();
    await sub.cancel();

    if (found == null) {
      _log('Device $mac tidak ditemukan');
      _setState(MiBandState.failed);
    } else {
      _log('Ditemukan ${found!.remoteId.str}');
    }
    return found;
  }

  // ------------------------------------------------------------- CONNECT
  /// Ambil device TANPA scan bila sudah bonded (Android boleh connect langsung
  /// ke MAC yang dikenal). Scan hanya dipakai sebagai fallback.
  BluetoothDevice deviceById(String mac) => BluetoothDevice.fromId(mac.toUpperCase());

  /// Connect + discover services, dengan retry (GATT 133 sering transient).
  Future<bool> connect(BluetoothDevice device, {int attempts = 3}) async {
    _setState(MiBandState.connecting);
    _device = device;

    for (var i = 0; i < attempts; i++) {
      try {
        _log('Connect (coba ${i + 1}/$attempts) ke ${device.remoteId.str}');

        // Rekam state connected sebelum connect (supaya tidak deadlock bila
        // koneksi sudah terbentuk dari pemanggilan sebelumnya).
        await device.connect(timeout: const Duration(seconds: 20));

        // Tunggu sampai koneksi benar-benar terbentuk.
        try {
          await device.connectionState
              .where((s) => s == BluetoothConnectionState.connected)
              .first
              .timeout(const Duration(seconds: 20));
        } catch (_) {
          _log('Tidak menerima state connected tepat waktu');
        }

        _connSub?.cancel();
        _connSub = device.connectionState.listen((s) {
          if (s == BluetoothConnectionState.disconnected) {
            _log('Terputus');
            _setState(MiBandState.disconnected);
          }
        });

        try {
          await device.requestMtu(247);
          _log('MTU 247');
        } catch (_) {
          _log('MTU gagal, pakai default');
        }

        final services = await device.discoverServices();
        _authChar =
            _find(services, HuamiProtocol.serviceAuth, HuamiProtocol.charAuth);
        _fetchChar =
            _find(services, HuamiProtocol.serviceMain, HuamiProtocol.charFetch);
        _activityChar = _find(
            services, HuamiProtocol.serviceMain, HuamiProtocol.charActivityData);
        _realtimeChar = _find(services, HuamiProtocol.serviceMain,
            HuamiProtocol.charRealtimeSteps);
        _hrChar = _find(
            services, HuamiProtocol.serviceMain, HuamiProtocol.charHeartRate);
        _hrControlChar = _find(services, HuamiProtocol.serviceMain,
            HuamiProtocol.charHeartRateControl);

        if (_authChar == null) {
          _log('AUTH characteristic tidak ada — bukan Mi Band 5?');
          _setState(MiBandState.failed);
          return false;
        }
        _log('Services OK (auth/fetch/activity/realtime)');
        _setState(MiBandState.connected);
        return true;
      } catch (e) {
        _log('Connect error (coba ${i + 1}): $e');
        try {
          await device.disconnect();
        } catch (_) {}
        if (i < attempts - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    _setState(MiBandState.failed);
    return false;
  }

  BluetoothCharacteristic? _find(
    List<BluetoothService> services,
    String svc,
    String chr,
  ) {
    for (final s in services) {
      if (s.uuid.str128.toLowerCase() == svc.toLowerCase() ||
          s.uuid.str.toLowerCase() == svc.toLowerCase()) {
        for (final c in s.characteristics) {
          if (c.uuid.str128.toLowerCase() == chr.toLowerCase() ||
              c.uuid.str.toLowerCase() == chr.toLowerCase()) {
            return c;
          }
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------- AUTH
  /// Bangun perintah "request random auth number".
  ///
  /// Mengikuti `InitOperation.requestAuthNumber()` Gadgetbridge:
  ///  - cryptFlags == 0x00 : `[0x02, 0x08]`
  ///  - cryptFlags != 0x00 : `[0x82, 0x08, 0x02, 0x01, 0x00]` (Mi Band 4/5)
  List<int> _buildRequestRandom() {
    if (HuamiProtocol.cryptFlags == 0x00) {
      return [
        HuamiProtocol.authRequestRandom,
        HuamiProtocol.authByte,
      ];
    }
    return [
      HuamiProtocol.authRequestRandom | HuamiProtocol.cryptFlags,
      HuamiProtocol.authByte,
      ...HuamiProtocol.authRequestRandomExtra,
    ];
  }

  Future<bool> authenticate(
    Uint8List key, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final auth = _authChar;
    if (auth == null) {
      _log('Tidak ada auth characteristic');
      return false;
    }
    _setState(MiBandState.authenticating);
    final done = Completer<bool>();
    String? failReason;

    final sub = auth.onValueReceived.listen((v) {
      if (v.length < 3 || v[0] != HuamiProtocol.authResponse) return;
      final cmd = v[1] & 0x0f;
      final status = v[2];
      _log('RX ${hexDump(v)}');

      // Kalau band menolak / error, jangan tunggu sisa alur — langsung selesai.
      if (status == HuamiProtocol.authKeyRejected) {
        failReason = 'Band balas 0x81 pada langkah '
            '0x${cmd.toRadixString(16)} (key/protokol tidak cocok).';
        if (!done.isCompleted) done.complete(false);
        return;
      }
      if (status != HuamiProtocol.authSuccess &&
          cmd != HuamiProtocol.authSendEncrypted) {
        failReason = 'Band balas status 0x${status.toRadixString(16)} '
            'pada langkah 0x${cmd.toRadixString(16)}';
        if (!done.isCompleted) done.complete(false);
        return;
      }

      switch (cmd) {
        case HuamiProtocol.authSendKey:
          // Fase 1: minta band kirim random challenge.
          // Hanya dipakai pada jalur cryptFlags == 0x00.
          _write(auth, _buildRequestRandom());
          break;
        case HuamiProtocol.authRequestRandom:
          // Fase 2: enkripsi random challenge dengan key, kirim balik.
          if (v.length < 19) {
            failReason = 'Challenge band tidak lengkap (${v.length} byte)';
            if (!done.isCompleted) done.complete(false);
            return;
          }
          final rnd = Uint8List.fromList(v.sublist(3, 19));
          final enc = aes128EcbEncrypt(key, rnd);
          final payload = Uint8List(2 + enc.length)
            ..[0] = HuamiProtocol.authSendEncrypted | HuamiProtocol.cryptFlags
            ..[1] = HuamiProtocol.authByte;
          payload.setRange(2, payload.length, enc);
          _write(auth, payload);
          break;
        case HuamiProtocol.authSendEncrypted:
          // Fase 3: hasil akhir.
          if (!done.isCompleted) {
            done.complete(status == HuamiProtocol.authSuccess);
            if (status != HuamiProtocol.authSuccess) {
              failReason = 'Enkripsi challenge salah (status '
                  '0x${status.toRadixString(16)})';
            }
          }
          break;
      }
    });

    try {
      await auth.setNotifyValue(true);

      // Band Huami butuh descriptor notifikasi benar-benar dikonfirmasi
      // sebelum menerima perintah auth. flutter_blue_plus bisa return lebih
      // awal; beri jeda singkat agar onDescriptorWrite native selesai dulu.
      await Future.delayed(const Duration(milliseconds: 300));

      if (HuamiProtocol.cryptFlags == 0x00) {
        // Protokol LAMA: kirim key mentah dulu.
        final sendKey = Uint8List(2 + key.length)
          ..[0] = HuamiProtocol.authSendKey
          ..[1] = HuamiProtocol.authByte;
        sendKey.setRange(2, sendKey.length, key);
        _log('TX ${hexDump(sendKey)}');
        await _write(auth, sendKey);
      } else {
        // Protokol Mi Band 4/5 (cryptFlags != 0x00): JANGAN kirim key mentah.
        // Langsung minta random challenge. Band yang akan mengembalikan
        // random, lalu kita kirim AES(key, random) di langkah berikutnya.
        final req = _buildRequestRandom();
        _log('TX ${hexDump(req)}');
        await _write(auth, req);
      }

      // Jeda singkat sebelum seandainya band butuh waktu memproses.
      await Future.delayed(const Duration(milliseconds: 200));

      final ok = await done.future.timeout(
        timeout,
        onTimeout: () {
          failReason ??= 'Timeout menunggu balasan band';
          return false;
        },
      );
      _setState(ok ? MiBandState.authenticated : MiBandState.failed);
      _log(ok ? 'Authenticated ✔' : 'Auth gagal ✘: $failReason');
      return ok;
    } catch (e) {
      _log('Auth error: $e');
      _setState(MiBandState.failed);
      return false;
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _write(BluetoothCharacteristic c, List<int> data) async {
    final p = c.properties;
    if (p.writeWithoutResponse) {
      try {
        await c.write(data, withoutResponse: true);
        return;
      } catch (_) {}
    }
    if (p.write) {
      await c.write(data, withoutResponse: false);
      return;
    }
    try {
      await c.write(data, withoutResponse: false);
    } catch (_) {
      await c.write(data, withoutResponse: true);
    }
  }

  // ------------------------------------------------------- REALTIME STEPS
  Future<void> startRealtimeSteps() async {
    final c = _realtimeChar;
    if (c == null) {
      _log('Tidak ada realtime steps characteristic');
      return;
    }
    _realtimeSub?.cancel();
    _realtimeSub = c.onValueReceived.listen((v) {
      if (v.length == 13) {
        final steps = (v[1] & 0xff) | ((v[2] & 0xff) << 8);
        if (!_realtimeStepsCtrl.isClosed) _realtimeStepsCtrl.add(steps);
      }
    });
    await c.setNotifyValue(true);
    _log('Realtime steps: ON');
  }

  Future<void> stopRealtimeSteps() async {
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    try {
      await _realtimeChar?.setNotifyValue(false);
    } catch (_) {}
  }

  // ------------------------------------------------------- HEART RATE
  /// Ukur detak jantung manual sekali. Return BPM atau null bila gagal.
  ///
  /// Alur protokol Huami (Mi Band 5):
  ///  - Subscribe notifikasi di char NILAI (0x2f).
  ///  - Kirim `[0x15, 0x01, 0x00]` (start) ke char KONTROL (0x2e).
  ///  - Band balas `[0x10, 0x01, 0x01]` (ack) → kirim `[0x15, 0x03, 0x00]`
  ///    (continue) ke char KONTROL.
  ///  - Selama ~10-15 detik band kirim `[0x10, 0x02, <bpm>]` ke char NILAI.
  ///    bpm 0 = belum siap, nilai >0 = hasil akhir.
  Future<int?> measureHeartRate({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final value = _hrChar; // 0x2f — notifikasi BPM
    final control = _hrControlChar ?? _hrChar; // 0x2e — kirim perintah
    if (value == null || control == null) {
      _log('Tidak ada heart rate characteristic');
      return null;
    }
    final done = Completer<int?>();

    final valueSub = value.onValueReceived.listen((v) {
      if (v.isEmpty) return;
      _log('HR RX ${hexDump(v)}');
      if (v[0] != HuamiProtocol.hrResponse) return;
      // v[1] = sub-tipe, v[2+] = data.
      if (v.length >= 3 && v[1] == HuamiProtocol.hrCmdResult) {
        final bpm = v[2] & 0xff;
        if (bpm > 0 && !done.isCompleted) done.complete(bpm);
      }
    });

    final ackSub = control.onValueReceived.listen((v) async {
      if (v.isEmpty) return;
      _log('HR CTRL RX ${hexDump(v)}');
      if (v[0] != HuamiProtocol.hrResponse) return;
      // Ack start → minta band lanjut mengukur.
      if (v.length >= 3 &&
          v[1] == HuamiProtocol.hrCmdStartAck &&
          !done.isCompleted) {
        await _write(control, [
          HuamiProtocol.hrCmdStartManual,
          HuamiProtocol.hrSubContinue,
          0x00,
        ]);
      }
    });

    try {
      await value.setNotifyValue(true);
      try {
        await control.setNotifyValue(true);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 300));

      final start = [
        HuamiProtocol.hrCmdStartManual,
        HuamiProtocol.hrSubStart,
        0x00,
      ];
      _log('HR TX ${hexDump(start)}');
      await _write(control, start);

      return await done.future.timeout(timeout, onTimeout: () {
        _log('HR timeout');
        return null;
      });
    } catch (e) {
      _log('HR error: $e');
      return null;
    } finally {
      try {
        await _write(control, [
          HuamiProtocol.hrCmdStartManual,
          HuamiProtocol.hrSubStop,
          0x00,
        ]);
      } catch (_) {}
      try {
        await value.setNotifyValue(false);
      } catch (_) {}
      try {
        await control.setNotifyValue(false);
      } catch (_) {}
      await valueSub.cancel();
      await ackSub.cancel();
    }
  }

  // ------------------------------------------------- FETCH AKTIVITAS
  /// Ambil sampel aktivitas (termasuk steps) sejak [since] sampai sekarang.
  Future<List<ActivitySample>> fetchActivitySince(
    DateTime since, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final fetch = _fetchChar;
    final data = _activityChar;
    if (fetch == null || data == null) throw StateError('Belum terhubung');

    _setState(MiBandState.fetching);
    final buffer = <int>[];
    var lastCounter = -1;
    var startDate = since;
    final done = Completer<List<ActivitySample>>();

    void finish() {
      if (!done.isCompleted) {
        done.complete(
            parseActivitySamples(Uint8List.fromList(buffer), startDate));
      }
    }

    final fetchSub = fetch.onValueReceived.listen((v) async {
      if (v.isEmpty || v[0] != HuamiProtocol.response) return;
      final cmd = v[1];
      _log('META RX ${hexDump(v)}');
      switch (cmd) {
        case HuamiProtocol.cmdActivityStartDate:
          if (v.length < 15) {
            finish();
            return;
          }
          final expected = u32le(v, 3);
          if (v.length >= 14) startDate = parseTimeBytes(v, 7);
          _log('Expect $expected byte sejak $startDate');
          if (expected == 0) {
            await _write(fetch, [HuamiProtocol.cmdAckActivityData]);
            return;
          }
          await data.setNotifyValue(true);
          await _write(fetch, [HuamiProtocol.cmdFetchData]);
          break;
        case HuamiProtocol.cmdFetchData:
          await _write(fetch, [HuamiProtocol.cmdAckActivityData]);
          finish();
          break;
        case HuamiProtocol.cmdAckActivityData:
          finish();
          break;
      }
    });

    final dataSub = data.onValueReceived.listen((v) {
      if (v.isEmpty) return;
      final counter = v[0];
      if (counter != ((lastCounter + 1) & 0xff)) {
        _log('counter gap: $counter (last $lastCounter)');
      }
      lastCounter = counter;
      buffer.addAll(v.sublist(1));
    });

    try {
      await fetch.setNotifyValue(true);
      await data.setNotifyValue(false);

      final tb = buildTimeBytesMinutes(since);
      final cmd = <int>[
        HuamiProtocol.cmdActivityStartDate,
        HuamiProtocol.activityTypeActivity,
        ...tb,
      ];
      _log('TX ${hexDump(cmd)}');
      await _write(fetch, cmd);

      final samples = await done.future.timeout(
        timeout,
        onTimeout: () =>
            parseActivitySamples(Uint8List.fromList(buffer), startDate),
      );
      _log('Dapat ${samples.length} sampel');
      _setState(MiBandState.authenticated);
      return samples;
    } catch (e) {
      _log('Fetch error: $e');
      _setState(MiBandState.failed);
      return const [];
    } finally {
      await fetchSub.cancel();
      await dataSub.cancel();
      try {
        await data.setNotifyValue(false);
      } catch (_) {}
      try {
        await fetch.setNotifyValue(false);
      } catch (_) {}
    }
  }

  // ------------------------------------------------------------ TEARDOWN
  Future<void> disconnect() async {
    await _realtimeSub?.cancel();
    await _connSub?.cancel();
    try {
      await _device?.disconnect();
    } catch (_) {}
    _setState(MiBandState.disconnected);
  }

  void dispose() {
    _realtimeSub?.cancel();
    _connSub?.cancel();
    _stateCtrl.close();
    _realtimeStepsCtrl.close();
  }
}
