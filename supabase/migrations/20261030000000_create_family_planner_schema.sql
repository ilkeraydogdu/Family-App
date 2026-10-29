-- 1. Create private schema for RLS helper functions
create schema if not exists private;
grant usage on schema private to authenticated;

-- 2. Create families table
create table if not exists public.families (
  id bigint generated always as identity primary key,
  name text not null,
  invite_code text not null unique,
  city text not null default 'Istanbul',
  country text not null default 'Turkey',
  wake_up_time text not null default '05:00',
  sleep_time text not null default '23:00',
  created_at timestamptz not null default now()
);

-- 3. Create family_members table
create table if not exists public.family_members (
  id bigint generated always as identity primary key,
  family_id bigint not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  role_label text not null default 'husband' check (role_label in ('husband', 'wife')),
  avatar_color text not null default '#4F46E5',
  created_at timestamptz not null default now(),
  unique (family_id, user_id)
);

create index if not exists family_members_family_id_idx on public.family_members (family_id);
create index if not exists family_members_user_id_idx on public.family_members (user_id);

-- 4. Create schedule_blocks table
create table if not exists public.schedule_blocks (
  id bigint generated always as identity primary key,
  family_id bigint not null references public.families(id) on delete cascade,
  owner_role text not null default 'shared' check (owner_role in ('husband', 'wife', 'shared')),
  created_by uuid references auth.users(id) on delete set null,
  title text not null,
  description text not null default '',
  category text not null default 'general' check (
    category in ('sleep', 'prayer', 'commute', 'work', 'lesson', 'personal', 'shared', 'focus', 'general')
  ),
  plan_date date not null default current_date,
  is_recurring_daily boolean not null default false,
  recurrence_days int[] not null default '{1,2,3,4,5,6,7}',
  start_time text not null,
  end_time text not null,
  is_prayer_anchored boolean not null default false,
  prayer_name text,
  prayer_offset_minutes int not null default 0,
  voice_reminder_enabled boolean not null default true,
  remind_before_minutes int not null default 15,
  repeat_count int not null default 3,
  repeat_interval_minutes int not null default 5,
  phone_lock_enabled boolean not null default false,
  allow_calls_only boolean not null default true,
  status text not null default 'planned' check (
    status in ('planned', 'checked_in', 'completed', 'skipped')
  ),
  checked_in_at timestamptz,
  completed_at timestamptz,
  skip_reason text not null default '',
  completion_notes text not null default '',
  checklist_items jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists schedule_blocks_family_id_date_idx on public.schedule_blocks (family_id, plan_date);
create index if not exists schedule_blocks_created_by_idx on public.schedule_blocks (created_by);

-- 5. Create focus_sessions table
create table if not exists public.focus_sessions (
  id bigint generated always as identity primary key,
  family_id bigint not null references public.families(id) on delete cascade,
  target_role text not null default 'shared' check (target_role in ('husband', 'wife', 'shared')),
  title text not null,
  start_time text not null,
  end_time text not null,
  is_active boolean not null default true,
  allow_calls_only boolean not null default true,
  emergency_contact_phone text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists focus_sessions_family_id_idx on public.focus_sessions (family_id);

-- 6. Helper function in private schema for RLS
create or replace function private.is_family_member(check_family_id bigint)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.family_members
    where family_id = $1 and user_id = (select auth.uid())
  );
$$;

revoke execute on function private.is_family_member(bigint) from PUBLIC, anon;
grant execute on function private.is_family_member(bigint) to authenticated;

-- 7. Enable RLS on all public tables
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.schedule_blocks enable row level security;
alter table public.focus_sessions enable row level security;
