# Templat Laporan Bug (Beta Bug Report Template)
**Versi Aplikasi:** Ambarket Closed Beta (Phase 9B)

Saat Anda menemukan anomali, kegagalan (*crash*), atau kesalahan tampilan di aplikasi, mohon gunakan format pelaporan di bawah ini untuk memudahkan tim Developer/Engineer menelusuri sumber masalahnya.

---

### 📝 Judul Bug
*(Contoh: Tombol Checkout Tidak Responsif Setelah Menghapus Item)*
**[Tuliskan judul bug yang singkat dan jelas di sini]**

### 👤 Role Tester
*(Pilih salah satu: Buyer / Seller / Admin)*
**[Role Anda saat bug terjadi]**

### 📱 Informasi Perangkat (Device & Environment)
- **Merek/Tipe Device:** (contoh: Samsung Galaxy S23 Ultra / Google Chrome)
- **Versi OS / Browser:** (contoh: Android 14 / Chrome M119)
- **App Version / Commit Hash:** (contoh: v0.9.0-rc1 / e.g. 730a305)

### 🔄 Langkah Reproduksi (Steps to Reproduce)
*(Tuliskan langkah-langkah presisi untuk memicu bug tersebut)*
1. Buka aplikasi dan Login sebagai Buyer.
2. Masuk ke halaman Detail Produk XYZ.
3. Klik tombol "Tambah ke Keranjang".
4. Buka Keranjang dan hapus item tersebut.
5. ...

### ❌ Hasil yang Terjadi (Actual Result)
*(Apa yang aplikasi lakukan secara keliru?)*
**[Jelaskan hasil yang tidak diharapkan di sini]**

### ✅ Hasil yang Diharapkan (Expected Result)
*(Apa yang seharusnya aplikasi lakukan?)*
**[Jelaskan sistem yang ideal/benar di sini]**

### 📸 Lampiran (Screenshots/Video)
*(Tautkan link gambar, rekam layar, atau lampirkan file di bawah ini)*
**[Lampiran Visual]**

### 🚨 Tingkat Keparahan (Severity)
*(Hapus opsi yang tidak perlu)*
- **Critical** (Aplikasi crash, Force Close, atau _blocker_ utama alur belanja)
- **High** (Fitur inti tidak berfungsi sebagian, mis. gagal upload gambar produk)
- **Medium** (Fitur bekerja namun ada logika yang salah perhitungan)
- **Low** (Masalah tampilan UI, _typo_, animasi _glitch_)

### 🏷️ Area Dampak (Impact Area)
*(Hapus area yang tidak terdampak)*
- Auth (Login/Register)
- Product (List, Search, Detail)
- Checkout / Cart
- Order / Tracking
- Seller Center (Dashboard, Kelola Produk, Offer Center)
- Wallet / Withdrawal
- Notification
- Admin / Moderasi
- UI / UX (Tampilan Antarmuka)
- Performance (Lag / Loading lama)
