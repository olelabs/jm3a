-- Item 7: pack situation filters must come from the database, not a
-- hardcoded Flutter list (lib/features/packs/domain/pack_situation_tags.dart
-- previously hardcoded kPackSituationTags). This table is CURATION METADATA
-- only (per-slug emoji + per-language display label + display order +
-- active toggle) layered on top of the EXISTING pack_tags table's slug
-- vocabulary — it does not duplicate that taxonomy. A pack's actual tags
-- still live in pack_tags exactly as before; this table only controls
-- which of those slugs are offered as a FILTER option in the lobby pack
-- picker (ToD only — see game_settings_sheet.dart) and how they're
-- labeled/ordered there.
--
-- Mirrors the existing pack_categories table's shape/RLS/grant pattern
-- exactly (id/name_json/slug/icon/sort_order/is_active, public SELECT,
-- no client-facing write policy — managed the same way pack_categories
-- already is).
--
-- Seeded with the exact 12 slugs/emoji/labels the hardcoded list already
-- had, so this migration changes zero user-visible behavior on its own;
-- only a later direct edit to this table (adding/disabling/reordering a
-- row) changes what the filter picker shows, with no app update needed.

BEGIN;

CREATE TABLE IF NOT EXISTS "public"."pack_situation_filters" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name_json" "jsonb" NOT NULL,
    "icon" "text" DEFAULT '🏷️'::"text",
    "sort_order" smallint DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "pack_situation_filters_slug_check" CHECK (("slug" ~ '^[a-z0-9_-]{1,30}$'::"text"))
);

ALTER TABLE "public"."pack_situation_filters" OWNER TO "postgres";

ALTER TABLE ONLY "public"."pack_situation_filters"
    ADD CONSTRAINT "pack_situation_filters_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."pack_situation_filters"
    ADD CONSTRAINT "pack_situation_filters_slug_key" UNIQUE ("slug");

ALTER TABLE "public"."pack_situation_filters" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pack_situation_filters: public read" ON "public"."pack_situation_filters" FOR SELECT USING (true);

GRANT ALL ON TABLE "public"."pack_situation_filters" TO "anon";
GRANT ALL ON TABLE "public"."pack_situation_filters" TO "authenticated";
GRANT ALL ON TABLE "public"."pack_situation_filters" TO "service_role";

INSERT INTO "public"."pack_situation_filters" ("slug", "name_json", "icon", "sort_order") VALUES
    ('relationship', '{"en":"Relationship","ar":"علاقة","fr":"Relation"}', '❤️', 0),
    ('breakup', '{"en":"Breakup","ar":"انفصال","fr":"Rupture"}', '💔', 1),
    ('fixing_relationship', '{"en":"Fixing relationship","ar":"إصلاح العلاقة","fr":"Réparer la relation"}', '🔧', 2),
    ('dating', '{"en":"Dating","ar":"مواعدة","fr":"Rencontres"}', '💌', 3),
    ('couples', '{"en":"Couples","ar":"أزواج","fr":"Couples"}', '💑', 4),
    ('friendship', '{"en":"Friendship","ar":"صداقة","fr":"Amitié"}', '🤝', 5),
    ('family', '{"en":"Family","ar":"عائلة","fr":"Famille"}', '👨‍👩‍👧', 6),
    ('party', '{"en":"Party","ar":"حفلة","fr":"Fête"}', '🎉', 7),
    ('icebreaker', '{"en":"Icebreaker","ar":"كسر الجليد","fr":"Brise-glace"}', '🧊', 8),
    ('work', '{"en":"Work","ar":"عمل","fr":"Travail"}', '💼', 9),
    ('travel', '{"en":"Travel","ar":"سفر","fr":"Voyage"}', '✈️', 10),
    ('late_night', '{"en":"Late night","ar":"سهرة ليلية","fr":"Tard le soir"}', '🌙', 11)
ON CONFLICT ("slug") DO NOTHING;

COMMIT;
