-- Add owner/cashier team roles for the POS app.
-- Safe to run from Supabase SQL Editor after the ownership/RLS migrations.

begin;

alter table public.profiles
  add column if not exists role text;

alter table public.profiles
  alter column role set default 'admin';

update public.profiles
set role = 'admin'
where role is null or btrim(role) = '';

update public.profiles
set role = 'kasir'
where role not in ('admin', 'kasir');

alter table public.profiles
  alter column role set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_role_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_role_check
      check (role in ('admin', 'kasir'));
  end if;
end $$;

alter table public.profiles
  add column if not exists store_owner_user_id uuid references auth.users (id) on delete cascade;

update public.profiles
set store_owner_user_id = id
where store_owner_user_id is null;

alter table public.profiles
  alter column store_owner_user_id set not null;

create index if not exists idx_profiles_store_owner_user_id
  on public.profiles (store_owner_user_id);

create or replace function public.current_store_owner_user_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select p.store_owner_user_id
      from public.profiles p
      where p.id = auth.uid()
      limit 1
    ),
    auth.uid()
  )
$$;

create or replace function public.current_profile_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select p.role
      from public.profiles p
      where p.id = auth.uid()
      limit 1
    ),
    'admin'
  )
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_profile_role() = 'admin'
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role text;
  requested_store_owner uuid;
begin
  requested_role := coalesce(new.raw_user_meta_data ->> 'role', 'admin');
  if requested_role not in ('admin', 'kasir') then
    requested_role := 'kasir';
  end if;

  requested_store_owner := coalesce(
    nullif(new.raw_user_meta_data ->> 'store_owner_user_id', '')::uuid,
    new.id
  );

  insert into public.profiles (
    id,
    email,
    full_name,
    avatar_url,
    role,
    store_owner_user_id,
    created_at,
    updated_at
  )
  values (
    new.id,
    coalesce(new.email, ''),
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url',
    requested_role,
    requested_store_owner,
    timezone('utc', now())::text,
    timezone('utc', now())::text
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(excluded.full_name, public.profiles.full_name),
        avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
        role = coalesce(public.profiles.role, excluded.role),
        store_owner_user_id = coalesce(
          public.profiles.store_owner_user_id,
          excluded.store_owner_user_id
        ),
        updated_at = timezone('utc', now())::text;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_select_team" on public.profiles;
drop policy if exists "profiles_insert_self" on public.profiles;
drop policy if exists "profiles_update_self" on public.profiles;

create policy "profiles_select_team"
on public.profiles
for select
using (
  id = auth.uid()
  or (
    public.is_admin()
    and store_owner_user_id = public.current_store_owner_user_id()
  )
);

create policy "profiles_insert_self"
on public.profiles
for insert
with check (id = auth.uid());

create policy "profiles_update_self"
on public.profiles
for update
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "app_profile_owner_all" on public.app_profile;
create policy "app_profile_owner_all"
on public.app_profile
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "categories_owner_all" on public.categories;
create policy "categories_owner_all"
on public.categories
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "products_owner_all" on public.products;
create policy "products_owner_all"
on public.products
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "customers_owner_all" on public.customers;
create policy "customers_owner_all"
on public.customers
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "transactions_owner_all" on public.transactions;
create policy "transactions_owner_all"
on public.transactions
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "transaction_items_owner_all" on public.transaction_items;
create policy "transaction_items_owner_all"
on public.transaction_items
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "debts_owner_all" on public.debts;
create policy "debts_owner_all"
on public.debts
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "debt_payments_owner_all" on public.debt_payments;
create policy "debt_payments_owner_all"
on public.debt_payments
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "stock_movements_owner_all" on public.stock_movements;
create policy "stock_movements_owner_all"
on public.stock_movements
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

drop policy if exists "operational_costs_owner_all" on public.operational_costs;
create policy "operational_costs_owner_all"
on public.operational_costs
for all
using (owner_user_id = public.current_store_owner_user_id())
with check (owner_user_id = public.current_store_owner_user_id());

grant execute on function public.current_store_owner_user_id() to authenticated;
grant execute on function public.current_profile_role() to authenticated;
grant execute on function public.is_admin() to authenticated;

commit;
