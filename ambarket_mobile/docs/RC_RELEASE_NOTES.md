# Ambarket Release Notes
**Version**: Ambarket RC1 (Phase 9A Candidate)
**Codename**: "Huashu Premium"

## 🚀 Fitur Utama (Major Features)
- **Huashu-inspired Premium UI**: Desain antarmuka baru menggunakan palet warna elegan, efek _glassmorphism_ (`AppGlassCard`), latar belakang dinamis animasi gelombang ombak yang mewah (`AppAnimatedBackground`), dan *micro-animations*.
- **Dynamic Marketplace Home**: Navigasi dan penemuan produk interaktif dengan sinkronisasi ke profil dan notifikasi.
- **Produk & Keranjang (Buyer Flow)**: Transisi mulus dari menemukan barang, menambahkan ke keranjang, *checkout*, hingga pembayaran.
- **Seller Center (Dashboard)**: Pusat kendali untuk para pelapak mengelola produk, penawaran harga, riwayat order, dan performa tokonya. Termasuk **Review Insights**.
- **Fitur Negosiasi (Offer Center)**: Mekanisme tawar menawar di mana pembeli dan penjual berinteraksi secara aman mengubah harga.
- **Notification Center In-App**: Penjual dan pembeli selalu ter-sinkronisasi dengan segala update pesanan.

## 🛡️ Status Keamanan (Security Status)
- **Supabase Row Level Security (RLS)**: 100% dipatuhi. Pengguna hanya dapat memanipulasi data mereka sendiri. Data sensitif seperti laporan dan penarikan terisolasi dengan aman.
- **RPC Validation**: Eksploitasi panggilan RPC notifikasi dan manipulasi _Dummy Wallet_ via *API Tampering* telah dicegah menggunakan validasi *business logic* database (Triggers dan otorisasi *Security Definer*).
- **Safe Environment**: Tidak ada kunci *service_role* Supabase yang bocor ke aplikasi Flutter. Seluruh perutean menggunakan `publishable_key`.

## 🧪 Testing Status
- **Test Coverage**: 100% dari tes regresi inti terlewati dengan sempurna.
- **Code Analyzer**: 0 *issues found*!

## ⚠️ Known Limitations & Disclaimers
Harap baca dokumen secara terpisah: `docs/KNOWN_LIMITATIONS.md`. Aplikasi ini saat ini sedang dalam status *Closed Beta* (Dummy Simulation).

## 📥 Panduan Instalasi (Install Notes)
Jika Anda menggunakan rilis APK:
1. Unduh file `app-release.apk` dari rilis terbaru GitHub.
2. Izinkan penginstalan dari "Sumber Tidak Dikenal" (*Unknown Sources*) di Android Anda.
3. Gunakan email percobaan yang didaftarkan ke portal Supabase.
