-- Allow an admin owner to edit cashier identity fields for the same store.

begin;

drop function if exists public.admin_update_cashier_info(
  uuid,
  text,
  text,
  text
);

create or replace function public.admin_get_cashier_info(cashier_user_id uuid)
returns table (
  id uuid,
  email text,
  full_name text,
  role text,
  nik text,
  phone text,
  created_at text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_profile record;
  cashier_profile record;
  store_owner_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Sesi admin tidak ditemukan.';
  end if;

  select p.id, p.role, p.store_owner_user_id
  into caller_profile
  from public.profiles p
  where p.id = auth.uid();

  if not found then
    raise exception 'Profil admin tidak ditemukan.';
  end if;

  if caller_profile.role <> 'admin' then
    raise exception 'Hanya admin owner yang bisa melihat akun kasir.';
  end if;

  if cashier_user_id is null then
    raise exception 'Akun kasir belum dipilih.';
  end if;

  store_owner_id := coalesce(
    caller_profile.store_owner_user_id,
    caller_profile.id
  );

  select p.id, p.role, p.store_owner_user_id
  into cashier_profile
  from public.profiles p
  where p.id = cashier_user_id;

  if not found then
    raise exception 'Akun kasir tidak ditemukan.';
  end if;

  if cashier_profile.role <> 'kasir' then
    raise exception 'Hanya akun kasir yang bisa dilihat.';
  end if;

  if cashier_profile.store_owner_user_id <> store_owner_id then
    raise exception 'Akun kasir bukan bagian dari toko admin ini.';
  end if;

  return query
  select
    p.id,
    coalesce(nullif(p.email, ''), u.email, '') as email,
    coalesce(
      nullif(p.full_name, ''),
      nullif(u.raw_user_meta_data ->> 'full_name', '')
    ) as full_name,
    p.role,
    coalesce(
      nullif(p.nik, ''),
      nullif(u.raw_user_meta_data ->> 'nik', '')
    ) as nik,
    coalesce(
      nullif(p.phone, ''),
      nullif(u.raw_user_meta_data ->> 'phone', '')
    ) as phone,
    p.created_at
  from public.profiles p
  left join auth.users u on u.id = p.id
  where p.id = cashier_user_id;
end;
$$;

create or replace function public.admin_update_cashier_info(
  cashier_user_id uuid,
  cashier_email text,
  cashier_full_name text,
  cashier_nik text,
  cashier_phone text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_profile record;
  cashier_profile record;
  store_owner_id uuid;
  normalized_email text;
  normalized_full_name text;
  normalized_nik text;
  normalized_phone text;
begin
  if auth.uid() is null then
    raise exception 'Sesi admin tidak ditemukan.';
  end if;

  normalized_email := lower(btrim(coalesce(cashier_email, '')));
  normalized_full_name := btrim(coalesce(cashier_full_name, ''));
  normalized_nik := btrim(coalesce(cashier_nik, ''));
  normalized_phone := btrim(coalesce(cashier_phone, ''));

  if normalized_email = '' or position('@' in normalized_email) = 0 then
    raise exception 'Email kasir belum valid.';
  end if;

  if normalized_full_name = '' then
    raise exception 'Nama kasir wajib diisi.';
  end if;

  if normalized_nik !~ '^[0-9]{16}$' then
    raise exception 'NIK harus 16 digit angka.';
  end if;

  if length(normalized_phone) < 8 then
    raise exception 'No HP belum valid.';
  end if;

  select id, role, store_owner_user_id
  into caller_profile
  from public.profiles
  where id = auth.uid();

  if not found then
    raise exception 'Profil admin tidak ditemukan.';
  end if;

  if caller_profile.role <> 'admin' then
    raise exception 'Hanya admin owner yang bisa mengedit akun kasir.';
  end if;

  if cashier_user_id is null then
    raise exception 'Akun kasir belum dipilih.';
  end if;

  if cashier_user_id = auth.uid() then
    raise exception 'Akun admin tidak bisa diedit di sini.';
  end if;

  store_owner_id := coalesce(
    caller_profile.store_owner_user_id,
    caller_profile.id
  );

  select id, role, store_owner_user_id
  into cashier_profile
  from public.profiles
  where id = cashier_user_id;

  if not found then
    raise exception 'Akun kasir tidak ditemukan.';
  end if;

  if cashier_profile.role <> 'kasir' then
    raise exception 'Hanya akun kasir yang bisa diedit.';
  end if;

  if cashier_profile.store_owner_user_id <> store_owner_id then
    raise exception 'Akun kasir bukan bagian dari toko admin ini.';
  end if;

  if exists (
    select 1
    from auth.users u
    where lower(u.email) = normalized_email
      and u.id <> cashier_user_id
  ) then
    raise exception 'Email kasir sudah digunakan akun lain.';
  end if;

  update auth.users
  set email = normalized_email,
      raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb)
        || jsonb_build_object(
          'full_name', normalized_full_name,
          'nik', normalized_nik,
          'phone', normalized_phone,
          'role', 'kasir',
          'store_owner_user_id', store_owner_id
        ),
      updated_at = now()
  where id = cashier_user_id;

  update public.profiles
  set email = normalized_email,
      full_name = normalized_full_name,
      nik = normalized_nik,
      phone = normalized_phone,
      updated_at = timezone('utc', now())::text
  where id = cashier_user_id;

  return jsonb_build_object(
    'id', cashier_user_id,
    'email', normalized_email,
    'full_name', normalized_full_name,
    'nik', normalized_nik,
    'phone', normalized_phone,
    'updated', true
  );
end;
$$;

revoke all on function public.admin_get_cashier_info(uuid) from public;
grant execute on function public.admin_get_cashier_info(uuid) to authenticated;

revoke all on function public.admin_update_cashier_info(
  uuid,
  text,
  text,
  text,
  text
) from public;
grant execute on function public.admin_update_cashier_info(
  uuid,
  text,
  text,
  text,
  text
) to authenticated;

commit;
