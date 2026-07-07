# Manual QA Matrix Checklist
Versi: Release Candidate (Phase 9A)

Gunakan daftar centang di bawah ini untuk menguji secara manual fitur-fitur kritis pada aplikasi sebelum didistribusikan ke pengguna beta.

## 1. Authentication & Profil
- [ ] Mendaftar (Register) akun baru berjalan lancar.
- [ ] Masuk (Login) dengan email dan password berhasil.
- [ ] Keluar (Logout) menghapus sesi dan mengembalikan ke layar login.
- [ ] Mengakses halaman *Protected Route* (contoh: Profil) memicu *redirect* otomatis ke *login* jika belum masuk.

## 2. Alur Pembeli (Buyer Flow)
- [ ] **Home**: Banner promosi, pencarian dinamis, dan produk penemuan dimuat sempurna.
- [ ] **Pencarian**: Kata kunci merespons secara real-time dan tepat.
- [ ] **Detail Produk**: Foto, harga, deksripsi, dan status stok tertampil dengan antarmuka elegan.
- [ ] **Wishlist**: Pembeli dapat menambahkan/menghapus produk ke daftar keinginan.
- [ ] **Keranjang**: Tambah produk, ubah jumlah stok, dan hitung subtotal otomatis bekerja.
- [ ] **Checkout**: Dapat memilih item dari keranjang untuk di-checkout.
- [ ] **Voucher & Pengiriman**: Fitur pemilihan kurir *dummy* dan voucher pemotongan berfungsi.
- [ ] **Pembayaran**: Gateway pembayaran *dummy* mensimulasikan konfirmasi dan menghasilkan _Invoice_ berhasil.
- [ ] **Order Tracking**: Status pesanan mulai dari `pending_payment` hingga `completed` terlihat dalam bentuk linimasa (timeline).
- [ ] **Review**: Pembeli dapat meninggalkan rating dan ulasan pada pesanan yang sudah *completed*.
- [ ] **Notifikasi**: Pembeli menerima notifikasi ketika status pesanan berubah.

## 3. Alur Penjual (Seller Flow)
- [ ] **Seller Dashboard**: Ringkasan performa dan *Quick Actions* dimuat.
- [ ] **Product Management**: Penjual dapat menambah, mengedit, serta mengubah status arsip produk.
- [ ] **Seller Orders**: Penjual dapat memproses pesanan (contoh: menandai dikemas dan dikirim).
- [ ] **Offer Center**: Penjual dapat merespons tawaran (Terima, Tolak, atau Ajukan Tawaran Balik).
- [ ] **Wallet & Withdrawal**: Saldo penjual (`dummy_balance`) tersinkron dengan pesanan yang selesai. Penarikan fiktif mencatat riwayat pemrosesan.
- [ ] **Review Insights**: Penjual dapat membaca rangkuman ulasan dari tokonya.
- [ ] **Notifikasi**: Penjual menerima notifikasi ketika ada pesanan/tawaran masuk.

## 4. Alur Admin (Admin Flow)
- [ ] **Dashboard**: Statistik seluruh aplikasi.
- [ ] **Moderasi Produk**: Admin dapat memoderasi produk yang melanggar.
- [ ] **Suspensi Pengguna**: Admin dapat menangguhkan user.
- [ ] **Moderasi Ulasan**: Menghapus ulasan tidak pantas.

## 5. Security & Edge Cases
- [ ] **RLS Product**: Pengguna biasa HANYA bisa mengedit produk yang ia buat sendiri (URL _tampering_ gagal).
- [ ] **Checkout Validation**: Pembeli TIDAK BOLEH membeli produk yang di-posting oleh dirinya sendiri (mencegah cuci saldo fiktif).
- [ ] **Stok Validation**: Produk yang telah terjual habis atau diarsipkan tidak bisa ditambahkan ke keranjang.
- [ ] **Wallet Exploit**: Saldo tidak bisa dimanipulasi bebas dari _client request_.
- [ ] **Notification Exploit**: *Dummy RPC* tidak mengizinkan satu user men-_spam_ user lain tanpa ikatan transaksi (Order/Offer).
- [ ] **Suspended User**: User yang disuspensi tidak bisa berinteraksi di _Marketplace_.
