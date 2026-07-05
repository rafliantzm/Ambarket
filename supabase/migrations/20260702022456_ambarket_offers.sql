-- Create offers table
create table public.offers (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  offer_price numeric not null check (offer_price > 0),
  message text,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger for updated_at
create trigger handle_offers_updated_at
  before update on public.offers
  for each row
  execute function public.handle_updated_at();

-- Enable RLS
alter table public.offers enable row level security;

-- RLS Policies

-- 1. Buyer can insert for themselves, but not for their own products
create policy "Buyers can insert their own offers"
  on public.offers for insert
  with check (
    auth.uid() = buyer_id 
    and auth.uid() != seller_id
    and status = 'pending'
  );

-- 2. Buyer can view their own sent offers
create policy "Buyers can view their sent offers"
  on public.offers for select
  using (auth.uid() = buyer_id);

-- 3. Seller can view offers received for their products
create policy "Sellers can view received offers"
  on public.offers for select
  using (auth.uid() = seller_id);

-- 4. Buyer can cancel their own pending offers
create policy "Buyers can update their own pending offers (cancel)"
  on public.offers for update
  using (auth.uid() = buyer_id and status = 'pending')
  with check (status = 'cancelled');

-- 5. Seller can accept or reject pending offers
create policy "Sellers can update pending offers (accept/reject)"
  on public.offers for update
  using (auth.uid() = seller_id and status = 'pending')
  with check (status in ('accepted', 'rejected'));
