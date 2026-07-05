# Release Notes: Ambarket RC1

**Build Name:** Ambarket RC1 (Release Candidate 1)  
**Date:** Juli 2026  
**Platform:** Android (APK / AAB) & Web Preview  

Ini adalah versi *Release Candidate* pertama untuk Ambarket, menandakan bahwa aplikasi telah berstatus *feature-complete* (seluruh fitur utama telah dibangun) dan memasuki tahap pemolesan kualitas (Quality Assurance) via skema *Closed Beta*.

## Fitur Utama yang Tersedia
- **Autentikasi:** Login/Register terintegrasi dengan Supabase Auth secara aman.
- **Marketplace Discovery:** Umpan beranda dengan dukungan pencarian (search debounce) dan paginasi yang dinamis (scroll-to-load).
- **Manajemen Profil & Penjual:** Halaman *dashboard* penjual, pembuatan produk, beserta unggahan gambar produk terhubung ke Supabase Storage.
- **Sistem Wishlist:** Penandaan barang favorit untuk disimpan.
- **Sistem Tawaran & Obrolan (*Offer & Realtime Chat*):** Pembeli dan penjual dapat melakukan tawar-menawar harga secara privat *realtime*.
- **Manajemen Pesanan (*Orders*):** Eksekusi checkout, status pengiriman, konfirmasi penerimaan barang.
- **Ulasan (*Reviews*):** Sistem pemberian rating terhadap kualitas layanan *seller*.
- **Moderasi & Pelaporan (*Reports*):** Pengguna dapat melaporkan pelanggaran/penipuan, dengan panel eksekusi khusus untuk admin.

## Sorotan Keamanan (Security Highlights)
- **Database RLS (Row Level Security):** Semua manipulasi data divalidasi pada tingkat *database*. Anda tidak bisa meretas/mengubah produk orang lain lewat API client.
- **Admin Guard & Audit Logs:** Eksekusi pelarangan pengguna (*suspend user*) dikunci dengan fungsi `SECURITY DEFINER`. Setiap pelarangan menghasilkan jejak audit di tabel `admin_audit_logs`.
- **Suspended User Trigger:** Akun yang masuk daftar blokir secara otomatis digugurkan aksesnya untuk membuat tawaran baru atau berjualan.
- **Safe Environment:** Tidak ada kunci *service_role* Supabase yang bocor ke aplikasi Flutter. Seluruh perutean menggunakan `publishable_key`.

## Batasan Diketahui (Known Limitations)
- **Payment Gateway:** Gateway pembayaran nyata (seperti Midtrans/Stripe) belum ditautkan sepenuhnya (saat ini *mock/simulated* untuk kepentingan alur transaksi).
- **Push Notification:** Belum diaktifkan. Pemberitahuan *chat* masih bergantung pada sinkronisasi *realtime* di dalam aplikasi (*in-app realtime listener*).
- **Moderation UI Limit:** Tampilan antarmuka untuk pelaporan (Review/Report) yang bersifat individual masih minimalis menunggu *feedback UX* lebih lanjut.
- **Lingkungan Database:** *Closed beta* ini sementara masih diarahkan ke *project* basis data pengembangan (*development/staging* Supabase).
- **Android Signing:** Artifact `.apk` dan `.aab` saat ini dikompilasi menggunakan *debug keystore* lokal atau *unsigned* via GitHub Actions CI, bukan menggunakan *production keystore*. Wajib di-*sign* sebelum perilisian ke Google Play Store.

## Catatan Instalasi (Installation Notes)
- File APK hasil CI/CD bernama: `ambarket-rc1-apk` (dalam format `.zip` berisi `app-release.apk`).
- File AppBundle hasil CI/CD bernama: `ambarket-rc1-aab` (dalam format `.zip` berisi `app-release.aab`).
- Silakan gunakan berkas `app-release.apk` hasil ekstrak dan pastikan perangkat mendukung *Install Unknown Sources*.
- Versi Android minimum: API 21 (Lollipop). Disarankan: Android 10+.


## Catatan untuk Tester
Apabila terjadi penutupan paksa aplikasi (*force close*) secara mendadak, segera gunakan templat (*BETA_FEEDBACK_TEMPLATE.md*) untuk merinci tindakan persis sebelum aplikasi tersebut mogok. Terus terang, uji aplikasi ini dengan interaksi paling ekstrem yang bisa Anda bayangkan!
