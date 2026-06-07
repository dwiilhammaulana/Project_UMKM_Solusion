-- Configure Supabase Storage for product and profile images.
-- Safe to run from the Supabase SQL Editor after the auth/team migrations.

begin;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'app-media',
  'app-media',
  true,
  5242880,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif'
  ]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "app_media_public_read" on storage.objects;
create policy "app_media_public_read"
on storage.objects
for select
using (bucket_id = 'app-media');

drop policy if exists "app_media_team_insert" on storage.objects;
create policy "app_media_team_insert"
on storage.objects
for insert
with check (
  bucket_id = 'app-media'
  and (storage.foldername(name))[1] = public.current_store_owner_user_id()::text
);

drop policy if exists "app_media_team_update" on storage.objects;
create policy "app_media_team_update"
on storage.objects
for update
using (
  bucket_id = 'app-media'
  and (storage.foldername(name))[1] = public.current_store_owner_user_id()::text
)
with check (
  bucket_id = 'app-media'
  and (storage.foldername(name))[1] = public.current_store_owner_user_id()::text
);

drop policy if exists "app_media_team_delete" on storage.objects;
create policy "app_media_team_delete"
on storage.objects
for delete
using (
  bucket_id = 'app-media'
  and (storage.foldername(name))[1] = public.current_store_owner_user_id()::text
);

commit;
