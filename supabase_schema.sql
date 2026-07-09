-- SkySource KRA Production Database Schema
-- Platform: Supabase PostgreSQL
-- Run this in Supabase SQL Editor.

-- Enable UUID generation
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- Profiles: one row per authenticated user
-- Supabase Auth stores secure passwords separately.
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  full_name text not null,
  role text not null default 'associate' check (role in ('admin', 'supervisor', 'associate')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Employees
-- ------------------------------------------------------------
create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(),
  employee_code text,
  full_name text not null,
  email text unique,
  department text,
  designation text,
  supervisor_name text,
  supervisor_email text,
  doj text,
  status text not null default 'Active',
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- KRA records: one employee per month
-- month_key format example: Apr 2026
-- ------------------------------------------------------------
create table if not exists public.kra_records (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.employees(id) on delete cascade,
  month_key text not null,

  raw_prod numeric,
  raw_qual numeric,
  raw_cross numeric,
  raw_ideas_sub numeric,
  raw_ideas_app numeric,
  raw_pkt numeric,
  raw_leaves numeric,
  raw_escal numeric,
  raw_apprec numeric,
  raw_warnings numeric,
  raw_adherence numeric,
  raw_security numeric,

  prod numeric,
  qual numeric,
  cross numeric,
  proc_imp numeric,
  pkt numeric,
  leaves numeric,
  escal numeric,
  apprec numeric,
  decorum numeric,
  sched numeric,
  security numeric,
  wfo numeric,
  leadership numeric,
  comm numeric,
  overall numeric,

  status text default 'Active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique(employee_id, month_key)
);

-- ------------------------------------------------------------
-- Settings stored as JSON
-- ------------------------------------------------------------
create table if not exists public.kra_settings (
  id text primary key default 'default',
  settings jsonb not null,
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Audit logs
-- ------------------------------------------------------------
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id),
  action text not null,
  entity_type text,
  entity_id text,
  details jsonb,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Helper function: current user role
-- ------------------------------------------------------------
create or replace function public.current_user_role()
returns text
language sql
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- ------------------------------------------------------------
-- Helper function: user is admin or supervisor
-- ------------------------------------------------------------
create or replace function public.is_privileged_user()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
    and role in ('admin', 'supervisor')
  );
$$;

-- ------------------------------------------------------------
-- Enable Row Level Security
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.employees enable row level security;
alter table public.kra_records enable row level security;
alter table public.kra_settings enable row level security;
alter table public.audit_logs enable row level security;

-- ------------------------------------------------------------
-- RLS Policies: Profiles
-- ------------------------------------------------------------
drop policy if exists "Profiles read self or privileged" on public.profiles;
create policy "Profiles read self or privileged"
on public.profiles for select
to authenticated
using (id = auth.uid() or public.is_privileged_user());

drop policy if exists "Profiles update self or admin" on public.profiles;
create policy "Profiles update self or admin"
on public.profiles for update
to authenticated
using (id = auth.uid() or public.current_user_role() = 'admin')
with check (id = auth.uid() or public.current_user_role() = 'admin');

-- ------------------------------------------------------------
-- RLS Policies: Employees
-- ------------------------------------------------------------
drop policy if exists "Employees read self or privileged" on public.employees;
create policy "Employees read self or privileged"
on public.employees for select
to authenticated
using (
  public.is_privileged_user()
  or lower(email) = lower((select email from public.profiles where id = auth.uid()))
);

drop policy if exists "Employees write privileged" on public.employees;
create policy "Employees write privileged"
on public.employees for all
to authenticated
using (public.is_privileged_user())
with check (public.is_privileged_user());

-- ------------------------------------------------------------
-- RLS Policies: KRA Records
-- ------------------------------------------------------------
drop policy if exists "KRA read own or privileged" on public.kra_records;
create policy "KRA read own or privileged"
on public.kra_records for select
to authenticated
using (
  public.is_privileged_user()
  or employee_id in (
    select e.id from public.employees e
    join public.profiles p on lower(p.email) = lower(e.email)
    where p.id = auth.uid()
  )
);

drop policy if exists "KRA write privileged" on public.kra_records;
create policy "KRA write privileged"
on public.kra_records for all
to authenticated
using (public.is_privileged_user())
with check (public.is_privileged_user());

-- ------------------------------------------------------------
-- RLS Policies: Settings
-- ------------------------------------------------------------
drop policy if exists "Settings read authenticated" on public.kra_settings;
create policy "Settings read authenticated"
on public.kra_settings for select
to authenticated
using (true);

drop policy if exists "Settings write privileged" on public.kra_settings;
create policy "Settings write privileged"
on public.kra_settings for all
to authenticated
using (public.is_privileged_user())
with check (public.is_privileged_user());

-- ------------------------------------------------------------
-- RLS Policies: Audit Logs
-- ------------------------------------------------------------
drop policy if exists "Audit read privileged" on public.audit_logs;
create policy "Audit read privileged"
on public.audit_logs for select
to authenticated
using (public.is_privileged_user());

drop policy if exists "Audit insert authenticated" on public.audit_logs;
create policy "Audit insert authenticated"
on public.audit_logs for insert
to authenticated
with check (actor_id = auth.uid());
