-- Phase 3A: User Profile Extensibility

-- 1. Add fields to profiles
alter table public.profiles
  add column if not exists username text unique,
  add column if not exists phone text,
  add column if not exists location text,
  add column if not exists bio text,
  add column if not exists updated_at timestamp with time zone default timezone('utc'::text, now());

-- 2. Create updated_at trigger function
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 3. Apply trigger to profiles
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row
  execute procedure public.handle_updated_at();

-- 4. Add insert policy for profiles
-- (Needed if auth.users trigger fails or if client ensures profile manually)
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);
