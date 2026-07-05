-- Profiles
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  name text,
  avatar_url text,
  role text default 'user' check (role in ('user', 'admin')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Categories
create table public.categories (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  icon text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Products
create table public.products (
  id uuid default gen_random_uuid() primary key,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete restrict not null,
  title text not null,
  description text not null,
  price numeric not null check (price >= 0),
  condition text not null,
  brand text,
  location text not null,
  is_negotiable boolean default false,
  defects text,
  completeness text,
  usage_duration text,
  status text default 'active' check (status in ('active', 'sold', 'archived')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Product Images
create table public.product_images (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references public.products(id) on delete cascade not null,
  image_url text not null,
  is_primary boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Wishlists
create table public.wishlists (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  product_id uuid references public.products(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, product_id)
);

-- Trigger for auth.users to public.profiles
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.wishlists enable row level security;

-- RLS Policies

-- Profiles: Anyone can read, users can update their own
create policy "Public profiles are viewable by everyone" on public.profiles for select using (true);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

-- Categories: Anyone can read, only admins can insert/update (for now just read is needed for discovery)
create policy "Categories are viewable by everyone" on public.categories for select using (true);

-- Products: Anyone can read active products, sellers can CRUD their own
create policy "Active products are viewable by everyone" on public.products for select using (status = 'active');
create policy "Sellers can view all their products" on public.products for select using (auth.uid() = seller_id);
create policy "Sellers can insert their products" on public.products for insert with check (auth.uid() = seller_id);
create policy "Sellers can update their products" on public.products for update using (auth.uid() = seller_id);
create policy "Sellers can delete their products" on public.products for delete using (auth.uid() = seller_id);

-- Product Images: Anyone can read if product is active (simplified: anyone can read)
create policy "Product images are viewable by everyone" on public.product_images for select using (true);
create policy "Sellers can manage product images" on public.product_images for all using (
  auth.uid() in (select seller_id from public.products where id = product_id)
);

-- Wishlists: Users can CRUD their own
create policy "Users can view own wishlists" on public.wishlists for select using (auth.uid() = user_id);
create policy "Users can insert own wishlists" on public.wishlists for insert with check (auth.uid() = user_id);
create policy "Users can delete own wishlists" on public.wishlists for delete using (auth.uid() = user_id);
