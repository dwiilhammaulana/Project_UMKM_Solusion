-- Fix fallback behavior for users whose profiles row is missing during onboarding.
-- Safe to run from Supabase SQL Editor.

begin;

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

grant execute on function public.current_store_owner_user_id() to authenticated;
grant execute on function public.current_profile_role() to authenticated;

commit;
