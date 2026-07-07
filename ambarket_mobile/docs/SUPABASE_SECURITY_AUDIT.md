# Supabase Security & RLS Audit

Dokumen ini merangkum hasil audit Row Level Security (RLS) dan Remote Procedure Call (RPC) di database Supabase untuk memastikan Phase 9A siap diluncurkan.

## Table Audit Status

| Table Name | Status RLS | Kebijakan SELECT | Kebijakan INSERT/UPDATE/DELETE |
| --- | --- | --- | --- |
| `profiles` | Aktif | Publik (Bisa dibaca semua orang) | Hanya user terkait (`id = auth.uid()`) |
| `products` | Aktif | Publik (Bisa dibaca semua orang) | Hanya penjual (`seller_id = auth.uid()`) |
| `product_images` | Aktif | Publik | Hanya penjual (via subquery ke `products`) |
| `wishlists` | Aktif | Hanya pemilik (`user_id = auth.uid()`) | Hanya pemilik (`user_id = auth.uid()`) |
| `cart_items` | Aktif | Hanya pemilik (`buyer_id = auth.uid()`) | Hanya pemilik (`buyer_id = auth.uid()`) |
| `offers` | Aktif | Pembeli dan Penjual (OR) | Pembuat (Insert), Keduanya (Update status) |
| `orders` | Aktif | Pembeli dan Penjual (OR) | Pembeli (Insert), Keduanya (Update status) |
| `reviews` | Aktif | Publik | Hanya pembeli (`user_id = auth.uid()`) |
| `reports` | Aktif | Hanya admin (Role khusus) | Hanya pelapor (`reporter_id = auth.uid()`) |
| `seller_wallets`| Aktif | Hanya pemilik (`seller_id = auth.uid()`) | Internal RPC / Hanya pemilik |
| `seller_withdrawals` | Aktif | Hanya pemilik (`seller_id = auth.uid()`) | Hanya pemilik |
| `notifications` | Aktif | Hanya pemilik (`user_id = auth.uid()`) | Hanya pemilik (Update khusus `is_read`) |

## Security Hardening Details

### 1. Notifications Hardening
- **Trigger**: Kolom tabel `notifications` dikunci melalui trigger `prevent_notification_tampering` pada `BEFORE UPDATE`. Pengguna HANYA diizinkan mengubah kolom `is_read`. Upaya memodifikasi pesan `title`, `body`, `type`, atau *foreign keys* akan langsung digagalkan (Raise Exception).
- **RPC `create_dummy_notification`**: Terdapat validasi *business logic* yang mengecek eksistensi transaksi pada `orders` dan `offers` untuk memastikan bahwa seorang pengguna (misalnya pembeli) hanya dapat memicu notifikasi ke pihak yang berelasi dengannya (misalnya penjual), sehingga menutup celah aksi _spam_ lintas pengguna.

### 2. Wallet & Financial Flow (Dummy)
- **RPC `process_dummy_withdrawal`**: Saldo diverifikasi secara ketat agar tidak boleh kurang dari jumlah yang ditarik, dan pembaruan `balance` dilakukan dalam satu transaksi atomik beserta _insertion_ pada tabel `seller_withdrawals`.
- **RPC `sync_seller_wallet`**: Proses kalkulasi pemasukan disimulasikan dari tabel `orders` yang berstatus `completed`. Pemasukan dummy ini divalidasi dan diakumulasikan. 

## Kesimpulan
Keseluruhan policy RLS sudah terkonfigurasi dengan sangat baik dan menjamin asas **Least Privilege**. Celah eksploitasi pada sisi Wallet dan Notifikasi (yang dipicu dari *client*) telah ditutup melalui validasi logika (RPC) dan Trigger. Ambarket aman dari ancaman eksploitasi data oleh *Authenticated Users*.
