import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// AES-128-ECB / NoPadding encryption — exactly what the Huami handshake uses
/// (see Gadgetbridge InitOperation.handleAESAuth: Cipher "AES/ECB/NoPadding").
///
/// [key] must be 16 bytes, [plaintext] a multiple of 16 bytes.
Uint8List aes128EcbEncrypt(Uint8List key, Uint8List plaintext) {
  if (key.length != 16) {
    throw ArgumentError('AES-128 key must be exactly 16 bytes, got ${key.length}');
  }
  if (plaintext.isEmpty || plaintext.length % 16 != 0) {
    throw ArgumentError('plaintext length must be a non-zero multiple of 16');
  }
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(key));
  final out = Uint8List(plaintext.length);
  for (var off = 0; off < plaintext.length; off += 16) {
    cipher.processBlock(plaintext, off, out, off);
  }
  return out;
}

/// Parse a hex string ("0xf5b6..." or "f5b6...") into bytes.
Uint8List hexToBytes(String hex) {
  var h = hex.trim();
  if (h.startsWith('0x') || h.startsWith('0X')) h = h.substring(2);
  if (h.length.isOdd) {
    throw ArgumentError('hex string must have an even length');
  }
  final out = Uint8List(h.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// Pretty-print bytes as "10 02 01 ...".
String hexDump(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
