-- PRICE RADAR: initial relational model
-- Apply only to a dedicated PRICE RADAR Supabase project.
-- All public-schema tables use RLS. Never put a service_role key in the PWA.

create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  parent_id uuid references public.categories(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  brand text,
  model text,
  gtin text,
  image_url text,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists products_gtin_unique
  on public.products (gtin) where gtin is not null;
create index if not exists products_name_search
  on public.products using gin (to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(brand, '') || ' ' || coalesce(model, '')));

create table if not exists public.sellers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  website_url text,
  country_code char(2),
  seller_type text not null default 'retailer'
    check (seller_type in ('retailer', 'marketplace', 'local_shop')),
  created_at timestamptz not null default now()
);

create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  seller_id uuid not null references public.sellers(id) on delete cascade,
  price numeric(14,2) not null check (price >= 0),
  currency char(3) not null,
  product_url text not null,
  availability text not null default 'unknown'
    check (availability in ('in_stock', 'out_of_stock', 'preorder', 'unknown')),
  source_type text not null
    check (source_type in ('retailer_feed', 'official_api', 'seller_submitted', 'community_submitted', 'editorial')),
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected', 'expired')),
  checked_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists offers_product_currency_price
  on public.offers (product_id, currency, price);
create index if not exists offers_verified_freshness
  on public.offers (verification_status, checked_at desc);

create table if not exists public.price_observations (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid not null references public.offers(id) on delete cascade,
  price numeric(14,2) not null check (price >= 0),
  currency char(3) not null,
  observed_at timestamptz not null default now(),
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected'))
);

create index if not exists price_observations_offer_time
  on public.price_observations (offer_id, observed_at desc);

create table if not exists public.price_submissions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id) on delete set null,
  seller_id uuid references public.sellers(id) on delete set null,
  submitted_by uuid not null references auth.users(id) on delete cascade,
  submitted_price numeric(14,2) not null check (submitted_price >= 0),
  currency char(3) not null,
  source_url text,
  shop_name text,
  country_code char(2),
  notes text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create index if not exists price_submissions_user_time
  on public.price_submissions (submitted_by, created_at desc);

create table if not exists public.user_watchlist (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  target_price numeric(14,2) check (target_price is null or target_price >= 0),
  currency char(3),
  created_at timestamptz not null default now(),
  primary key (user_id, product_id),
  check ((target_price is null and currency is null) or (target_price is not null and currency is not null))
);

-- Enable RLS on every exposed table.
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.sellers enable row level security;
alter table public.offers enable row level security;
alter table public.price_observations enable row level security;
alter table public.price_submissions enable row level security;
alter table public.user_watchlist enable row level security;

-- Public catalogue reads.
drop policy if exists "Public can read categories" on public.categories;
create policy "Public can read categories" on public.categories
  for select to anon, authenticated using (true);

drop policy if exists "Public can read products" on public.products;
create policy "Public can read products" on public.products
  for select to anon, authenticated using (true);

drop policy if exists "Public can read sellers" on public.sellers;
create policy "Public can read sellers" on public.sellers
  for select to anon, authenticated using (true);

-- Only approved, non-expired offers are visible to the public.
drop policy if exists "Public can read verified current offers" on public.offers;
create policy "Public can read verified current offers" on public.offers
  for select to anon, authenticated
  using (
    verification_status = 'verified'
    and checked_at is not null
    and checked_at >= now() - interval '30 days'
    and (expires_at is null or expires_at > now())
  );

drop policy if exists "Public can read verified price history" on public.price_observations;
create policy "Public can read verified price history" on public.price_observations
  for select to anon, authenticated using (verification_status = 'verified');

-- Users can submit prices and inspect only their own submissions.
drop policy if exists "Users can submit price reports" on public.price_submissions;
create policy "Users can submit price reports" on public.price_submissions
  for insert to authenticated
  with check ((select auth.uid()) = submitted_by);

drop policy if exists "Users can read their own price reports" on public.price_submissions;
create policy "Users can read their own price reports" on public.price_submissions
  for select to authenticated
  using ((select auth.uid()) = submitted_by);

-- Watchlists are private and scoped to the signed-in owner.
drop policy if exists "Users can read their own watchlist" on public.user_watchlist;
create policy "Users can read their own watchlist" on public.user_watchlist
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "Users can add to their own watchlist" on public.user_watchlist;
create policy "Users can add to their own watchlist" on public.user_watchlist
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own watchlist" on public.user_watchlist;
create policy "Users can update their own watchlist" on public.user_watchlist
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can remove from their own watchlist" on public.user_watchlist;
create policy "Users can remove from their own watchlist" on public.user_watchlist
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Explicit minimum grants for the browser Data API.
grant select on public.categories, public.products, public.sellers,
  public.offers, public.price_observations to anon, authenticated;
grant select, insert on public.price_submissions to authenticated;
grant select, insert, update, delete on public.user_watchlist to authenticated;
