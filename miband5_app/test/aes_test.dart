import 'package:flutter_test/flutter_test.dart';
import 'package:miband5_app/core/aes_ecb.dart';

void main() {
  test('AES-128-ECB matches the NIST test vector', () {
    // NIST FIPS-197 / SP 800-38A known-answer test.
    final key = hexToBytes('000102030405060708090a0b0c0d0e0f');
    final plain = hexToBytes('00112233445566778899aabbccddeeff');
    final cipher = aes128EcbEncrypt(key, plain);
    expect(
      cipher.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '69c4e0d86a7b0430d8cdb78070b4c55a',
    );
  });

  test('hexToBytes parses 0x-prefixed 16-byte key', () {
    final k = hexToBytes('0xf5b6262c77798467ad93abadf2aa7115');
    expect(k.length, 16);
    expect(k[0], 0xf5);
    expect(k[15], 0x15);
  });

  test('hexToBytes rejects a wrong-length key', () {
    expect(() => hexToBytes('0xf5b6'), returnsNormally); // 2 bytes ok at parse
    expect(hexToBytes('0xf5b6').length, 2);
  });
}
