# Android Release Signing Status

## Status Saat Ini (Current Status)
Saat ini proyek Ambarket Mobile (Kandidat Rilis RC1) dikompilasi pada mode **Release** namun masih menggunakan *debug keystore* bawaan (atau *unsigned* jika tidak di-setup di environment).
Oleh karena itu, file APK hasil build (melalui GitHub Actions CI/CD) mungkin masih menggunakan default debug keystore dan bukan *production keystore*. Ini adalah limitasi yang dicatat sebelum rilis penuh ke Google Play Store.

## Panduan Pengaturan Keystore Produksi
Jika aplikasi siap diunggah ke Google Play, wajib membuat keystore produksi.

1. **Membuat Keystore Lokal:**
   Gunakan perintah `keytool` (pastikan Java JDK terinstall):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Setup file `key.properties`:**
   Buat file `android/key.properties` (JANGAN DI-COMMIT):
   ```properties
   storePassword=<password-dari-keystore>
   keyPassword=<password-dari-alias>
   keyAlias=upload
   storeFile=<path-ke-upload-keystore.jks>
   ```

## Aturan Keamanan (Security Rules)
Untuk melindungi kredensial *signing*:
- File `key.properties` **TIDAK BOLEH** di-*commit* ke repositori git.
- File keystore (`*.jks`, `*.keystore`) **TIDAK BOLEH** di-*commit*.
- Keduanya telah diblokir secara otomatis via `.gitignore`.

## Menyimpan Kredensial di GitHub Actions
Jika ingin melakukan build App Bundle (AAB) *signed* via GitHub Actions CI:
1. Simpan isi `.jks` sebagai base64 string ke GitHub Secrets (misal: `KEYSTORE_BASE64`).
2. Simpan sandi-sandi ke GitHub Secrets: `KEY_PASSWORD`, `STORE_PASSWORD`, `KEY_ALIAS`.
3. Di dalam skrip `.github/workflows/ambarket_android_release.yml`, tambahkan instruksi untuk men-decode base64 kembali menjadi file `.jks` dan memasukkan environment variables ke dalam proses *build* gradle.

*Catatan Tambahan:* Google Play mewajibkan format **Android App Bundle (.aab)** yang sudah di-*sign* dengan production key.
