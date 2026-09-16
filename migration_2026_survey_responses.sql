-- Item 5 (Answer our survey).
--
-- No reusable survey/form system exists anywhere in this schema (checked
-- directly: no forms/surveys/questions table; the only structurally
-- similar precedent is `reports`, a flat table keyed on reporter_id with
-- own-row insert/read RLS — reused here as the closest existing pattern
-- for "a user submits structured feedback tied to their own auth.uid()").
-- This is ONE fixed, developer-authored survey (question text/choices
-- live in Dart/l10n, not database-driven/admin-configurable), so the
-- smallest clean schema is a single response table, not a normalized
-- survey_forms/survey_questions/survey_answers system — that would be
-- real over-engineering for a single, code-defined questionnaire with no
-- admin survey-builder requested in this pass.
--
-- Structured vs free-text split, chosen specifically so the team can
-- analyze results later without parsing prose:
--   - overall_rating (1-5), recommend_score (0-10 NPS-style): plain
--     smallint, directly AVG()-able.
--   - liked_most / annoyances / wanted_features: text[] of STABLE OPTION
--     KEYS (never localized display strings — see SurveyRepository.
--     submitSurvey's own doc comment), directly GROUP-able
--     (unnest(annoyances) ... GROUP BY 1 ... ORDER BY count(*) DESC gets
--     "most common annoyance" with zero string-matching heuristics).
--   - *_other / confusing_feedback / more_often_feature /
--     change_one_thing / additional_feedback: plain free text.
--
-- Duplicate policy: ONE response per (user, survey_version), enforced by
-- the database (UNIQUE constraint below), not just a client-side check —
-- SurveyRepository.hasSubmitted is a pre-flight UX convenience, this
-- constraint is the actual authority, with a 23505 unique-violation on a
-- racing duplicate insert treated as an idempotent success by the
-- repository (mirrors FriendsRepository.reportUser's own existing
-- precedent for the exact same class of race).
--
-- survey_version (not hardcoded to 'v1' anywhere in the schema itself)
-- is what lets a FUTURE, meaningfully-different survey exist as a new
-- version string without touching this table or conflicting with
-- existing responses — see SurveyRepository.currentVersion's own doc
-- comment.

CREATE TABLE IF NOT EXISTS public.survey_responses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    survey_version text NOT NULL DEFAULT 'v1',
    overall_rating smallint NOT NULL,
    recommend_score smallint NOT NULL,
    liked_most text[] NOT NULL DEFAULT '{}',
    liked_most_other text,
    annoyances text[] NOT NULL DEFAULT '{}',
    annoyances_other text,
    confusing_feedback text,
    wanted_features text[] NOT NULL DEFAULT '{}',
    wanted_features_other text,
    more_often_feature text,
    change_one_thing text,
    additional_feedback text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT survey_responses_pkey PRIMARY KEY (id),
    CONSTRAINT survey_responses_overall_rating_check
        CHECK (overall_rating BETWEEN 1 AND 5),
    CONSTRAINT survey_responses_recommend_score_check
        CHECK (recommend_score BETWEEN 0 AND 10),
    -- Generous but finite caps on every free-text field — same
    -- "bound every user-supplied text column" convention already used
    -- throughout this schema (e.g. official_posts.body <= 2000,
    -- room_invites.message <= 200), not specific to this table.
    CONSTRAINT survey_responses_liked_most_other_check
        CHECK (char_length(liked_most_other) <= 500),
    CONSTRAINT survey_responses_annoyances_other_check
        CHECK (char_length(annoyances_other) <= 500),
    CONSTRAINT survey_responses_confusing_feedback_check
        CHECK (char_length(confusing_feedback) <= 500),
    CONSTRAINT survey_responses_wanted_features_other_check
        CHECK (char_length(wanted_features_other) <= 500),
    CONSTRAINT survey_responses_more_often_feature_check
        CHECK (char_length(more_often_feature) <= 500),
    CONSTRAINT survey_responses_change_one_thing_check
        CHECK (char_length(change_one_thing) <= 500),
    CONSTRAINT survey_responses_additional_feedback_check
        CHECK (char_length(additional_feedback) <= 500)
);
ALTER TABLE public.survey_responses OWNER TO postgres;

ALTER TABLE ONLY public.survey_responses
    DROP CONSTRAINT IF EXISTS survey_responses_user_id_fkey,
    ADD CONSTRAINT survey_responses_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES public.profiles(id)
        ON DELETE CASCADE;

-- The actual duplicate-prevention authority: one response per user per
-- survey version.
ALTER TABLE ONLY public.survey_responses
    DROP CONSTRAINT IF EXISTS survey_responses_user_version_unique,
    ADD CONSTRAINT survey_responses_user_version_unique
        UNIQUE (user_id, survey_version);

-- Analytics-friendly indexes: "responses for this survey version" and
-- "most common annoyance/wanted-feature/liked-most option" are both
-- direct, no-scan-of-everything queries with these in place.
CREATE INDEX IF NOT EXISTS idx_survey_responses_version
    ON public.survey_responses USING btree (survey_version);
CREATE INDEX IF NOT EXISTS idx_survey_responses_annoyances
    ON public.survey_responses USING gin (annoyances);
CREATE INDEX IF NOT EXISTS idx_survey_responses_wanted_features
    ON public.survey_responses USING gin (wanted_features);
CREATE INDEX IF NOT EXISTS idx_survey_responses_liked_most
    ON public.survey_responses USING gin (liked_most);

ALTER TABLE public.survey_responses ENABLE ROW LEVEL SECURITY;

-- Own-row only, both directions — mirrors reports' exact existing RLS
-- shape. No client UPDATE/DELETE policy at all (a submitted response is
-- immutable from the client's own side, matching "duplicate submission
-- is prevented" rather than "editable afterward" — not requested in this
-- pass). No broad/public read policy of any kind: another user's answers
-- are never visible to a normal client, and there is no admin-role read
-- policy needed here either — the Jma3a team queries this table via the
-- existing service-role/admin architecture (service_role already
-- bypasses RLS entirely, same as every other admin-analytics path in
-- this schema), not a new RLS grant.
DROP POLICY IF EXISTS "survey_responses: own insert" ON public.survey_responses;
CREATE POLICY "survey_responses: own insert" ON public.survey_responses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "survey_responses: own read" ON public.survey_responses;
CREATE POLICY "survey_responses: own read" ON public.survey_responses
    FOR SELECT USING (auth.uid() = user_id);

GRANT SELECT, INSERT ON TABLE public.survey_responses TO authenticated;
GRANT ALL ON TABLE public.survey_responses TO service_role;
