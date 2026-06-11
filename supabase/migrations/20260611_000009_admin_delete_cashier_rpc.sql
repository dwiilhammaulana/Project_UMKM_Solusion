-- Add a database RPC fallback for deleting cashier auth accounts.
-- This keeps account deletion working even when the Edge Function has not
-- been deployed yet.

begin;

create or replace function public.admin_delete_cashier(cashier_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_profile record;
  cashier_profile record;
  store_owner_id uuid;
  deleted_count integer;
begin
  if auth.uid() is null then
    raise exception 'Sesi admin tidak ditemukan.';
  end if;

  select id, role, store_owner_user_id
  into caller_profile
  from public.profiles
  where id = auth.uid();

  if not found then
    raise exception 'Profil admin tidak ditemukan.';
  end if;

  if caller_profile.role <> 'admin' then
    raise exception 'Hanya admin owner yang bisa menghapus akun kasir.';
  end if;

  if cashier_user_id is null then
    raise exception 'Akun kasir belum dipilih.';
  end if;

  if cashier_user_id = auth.uid() then
    raise exception 'Akun admin tidak bisa dihapus di sini.';
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
    raise exception 'Hanya akun kasir yang bisa dihapus.';
  end if;

  if cashier_profile.store_owner_user_id <> store_owner_id then
    raise exception 'Akun kasir bukan bagian dari toko admin ini.';
  end if;

  delete from auth.users
  where id = cashier_user_id;

  get diagnostics deleted_count = row_count;

  if deleted_count = 0 then
    delete from public.profiles
    where id = cashier_user_id;
  end if;

  return jsonb_build_object(
    'id', cashier_user_id,
    'deleted', true
  );
end;
$$;

revoke all on function public.admin_delete_cashier(uuid) from public;
grant execute on function public.admin_delete_cashier(uuid) to authenticated;

commit;
