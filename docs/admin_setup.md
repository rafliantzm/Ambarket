# Panduan Setup Admin Ambarket

Aplikasi Ambarket didesain agar role `admin` tidak bisa di-set dari sisi klien (Flutter) untuk alasan keamanan. Role ini harus diberikan secara manual langsung ke database.

Berikut adalah cara mengubah sebuah akun pengguna biasa menjadi **Admin** menggunakan Supabase SQL Editor.

## Langkah-Langkah

1. Buka [Supabase Dashboard](https://supabase.com/dashboard).
2. Pilih project Ambarket Anda.
3. Di menu sidebar sebelah kiri, klik **SQL Editor**.
4. Klik **New Query**.
5. Salin dan tempel perintah SQL berikut ke dalam editor:

```sql
-- Ganti 'email_pengguna@domain.com' dengan email akun yang ingin dijadikan admin.

UPDATE public.profiles
SET role = 'admin'
WHERE id = (
    SELECT id
    FROM auth.users
    WHERE email = 'email_pengguna@domain.com'
);
```

6. Jika Anda tidak mengetahui emailnya namun mengetahui **username**-nya, Anda bisa menggunakan query ini:

```sql
-- Ganti 'username_pengguna' dengan username yang sesuai

UPDATE public.profiles
SET role = 'admin'
WHERE username = 'username_pengguna';
```

7. Klik tombol **Run** (atau tekan `Cmd/Ctrl + Enter`) untuk mengeksekusi query.
8. Buka aplikasi Ambarket di device/emulator Anda. Jika sebelumnya Anda sudah login menggunakan akun tersebut, silakan **Logout (Keluar)** lalu **Login kembali** agar data profil (termasuk role admin) bisa di-refresh dan menu Admin Dashboard muncul di halaman Akun Saya.

## Keamanan
- Halaman admin seperti `/admin`, `/admin/reports`, `/admin/users`, dll secara otomatis akan mendeteksi apakah profil Anda memiliki role `admin`. Jika bukan admin, Anda akan langsung ditolak (diredirect ke halaman Home).
- Jangan pernah membagikan `service_role_key` Supabase ke aplikasi Flutter. Gunakan `anon_key` untuk klien, dan kontrol akses sepenuhnya melalui skema SQL Role atau Row Level Security (RLS) di Supabase.
