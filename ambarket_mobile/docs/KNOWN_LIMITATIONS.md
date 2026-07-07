# Known Limitations
Versi: Ambarket RC1 (Phase 9A)

Aplikasi Ambarket saat ini dirilis dalam fase **Closed Beta** (Uji Coba Tertutup). Selama fase ini, beberapa sistem belum terintegrasi dengan penyedia layanan (*third-party*) eksternal yang nyata di dunia nyata. 

Berikut adalah batasan sistem yang secara sengaja diimplementasikan dalam versi ini:

### 1. Pembayaran (Payment Gateway)
- Belum ada integrasi dengan penyedia *Payment Gateway* nyata seperti Midtrans, Xendit, atau Stripe.
- Seluruh proses Checkout akan diarahkan ke antarmuka **Payment Dummy**. Status transaksi secara otomatis berubah menjadi `Lunas` saat Anda mengeklik "Simulasikan Pembayaran Berhasil". 
- Tidak ada uang nyata yang ditransaksikan.

### 2. Pengiriman Logistik (Shipping)
- Sistem kurir dan ongkos kirim masih berupa simulasi statis (JNE Reguler 10.000 / J&T Express 12.000 dll).
- Belum ada API pelacakan paket (*resi/airwaybill*) asli seperti RajaOngkir atau kurir lainnya.
- Penjual cukup mengeklik tombol aksi untuk mengubah status pesanan (`Dikemas` -> `Dikirim` -> `Selesai`) secara instan.

### 3. Penarikan Saldo Penjual (Withdrawal)
- Saldo Dompet Penjual (*Seller Wallet*) terisi hanya sebagai simulasi dari pesanan yang sukses.
- Proses pencairan dana (*Withdrawal*) menggunakan bank/rekening simulasi. Uang tidak akan ditransfer ke rekening bank asli di dunia nyata.

### 4. Notifikasi
- Push Notifications melalui Firebase Cloud Messaging (FCM/APNS) **belum diaktifkan**.
- Semua notifikasi saat ini hanya bersifat *In-App* (terlihat ketika aplikasi dibuka dan masuk ke halaman Notification Center).

### 5. Distribusi
- Aplikasi **belum dirilis** di Google Play Store (Production Listing).
- Saat ini distribusi berjalan manual via penyebaran APK melalui _GitHub Release_ (sideloading).

> Semua limitasi ini dirancang agar siklus pengujian QA (Quality Assurance) dapat berjalan mulus dari ujung ke ujung (end-to-end) pada platform mandiri, tanpa terhalang prasyarat izin finansial & infrastruktur.
