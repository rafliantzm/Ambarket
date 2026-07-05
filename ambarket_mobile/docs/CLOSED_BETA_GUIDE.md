# Ambarket Closed Beta Tester Guide

Selamat datang di pengujian awal (Closed Beta) untuk Ambarket – platform jual beli barang bekas modern!

## 1. Tujuan Closed Beta
Tujuan utama dari pengujian ini adalah memastikan kelancaran seluruh transaksi, pencarian barang, stabilitas aplikasi, serta memastikan bahwa batas keamanan (hak akses antar penjual, pembeli, dan moderator) berjalan semestinya sebelum aplikasi diluncurkan ke publik.

## 2. Cara Install APK
1. Unduh file `app-release.apk` yang telah disediakan oleh tim pengembang.
2. Pada perangkat Android, masuk ke **Settings > Security** dan pastikan **"Install from Unknown Sources"** telah diaktifkan (bervariasi per perangkat).
3. Buka file `.apk` dan tekan **Install**.
4. Buka aplikasi Ambarket yang kini muncul di layar utama (ber-icon hijau dengan gambar keranjang).

## 3. Cara Login / Register
- Jika Anda belum memiliki akun, masuk ke tab **Profile** atau coba berinteraksi dengan produk, lalu pilih **Register**.
- Masukkan Email dan Password Anda.
- *(Catatan: Konfirmasi email mungkin tidak diperlukan untuk fase testing ini bergantung konfigurasi backend, silakan coba langsung login jika pendaftaran berhasil).*

## 4. Rekomendasi Skenario Uji Wajib
Kami merekomendasikan Anda untuk memiliki minimal dua akun (satu sebagai Penjual, satu sebagai Pembeli) untuk menguji fitur secara menyeluruh, atau berinteraksi dengan tester lain. 
Lakukan skenario berikut:

### Skenario Dasar:
- [ ] Register / Login.
- [ ] Edit Profile (Ganti nama & avatar).

### Skenario Penjual (Seller):
- [ ] Buat Produk baru (Upload gambar, set kategori, harga, dan kondisi).
- [ ] Edit Produk (Ubah harga/deskripsi).
- [ ] Terima Tawaran (Accept Offer) dari pembeli di halaman chat.
- [ ] Tandai barang sebagai "Terkirim" di menu Order.

### Skenario Pembeli (Buyer):
- [ ] Cari Produk dengan fitur *Search* dan coba *Filter* (rentang harga, kondisi).
- [ ] Tambahkan produk ke keranjang *Wishlist*.
- [ ] Kirim Pesan / *Chat* kepada penjual.
- [ ] Ajukan Tawaran Harga (*Make Offer*).
- [ ] Simulasikan Checkout (pembayaran dummy).
- [ ] Tandai Pesanan sebagai "Diterima".
- [ ] Beri *Review* dan Rating (Bintang) untuk penjual.

### Skenario Keamanan / Moderasi:
- [ ] Lakukan fungsi *Report* pada produk yang tidak senonoh / fiktif.
- [ ] Jika Anda mendapat akun khusus "Suspended", pastikan Anda **DITOLAK** saat mencoba mengirim penawaran, mengubah produk, atau memulai percakapan.

## 5. Cara Melaporkan Bug
Jika Anda menemukan *error* (layar merah, macet, fitur tidak bereaksi), atau masalah UI/UX, mohon isi [BETA_FEEDBACK_TEMPLATE.md](./BETA_FEEDBACK_TEMPLATE.md) dan kirimkan kembali kepada tim kami melalui kanal Discord/Email khusus tester.
