# HANDOFF — Mi Band 5 × Flutter (Custom App)

> Catatan ini dibuat agar pekerjaan bisa dilanjutkan kapan saja.
> **Bersifat SENSITIF** (memuat auth key) — jangan di-commit ke repo publik / gitignore.

Terakhir diperbarui: sesi lanjutan — **integrasi ke app `ragefit` (Kinetix Pro) + fetch steps**.

---

## 1. Tujuan
Membuat aplikasi Flutter sendiri untuk Mi Band 5: pantau, olah, dan buat data sendiri
(tanpa cloud Zepp).

**Keputusan sesi ini:** kode BLE **diintegrasikan ke app `ragefit`** (project Flutter
utama, "Kinetix Pro"), bukan lagi overlay terpisah. Fitur pertama: **ambil data langkah**.

## 2. Data device (RAHASIA — jangan disebar)
- **MAC address:** `C4:B5:F6:1D:93:69`
- **Auth key (16 byte):** `0xf5b6262c77798467ad93abadf2aa7115`
- Cara dapat key: **huafetcher**, mode **Amazfit**.
  - Error yang pernah muncul: `NO location header in amazfit auth responses 429`
    → itu **rate limit/anti-bot**, bukan salah password. Solusi: berhenti retry,
    jeda 30–60 mnt, matikan VPN, atau pakai mode **Xiaomi** (browser).
- Aturan penting: band hanya bisa terhubung ke SATU app. **Uninstall/kill Zepp Life**
  (jangan unpair) sebelum app kita connect. Hard reset → MAC & key berubah.

## 3. Lokasi kode (SEKARANG: di project ragefit)
Project Flutter utama: `C:\web\ragefit\`

```
ragefit/
├─ pubspec.yaml                                  # + flutter_blue_plus, pointycastle, flutter_secure_storage
├─ android/app/src/main/AndroidManifest.xml      # + izin Bluetooth
├─ lib/
│  ├─ main.dart                                  # app Kinetix (tab: Beranda/Langkah/Tidur/Jantung)
│  ├─ services/
│  │  ├─ miband_service.dart                     # SINGLETON MiBandService (ChangeNotifier)
│  │  └─ miband/
│  │     ├─ huami_protocol.dart                  # UUID, konstanta, AES-128-ECB, parser
│  │     └─ miband5.dart                         # driver: scan→connect→auth→steps
│  └─ screens/steps_screen.dart                  # UI langkah (sudah pakai band)
└─ test/
   ├─ aes_test.dart                              # verifikasi AES vs NIST
   └─ widget_test.dart                           # smoke test app

miband5_app/                                     # overlay LAMA (referensi, tidak dipakai run)
```

Status validasi: `flutter pub get` OK; `flutter analyze` → **No issues found**;
`flutter test` → **All tests passed** (AES cocok NIST `69c4e0d86a7b0430d8cdb78070b4c55a`).

## 4. Yang SUDAH jalan
- Scan band berdasarkan MAC
- Connect + discover service + MTU 247
- **Handshake auth 3 langkah** (challenge/response AES-128-ECB)
- **Realtime steps** (notify char `00000007`, 13 byte, steps = `uint16LE(v[1],v[2])`)
- **Fetch aktivitas historis** (steps per menit) → parser sampel 8 byte
- Auth key disimpan di `flutter_secure_storage`
- UI: tab **LANGKAH** → tombol **HUBUNGKAN BAND** & **AMBIL DATA HARI INI**

## 5. Protokol auth (dari source Gadgetbridge, presisi)
Konstanta: `AUTH_RESPONSE=0x10`, `AUTH_SUCCESS=0x01`, `AUTH_FAIL=0x04`,
`AUTH_SEND_KEY=0x01`, `AUTH_REQUEST_RANDOM=0x02`, `AUTH_SEND_ENCRYPTED=0x03`, `AUTH_BYTE=0x08`.

| Step | Kirim (hex) | Band balas |
|------|-------------|-----------|
| 1 | `01 08` + key(16B) | `10 01 01` |
| 2 | `02 08` | `10 02 01` + 16 byte random |
| 3 | `03 08` + AES128ECB(random, key) | `10 03 01` = sukses |

- Parse respons pakai low nibble byte[1]: `value[1] & 0x0f`.
- Kalau band bilang "Update the app", coba varian **New Auth Protocol**.

## 6. Protokol fetch aktivitas/steps (dari AbstractFetchOperation.java)
Konstanta: `RESPONSE=0x10`, `SUCCESS=0x01`, `COMMAND_ACTIVITY_DATA_START_DATE=0x01`,
`COMMAND_ACTIVITY_DATA_TYPE_ACTIVTY=0x01`, `COMMAND_FETCH_DATA=0x02`, `COMMAND_ACK_ACTIVITY_DATA=0x03`.

Alur (char fetch = `00000004`, char data = `00000005`, dua-duanya di bawah FEE0):
1. Notify **char 4** ON.
2. Write ke **char 4**: `[0x01, 0x01] + timeBytes(since, MINUTES)` — 8 byte: `yearLo,yearHi,month,day,hour,minute,0x00,tzQuarterHours`.
3. Band balas di **char 4**: `10 01 01` + `expectedLen(u32LE)` + tanggal(7B).
4. Kalau `expectedLen>0`: notify **char 5** ON, lalu write `[0x02]` ke char 4.
5. Data mengalir di **char 5**: tiap packet = `[counter] + payload`. counter harus berurutan (mulai 0). Gabung payload.
6. Selesai → band balas `10 02 01` di char 4 → write ack `[0x03]`.
7. **Parser Mi Band 5 (sampleSize=8)**: per 8 byte = 1 menit →
   `rawKind, rawIntensity, steps, heartRate, unknown1, sleep, deepSleep, remSleep`.
   Timestamp mulai dari tanggal yang dikirim band, +1 menit per sampel.

## 7. UUID penting
- Service main `0000fee0-...`, service auth `0000fee1-...`
- Auth char `00000009-0000-3512-2118-0009af100700`
- **Fetch char `00000004-0000-3512-2118-0009af100700`**
- **Activity data char `00000005-0000-3512-2118-0009af100700`**
- Realtime steps `00000007-...`, battery `00000006-...`, user settings `00000008-...`
- HR service `0000180d-...`, HR measure `00002a37-...`

## 8. Cara menjalankan
```bash
cd C:\web\ragefit
flutter pub get
flutter test          # opsional: verifikasi AES
flutter run           # WAJIB HP fisik; BLE tidak jalan di emulator
```
Sebelum connect: **uninstall/force-stop Zepp Life** di HP (jangan unpair).
Di app: tab **LANGKAH** → **HUBUNGKAN BAND** (status jadi `SIAP ✔`) →
**AMBIL DATA HARI INI**.

Catatan dependency: `flutter_secure_storage` **harus ^11.2.0** (bukan 9.x) karena
bentrok `win32` dengan paket `health`. minSdk sudah 26 (aman, butuh ≥21).

## 9. LANGKAH BERIKUTNYA (belum dikerjakan)
1. ~~Fetch data langkah + parser~~ **SELESAI**
2. Heart rate (service `180D` + control point `2a39`).
3. Database lokal (drift/sqflite) + dashboard grafik (fl_chart) dari `ActivitySample`.
4. Data tidur (sudah ada di sampel: field sleep/deepSleep/remSleep).
5. Opsional: auto-sync background (workmanager), export JSON/CSV.

## 10. Catatan lisensi
Protokol diambil dari **Gadgetbridge (AGPLv3)**. Untuk pemakaian pribadi aman;
kalau app didistribusikan, wajib ikut AGPLv3.

## 11. Ringkasan error yang pernah dihadapi
| Gejala | Arti | Solusi |
|--------|------|--------|
| `429 / NO location header` saat fetch key | Rate limit anti-bot Huami | Stop retry, jeda, ganti jaringan, mode Xiaomi |
| `version solving failed` (health vs secure_storage) | Bentrok win32 | Naikkan `flutter_secure_storage` ke ^11.2.0 |
| auth gagal | Key salah / firmware baru | Cek key, coba New Auth Protocol |
| Band tak muncul | Masih ter-pair ke Zepp Life | Uninstall Zepp Life (jangan unpair) |
| Fetch 0 sampel | Band baru reset / belum catat | Tunggu, jalan sebentar, fetch lagi |
