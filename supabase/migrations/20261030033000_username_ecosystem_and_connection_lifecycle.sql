-- Migration: Username (@kullanici_adi) Ecosystem, Zero Email Exposure, and Full Partner Connection Lifecycle
ALTER TABLE public.family_members ADD COLUMN IF NOT EXISTS username text;
ALTER TABLE public.family_members ADD COLUMN IF NOT EXISTS connection_status text NOT NULL DEFAULT 'connected';

CREATE UNIQUE INDEX IF NOT EXISTS idx_family_members_username ON public.family_members(lower(username));

INSERT INTO public.family_members (family_id, user_id, display_name, role_label, avatar_color, username, connection_status)
VALUES
  (1, '11111111-1111-1111-1111-111111111111', 'İlker', 'husband', '#0F766E', 'ilker', 'connected'),
  (1, '22222222-2222-2222-2222-222222222222', 'Neslihan', 'wife', '#4F46E5', 'neslihan', 'connected')
ON CONFLICT (family_id, user_id) DO UPDATE
SET
  display_name = EXCLUDED.display_name,
  username = COALESCE(public.family_members.username, EXCLUDED.username),
  connection_status = 'connected';

ALTER TABLE public.partner_invitations ADD COLUMN IF NOT EXISTS inviter_username text NOT NULL DEFAULT 'ilker';
ALTER TABLE public.partner_invitations ADD COLUMN IF NOT EXISTS target_username text NOT NULL DEFAULT 'neslihan';
ALTER TABLE public.partner_invitations ADD COLUMN IF NOT EXISTS sharing_paused boolean NOT NULL DEFAULT false;
ALTER TABLE public.partner_invitations DROP CONSTRAINT IF EXISTS partner_invitations_status_check;
ALTER TABLE public.partner_invitations ADD CONSTRAINT partner_invitations_status_check CHECK (status IN ('pending', 'accepted', 'paused', 'removed'));

CREATE POLICY "partner_invitations_delete_policy"
ON public.partner_invitations
FOR DELETE
TO authenticated
USING ((SELECT private.is_family_member(family_id)));

ALTER POLICY "family_members_update_policy"
ON public.family_members
USING (
  (user_id = (SELECT auth.uid()))
  OR (SELECT private.is_family_member(family_id))
)
WITH CHECK (
  (user_id = (SELECT auth.uid()))
  OR (SELECT private.is_family_member(family_id))
);

ALTER POLICY "schedule_blocks_select_policy"
ON public.schedule_blocks
USING (
  (SELECT private.is_family_member(family_id))
  AND (
    created_by = (SELECT auth.uid())
    OR (
      owner_role = 'shared'
      AND EXISTS (
        SELECT 1 FROM public.family_members fm
        WHERE fm.family_id = schedule_blocks.family_id
          AND fm.user_id = (SELECT auth.uid())
          AND fm.connection_status = 'connected'
      )
    )
  )
);
