-- Item 1 (official content: separate posts from ads).
--
-- Root cause: official_posts had no content-type discriminator, so every
-- row rendered under one single "Announcements" section on the official
-- profile — and that section's own AR/FR labels ("الإعلانات"/"Annonces")
-- happen to read as "Advertisements" to native speakers even though the
-- content is genuinely posts, not ads. Fixed on the Dart/l10n side by
-- giving the two concepts distinct, unambiguous labels in every language
-- (friendsJma3aFeedHeader / friendsAdvertisementsHeader). This migration
-- adds the real `type` column so the app can ACTUALLY separate the two
-- kinds of content at the query level (never a client-side split over
-- one unfiltered fetch), not just relabel one mixed list.
--
-- Self-contained and idempotent by design: the environment this is
-- being applied from no longer has read access to the sibling migration
-- that originally created official_posts (supabase/migrations/
-- 20260915090000_official_posts.sql, written in an earlier session,
-- never yet applied to any database) — every statement below is guarded
-- so this file is safe to run whether that original migration was
-- applied first, applied never, or applied at some point in between.
-- Apply supabase/migrations/20260915090000_official_posts.sql FIRST if
-- it has not been applied yet; either way, running this file afterward
-- (or instead, since the CREATE TABLE below recreates the same shape)
-- leaves the database in the same correct end state.

DO $$ BEGIN
  CREATE TYPE public.official_content_type_enum AS ENUM ('post', 'ad');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.official_posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    author_profile_id uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    image_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT official_posts_pkey PRIMARY KEY (id),
    CONSTRAINT official_posts_title_check CHECK (char_length(title) <= 200),
    CONSTRAINT official_posts_body_check CHECK (char_length(body) <= 2000)
);
ALTER TABLE public.official_posts OWNER TO postgres;

ALTER TABLE ONLY public.official_posts
    DROP CONSTRAINT IF EXISTS official_posts_author_profile_id_fkey,
    ADD CONSTRAINT official_posts_author_profile_id_fkey
        FOREIGN KEY (author_profile_id) REFERENCES public.profiles(id)
        ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_official_posts_created_at
    ON public.official_posts USING btree (created_at DESC);

-- The actual type discriminator. DEFAULT 'post' both (a) makes any
-- pre-existing row become a post rather than silently/accidentally an
-- ad, satisfying "existing rows currently intended to be posts must
-- become 'post'", and (b) means every future INSERT that doesn't
-- explicitly set type also defaults safely to the non-ad kind.
ALTER TABLE public.official_posts
    ADD COLUMN IF NOT EXISTS type public.official_content_type_enum NOT NULL DEFAULT 'post';

CREATE INDEX IF NOT EXISTS idx_official_posts_type_created_at
    ON public.official_posts USING btree (type, created_at DESC);

-- Author-must-be-an-official-account trigger — unchanged from the
-- original migration, restated here so this file is fully self-
-- contained. Never keyed to a specific UUID — any number of future
-- official accounts can author either content type.
CREATE OR REPLACE FUNCTION public.official_posts_enforce_official_author()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = NEW.author_profile_id AND is_official_account = true
  ) THEN
    RAISE EXCEPTION 'official_posts_author_must_be_official_account';
  END IF;
  RETURN NEW;
END;
$$;
ALTER FUNCTION public.official_posts_enforce_official_author() OWNER TO postgres;

DROP TRIGGER IF EXISTS trg_official_posts_enforce_official_author ON public.official_posts;
CREATE TRIGGER trg_official_posts_enforce_official_author
    BEFORE INSERT OR UPDATE ON public.official_posts
    FOR EACH ROW EXECUTE FUNCTION public.official_posts_enforce_official_author();

ALTER TABLE public.official_posts ENABLE ROW LEVEL SECURITY;

-- RLS unchanged from the original design: public read, no client write
-- of either content type — content (post OR ad) is authored via
-- service-role/direct DB access only. Re-declaring this policy here is
-- a no-op if it already exists in the same shape (DROP+CREATE), and
-- correctly establishes it if this is the first time official_posts'
-- RLS is being set up in this database.
DROP POLICY IF EXISTS "official_posts: public read" ON public.official_posts;
CREATE POLICY "official_posts: public read" ON public.official_posts
    FOR SELECT USING (true);

GRANT SELECT ON TABLE public.official_posts TO anon;
GRANT SELECT ON TABLE public.official_posts TO authenticated;
GRANT ALL ON TABLE public.official_posts TO service_role;
