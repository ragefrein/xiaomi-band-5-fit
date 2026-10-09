import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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

  /// Detak jantung terakhir yang diukur (BPM), null bila belum ada.
  int? heartRate;
  /// Apakah sedang mengukur detak jantung.
  bool measuringHr = false;
  /// Kalori terbakar hari ini (kkal), diturunkan dari data band.
  double todayCalories = 0;

  /// Ringkasan tidur semalam (diturunkan dari sampel aktivitas).
  Duration sleepDuration = Duration.zero;
  Duration deepSleep = Duration.zero;
  Duration remSleep = Duration.zero;
  Duration lightSleep = Duration.zero;

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

  /// Minta izin Bluetooth + lokasi. Return true kalau boleh scan/connect.
  Future<bool> requestPermissions() => _requestPermissions();

  /// Scan device BLE di sekitar (untuk popup connect).
  Future<List<ScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    await _requestPermissions();
    return _band.scanDevices(timeout: timeout);
  }

  /// Connect + auth ke device yang dipilih dari popup scan, memakai key
  /// yang diketik user. Simpan credential supaya tidak perlu isi ulang.
  Future<bool> connectToDevice(BluetoothDevice device, String keyHex) async {
    lastError = null;
    notifyListeners();

    final bytes = _tryParseKey(keyHex);
    if (bytes == null) {
      lastError = 'Auth key tidak valid (harus 32 digit hex / 16 byte).';
      notifyListeners();
      return false;
    }

    if (!await _band.connect(device)) {
      lastError = 'Gagal connect ke ${device.remoteId.str}.';
      notifyListeners();
      return false;
    }

    if (!await _band.authenticate(bytes)) {
      lastError = 'Auth gagal — cek auth key (pastikan key diambil SETELAH '
          'pairing terakhir & band belum di-factory-reset)';
      notifyListeners();
      return false;
    }

    // Simpan credential pilihan user.
    await saveCredentials(device.remoteId.str, '0x${_bytesToHex(bytes)}');

    await _band.startRealtimeSteps();
    notifyListeners();
    return true;
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

  /// Ukur detak jantung manual sekarang. Update [heartRate] bila berhasil.
  Future<int?> measureHeartRate() async {
    if (!ready) {
      lastError = 'Band belum terhubung.';
      notifyListeners();
      return null;
    }
    measuringHr = true;
    lastError = null;
    notifyListeners();
    try {
      final bpm = await _band.measureHeartRate();
      if (bpm != null) {
        heartRate = bpm;
        lastError = null;
      } else {
        lastError = 'Pengukuran belum berhasil. Pastikan band dipakai di '
            'pergelangan tangan & tunggu beberapa detik, lalu coba lagi.';
      }
      return bpm;
    } finally {
      measuringHr = false;
      notifyListeners();
    }
  }

  Future<void> fetchToday() async {
    lastError = null;
    notifyListeners();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final list = await _band.fetchActivitySince(midnight);
    samples = list;
    todaySteps = list.fold<int>(0, (a, s) => a + s.steps);
    todayCalories = estimateCaloriesFromSamples(list);
    // Ambil HR terakhir dari sampel kalau belum diukur manual.
    heartRate ??= _lastHr(list);
    notifyListeners();
  }

  /// Ambil ringkasan tidur semalam (dari tengah malam kemarin s/d sekarang).
  Future<void> fetchSleep() async {
    lastError = null;
    notifyListeners();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(hours: 18)); // mulai dari sore kemarin
    final list = await _band.fetchActivitySince(start);
    _computeSleep(list);
    notifyListeners();
  }

  void _computeSleep(List<ActivitySample> list) {
    var deep = 0, rem = 0, light = 0;
    for (final s in list) {
      if (s.deepSleep > 0) {
        deep++;
      } else if (s.remSleep > 0) {
        rem++;
      } else if (s.sleep > 0) {
        light++;
      }
    }
    deepSleep = Duration(minutes: deep);
    remSleep = Duration(minutes: rem);
    lightSleep = Duration(minutes: light);
    sleepDuration = deepSleep + remSleep + lightSleep;
    if (sleepDuration > Duration.zero) samples = list;
  }

  int? _lastHr(List<ActivitySample> list) {
    for (final s in list.reversed) {
      if (s.heartRate > 0) return s.heartRate;
    }
    return null;
  }

  Future<void> disconnect() async {
    await _band.stopRealtimeSteps();
    await _band.disconnect();
    notifyListeners();
  }
}
