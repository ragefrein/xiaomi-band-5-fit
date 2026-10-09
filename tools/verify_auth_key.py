#!/usr/bin/env python3
"""
Verifikasi auth key Mi Band 5 secara OFFLINE.

Kita memakai data dari log Gadgetbridge yang sudah berhasil auth:
  - random challenge yang band kirim (16 byte)
  - hasil AES(key, random) yang Gadgetbridge kirim balik (16 byte)

Kalau key kamu benar, AES-128-ECB(key, random) HARUS sama dengan
ciphertext dari Gadgetbridge. Kalau cocok -> key itu key yang benar.

Pakai:
  python verify_auth_key.py 0x0123456789abcdef0123456789abcdef
  python verify_auth_key.py 0123456789abcdef0123456789abcdef
"""

import sys

# ---- Data dari log Gadgetbridge (10:05:07) -------------------------------
# Band balas random: <@ 108201 4DB0D87E2362BE5EDE1CD9333FFA5E27
RANDOM_CHALLENGE = bytes.fromhex("4DB0D87E2362BE5EDE1CD9333FFA5E27")

# Gadgetbridge kirim: >@ 8300 F57886F63AC22C9E096F4C615D42CACF
EXPECTED_CIPHER = bytes.fromhex("F57886F63AC22C9E096F4C615D42CACF")


def normalize_key(s: str) -> bytes:
    s = s.strip()
    if s.lower().startswith("0x"):
        s = s[2:]
    s = s.replace(" ", "").replace(":", "")
    if len(s) != 32:
        raise ValueError(f"Key harus 32 hex char (16 byte), dapat {len(s)}")
    return bytes.fromhex(s)


def aes_ecb_encrypt(key: bytes, data: bytes) -> bytes:
    """AES-128-ECB/NoPadding. Coba pakai cryptography, fallback pycryptodome."""
    try:
        from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
        cipher = Cipher(algorithms.AES(key), modes.ECB())
        enc = cipher.encryptor()
        return enc.update(data) + enc.finalize()
    except ImportError:
        pass
    try:
        from Crypto.Cipher import AES  # pycryptodome
        cipher = AES.new(key, AES.MODE_ECB)
        return cipher.encrypt(data)
    except ImportError:
        pass
    raise SystemExit(
        "Butuh salah satu: `pip install cryptography` atau `pip install pycryptodome`"
    )


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2

    try:
        key = normalize_key(sys.argv[1])
    except ValueError as e:
        print(f"[ERROR] {e}")
        return 2

    got = aes_ecb_encrypt(key, RANDOM_CHALLENGE).hex().upper()
    exp = EXPECTED_CIPHER.hex().upper()

    print(f"Key       : 0x{key.hex().upper()}")
    print(f"Random    : {RANDOM_CHALLENGE.hex().upper()}")
    print(f"Harusnya  : {exp}")
    print(f"Hasil Anda: {got}")
    print()

    if got == exp:
        print("[OK] COCOK! Ini key yang BENAR untuk band kamu.")
        print("     Pakai key ini di miband_service.dart (defaultKey).")
        return 0
    print("[X] TIDAK cocok. Key ini bukan key yang dipakai Gadgetbridge.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
