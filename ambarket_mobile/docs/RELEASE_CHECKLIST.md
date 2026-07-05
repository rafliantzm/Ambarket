# Ambarket Release Checklist

Dokumen ini berisi panduan dan persyaratan infrastruktur sebelum aplikasi direkomendasikan untuk masuk ke rilis Production (serta untuk persiapan RC1).

## 1. Environment & Secrets
- [x] File `.env` dipastikan tersimpan aman dan tidak masuk ke version control (Github).
- [x] Key API di klien dipastikan HANYA `SUPABASE_PUBLISHABLE_KEY` (Anon Key). `SERVICE_ROLE_KEY` haram ditaruh di *client*.
- [x] `.env.example` terverifikasi aman.
- [ ] Lingkungan *production* Supabase harus dikonfigurasi (untuk saat ini masih *staging/development* di tahap *Closed Beta*).

## 2. Supabase Migrations & Storage
- [x] Semua file migrasi SQL di bawah direktori `supabase/migrations/` berhasil di-`push` ke *remote db*.
- [x] Constraint tabel (anti-pesan kosong) sukses di-deploy.
- [x] RLS diaktifkan di SEMUA tabel.
- [x] Bucket `product-images` telah ter-provision dan berstatus publik dengan batas *insert/update/delete* berdasarkan `auth.uid()`.

## 3. Test Accounts & Admin Setup
- [x] Akun pengguna *test* (buyer/seller) telah disiapkan.
- [x] Setidaknya satu akun diberikan *role* `admin`.
- [x] Trigger otomatis profil saat insert `auth.users` berfungsi.

## 4. Build Validation & CI/CD (Phase 7D.1)
- [x] `flutter analyze` passed (termasuk di CI).
- [x] `flutter test` passed (termasuk di CI).
- [x] `flutter build web` passed.
- [x] GitHub Actions Android build tersedia.
- [x] GitHub Secrets `SUPABASE_URL` tersedia.
- [x] GitHub Secrets `SUPABASE_PUBLISHABLE_KEY` tersedia.
- [x] APK artifact berhasil dibuat di CI.
- [x] AAB artifact berhasil dibuat di CI.
- [x] Status signing dicatat sebagai limitation pada rilis ini (Unsigned/Debug).

## 5. Manual RC Smoke Test (Tertunda via CI)
- [ ] APK diunduh dari CI.
- [ ] APK diinstall di device fisik.
- [ ] Smoke test Android selesai (Login, Upload, Chat, Order, Report, Moderation).
- [x] Known limitations didokumentasikan di `RC_RELEASE_NOTES.md`.

## 6. Known Limitations to Monitor
- **Orphan Files**: Gambar tidak akan langsung terhapus dari bucket ketika `products` dihapus. 
- **Database indexing**: sudah diimplementasi pada Phase 7B (selesai).
- **Android Signing**: Artefak build saat ini mungkin belum menggunakan production keystore.
