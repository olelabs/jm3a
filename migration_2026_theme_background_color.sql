-- migration_2026_theme_background_color.sql
--
-- Premium/Premium Plus background-color customization: a nullable per-user
-- solid background override applied on top of whichever of the 20 themes
-- the user has selected (see AppTheme.withPrimary's new backgroundOverride
-- param in the Dart client). Writes are locked to the
-- set_theme_background_color() RPC only, which re-verifies the caller's
-- LIVE premium status server-side (is_premium AND premium_expires_at still
-- in the future) rather than trusting the raw is_premium column alone —
-- sync_premium_status only fires reactively on writes to the subscriptions
-- table (trg_sync_premium), there is no cron/scheduled job, so is_premium
-- can stay stale=true well past a subscription's actual expiry.
--
-- Safe to run multiple times. Apply by hand in the Supabase SQL editor.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS theme_background_color text;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_theme_background_color_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_theme_background_color_check
    CHECK (theme_background_color IS NULL OR theme_background_color ~ '^#[0-9A-Fa-f]{6}$');

COMMENT ON COLUMN public.profiles.theme_background_color IS
  'Premium/Premium Plus: user-chosen solid background override (hex #RRGGBB) applied on top of the selected theme. NULL = theme default. Locked to writes via set_theme_background_color() RPC — see "profiles: own safe update" RLS policy.';

CREATE OR REPLACE FUNCTION public.set_theme_background_color(p_hex_color text) RETURNS public.profiles
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_row public.profiles;
BEGIN
  IF p_hex_color IS NOT NULL THEN
    IF p_hex_color !~ '^#[0-9A-Fa-f]{6}$' THEN
      RAISE EXCEPTION 'invalid_hex_color';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND is_premium = true
        AND (premium_expires_at IS NULL OR premium_expires_at > now())
    ) THEN
      RAISE EXCEPTION 'premium_required';
    END IF;
  END IF;

  -- NULL (reset to theme default) is always allowed, even if lapsed —
  -- resetting your own preference isn't a premium-gated action.
  UPDATE public.profiles
  SET theme_background_color = p_hex_color, updated_at = now()
  WHERE id = auth.uid()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

GRANT ALL ON FUNCTION public.set_theme_background_color(text) TO anon;
GRANT ALL ON FUNCTION public.set_theme_background_color(text) TO authenticated;
GRANT ALL ON FUNCTION public.set_theme_background_color(text) TO service_role;

-- Lock the column to RPC-only writes, same convention already used for
-- is_banned/verification_status/email on this policy. IMPORTANT: this is
-- the first NULLABLE column added to this lock pattern — plain `=` (as
-- used for the three existing NOT NULL locked columns) evaluates to NULL
-- (not TRUE) when comparing NULL to NULL, which would silently reject
-- every ordinary profile update for the majority of users who have never
-- set this column. Must use IS NOT DISTINCT FROM.
DROP POLICY IF EXISTS "profiles: own safe update" ON public.profiles;
CREATE POLICY "profiles: own safe update" ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND is_banned = (SELECT p.is_banned FROM public.profiles p WHERE p.id = auth.uid())
  AND verification_status = (SELECT p.verification_status FROM public.profiles p WHERE p.id = auth.uid())
  AND email = (SELECT p.email FROM public.profiles p WHERE p.id = auth.uid())
  AND theme_background_color IS NOT DISTINCT FROM
      (SELECT p.theme_background_color FROM public.profiles p WHERE p.id = auth.uid())
);
