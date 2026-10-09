import 'package:flutter_test/flutter_test.dart';
import 'package:ragefit/services/miband/huami_protocol.dart';

void main() {
  test('AES-128-ECB cocok dengan test vector NIST', () {
    final key = hexToBytes('000102030405060708090a0b0c0d0e0f');
    final pt = hexToBytes('00112233445566778899aabbccddeeff');
    final ct = aes128EcbEncrypt(key, pt);
    // hexDump memakai spasi, jadi bandingkan tanpa spasi.
    expect(hexDump(ct).replaceAll(' ', ''), '69c4e0d86a7b0430d8cdb78070b4c55a');
  });
}
