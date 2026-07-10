# Panduan GitHub Release Tagging
**Ambarket Mobile CI/CD**

Dokumen ini menjelaskan alur pembuatan versi rilis melalui *Git Tags* yang terintegrasi dengan GitHub Actions.

---

## 🚀 1. Mekanisme Git Tag & Pemicu (*Trigger*)
Setiap kali pengembang mendorong (*push*) tag yang berawalan `v` (contoh: `v0.9.0-rc1` atau `v1.0.0`) ke repositori GitHub, GitHub Actions secara otomatis akan menjalankan *workflow* yang telah didefinisikan pada file `.github/workflows/ambarket_android_release.yml`.

**Langkah membuat rilis baru melalui Terminal:**
1. Pastikan Anda berada di branch utama (*main* atau *master*) dan semua perubahan sudah di-*commit*:
   ```bash
   git status
   ```
2. Buat Tag baru dengan anotasi rilis:
   ```bash
   git tag v0.9.0-rc1
   ```
3. Dorong tag tersebut ke remote repositori (GitHub):
   ```bash
   git push origin v0.9.0-rc1
   ```

Setelah perintah dijalankan, buka halaman tab **Actions** di GitHub Anda. Anda akan melihat _pipeline build_ mulai berjalan.

---

## 📦 2. Artefak Rilis (Expected Artifacts)
Apabila proses kompilasi sukses, GitHub Actions akan menghasilkan dan mengunggah artefak berikut pada ringkasan *workflow*:
1. **APK (`ambarket-release-apk`)**: Format standar untuk diinstal manual (_sideloading_) oleh *Beta Tester*.
2. **AAB (`ambarket-release-aab`)**: Android App Bundle, format ini diwajibkan oleh Google jika Anda bermaksud mengunggah aplikasi ke Konsol Google Play Store.

---

## 🔑 3. Prasyarat GitHub Secrets
Workflow ini mengompilasi APK dan AAB pada mode *Release*, yang mana wajib di-*signed* dengan Keystore Produksi (bukan *debug keystore*). Karena keamanan adalah prioritas, file Keystore dan Sandi **TIDAK PERNAH** dimasukkan ke dalam basis kode Git.

Anda harus mengatur rahasia (*Secrets*) di **Settings > Secrets and variables > Actions** pada repositori GitHub Anda:

**Signing Secrets:**
- `ANDROID_KEYSTORE_BASE64` : Isi _file_ upload-keystore.jks yang sudah di-*encode* ke teks Base64.
- `ANDROID_KEYSTORE_PASSWORD` : Kata sandi untuk membuka Keystore (storePassword).
- `ANDROID_KEY_ALIAS` : Nama alias kunci (*keyAlias*), contoh: `upload`.
- `ANDROID_KEY_PASSWORD` : Kata sandi untuk kunci alias (*keyPassword*).

**Supabase Environment Secrets:**
- `SUPABASE_URL` : URL Endpoint API Supabase untuk basis data produksi/beta Anda.
- `SUPABASE_PUBLISHABLE_KEY` : Kunci anonim klien untuk disematkan di aplikasi klien. (Ingat, JANGAN memasukkan `service_role`).

Saat *runner* berjalan, skrip akan merekonstruksi file `key.properties` dan file `.jks` _on-the-fly_ untuk menyukseskan tahap kompilasi.
