import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Protokol Huami / Mi Band 5: UUID, konstanta, crypto, dan parser.
/// Diturunkan dari Gadgetbridge (AGPLv3).
class HuamiProtocol {
  HuamiProtocol._();

  // ---- GATT services ----
  static const String serviceMain = '0000fee0-0000-1000-8000-00805f9b34fb';
  static const String serviceAuth = '0000fee1-0000-1000-8000-00805f9b34fb';
  /// Standard SIG Heart Rate Service (dipakai band untuk live/manual HR).
  static const String serviceHeartRate = '0000180d-0000-1000-8000-00805f9b34fb';

  // ---- Characteristics (di bawah FEE0) ----
  /// Fetch/control char (dipakai untuk trigger & ack fetch aktivitas).
  static const String charFetch = '00000004-0000-3512-2118-0009af100700';
  /// Activity data (buffer sampel per menit).
  static const String charActivityData = '00000005-0000-3512-2118-0009af100700';
  /// Baterai.
  static const String charBattery = '00000006-0000-3512-2118-0009af100700';
  /// Realtime steps.
  static const String charRealtimeSteps = '00000007-0000-3512-2118-0009af100700';
  /// Konfigurasi — start/stop pengukuran HR manual dikirim ke sini.
  static const String charConfiguration =
      '00000003-0000-3512-2118-0009af100700';
  /// Standard SIG Heart Rate Measurement (notifikasi BPM masuk ke sini).
  static const String charHeartRateMeasurement =
      '00002a37-0000-1000-8000-00805f9b34fb';

  // ---- Characteristics (di bawah FEE1) ----
  /// Auth char.
  static const String charAuth = '00000009-0000-3512-2118-0009af100700';

  // ---- Konstanta auth (InitOperation) ----
  static const int authResponse = 0x10;
  static const int authSuccess = 0x01;
  static const int authFail = 0x04;
  /// Status 0x81 = band menolak (dipakai jalur protokol lama `cryptFlags == 0`).
  static const int authKeyRejected = 0x81;
  static const int authSendKey = 0x01;
  static const int authRequestRandom = 0x02;
  static const int authSendEncrypted = 0x03;

  /// "authFlags" — byte kedua pada setiap perintah auth.
  ///
  /// Gadgetbridge default-nya 0x08 (`HuamiService.AUTH_BYTE`), TETAPI log
  /// perangkat ini membuktikan band memakai 0x00:
  ///     GB kirim: 82 00 02 01 00  dan  83 00 `AES`
  ///                  ^^^             ^^^
  ///                  authFlags = 0x00
  /// Kalau nilai ini salah, band membalas bukan 0x01 (mis. 0x07).
  static const int authByte = 0x00;

  /// Flag kripto Mi Band 4/5 (Gadgetbridge `MiBand4Support.getCryptFlags()`).
  ///
  /// Bila nilainya != 0x00, protokol auth BERBEDA total:
  ///  - Gadgetbridge TIDAK mengirim key mentah (`01 08`) lebih dulu.
  ///  - Langsung minta random: `82 00 02 01 00` (5 byte).
  ///  - Band balas: `10 82 01` + 16 byte random.
  ///  - Kirim AES: `83 00` + AES(key,random) 16 byte.
  ///  - Band balas: `10 83 01` (sukses).
  static const int cryptFlags = 0x80;

  /// 3 byte ekstra yang WAJIB ada di akhir request-random Mi Band 4/5.
  /// Lihat `InitOperation.requestAuthNumber()` Gadgetbridge.
  static const List<int> authRequestRandomExtra = [0x02, 0x01, 0x00];

  // ---- Konstanta fetch aktivitas (HuamiService) ----
  static const int response = 0x10;
  static const int success = 0x01;
  static const int cmdActivityStartDate = 0x01;
  static const int activityTypeActivity = 0x01;
  static const int cmdFetchData = 0x02;
  static const int cmdAckActivityData = 0x03;

  /// Mi Band 5 memakai sampel "extended" 8 byte.
  static const int activitySampleSize = 8;

  // ---- Konstanta detak jantung ----
  /// Endpoint pengukuran HR manual (byte pertama perintah ke char konfigurasi).
  static const int hrEndpoint = 0x15;
  /// Sub-aksi "start".
  static const int hrSubStart = 0x01;
  /// Sub-aksi "stop".
  static const int hrSubStop = 0x02;
}

/// Satu sampel aktivitas = 1 menit data dari band.
class ActivitySample {
  ActivitySample({
    required this.timestamp,
    required this.rawKind,
    required this.rawIntensity,
    required this.steps,
    required this.heartRate,
    required this.sleep,
    required this.deepSleep,
    required this.remSleep,
  });

  final DateTime timestamp;
  final int rawKind;
  final int rawIntensity;
  final int steps;
  final int heartRate;
  final int sleep;
  final int deepSleep;
  final int remSleep;

  bool get isSleep => sleep > 0 || deepSleep > 0 || remSleep > 0;

  @override
  String toString() =>
      'ActivitySample($timestamp, steps=$steps, hr=$heartRate)';
}

/// Parse buffer aktivitas mentah (sampel 8 byte, 1 per menit).
List<ActivitySample> parseActivitySamples(Uint8List bytes, DateTime start) {
  final out = <ActivitySample>[];
  const n = HuamiProtocol.activitySampleSize;
  for (var i = 0; i + n <= bytes.length; i += n) {
    out.add(ActivitySample(
      timestamp: start.add(Duration(minutes: out.length)),
      rawKind: bytes[i],
      rawIntensity: bytes[i + 1],
      steps: bytes[i + 2],
      heartRate: bytes[i + 3],
      sleep: bytes[i + 5],
      deepSleep: bytes[i + 6],
      remSleep: bytes[i + 7],
    ));
  }
  return out;
}

/// AES-128-ECB / NoPadding (untuk handshake Huami).
Uint8List aes128EcbEncrypt(Uint8List key, Uint8List plaintext) {
  if (key.length != 16) {
    throw ArgumentError('AES-128 key harus 16 byte, dapat ${key.length}');
  }
  if (plaintext.isEmpty || plaintext.length % 16 != 0) {
    throw ArgumentError('plaintext harus kelipatan 16');
  }
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(key));
  final out = Uint8List(plaintext.length);
  for (var off = 0; off < plaintext.length; off += 16) {
    cipher.processBlock(plaintext, off, out, off);
  }
  return out;
}

/// Huami "time bytes" presisi MENIT + tail timezone.
/// Format: [yearLo, yearHi, month, day, hour, minute, 0x00, tzQuarterHours]
Uint8List buildTimeBytesMinutes(DateTime dt) {
  final y = dt.year;
  final tzQuarterHours = dt.timeZoneOffset.inMinutes ~/ 15;
  return Uint8List.fromList([
    y & 0xff, (y >> 8) & 0xff,
    dt.month, dt.day, dt.hour, dt.minute,
    0x00, tzQuarterHours & 0xff,
  ]);
}

/// Helper little-endian.
int u16le(List<int> b, int o) => (b[o] & 0xff) | ((b[o + 1] & 0xff) << 8);

int u32le(List<int> b, int o) =>
    (b[o] & 0xff) |
    ((b[o + 1] & 0xff) << 8) |
    ((b[o + 2] & 0xff) << 16) |
    ((b[o + 3] & 0xff) << 24);

/// Parse timestamp 7 byte Huami: year(u16le), month, day, hour, minute, second.
DateTime parseTimeBytes(List<int> b, int o) => DateTime(
      u16le(b, o),
      b[o + 2],
      b[o + 3],
      b[o + 4],
      b[o + 5],
      (o + 6 < b.length) ? b[o + 6] : 0,
    );

/// "0xf5b6..." atau "f5b6..." -> bytes.
Uint8List hexToBytes(String hex) {
  var h = hex.trim();
  if (h.startsWith('0x') || h.startsWith('0X')) h = h.substring(2);
  if (h.length.isOdd) throw ArgumentError('hex harus panjang genap');
  final out = Uint8List(h.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// Cetak bytes jadi "10 02 01 ...".
String hexDump(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

/// Estimasi kalori terbakar dari langkah.
///
/// Pendekatan sederhana (tanpa berat/tinggi badan): ±0.04 kkal/langkah,
/// umum dipakai untuk orang dewasa ~70 kg saat berjalan santai.
/// (1 langkah ≈ 0.04 kkal; 10.000 langkah ≈ 400 kkal.)
double estimateCaloriesFromSteps(int steps) => steps * 0.04;

/// Estimasi kalori dari sampel aktivitas (pakai intensitas + langkah).
///
/// Intensitas tinggi (loncat/lari) menambah faktor pengali kecil supaya
/// kalori yang ditampilkan terasa wajar, bukan hanya dari langkah.
double estimateCaloriesFromSamples(Iterable<ActivitySample> samples) {
  var kcal = 0.0;
  for (final s in samples) {
    kcal += s.steps * 0.04;
    // intensitas 0..255 → tambahan maksimal ~0.02 kkal/menit saat sangat aktif.
    kcal += (s.rawIntensity / 255.0) * 0.02;
  }
  return kcal;
}
