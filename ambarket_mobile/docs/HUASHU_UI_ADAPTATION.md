# Analisis & Adaptasi Desain Huashu untuk Ambarket

Berdasarkan analisis repositori referensi `tools/huashu-design` dan demonstrasi *hero-animation*, desain Huashu (sering juga disebut Amvibe OS) mengusung filosofi *Premium, Glassmorphism, dan Typography-driven*. 

## 1. Identifikasi Elemen Huashu
- **Color Palette (Dark Premium):** Latar belakang tidak menggunakan hitam murni (`#000000`) melainkan gelap berlapis (`var(--bg)` dengan *surface* semi transparan/glass). Warna *ink* (teks utama) sangat kontras, sementara teks sekunder (*muted*, *dim*) dikontrol melalui opacity putih (misal: `rgba(255,255,255,0.40)`). Terdapat *accent* spesifik (seperti Terracotta `#D97757` atau Emerald `#2D4A3A`).
- **Typography Style:** Kuat pada tipe sans-serif modern (`Inter` atau *system fonts*) berpadu dengan tipe serif elegan untuk judul besar/hero teks. Berat font dimainkan dengan dinamis (tipis elegan di hero, bold di harga).
- **Glass Card & Hierarchy:** Panel konten menggunakan efek *glassmorphism* — warna dasar semitransparan, dengan *hairline border* (`rgba(255,255,255,0.12)`), *blur backdrop*, dan *shadow* halus untuk memisahkannya dari *background*.
- **Background Animation:** Sering kali terdapat *grid* subtil atau animasi latar belakang statis/partikel yang tidak mendominasi konten namun memberi kesan hidup.
- **Button & Navigation:** Tombol tidak selalu datar (*flat*); CTA utama memakai gradient/aksen terang, sementara tombol sekunder berupa *outline* tipis. Navigasi rapi dengan proporsi ruang kosong (*whitespace*) yang lapang.

## 2. Elemen yang Diadaptasi (Mapping ke Ambarket)
Kita akan mentransformasi UI *marketplace* biasa menjadi lebih premium dengan gaya berikut di Flutter:
1. **AppColors:** 
   - `background`: Dark slate/Charcoal yang elegan (misal: `#0F1115` atau `#121212`).
   - `surface`: Semi-transparan (`Colors.white.withOpacity(0.05)`) dikombinasikan dengan `BackdropFilter` (blur).
   - `accent`: Warna neon/cerah sebagai *primary* (misal: Emerald Green `#10B981` atau Neon Red/Coral `#F43F5E`) agar kontras dengan mode gelap.
   - `text`: Pure White untuk judul utama, Grey (opacity 0.6) untuk *subtitle*.
2. **AppTypography:** Penggunaan Google Fonts (`Inter` untuk sans, dan font elegan lain jika perlu) dengan struktur tebal untuk *Price*, tipis elegan untuk *Hero Title*, dan rapi untuk deskripsi.
3. **AppGlassCard:** Komponen inti pengganti `Card` standar Flutter. Akan memanfaatkan `Container` + `BackdropFilter` + border radius yang halus.
4. **AppAnimatedBackground:** Sebuah `CustomPainter` yang menggambar garis grid samar atau partikel di layar *Auth* dan *Home* (*hero section*).
5. **AppGradientButton & OutlineButton:** Menggantikan `ElevatedButton` polos untuk tombol utama seperti "Beli Sekarang", "Jual Barang", dll.

## 3. Elemen yang Tidak Cocok untuk Marketplace (Dihindari)
- **Animasi transisi yang terlalu lama (Tweak/Narration):** Huashu banyak dipakai untuk *demo/presentation*. Di aplikasi *marketplace* nyata (Ambarket), user ingin membeli dan mencari barang dengan cepat. Animasi hanya boleh di latar belakang atau *micro-interaction* (tombol ditekan), BUKAN menunda rute antar halaman.
- **Teks terlalu abstrak:** Konsep *hero text* di desain presentasi kadang terlalu filosofis. Di Ambarket, teks pahlawan harus fungsional ("Jual Beli Barang Bekas Berkualitas").
- **Tanpa Border Asli (Pure Glass):** *Marketplace* butuh kontras antara produk. Jika semua *glass*, gambar produk akan bocor. Akan digunakan kombinasi solid dark + glass border untuk *ProductCard*.

*Adaptasi ini akan berfokus pada fondasi (Theme, Typography, Core Widgets, Shell, Home, Profile, Auth) untuk memastikan keseluruhan aplikasi terasa seperti desain premium kelas-A, sebelum akhirnya diekspansi ke komponen yang lebih kecil di iterasi masa depan.*
