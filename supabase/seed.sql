-- Ambarket safe seed data
-- Tidak membuat user auth manual.
-- Produk dummy akan memakai profile pertama yang sudah ada sebagai seller.

insert into public.categories (name, icon)
values
  ('Elektronik', 'devices'),
  ('Fashion', 'checkroom'),
  ('Kendaraan', 'directions_car'),
  ('Perabotan', 'chair'),
  ('Buku', 'menu_book'),
  ('Hobi', 'sports_esports')
on conflict (name) do update
set icon = excluded.icon;

with seller as (
  select id
  from public.profiles
  order by created_at asc
  limit 1
),
electronics as (
  select id from public.categories where name = 'Elektronik' limit 1
),
fashion as (
  select id from public.categories where name = 'Fashion' limit 1
),
furniture as (
  select id from public.categories where name = 'Perabotan' limit 1
),
books as (
  select id from public.categories where name = 'Buku' limit 1
),
hobby as (
  select id from public.categories where name = 'Hobi' limit 1
)
insert into public.products (
  seller_id,
  category_id,
  title,
  description,
  price,
  condition,
  brand,
  location,
  is_negotiable,
  defects,
  completeness,
  usage_duration,
  status
)
select seller.id, electronics.id,
  'MacBook Pro M1 2020 Bekas',
  'MacBook Pro M1 pemakaian pribadi, performa normal, cocok untuk coding, kuliah, desain ringan, dan produktivitas.',
  10500000,
  'like_new',
  'Apple',
  'Semarang',
  true,
  'Lecet halus pemakaian normal.',
  'Unit, charger, dan box.',
  '3 tahun',
  'active'
from seller, electronics
where not exists (
  select 1 from public.products where title = 'MacBook Pro M1 2020 Bekas'
)

union all

select seller.id, electronics.id,
  'Samsung Galaxy A Series Bekas',
  'Smartphone Android bekas kondisi normal, layar aman, baterai masih awet untuk penggunaan harian.',
  1750000,
  'good',
  'Samsung',
  'Semarang',
  true,
  'Bodi terdapat baret tipis.',
  'Unit dan charger.',
  '2 tahun',
  'active'
from seller, electronics
where not exists (
  select 1 from public.products where title = 'Samsung Galaxy A Series Bekas'
)

union all

select seller.id, fashion.id,
  'Jaket Kulit Asli Vintage',
  'Jaket kulit vintage dengan bahan tebal, cocok untuk gaya kasual dan touring ringan.',
  450000,
  'good',
  'Vintage',
  'Semarang',
  true,
  'Ada kerutan alami pada kulit.',
  'Jaket saja.',
  '4 tahun',
  'active'
from seller, fashion
where not exists (
  select 1 from public.products where title = 'Jaket Kulit Asli Vintage'
)

union all

select seller.id, furniture.id,
  'Meja Belajar Minimalis Bekas',
  'Meja belajar minimalis kondisi kokoh, cocok untuk kamar kos atau ruang kerja kecil.',
  250000,
  'fair',
  'No Brand',
  'Semarang',
  true,
  'Ada goresan kecil di permukaan.',
  'Meja saja.',
  '1 tahun',
  'active'
from seller, furniture
where not exists (
  select 1 from public.products where title = 'Meja Belajar Minimalis Bekas'
)

union all

select seller.id, books.id,
  'Paket Buku Pemrograman Dasar',
  'Paket buku bekas untuk belajar pemrograman dasar, cocok untuk mahasiswa informatika.',
  120000,
  'good',
  'Mixed Publisher',
  'Semarang',
  false,
  'Beberapa halaman ada stabilo.',
  '3 buku.',
  '2 tahun',
  'active'
from seller, books
where not exists (
  select 1 from public.products where title = 'Paket Buku Pemrograman Dasar'
)

union all

select seller.id, hobby.id,
  'Controller Game Bluetooth Bekas',
  'Controller game bluetooth bekas, tombol masih responsif dan bisa dipakai untuk Android maupun PC.',
  180000,
  'good',
  'Generic',
  'Semarang',
  true,
  'Dus sudah tidak ada.',
  'Unit dan kabel.',
  '1 tahun',
  'active'
from seller, hobby
where not exists (
  select 1 from public.products where title = 'Controller Game Bluetooth Bekas'
);

insert into public.product_images (product_id, image_url, is_primary)
select p.id, 'https://placehold.co/900x700/png?text=MacBook+Pro+M1', true
from public.products p
where p.title = 'MacBook Pro M1 2020 Bekas'
and not exists (
  select 1 from public.product_images pi
  where pi.product_id = p.id and pi.image_url like '%MacBook%'
);

insert into public.product_images (product_id, image_url, is_primary)
select p.id, 'https://placehold.co/900x700/png?text=Samsung+Galaxy+Bekas', true
from public.products p
where p.title = 'Samsung Galaxy A Series Bekas'
and not exists (
  select 1 from public.product_images pi
  where pi.product_id = p.id and pi.image_url like '%Samsung%'
);

insert into public.product_images (product_id, image_url, is_primary)
select p.id, 'https://placehold.co/900x700/png?text=Jaket+Kulit+Vintage', true
from public.products p
where p.title = 'Jaket Kulit Asli Vintage'
and not exists (
  select 1 from public.product_images pi
  where pi.product_id = p.id and pi.image_url like '%Jaket%'
);

insert into public.product_images (product_id, image_url, is_primary)
select p.id, 'https://placehold.co/900x700/png?text=Meja+Belajar', true
from public.products p
where p.title = 'Meja Belajar Minimalis Bekas'
and not exists (
  select 1 from public.product_images pi
  where pi.product_id = p.id and pi.image_url like '%Meja%'
);

insert into public.product_images (product_id, image_url, is_primary)
select p.id, 'https://placehold.co/900x700/png?text=Buku+Pemrograman', true
from public.products p
where p.title = 'Paket Buku Pemrograman Dasar'
and not exists (
  select 1 from public.product_images pi
  where pi.product_id = p.id and pi.image_url like '%Buku%'
);

insert into public.product_images (product_id, image_url, is_primary)
select p.id, 'https://placehold.co/900x700/png?text=Controller+Game', true
from public.products p
where p.title = 'Controller Game Bluetooth Bekas'
and not exists (
  select 1 from public.product_images pi
  where pi.product_id = p.id and pi.image_url like '%Controller%'
);