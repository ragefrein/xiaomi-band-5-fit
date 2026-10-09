import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import 'miband/huami_protocol.dart';
import 'miband/miband5.dart';

/// Service global (singleton) untuk Mi Band 5.
/// Pakai: `MiBandService.instance` + `AnimatedBuilder`.
class MiBandService extends ChangeNotifier {
  MiBandService._();
  static final MiBandService instance = MiBandService._();

  final MiBand5 _band = MiBand5(onLog: (m) => debugPrint('[MiBand] $m'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Nilai DEFAULT (fallback) — hanya dipakai kalau belum ada yang disimpan.
  // Setelah user menyimpan lewat UI, nilai tersimpan selalu dipakai.
  static const String _defaultMac = 'C4:B5:F6:1D:93:69';
  static const String _defaultKey = '0x15eda396884d8f2c1fe52817a61764dc';

  String _mac = _defaultMac;
  String _keyHex = _defaultKey;

  MiBandState state = MiBandState.idle;
  int realtimeSteps = 0;
  int todaySteps = 0;
  List<ActivitySample> samples = const [];
  String? lastError;

  /// true kalau mac & key berasal dari input user (bukan default).
  bool _hasSaved = false;

  bool _initialized = false;

  String get mac => _mac;
  String get keyHex => _keyHex;

  /// Apakah credential sudah diisi/diubah manual oleh user.
  bool get hasSavedCredentials => _hasSaved;

  bool get busy =>
      state == MiBandState.scanning ||
      state == MiBandState.connecting ||
      state == MiBandState.authenticating ||
      state == MiBandState.fetching;

  bool get ready => state == MiBandState.authenticated;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _band.stateStream.listen((s) {
      state = s;
      notifyListeners();
    });
    _band.realtimeSteps.listen((s) {
      realtimeSteps = s;
      notifyListeners();
    });
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final savedMac = await _storage.read(key: 'miband_mac');
      final savedKey = await _storage.read(key: 'miband_key');

      // Credential tersimpan selalu menang atas default hardcode.
      // Jadi update app TIDAK menimpa key yang sudah diisi user.
      if (savedMac != null && savedMac.trim().isNotEmpty) {
        _mac = savedMac.trim();
      }
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _keyHex = savedKey.trim();
        _hasSaved = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('load saved gagal: $e');
    }
  }

  /// Simpan credential yang diisi user ke secure storage.
  /// Melempar [ArgumentError] kalau format tidak valid.
  Future<void> saveCredentials(String mac, String keyHex) async {
    final m = mac.trim();
    final k = keyHex.trim();

    if (!_isValidMac(m)) {
      throw ArgumentError('Format MAC tidak valid (contoh: C4:B5:F6:1D:93:69)');
    }
    final bytes = _tryParseKey(k);
    if (bytes == null) {
      throw ArgumentError(
          'Auth key tidak valid — harus 32 digit hex (16 byte), '
          'boleh pakai awalan 0x.');
    }

    _mac = m;
    _keyHex = '0x${_bytesToHex(bytes)}';
    _hasSaved = true;

    await _storage.write(key: 'miband_mac', value: _mac);
    await _storage.write(key: 'miband_key', value: _keyHex);
    notifyListeners();
  }

  /// Kembalikan ke credential default bawaan.
  Future<void> resetCredentials() async {
    _mac = _defaultMac;
    _keyHex = _defaultKey;
    _hasSaved = false;
    await _storage.delete(key: 'miband_mac');
    await _storage.delete(key: 'miband_key');
    notifyListeners();
  }

  static bool _isValidMac(String mac) =>
      RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$').hasMatch(mac);

  /// Terima "0x...." atau "...." ; kembalikan null kalau bukan 16 byte.
  static Uint8List? _tryParseKey(String key) {
    var s = key.replaceAll(RegExp(r'\s+'), '');
    if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
    if (!RegExp(r'^[0-9A-Fa-f]{32}$').hasMatch(s)) return null;
    try {
      return hexToBytes('0x$s');
    } catch (_) {
      return null;
    }
  }

  static String _bytesToHex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  Future<bool> _requestPermissions() async {
    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    if (results.values.every((s) => s.isGranted)) return true;
    // Android <= 11 butuh location
    final loc = await Permission.locationWhenInUse.request();
    return loc.isGranted;
  }

  Future<bool> connectAndAuth() async {
    lastError = null;
    notifyListeners();

    await _requestPermissions();

    Uint8List key;
    try {
      final parsed = _tryParseKey(_keyHex);
      if (parsed == null) throw 'key harus 16 byte (32 digit hex)';
      key = parsed;
    } catch (e) {
      lastError = 'Key tidak valid: $e';
      notifyListeners();
      return false;
    }

    // 1) Coba connect LANGSUNG ke MAC (band sudah bonded, tanpa perlu scan).
    var device = _band.deviceById(_mac);
    var ok = await _band.connect(device);

    // 2) Fallback: baru scan kalau connect langsung gagal.
    if (!ok) {
      lastError = 'Connect langsung gagal — mencoba scan…';
      notifyListeners();
      final scanned = await _band.scanFor(_mac);
      if (scanned != null) {
        device = scanned;
        ok = await _band.connect(device);
      }
    }

    if (!ok) {
      lastError =
          'Gagal connect. Pastikan Bluetooth dimatikan-nyalakan (buang koneksi hantu), '
          'band dekat HP, dan Zepp Life sudah di-uninstall.';
      notifyListeners();
      return false;
    }

    if (!await _band.authenticate(key)) {
      lastError = 'Auth gagal — cek auth key (pastikan key diambil SETELAH '
          'pairing terakhir & band belum di-factory-reset)';
      notifyListeners();
      return false;
    }

    await _band.startRealtimeSteps();
    notifyListeners();
    return true;
  }

  Future<void> fetchToday() async {
    lastError = null;
    notifyListeners();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final list = await _band.fetchActivitySince(midnight);
    samples = list;
    todaySteps = list.fold<int>(0, (a, s) => a + s.steps);
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _band.stopRealtimeSteps();
    await _band.disconnect();
    notifyListeners();
  }
}
