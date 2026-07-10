# Panduan Penguji Closed Beta (Closed Beta Tester Guide)
**Ambarket Mobile - Phase 9B**

Selamat datang di pengujian internal tertutup (Closed Beta) Ambarket. Pengujian ini bertujuan untuk menguji fungsionalitas aplikasi dari ujung ke ujung (*end-to-end*) sebelum peluncuran komersial, dengan tujuan mendeteksi dan melaporkan _bug_ terkait *user experience* dan integrasi alur kerja (Buyer dan Seller).

---

## 📲 Cara Instalasi (Sideload APK)
Aplikasi ini belum didistribusikan melalui Google Play Store. Untuk menginstall, ikuti langkah berikut:
1. Unduh file `app-release.apk` atau `app-debug.apk` yang dibagikan oleh tim *developer*.
2. Buka file APK tersebut di *smartphone* Android Anda.
3. Anda mungkin akan melihat peringatan keamanan Android. Izinkan penginstalan dari "Sumber Tidak Dikenal" (*Unknown Sources*).
4. **Catatan Play Protect**: Karena aplikasi belum diverifikasi oleh Google Play Protect, akan muncul peringatan "Unsafe app blocked" atau serupa. Ketuk **More details** lalu ketuk **Install anyway**.

---

## 👥 Rekomendasi Akun Testing
Untuk menguji fitur yang maksimal, sangat disarankan Anda membuat 2 akun atau berkoordinasi dengan tester lain:
- **Akun Buyer (Pembeli)**: Untuk menjelajah beranda, berbelanja, *checkout*, menawar barang, dan menulis ulasan.
- **Akun Seller (Penjual)**: Untuk memasukkan barang jualan ke sistem, melacak performa, menjawab tawaran, mengelola pesanan, dan mengecek mutasi *dummy wallet*.
- **Akun Admin**: (Jika diberikan oleh koordinator) Untuk memantau laporan pelanggaran dan melakukan suspensi produk/pengguna.

---

## 🎯 Daftar Fitur Wajib Uji (QA Matrix)
Harap telusuri dan pastikan kelancaran alur dari fitur-fitur di bawah ini:
- **Auth**: Daftar, masuk, dan keluar akun.
- **Browse Product**: Navigasi Beranda (*Home*) dinamis, *scroll*, dan pencarian.
- **Product Detail**: Pembacaan informasi produk dan penjual.
- **Wishlist**: Menyimpan barang favorit.
- **Cart**: Memasukkan barang dan menyesuaikan kuantitas keranjang.
- **Checkout & Voucher**: Proses memesan barang, menggunakan voucher *dummy*, memilih metode pengiriman.
- **Payment Dummy & Invoice**: Simulasi pembayaran tanpa uang nyata dan memvalidasi munculnya resi/faktur.
- **Tracking**: Melacak perkembangan status pengiriman produk (`packed` -> `shipped` -> `completed`).
- **Offer (Penawaran)**: Tawar menawar harga melalui *Offer Center*.
- **Chat**: Sistem pesan singkat antar pembeli dan penjual (bila tersedia).
- **Seller Dashboard**: Visualisasi data performa lapak untuk si penjual.
- **Seller Orders & Offers**: Manajemen konfirmasi kirim barang dan persetujuan tawaran.
- **Seller Products**: *Listing* produk baru, pengubahan harga, dan menonaktifkan barang (*archive*).
- **Seller Wallet Dummy**: Memastikan saldo bertambah saat status order `completed` dan fungsi Penarikan Fiktif (`Withdrawal Dummy`).
- **Notification Center**: Pengecekan riwayat pesan otomatis untuk order masuk, tawaran baru, dll.
- **Admin Moderation**: Pembredelan (*suspend*) entitas bermasalah (bila memiliki akses *admin*).

---

## ⚠️ Batasan Pengujian (Limitations)
Mohon diingat bahwa pada versi Beta ini:
1. **Payment Dummy**: Gateway pembayaran masih menggunakan simulator bawaan. **TIDAK ADA UANG NYATA** yang ditarik.
2. **Shipping Dummy**: Opsi ekspedisi (JNE/J&T) dan sistem resi pelacakan (tracking) hanya sebuah simulasi fiktif yang dimutasi langsung oleh aksi Penjual.
3. **Wallet Dummy**: Saldo yang tampil di akun Penjual hanyalah poin digital (*dummy revenue*), tidak mencerminkan transaksi bank asli.
4. Jangan mengeksploitasi sistem menggunakan injeksi skrip di sisi klien (semuanya telah diamankan di *backend* via RPC & RLS).

Silakan rekam dan kumpulkan _bug_ yang Anda temukan berdasarkan format *Bug Report Template* resmi. Selamat menguji!
