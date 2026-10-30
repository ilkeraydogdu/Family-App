-- =============================================================================
-- Migration: Enforce Strict Member Privacy (Personal Plans Private, Only Shared Visible)
-- =============================================================================

alter table public.medication_reminders
  add column if not exists created_by uuid references auth.users(id) on delete set null default auth.uid();

create index if not exists idx_medication_reminders_created_by
  on public.medication_reminders(created_by);

alter table public.water_trackers
  add column if not exists user_id uuid references auth.users(id) on delete cascade default auth.uid();

create index if not exists idx_water_trackers_user_id
  on public.water_trackers(user_id);

-- Strictly restrict schedule_blocks SELECT so each member ONLY sees:
-- 1) Their own private personal plans (created_by = auth.uid())
-- 2) Explicitly shared plans (owner_role = 'shared')
alter policy "schedule_blocks_select_policy"
  on public.schedule_blocks
  using (
    (select private.is_family_member(family_id))
    and (
      owner_role = 'shared'
      or created_by = (select auth.uid())
    )
  );

-- Strictly restrict medication_reminders SELECT so each member ONLY sees:
-- 1) Their own private medications (created_by = auth.uid())
-- 2) Shared reminders (owner_role = 'shared')
alter policy "medication_reminders_select_policy"
  on public.medication_reminders
  using (
    (select private.is_family_member(family_id))
    and (
      owner_role = 'shared'
      or created_by = (select auth.uid())
    )
  );

-- Strictly restrict water_trackers SELECT so each member ONLY sees their own water intake
alter policy "water_trackers_select_policy"
  on public.water_trackers
  using (
    (select private.is_family_member(family_id))
    and user_id = (select auth.uid())
  );
