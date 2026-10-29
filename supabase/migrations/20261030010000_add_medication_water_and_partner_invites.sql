-- =============================================================================
-- Migration: Add Medication Reminders, Water Tracker, and Partner Invitations
-- =============================================================================

create table if not exists public.medication_reminders (
  id bigint generated always as identity primary key,
  family_id bigint not null references public.families(id) on delete cascade,
  owner_role text not null default 'husband' check (owner_role in ('husband', 'wife', 'shared')),
  medication_name text not null,
  dosage text not null default '1 Tablet',
  reminder_time text not null default '09:00',
  meal_relation text not null default 'Tok Karnına',
  taken_today boolean not null default false,
  last_taken_date date,
  notification_enabled boolean not null default true,
  notes text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists idx_medication_reminders_family_id
  on public.medication_reminders(family_id);

alter table public.medication_reminders enable row level security;

create policy "Authenticated users can view medication reminders"
  on public.medication_reminders for select
  to authenticated
  using (true);

create policy "Authenticated users can insert medication reminders"
  on public.medication_reminders for insert
  to authenticated
  with check ((select auth.uid()) is not null);

create policy "Authenticated users can update medication reminders"
  on public.medication_reminders for update
  to authenticated
  using ((select auth.uid()) is not null)
  with check ((select auth.uid()) is not null);

create policy "Authenticated users can delete medication reminders"
  on public.medication_reminders for delete
  to authenticated
  using ((select auth.uid()) is not null);

create table if not exists public.water_trackers (
  id bigint generated always as identity primary key,
  family_id bigint not null references public.families(id) on delete cascade,
  owner_role text not null default 'husband' check (owner_role in ('husband', 'wife')),
  daily_goal_ml integer not null default 2500,
  current_intake_ml integer not null default 0,
  cup_size_ml integer not null default 250,
  reminder_interval_minutes integer not null default 90,
  reminder_enabled boolean not null default true,
  updated_date date not null default current_date,
  unique (family_id, owner_role)
);

create index if not exists idx_water_trackers_family_id
  on public.water_trackers(family_id);

alter table public.water_trackers enable row level security;

create policy "Authenticated users can view water trackers"
  on public.water_trackers for select
  to authenticated
  using (true);

create policy "Authenticated users can insert water trackers"
  on public.water_trackers for insert
  to authenticated
  with check ((select auth.uid()) is not null);

create policy "Authenticated users can update water trackers"
  on public.water_trackers for update
  to authenticated
  using ((select auth.uid()) is not null)
  with check ((select auth.uid()) is not null);

create table if not exists public.partner_invitations (
  id bigint generated always as identity primary key,
  family_id bigint not null references public.families(id) on delete cascade,
  inviter_role text not null default 'husband',
  invitee_label text not null,
  invitee_email text,
  relationship_type text not null default 'Eş / Partner',
  invite_code text not null,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  allow_shared_plans boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_partner_invitations_family_id
  on public.partner_invitations(family_id);

alter table public.partner_invitations enable row level security;

create policy "Authenticated users can view partner invitations"
  on public.partner_invitations for select
  to authenticated
  using (true);

create policy "Authenticated users can insert partner invitations"
  on public.partner_invitations for insert
  to authenticated
  with check ((select auth.uid()) is not null);

create policy "Authenticated users can update partner invitations"
  on public.partner_invitations for update
  to authenticated
  using ((select auth.uid()) is not null)
  with check ((select auth.uid()) is not null);

alter publication supabase_realtime add table public.medication_reminders;
alter publication supabase_realtime add table public.water_trackers;
alter publication supabase_realtime add table public.partner_invitations;
