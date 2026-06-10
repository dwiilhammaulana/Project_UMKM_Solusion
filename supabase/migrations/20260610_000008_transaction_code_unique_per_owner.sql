begin;

alter table public.transactions
  drop constraint if exists transactions_transaction_code_key;

create unique index if not exists idx_transactions_owner_transaction_code
  on public.transactions (owner_user_id, transaction_code);

commit;
