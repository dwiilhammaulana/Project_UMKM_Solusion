begin;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  full_name text,
  avatar_url text,
  created_at text not null default timezone('utc', now())::text,
  updated_at text not null default timezone('utc', now())::text
);

create or replace function public.handle_profile_timestamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := timezone('utc', now())::text;
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.handle_profile_timestamp();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    full_name,
    avatar_url,
    created_at,
    updated_at
  )
  values (
    new.id,
    coalesce(new.email, ''),
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url',
    timezone('utc', now())::text,
    timezone('utc', now())::text
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(excluded.full_name, public.profiles.full_name),
        avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
        updated_at = timezone('utc', now())::text;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

insert into public.profiles (id, email, full_name, avatar_url, created_at, updated_at)
select
  u.id,
  coalesce(u.email, ''),
  u.raw_user_meta_data ->> 'full_name',
  u.raw_user_meta_data ->> 'avatar_url',
  timezone('utc', now())::text,
  timezone('utc', now())::text
from auth.users u
on conflict (id) do nothing;

delete from public.app_profile
where id = 'store-main';

alter table public.app_profile
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.categories
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.products
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.customers
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.transactions
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.transaction_items
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.debts
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.debt_payments
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.stock_movements
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.operational_costs
  add column if not exists owner_user_id uuid references auth.users (id) on delete cascade;

alter table public.app_profile
  alter column owner_user_id set not null;

alter table public.categories
  alter column owner_user_id set not null;

alter table public.products
  alter column owner_user_id set not null;

alter table public.customers
  alter column owner_user_id set not null;

alter table public.transactions
  alter column owner_user_id set not null;

alter table public.transaction_items
  alter column owner_user_id set not null;

alter table public.debts
  alter column owner_user_id set not null;

alter table public.debt_payments
  alter column owner_user_id set not null;

alter table public.stock_movements
  alter column owner_user_id set not null;

alter table public.operational_costs
  alter column owner_user_id set not null;

create index if not exists idx_app_profile_owner_user_id
  on public.app_profile (owner_user_id);

create index if not exists idx_categories_owner_user_id
  on public.categories (owner_user_id);

create index if not exists idx_products_owner_user_id
  on public.products (owner_user_id);

create index if not exists idx_customers_owner_user_id
  on public.customers (owner_user_id);

create index if not exists idx_transactions_owner_user_id
  on public.transactions (owner_user_id);

create index if not exists idx_transaction_items_owner_user_id
  on public.transaction_items (owner_user_id);

create index if not exists idx_debts_owner_user_id
  on public.debts (owner_user_id);

create index if not exists idx_debt_payments_owner_user_id
  on public.debt_payments (owner_user_id);

create index if not exists idx_stock_movements_owner_user_id
  on public.stock_movements (owner_user_id);

create index if not exists idx_operational_costs_owner_user_id
  on public.operational_costs (owner_user_id);

alter table public.profiles enable row level security;
alter table public.app_profile enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_items enable row level security;
alter table public.debts enable row level security;
alter table public.debt_payments enable row level security;
alter table public.stock_movements enable row level security;
alter table public.operational_costs enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "app_profile_owner_all" on public.app_profile;
create policy "app_profile_owner_all"
on public.app_profile
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "categories_owner_all" on public.categories;
create policy "categories_owner_all"
on public.categories
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "products_owner_all" on public.products;
create policy "products_owner_all"
on public.products
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "customers_owner_all" on public.customers;
create policy "customers_owner_all"
on public.customers
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "transactions_owner_all" on public.transactions;
create policy "transactions_owner_all"
on public.transactions
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "transaction_items_owner_all" on public.transaction_items;
create policy "transaction_items_owner_all"
on public.transaction_items
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "debts_owner_all" on public.debts;
create policy "debts_owner_all"
on public.debts
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "debt_payments_owner_all" on public.debt_payments;
create policy "debt_payments_owner_all"
on public.debt_payments
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "stock_movements_owner_all" on public.stock_movements;
create policy "stock_movements_owner_all"
on public.stock_movements
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "operational_costs_owner_all" on public.operational_costs;
create policy "operational_costs_owner_all"
on public.operational_costs
for all
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

commit;
