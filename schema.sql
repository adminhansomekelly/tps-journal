-- ═══════════════════════════════════════════════════════════════
-- TPS JOURNAL · SUPABASE SCHEMA
-- Run this once in Supabase: SQL Editor → New query → paste → Run
-- Safe to re-run: it drops and recreates its own objects.
-- ═══════════════════════════════════════════════════════════════

-- ── 1 · PROFILES ─────────────────────────────────────────────
-- One row per user. Role controls coach dashboard access.
create table if not exists public.profiles (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  email        text,
  display_name text,
  role         text not null default 'student' check (role in ('student','coach')),
  created_at   timestamptz not null default now()
);

-- Auto-create a profile whenever someone signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (user_id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1))
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── 2 · JOURNAL DATA ─────────────────────────────────────────
-- Mirrors the app's tps_ localStorage keys, one row per key per user.
create table if not exists public.journal_data (
  user_id    uuid not null references auth.users(id) on delete cascade,
  key        text not null check (key like 'tps\_%'),
  value      text,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);

create index if not exists journal_data_user_idx on public.journal_data (user_id);

-- ── 3 · COACH CHECK ──────────────────────────────────────────
-- security definer so it can read profiles without recursive RLS issues
create or replace function public.is_coach()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where user_id = auth.uid() and role = 'coach'
  );
$$;

-- ── 4 · ROW LEVEL SECURITY ───────────────────────────────────
alter table public.profiles     enable row level security;
alter table public.journal_data enable row level security;

-- Profiles: you can see your own; a coach can see everyone.
-- No client-side writes to profiles at all — display name is set by the
-- signup trigger, and roles are promoted only from the Supabase dashboard.
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using ( user_id = auth.uid() or public.is_coach() );

-- Journal data: students read and write ONLY their own rows.
-- A coach can additionally read (never write) every student's rows.
drop policy if exists journal_select on public.journal_data;
create policy journal_select on public.journal_data
  for select using ( user_id = auth.uid() or public.is_coach() );

drop policy if exists journal_insert on public.journal_data;
create policy journal_insert on public.journal_data
  for insert with check ( user_id = auth.uid() );

drop policy if exists journal_update on public.journal_data;
create policy journal_update on public.journal_data
  for update using ( user_id = auth.uid() )
  with check ( user_id = auth.uid() );

drop policy if exists journal_delete on public.journal_data;
create policy journal_delete on public.journal_data
  for delete using ( user_id = auth.uid() );

-- ── 5 · DONE ─────────────────────────────────────────────────
-- After running this, promote yourself to coach (replace the email):
--
--   update public.profiles set role = 'coach'
--   where email = 'you@yourdomain.com';
--
-- (Sign up in the app first so your profile row exists.)
