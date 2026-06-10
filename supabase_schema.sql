create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  email text,
  role text default 'user' check (role in ('user', 'admin')),
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.files (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  original_name text not null,
  stored_name text not null,
  file_path text not null,
  file_type text not null,
  file_size bigint not null check (file_size > 0),
  status text default 'private' check (status in ('private', 'shared', 'deleted')),
  download_count int default 0 check (download_count >= 0),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.share_links (
  id uuid primary key default gen_random_uuid(),
  file_id uuid references public.files(id) on delete cascade not null,
  token text unique not null,
  access_type text not null check (access_type in ('public', 'protected', 'private', 'specific_user')),
  password_hash text,
  expired_at timestamptz,
  is_active boolean default true,
  can_view boolean default true,
  can_download boolean default true,
  created_by uuid references auth.users(id) on delete cascade not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.share_recipients (
  id uuid primary key default gen_random_uuid(),
  share_link_id uuid references public.share_links(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade,
  email text,
  can_view boolean default true,
  can_download boolean default true,
  created_at timestamptz default now()
);

alter table public.share_links
add column if not exists can_view boolean default true;

alter table public.share_links
add column if not exists can_download boolean default true;

alter table public.share_recipients
add column if not exists can_view boolean default true;

alter table public.share_recipients
add column if not exists can_download boolean default true;

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  file_id uuid references public.files(id) on delete set null,
  action text not null,
  status text not null check (status in ('success', 'failed')),
  platform text,
  ip_address text,
  user_agent text,
  created_at timestamptz default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, email, role, status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    'user',
    'active'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists touch_profiles_updated_at on public.profiles;
create trigger touch_profiles_updated_at before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists touch_files_updated_at on public.files;
create trigger touch_files_updated_at before update on public.files
for each row execute function public.touch_updated_at();

drop trigger if exists touch_share_links_updated_at on public.share_links;
create trigger touch_share_links_updated_at before update on public.share_links
for each row execute function public.touch_updated_at();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'admin'
      and status = 'active'
  );
$$;

alter table public.profiles enable row level security;
alter table public.files enable row level security;
alter table public.share_links enable row level security;
alter table public.share_recipients enable row level security;
alter table public.activity_logs enable row level security;

do $$
begin
  alter publication supabase_realtime add table public.profiles;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.files;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.share_links;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.share_recipients;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.activity_logs;
exception when duplicate_object then null;
end $$;

drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin" on public.profiles
for select using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
for insert with check (id = auth.uid() and role = 'user');

drop policy if exists "profiles_update_own_basic" on public.profiles;
create policy "profiles_update_own_basic" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "profiles_admin_update" on public.profiles;
create policy "profiles_admin_update" on public.profiles
for update using (public.is_admin()) with check (public.is_admin());

drop policy if exists "files_select_own_or_admin" on public.files;
create policy "files_select_own_or_admin" on public.files
for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "files_insert_own" on public.files;
create policy "files_insert_own" on public.files
for insert with check (user_id = auth.uid());

drop policy if exists "files_update_own_or_admin" on public.files;
create policy "files_update_own_or_admin" on public.files
for update using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "files_delete_admin" on public.files;
create policy "files_delete_admin" on public.files
for delete using (public.is_admin());

drop policy if exists "share_links_select_owner_or_admin" on public.share_links;
create policy "share_links_select_owner_or_admin" on public.share_links
for select using (
  public.is_admin()
  or exists (select 1 from public.files f where f.id = file_id and f.user_id = auth.uid())
  or exists (
    select 1
    from public.share_recipients sr
    where sr.share_link_id = id
      and (sr.user_id = auth.uid() or sr.email = auth.email())
  )
);

drop policy if exists "share_links_insert_owner" on public.share_links;
create policy "share_links_insert_owner" on public.share_links
for insert with check (
  created_by = auth.uid()
  and exists (select 1 from public.files f where f.id = file_id and f.user_id = auth.uid())
);

drop policy if exists "share_links_update_owner_or_admin" on public.share_links;
create policy "share_links_update_owner_or_admin" on public.share_links
for update using (
  public.is_admin()
  or exists (select 1 from public.files f where f.id = file_id and f.user_id = auth.uid())
);

drop policy if exists "share_recipients_owner_or_admin" on public.share_recipients;
create policy "share_recipients_owner_or_admin" on public.share_recipients
for all using (
  public.is_admin()
  or user_id = auth.uid()
  or email = auth.email()
  or exists (
    select 1
    from public.share_links sl
    join public.files f on f.id = sl.file_id
    where sl.id = share_link_id and f.user_id = auth.uid()
  )
);

drop policy if exists "activity_logs_select_own_or_admin" on public.activity_logs;
create policy "activity_logs_select_own_or_admin" on public.activity_logs
for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "activity_logs_insert_authenticated" on public.activity_logs;
create policy "activity_logs_insert_authenticated" on public.activity_logs
for insert with check (auth.uid() is not null);

insert into storage.buckets (id, name, public)
values ('secure-files', 'secure-files', false)
on conflict (id) do update set public = false;

drop policy if exists "secure_files_owner_upload" on storage.objects;
create policy "secure_files_owner_upload" on storage.objects
for insert with check (
  bucket_id = 'secure-files'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "secure_files_owner_manage" on storage.objects;
create policy "secure_files_owner_manage" on storage.objects
for update using (
  bucket_id = 'secure-files'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "secure_files_owner_delete" on storage.objects;
create policy "secure_files_owner_delete" on storage.objects
for delete using (
  bucket_id = 'secure-files'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Public share download must go through Edge Function generate-download-url.
-- The service role can read objects and issue short-lived signed URLs after validation.
