-- Add cashier identity fields used by the account management screen.

begin;

alter table public.profiles
  add column if not exists nik text,
  add column if not exists phone text;

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
    nik,
    phone,
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
    new.raw_user_meta_data ->> 'nik',
    new.raw_user_meta_data ->> 'phone',
    requested_role,
    requested_store_owner,
    timezone('utc', now())::text,
    timezone('utc', now())::text
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(excluded.full_name, public.profiles.full_name),
        avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url),
        nik = coalesce(excluded.nik, public.profiles.nik),
        phone = coalesce(excluded.phone, public.profiles.phone),
        role = coalesce(public.profiles.role, excluded.role),
        store_owner_user_id = coalesce(
          public.profiles.store_owner_user_id,
          excluded.store_owner_user_id
        ),
        updated_at = timezone('utc', now())::text;

  return new;
end;
$$;

commit;
