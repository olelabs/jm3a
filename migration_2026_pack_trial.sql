-- Trial Packs — try before purchase.
--
-- Adds trial configuration to `packs` and a new `pack_trial_usage` table
-- tracking per-(user, pack) trial consumption, plus three SECURITY
-- DEFINER RPCs that are the ONLY way trial state is ever created or
-- mutated (mirrors purchase_pack's existing pattern: pack_purchases has
-- no client INSERT policy either, only a SECURITY DEFINER RPC writes to
-- it — see "pack_purchases: no client insert" below for the same shape
-- applied to trial usage).
--
-- Idempotent throughout (IF NOT EXISTS / DROP...CREATE / CREATE OR
-- REPLACE), safe to run multiple times, matching this repo's existing
-- migration_2026_*.sql convention. NOT applied automatically — for
-- manual application only.

-- ─────────────────────────────────────────────────────────────────────────
-- 1. packs: trial configuration
-- ─────────────────────────────────────────────────────────────────────────
-- Defaults (false / 0) apply to every existing row automatically — no
-- existing pack becomes trial-enabled by this migration. A pack only
-- becomes a trial pack when an admin explicitly sets trial_enabled=true
-- via the admin official-pack edit flow (the only writer of these two
-- columns — see jma3a-api/src/admin/adminPackRoutes.js /
-- packModerationService.js changes in this same task).
ALTER TABLE public.packs
  ADD COLUMN IF NOT EXISTS trial_enabled boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS trial_card_count integer NOT NULL DEFAULT 0;

-- Keeps the two fields consistent by construction: disabling trial
-- always means trial_card_count is 0 (never a stale nonzero leftover),
-- and an enabled trial always has a real positive count. Upper bound
-- (50) is a "reasonable maximum" per the task's own instruction — a
-- trial is meant to be a short preview, not most/all of a pack.
ALTER TABLE public.packs
  DROP CONSTRAINT IF EXISTS packs_trial_card_count_check,
  ADD CONSTRAINT packs_trial_card_count_check
    CHECK (
      (trial_enabled = false AND trial_card_count = 0)
      OR (trial_enabled = true AND trial_card_count > 0 AND trial_card_count <= 50)
    );

COMMENT ON COLUMN public.packs.trial_enabled IS
  'Admin-only (official-pack edit flow). When true, eligible users who have not purchased this pack may play the first trial_card_count cards once, via pack_trial_usage / start_pack_trial() / try_consume_trial_card().';
COMMENT ON COLUMN public.packs.trial_card_count IS
  'Number of cards a trial covers. Always 0 when trial_enabled is false (packs_trial_card_count_check enforces this pairing).';

-- ─────────────────────────────────────────────────────────────────────────
-- 2. pack_trial_usage — one row per (user_id, pack_id), the persistent,
--    server-authoritative trial state.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pack_trial_usage (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    pack_id uuid NOT NULL,
    trial_started_at timestamp with time zone DEFAULT now() NOT NULL,
    trial_completed_at timestamp with time zone,
    cards_played integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pack_trial_usage_pkey PRIMARY KEY (id),
    CONSTRAINT pack_trial_usage_cards_played_check CHECK (cards_played >= 0)
);
ALTER TABLE public.pack_trial_usage OWNER TO postgres;

ALTER TABLE ONLY public.pack_trial_usage
    DROP CONSTRAINT IF EXISTS pack_trial_usage_user_id_fkey,
    ADD CONSTRAINT pack_trial_usage_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.pack_trial_usage
    DROP CONSTRAINT IF EXISTS pack_trial_usage_pack_id_fkey,
    ADD CONSTRAINT pack_trial_usage_pack_id_fkey
        FOREIGN KEY (pack_id) REFERENCES public.packs(id) ON DELETE CASCADE;

-- The actual "once per user per pack" authority — start_pack_trial()
-- below relies on this for its atomic, race-safe create-if-absent
-- semantics (INSERT ... ON CONFLICT (user_id, pack_id) DO NOTHING).
ALTER TABLE ONLY public.pack_trial_usage
    DROP CONSTRAINT IF EXISTS pack_trial_usage_user_pack_unique,
    ADD CONSTRAINT pack_trial_usage_user_pack_unique
        UNIQUE (user_id, pack_id);

CREATE INDEX IF NOT EXISTS idx_pack_trial_usage_user
    ON public.pack_trial_usage USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_pack_trial_usage_pack
    ON public.pack_trial_usage USING btree (pack_id);

ALTER TABLE public.pack_trial_usage ENABLE ROW LEVEL SECURITY;

-- Own-row read only — a user can see their own trial progress (e.g. to
-- know "cards remaining"), never another user's.
DROP POLICY IF EXISTS "pack_trial_usage: own read" ON public.pack_trial_usage;
CREATE POLICY "pack_trial_usage: own read" ON public.pack_trial_usage
    FOR SELECT USING (auth.uid() = user_id);

-- Deliberately NO INSERT/UPDATE/DELETE policy for authenticated at all
-- (mirrors "pack_purchases: no client insert" below) — this is the real
-- enforcement of "the client cannot reset cards_played, cannot delete
-- its own trial record, cannot create a second trial row." Every write
-- goes through start_pack_trial()/try_consume_trial_card() (SECURITY
-- DEFINER, owned by postgres, bypasses RLS internally, but only ever
-- performs the one specific, bounded mutation each function allows).

GRANT SELECT ON TABLE public.pack_trial_usage TO authenticated;
GRANT ALL ON TABLE public.pack_trial_usage TO service_role;

-- Defensive — restate the existing pack_purchases "no client insert"
-- policy if it's somehow missing on this environment (idempotent
-- no-op if it already exists exactly as before); trial's security model
-- depends on this being true for the ownership checks below to be
-- meaningful.
DROP POLICY IF EXISTS "pack_purchases: no client insert" ON public.pack_purchases;
CREATE POLICY "pack_purchases: no client insert" ON public.pack_purchases
    FOR INSERT WITH CHECK (false);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. get_eligible_trial_packs() — room-settings visibility.
--    Returns trial-enabled packs the CALLING user (auth.uid()) has
--    neither purchased nor already trialed. No arguments (uses auth.uid()
--    internally) so a client can never query another user's eligibility.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_eligible_trial_packs()
RETURNS SETOF public.packs
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT p.*
  FROM public.packs p
  WHERE p.trial_enabled = true
    AND p.status = 'approved'
    AND p.deleted_at IS NULL
    AND auth.uid() IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM public.pack_purchases pp
      WHERE pp.pack_id = p.id
        AND pp.buyer_id = auth.uid()
        AND pp.status = 'completed'
        AND (pp.expires_at IS NULL OR pp.expires_at > now())
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.pack_trial_usage ptu
      WHERE ptu.pack_id = p.id AND ptu.user_id = auth.uid()
    );
$$;

GRANT EXECUTE ON FUNCTION public.get_eligible_trial_packs() TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 4. start_pack_trial(p_pack_id) — atomically claim/start a trial.
--    Called once, when the game actually begins with a trial-eligible
--    pack selected (NOT when the pack merely appears in a list). Race-
--    safe: two concurrent calls for the same (auth.uid(), pack) can
--    never create two rows — the second sees the first's committed row
--    via ON CONFLICT DO NOTHING and returns it unchanged.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.start_pack_trial(p_pack_id uuid)
RETURNS public.pack_trial_usage
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_pack public.packs;
  v_row public.pack_trial_usage;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_pack FROM public.packs WHERE id = p_pack_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'pack_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF NOT v_pack.trial_enabled THEN
    RAISE EXCEPTION 'not_a_trial_pack' USING ERRCODE = 'P0001';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.pack_purchases
    WHERE pack_id = p_pack_id AND buyer_id = v_uid AND status = 'completed'
      AND (expires_at IS NULL OR expires_at > now())
  ) THEN
    RAISE EXCEPTION 'already_owns_pack' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.pack_trial_usage (user_id, pack_id)
  VALUES (v_uid, p_pack_id)
  ON CONFLICT (user_id, pack_id) DO NOTHING
  RETURNING * INTO v_row;

  IF v_row.id IS NULL THEN
    -- Already existed (this call, or a concurrent one, lost the race) —
    -- return the existing trial state rather than creating a second one.
    SELECT * INTO v_row FROM public.pack_trial_usage
    WHERE user_id = v_uid AND pack_id = p_pack_id;
  END IF;

  RETURN v_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.start_pack_trial(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────
-- 5. try_consume_trial_card(p_pack_id) — the authoritative "may the next
--    card be revealed" check + atomic consumption, called by the room
--    owner's client immediately before advancing to a new card for a
--    trial (unowned) pack. Row-locked increment: the
--    `WHERE cards_played < v_pack.trial_card_count` guard on the UPDATE
--    means a losing concurrent call simply updates 0 rows instead of
--    over-incrementing — cards_played can never exceed trial_card_count.
--
--    Returns one row: (allowed boolean, reason text, cards_played int,
--    trial_card_count int). reason is one of:
--      'not_trial_pack'  — trial_enabled=false; caller should treat this
--                           pack as always-allowed (no trial gating at all,
--                           existing non-trial behavior).
--      'owned'           — user already owns the pack; always allowed,
--                           no pack_trial_usage row touched.
--      'trial'           — a trial card was consumed; allowed=true.
--      'no_active_trial' — trial-enabled, unowned, but start_pack_trial
--                           was never called for this user/pack (caller
--                           bug — the game-start path must call it first).
--      'trial_exhausted' — cards_played already == trial_card_count.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.try_consume_trial_card(p_pack_id uuid)
RETURNS TABLE (
  allowed boolean,
  reason text,
  cards_played integer,
  trial_card_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_pack public.packs;
  v_row public.pack_trial_usage;
  v_new_cards_played integer;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_pack FROM public.packs WHERE id = p_pack_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'pack_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF NOT v_pack.trial_enabled THEN
    RETURN QUERY SELECT true, 'not_trial_pack'::text, 0, 0;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.pack_purchases
    WHERE pack_id = p_pack_id AND buyer_id = v_uid AND status = 'completed'
      AND (expires_at IS NULL OR expires_at > now())
  ) THEN
    RETURN QUERY SELECT true, 'owned'::text, 0, v_pack.trial_card_count;
    RETURN;
  END IF;

  -- Row lock: a concurrent call for the same user+pack blocks here until
  -- the other transaction commits/rolls back, so the two never both read
  -- the same pre-increment cards_played value.
  SELECT * INTO v_row FROM public.pack_trial_usage
  WHERE user_id = v_uid AND pack_id = p_pack_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'no_active_trial'::text, 0, v_pack.trial_card_count;
    RETURN;
  END IF;

  IF v_row.cards_played >= v_pack.trial_card_count THEN
    RETURN QUERY SELECT false, 'trial_exhausted'::text,
      v_row.cards_played, v_pack.trial_card_count;
    RETURN;
  END IF;

  UPDATE public.pack_trial_usage
  SET cards_played = cards_played + 1,
      updated_at = now(),
      trial_completed_at = CASE
        WHEN cards_played + 1 >= v_pack.trial_card_count THEN now()
        ELSE trial_completed_at
      END
  WHERE id = v_row.id
  RETURNING cards_played INTO v_new_cards_played;

  RETURN QUERY SELECT true, 'trial'::text, v_new_cards_played, v_pack.trial_card_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.try_consume_trial_card(uuid) TO authenticated;
