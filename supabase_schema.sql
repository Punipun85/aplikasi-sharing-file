create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  email text,
  avatar_url text,
  role text default 'user' check (role in ('user', 'admin')),
  status text default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles
add column if not exists avatar_url text;

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
  is_encrypted boolean default false,
  encryption_algorithm text default 'AES-256-GCM',
  encryption_key text,
  encryption_nonce text,
  encryption_mac text,
  plain_sha256 text,
  encrypted_sha256 text,
  risk_status text default 'unknown' check (risk_status in ('unknown', 'clean', 'suspicious', 'malicious')),
  risk_reason text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.files
add column if not exists is_encrypted boolean default false;

alter table public.files
add column if not exists encryption_algorithm text default 'AES-256-GCM';

alter table public.files
add column if not exists encryption_key text;

alter table public.files
add column if not exists encryption_nonce text;

alter table public.files
add column if not exists encryption_mac text;

alter table public.files
add column if not exists plain_sha256 text;

alter table public.files
add column if not exists encrypted_sha256 text;

alter table public.files
add column if not exists risk_status text default 'unknown';

alter table public.files
add column if not exists risk_reason text;

do $$
begin
  alter table public.files
  add constraint files_risk_status_check
  check (risk_status in ('unknown', 'clean', 'suspicious', 'malicious'));
exception when duplicate_object then null;
end $$;

create table if not exists public.share_links (
  id uuid primary key default gen_random_uuid(),
  file_id uuid references public.files(id) on delete cascade not null,
  token text unique not null,
  access_type text not null check (access_type in ('public', 'protected', 'private', 'specific_user')),
  password_hash text,
  password_delivery_token text unique,
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

alter table public.share_links
add column if not exists password_delivery_token text;

create unique index if not exists share_links_password_delivery_token_key
on public.share_links(password_delivery_token)
where password_delivery_token is not null;

create table if not exists public.threat_signatures (
  sha256 text primary key,
  label text not null,
  severity text default 'malicious' check (severity in ('suspicious', 'malicious')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now()
);

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

create or replace function public.classify_file_risk()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  matched public.threat_signatures%rowtype;
begin
  select *
  into matched
  from public.threat_signatures
  where sha256 in (new.plain_sha256, new.encrypted_sha256)
  order by case severity when 'malicious' then 0 else 1 end
  limit 1;

  if found then
    new.risk_status = matched.severity;
    new.risk_reason = 'Matched threat signature: ' || matched.label;
  elsif new.plain_sha256 is not null or new.encrypted_sha256 is not null then
    new.risk_status = coalesce(new.risk_status, 'clean');
    if new.risk_status = 'unknown' then
      new.risk_status = 'clean';
    end if;
    new.risk_reason = coalesce(new.risk_reason, 'No known threat signature match');
  end if;

  return new;
end;
$$;

drop trigger if exists touch_profiles_updated_at on public.profiles;
create trigger touch_profiles_updated_at before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists touch_files_updated_at on public.files;
create trigger touch_files_updated_at before update on public.files
for each row execute function public.touch_updated_at();

drop trigger if exists classify_file_risk_before_write on public.files;
create trigger classify_file_risk_before_write before insert or update of plain_sha256, encrypted_sha256 on public.files
for each row execute function public.classify_file_risk();

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

create or replace function public.owns_file(target_file_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.files
    where id = target_file_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.owns_share_link(target_share_link_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.share_links sl
    join public.files f on f.id = sl.file_id
    where sl.id = target_share_link_id
      and (sl.created_by = auth.uid() or f.user_id = auth.uid())
  );
$$;

create or replace function public.can_access_share_link(target_share_link_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.share_recipients sr
    where sr.share_link_id = target_share_link_id
      and (
        sr.user_id = auth.uid()
        or lower(sr.email) = lower(auth.email())
      )
  );
$$;

create or replace function public.admin_list_file_audits()
returns table (
  id uuid,
  user_id uuid,
  original_name text,
  stored_name text,
  file_path text,
  file_type text,
  file_size bigint,
  status text,
  download_count int,
  is_encrypted boolean,
  encryption_algorithm text,
  encryption_key text,
  encryption_nonce text,
  encryption_mac text,
  plain_sha256 text,
  encrypted_sha256 text,
  risk_status text,
  risk_reason text,
  created_at timestamptz
) language sql stable security definer set search_path = public as $$
  select
    f.id,
    f.user_id,
    'Confidential file'::text as original_name,
    ''::text as stored_name,
    ''::text as file_path,
    f.file_type,
    f.file_size,
    f.status,
    f.download_count,
    f.is_encrypted,
    null::text as encryption_algorithm,
    null::text as encryption_key,
    null::text as encryption_nonce,
    null::text as encryption_mac,
    null::text as plain_sha256,
    null::text as encrypted_sha256,
    f.risk_status,
    f.risk_reason,
    f.created_at
  from public.files f
  where public.is_admin()
  order by f.created_at desc;
$$;

create or replace function public.admin_mark_file_deleted(target_file_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'Only admin can moderate files';
  end if;

  update public.files
  set status = 'deleted', updated_at = now()
  where id = target_file_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.files enable row level security;
alter table public.share_links enable row level security;
alter table public.share_recipients enable row level security;
alter table public.threat_signatures enable row level security;
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
drop policy if exists "files_select_own" on public.files;
create policy "files_select_own" on public.files
for select using (user_id = auth.uid());

drop policy if exists "files_insert_own" on public.files;
create policy "files_insert_own" on public.files
for insert with check (user_id = auth.uid());

drop policy if exists "files_update_own_or_admin" on public.files;
drop policy if exists "files_update_own" on public.files;
create policy "files_update_own" on public.files
for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "files_delete_admin" on public.files;

drop policy if exists "files_select_own_or_admin" on public.files;
drop policy if exists "files_update_own_or_admin" on public.files;

drop policy if exists "share_links_select_owner_or_admin" on public.share_links;
create policy "share_links_select_owner_or_admin" on public.share_links
for select using (
  public.is_admin()
  or created_by = auth.uid()
  or public.owns_file(file_id)
  or public.can_access_share_link(id)
  or (
    is_active = true
    and (expired_at is null or expired_at > now())
    and auth.uid() is not null
    and access_type in ('public', 'protected')
  )
);

drop policy if exists "threat_signatures_admin_all" on public.threat_signatures;
create policy "threat_signatures_admin_all" on public.threat_signatures
for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists "share_links_insert_owner" on public.share_links;
create policy "share_links_insert_owner" on public.share_links
for insert with check (
  created_by = auth.uid()
  and public.owns_file(file_id)
);

drop policy if exists "share_links_update_owner_or_admin" on public.share_links;
create policy "share_links_update_owner_or_admin" on public.share_links
for update using (
  public.is_admin()
  or public.owns_file(file_id)
) with check (
  public.is_admin()
  or public.owns_file(file_id)
);

drop policy if exists "share_recipients_owner_or_admin" on public.share_recipients;

drop policy if exists "share_recipients_select_owner_recipient_or_admin" on public.share_recipients;
create policy "share_recipients_select_owner_recipient_or_admin" on public.share_recipients
for select using (
  public.is_admin()
  or user_id = auth.uid()
  or lower(email) = lower(auth.email())
  or public.owns_share_link(share_link_id)
);

drop policy if exists "share_recipients_insert_owner_or_admin" on public.share_recipients;
create policy "share_recipients_insert_owner_or_admin" on public.share_recipients
for insert with check (
  public.is_admin()
  or public.owns_share_link(share_link_id)
);

drop policy if exists "share_recipients_update_owner_or_admin" on public.share_recipients;
create policy "share_recipients_update_owner_or_admin" on public.share_recipients
for update using (
  public.is_admin()
  or public.owns_share_link(share_link_id)
) with check (
  public.is_admin()
  or public.owns_share_link(share_link_id)
);

drop policy if exists "share_recipients_delete_owner_or_admin" on public.share_recipients;
create policy "share_recipients_delete_owner_or_admin" on public.share_recipients
for delete using (
  public.is_admin()
  or public.owns_share_link(share_link_id)
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

insert into storage.buckets (id, name, public)
values ('profile-avatars', 'profile-avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "secure_files_owner_upload" on storage.objects;
create policy "secure_files_owner_upload" on storage.objects
for insert with check (
  bucket_id = 'secure-files'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "secure_files_owner_read" on storage.objects;
create policy "secure_files_owner_read" on storage.objects
for select using (
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

drop policy if exists "profile_avatars_public_read" on storage.objects;
create policy "profile_avatars_public_read" on storage.objects
for select using (bucket_id = 'profile-avatars');

drop policy if exists "profile_avatars_owner_upload" on storage.objects;
create policy "profile_avatars_owner_upload" on storage.objects
for insert with check (
  bucket_id = 'profile-avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "profile_avatars_owner_update" on storage.objects;
create policy "profile_avatars_owner_update" on storage.objects
for update using (
  bucket_id = 'profile-avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "profile_avatars_owner_delete" on storage.objects;
create policy "profile_avatars_owner_delete" on storage.objects
for delete using (
  bucket_id = 'profile-avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Public share download must go through Edge Function generate-download-url.
-- The service role can read objects and issue short-lived signed URLs after validation.
