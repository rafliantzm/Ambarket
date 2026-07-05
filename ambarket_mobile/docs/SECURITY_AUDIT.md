# Phase 7A: Security Audit

Dokumen ini berisi hasil audit postur keamanan aplikasi Ambarket.

## 1. RLS (Row Level Security) Summary
Seluruh fungsionalitas bisnis dilindungi pada level database melalui Supabase RLS. Klien hanya menggunakan *Publishable Key* (Anon Key) dan semua akses difilter otomatis berdasarkan `auth.uid()`.
- **Profiles:** Publik dapat melihat. Update hanya diizinkan untuk diri sendiri. Kolom sensitif seperti `role` dan `is_suspended` dicabut aksesnya dari tabel publik (`REVOKE UPDATE`) sehingga aman.
- **Products:** Operasi INSERT/UPDATE/DELETE wajib memenuhi `auth.uid() = seller_id`. Publik hanya bisa me-SELECT jika `status = 'active'`.
- **Offers:** Pembeli (Buyer) hanya dapat melakukan INSERT jika produk bukan miliknya. 
- **Conversations & Messages:** Akses partisipan dibatasi mutlak via pengecekan silang terhadap relasi `buyer_id` dan `seller_id`.
- **Orders:** Hanya pembeli dari offer terkait yang bisa membuat entitas.
- **Reviews:** Hanya dapat dibuat jika Order berstatus `completed`.
- **Reports:** Terbuka untuk diisi (*insert*) tapi dibatasi visibilitas (*select*) hanya untuk pembuat dan admin.

## 2. Admin Security
Keamanan administratif (Moderasi) menggunakan Custom Helper Function `public.is_admin()`, yang berjalan dengan `SECURITY DEFINER` mengecek tabel profil. Ini menjamin kebijakan RLS Admin kebal terhadap manipulasi JWT atau sesi front-end. Akses UI dilindungi oleh GoRouter `redirect` yang melakukan validasi *Role*.

## 3. Suspended User Enforcement
Database menggunakan kombinasi *Trigger Check*: `check_user_not_suspended()`. Trigger ini dijalankan `BEFORE INSERT OR UPDATE` pada tabel Products, Offers, Messages, Orders, Reviews, dan Reports. Solusi ini paling handal karena jika frontend Flutter secara tidak sengaja mengizinkan klik (sebelum *state update*), transaksi database akan melempar `RAISE EXCEPTION`.

## 4. Storage Policy
Bucket `product-images` dilindungi dengan kebijakan path. Pengguna hanya dapat melakukan INSERT, UPDATE, dan DELETE file pada direktori yang namanya sesuai dengan *UUID* mereka: `auth.uid()::text = (storage.foldername(name))[1]`.

## 5. Route Guard
Semua URL internal dipastikan tidak bocor. Routing utama diatur pada `app_router.dart`:
- Rute `/login` dan `/register` diarahkan kembali ke `/` (home) jika sesi masih aktif.
- Rute seperti `/chats`, `/seller`, `/wishlist`, `/orders` diarahkan ke `/login` jika tidak ada sesi.
- Rute `/admin/*` diverifikasi role-nya. Jika tidak valid, ditolak kembali ke `/`.

## 6. Known Risks / Limitations
- *DDoS on Auth API:* Supabase Rate Limiting standar diterapkan.
- File Orphan di Storage: Jika entitas dihapus, gambar fisik tidak serta merta terhapus kecuali jika ada trigger khusus atau Supabase Edge Function untuk cron cleanup (direkomendasikan untuk pengembangan tingkat lanjut/Production).
