# Huashu White Marketplace - Visual Audit

## 1. Perubahan Tema Utama (Light Premium)
Ambarket telah sepenuhnya bermigrasi dari *Dark Glassmorphism* menjadi *Light Premium Marketplace* sesuai filosofi `huashu-design`:
- **Background**: Menggunakan off-white (`#F8FAFC`) untuk shell utama.
- **Surface**: Menggunakan putih solid (`#FFFFFF`) untuk kartu, navbar, dan header agar konten (gambar produk dan harga) lebih menonjol.
- **Primary Color**: Emerald Green (`#10B981`) digunakan sebagai warna aksen utama yang bersih dan merepresentasikan "Trust & Commerce".
- **Typografi**: Hirarki ditegaskan dengan weight `w600` untuk heading (H1-H4) agar teks tetap tajam di atas latar terang.

## 2. Refactoring Komponen Inti
- **AppGlassCard**: Blur *glassmorphism* dihapus di light mode. Kartu kini menggunakan border abu-abu yang sangat halus (`#E2E8F0`) dan shadow yang *soft* (hitam dengan alpha rendah), memberikan elevasi fisik yang natural (bukan flat UI).
- **Home Search Header**: Menjadi *solid surface* putih yang bersih, bukan lagi kaca transparan, dengan *border* bawah tipis.
- **Home Hero Carousel**: Gradien diperbarui agar kontras di latar terang. Banner pertama menggunakan kombinasi Emerald-Blue, sementara banner selanjutnya menggunakan off-white.
- **Bottom Navigation**: Background diubah menjadi putih bersih (`surface`) dengan indikator aktif berona Emerald transparan.
- **Product Card**: Shadow dan border halus ditambahkan. Gambar mendapat gradient hitam *hanya di bagian bawah* untuk memastikan *badge* status produk tetap terbaca dengan jelas.

## 3. Hasil Pengujian
- **Uji Fungsionalitas**: Masalah *empty state* pada Chat Screen yang memblokir *test* telah diselesaikan. Semua uji komponen `flutter test` kini berhasil lolos.
- **Uji Visual Responsif**: Layout dijamin tidak tumpang tindih berkat batasan constraint pada desktop (max-width 1200px) dan proporsi yang ditingkatkan pada carousel.

Semua perombakan ini telah menghilangkan kesan "Template AI statis" dan mengangkat visual Ambarket menjadi "Product-grade UI".
