-- Phase 3B: Seller Product Management & Storage

-- 1. Add fields to products
alter table public.products
  add column if not exists updated_at timestamp with time zone default timezone('utc'::text, now()),
  add column if not exists sold_at timestamp with time zone;

-- 2. Create updated_at trigger function for products
create or replace function public.handle_products_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 3. Apply trigger to products
create trigger set_products_updated_at
  before update on public.products
  for each row
  execute procedure public.handle_products_updated_at();

-- 4. Create product-images storage bucket
insert into storage.buckets (id, name, public) 
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- 5. Storage RLS Policies for product-images
-- Anyone can view the images
create policy "Product images are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'product-images' );

-- Users can upload images to their own folder (folder path is {uid}/...)
create policy "Sellers can upload product images"
  on storage.objects for insert
  with check ( 
    bucket_id = 'product-images' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can update/delete their own images
create policy "Sellers can update own product images"
  on storage.objects for update
  using ( 
    bucket_id = 'product-images' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Sellers can delete own product images"
  on storage.objects for delete
  using ( 
    bucket_id = 'product-images' and
    auth.uid()::text = (storage.foldername(name))[1]
  );
