-- Store the account identity that created each transaction.

begin;

alter table public.transactions
  add column if not exists created_by_user_id uuid
    references public.profiles (id)
    on delete set null,
  add column if not exists created_by_name text;

update public.transactions t
set created_by_user_id = coalesce(t.created_by_user_id, t.owner_user_id),
    created_by_name = coalesce(
      nullif(btrim(t.created_by_name), ''),
      nullif(btrim(p.full_name), ''),
      nullif(btrim(p.email), ''),
      t.owner_user_id::text
    )
from public.profiles p
where p.id = t.owner_user_id
  and (
    t.created_by_user_id is null
    or t.created_by_name is null
    or btrim(t.created_by_name) = ''
  );

create index if not exists idx_transactions_created_by_user_id
  on public.transactions (created_by_user_id);

commit;
