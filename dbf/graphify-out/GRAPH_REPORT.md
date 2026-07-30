# Graph Report - jma3a/dbf  (2026-07-30)

## Corpus Check
- 1 files · ~0 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1040 nodes · 1333 edges · 68 communities (64 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67

## God Nodes (most connected - your core abstractions)
1. `profiles` - 93 edges
2. `packs` - 76 edges
3. `rooms` - 72 edges
4. `profiles.id ("uuid")` - 59 edges
5. `room_members` - 46 edges
6. `game_sessions` - 45 edges
7. `physical_pack_requests` - 34 edges
8. `deposits` - 30 edges
9. `withdrawals` - 30 edges
10. `room_settings` - 25 edges

## Surprising Connections (you probably didn't know these)
- `apply_wallet_transaction("p_wallet_id" "uuid", "p_type" "public"."transaction_type_enum", "p_amount_mru" integer, "p_reference_id" "uuid" DEFAULT NULL::"uuid", "p_description" "text" DEFAULT NULL::"text", "p_idempotency_key" "text" DEFAULT NULL::"text", "p_balance_type" "text" DEFAULT 'wallet'::"text") -> "public"."wallet_transactions"` --references_table--> `wallet_transactions`  [EXTRACTED]
  jma3a/dbf/schema.sql → jma3a/dbf/schema.sql  _Bridges community 27 → community 15_
- `deposits` --references_table--> `wallet_transactions`  [EXTRACTED]
  jma3a/dbf/schema.sql → jma3a/dbf/schema.sql  _Bridges community 27 → community 14_
- `pack_submissions` --references_table--> `wallet_transactions`  [EXTRACTED]
  jma3a/dbf/schema.sql → jma3a/dbf/schema.sql  _Bridges community 27 → community 52_
- `physical_pack_requests` --references_table--> `wallet_transactions`  [EXTRACTED]
  jma3a/dbf/schema.sql → jma3a/dbf/schema.sql  _Bridges community 27 → community 9_
- `wallet_transactions` --primary_key--> `wallet_transactions.id ("uuid")`  [EXTRACTED]
  jma3a/dbf/schema.sql → jma3a/dbf/schema.sql  _Bridges community 27 → community 57_

## Import Cycles
- None detected.

## Communities (68 total, 4 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (40): handle_new_auth_user() -> "trigger", handle_new_user() -> "trigger", set_theme_background_color("p_hex_color" "text") -> "public"."profiles", idx_profiles_email (btree: "email"), idx_profiles_is_banned (btree: "is_banned"), idx_profiles_online_status (btree: "online_status"), idx_profiles_search (gin: "public"."immutable_to_tsvector"(((COALESCE("username", ''::"text"), idx_profiles_username_lower (btree: "lower"("username") (+32 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (38): idx_packs_browse (btree: "status", "game_type", "avg_rating" DESC, "total_purchases" DESC), idx_packs_category (btree: "category_id", "avg_rating" DESC), idx_packs_creator (btree: "creator_id", "status", "created_at" DESC), idx_packs_featured (btree: "is_featured", "is_promoted"), idx_packs_languages (gin: "available_languages"), idx_packs_search (gin: "public"."immutable_to_tsvector"(((((COALESCE(("title" ->> 'en'::"text"), packs: creator insert (FOR INSERT), packs: creator update (FOR UPDATE) (+30 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (36): purchase_status_enum (enum: pending, completed, refunded, failed), cleanup_expired_purchases() -> integer, refresh_pack_purchase_count() -> "trigger", idx_commissions_creator (btree: "creator_id", "created_at" DESC), idx_purchases_buyer (btree: "buyer_id", "pack_id", "expires_at" DESC), idx_purchases_pack (btree: "pack_id", "purchased_at" DESC), commissions: creator read (FOR SELECT), commissions: no client write (FOR INSERT) (+28 more)

### Community 3 - "Community 3"
Cohesion: 0.06
Nodes (36): cleanup_expired_bans() -> integer, cleanup_expired_invites() -> integer, cleanup_expired_notifications() -> integer, cleanup_expired_platform_bans() -> integer, cleanup_otp_audit_log() -> integer, cleanup_purge_closed_rooms() -> integer, cleanup_stale_online_status() -> integer, cleanup_stale_rooms() -> integer (+28 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (34): notification_type_enum (enum: friend_request, friend_accepted, room_invite, room_started, pack_approved, pack_rejected, pack_sale, wallet_credit, wallet_debit, moderation, system, achievement, wallet_deposit_rejected, wallet_withdrawal_rejected, room_join_request, room_join_approved, room_join_rejected, game_ended), create_default_notification_preferences("p_user_id" "uuid") -> "void", notifications_set_read_at() -> "trigger", send_notification("p_user_id" "uuid", "p_type" "public"."notification_type_enum", "p_title" "jsonb", "p_body" "jsonb", "p_data" "jsonb" DEFAULT '{}'::"jsonb") -> "uuid", idx_notifications_expires (btree: "expires_at"), idx_notifications_user_all (btree: "user_id", "created_at" DESC), idx_notifications_user_unread (btree: "user_id", "created_at" DESC), notification_preferences: own access (FOR ALL) (+26 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (34): room_status_enum (enum: waiting, starting, in_game, paused, ended, closed), room_visibility_enum (enum: public, private), generate_invite_code() -> "text", get_my_closed_rooms() -> TABLE("room_id" "uuid", "name" "text", "cover_emoji" "text", "game_type" "public"."game_type_enum", "closed_at" timestamp with time zone, "max_players" smallint, "created_at" timestamp with time zone), get_room_by_invite_code("p_code" "text") -> TABLE("id" "uuid", "name" "text", "visibility" "text", "status" "text", "game_type" "text", "current_players" smallint, "max_players" smallint, "owner_id" "uuid", "pack_id" "uuid", "language" "text", "allow_spicy" boolean, "invite_code" "text", "cover_emoji" "text", "last_active_at" timestamp with time zone, "created_at" timestamp with time zone), rooms_set_invite_code() -> "trigger", idx_rooms_invite_code (btree: "invite_code"), idx_rooms_owner (btree: "owner_id") (+26 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (34): record_proof_view("p_session_id" "uuid", "p_turn_started_at" bigint) -> "jsonb", rooms_create_settings() -> "trigger", sync_requires_approval() -> "trigger", room_settings: member read (FOR SELECT), room_settings: moderator update (FOR UPDATE), room_settings: no client insert (FOR INSERT), tod_proof_views: no client insert (FOR INSERT), tod_proof_views: no client update (FOR UPDATE) (+26 more)

### Community 7 - "Community 7"
Cohesion: 0.06
Nodes (33): idx_pack_reactions_pack (btree: "pack_id", "sort_order"), idx_pack_tags_tag (btree: "tag"), idx_promoted_active (btree: "position", "starts_at", "ends_at"), pack_reactions: read (FOR SELECT), pack_tags: creator delete (FOR DELETE), pack_tags: creator write (FOR INSERT), pack_tags: public read (FOR SELECT), promoted_packs: public read (FOR SELECT) (+25 more)

### Community 8 - "Community 8"
Cohesion: 0.07
Nodes (31): room_member_role_enum (enum: player, moderator, spectator), can_view_hidden_room_member("p_room_id" "uuid", "p_user_id" "uuid") -> boolean, create_room("p_name" "text", "p_visibility" "text" DEFAULT 'public'::"text", "p_max_players" smallint DEFAULT NULL::smallint, "p_language" "text" DEFAULT 'en'::"text", "p_cover_emoji" "text" DEFAULT '🎮'::"text") -> "public"."rooms", is_room_member("p_room_id" "uuid", "p_user_id" "uuid") -> boolean, refresh_room_player_count() -> "trigger", touch_room_presence("p_room_id" "uuid") -> "void", _trg_update_current_players() -> "trigger", idx_room_members_away (btree: "room_id", "is_away") (+23 more)

### Community 9 - "Community 9"
Cohesion: 0.07
Nodes (30): physical_pack_request_status_enum (enum: pending, processing, shipped, delivered, cancelled, payment_confirmed, under_review, printing, packaging, out_for_delivery, completed), physical_pack_requests: no client insert (FOR INSERT), physical_pack_requests: no client update (FOR UPDATE), physical_pack_requests: own read (FOR SELECT), physical_pack_requests, physical_pack_requests.address_line1 ("text"), physical_pack_requests.address_line2 ("text"), physical_pack_requests.cancelled_at (timestamp with time zone) (+22 more)

### Community 10 - "Community 10"
Cohesion: 0.08
Nodes (28): refresh_pack_rating() -> "trigger", idx_pack_ratings_pack (btree: "pack_id"), idx_pack_reviews_pack (btree: "pack_id", "created_at" DESC), pack_ratings: buyer write (FOR INSERT), pack_ratings: own update (FOR UPDATE), pack_ratings: public read (FOR SELECT), pack_reviews: buyer insert (FOR INSERT), pack_reviews: own update (FOR UPDATE) (+20 more)

### Community 11 - "Community 11"
Cohesion: 0.08
Nodes (25): game_session_status_enum (enum: active, paused, completed, aborted), close_abandoned_room("p_room_id" "uuid") -> "void", close_room("p_room_id" "uuid") -> "void", recover_owner_room("p_room_id" "uuid") -> "jsonb", transfer_room_ownership("p_room_id" "uuid", "p_new_owner_id" "uuid") -> "void", idx_game_sessions_room (btree: "room_id", "started_at" DESC), idx_game_sessions_status (btree: "status"), game_sessions: no client write (FOR INSERT) (+17 more)

### Community 12 - "Community 12"
Cohesion: 0.09
Nodes (23): verification_status_enum (enum: unverified, pending, verified, rejected), apply_verification_decision() -> "trigger", idx_verifications_pending (btree: "status", "created_at"), creator_verifications: no client update (FOR UPDATE), creator_verifications: own insert (FOR INSERT), creator_verifications: own read (FOR SELECT), creator_verifications, creator_verifications.bio ("text") (+15 more)

### Community 13 - "Community 13"
Cohesion: 0.09
Nodes (23): admin_grant_premium("p_user_id" "uuid", "p_days" integer DEFAULT 30, "p_tier" "text" DEFAULT 'premium'::"text", "p_source" "text" DEFAULT 'admin'::"text") -> "void", expire_subscriptions() -> "void", sync_premium_status("p_user_id" "uuid") -> "void", _trg_sync_premium() -> "trigger", idx_subscriptions_expires_at (btree: "expires_at"), idx_subscriptions_user_id (btree: "user_id", "status"), subscriptions: owner read (FOR SELECT), subscriptions (+15 more)

### Community 14 - "Community 14"
Cohesion: 0.10
Nodes (21): idx_deposits_pending (btree: "status", "created_at"), idx_deposits_user (btree: "user_id", "created_at" DESC), deposits: no client update (FOR UPDATE), deposits: own insert (FOR INSERT), deposits: own read (FOR SELECT), deposits, deposits.amount_mru (integer NOT NULL), deposits.approved_at (timestamp with time zone) (+13 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (20): apply_wallet_transaction("p_wallet_id" "uuid", "p_type" "public"."transaction_type_enum", "p_amount_mru" integer, "p_reference_id" "uuid" DEFAULT NULL::"uuid", "p_description" "text" DEFAULT NULL::"text", "p_idempotency_key" "text" DEFAULT NULL::"text", "p_balance_type" "text" DEFAULT 'wallet'::"text") -> "public"."wallet_transactions", check_wallet_balance("p_wallet_id" "uuid", "p_amount" integer) -> boolean, create_user_wallet() -> "trigger", purchase_pack("p_user_id" "uuid", "p_pack_id" "uuid", "p_idempotency_key" "text" DEFAULT NULL::"text") -> "jsonb", request_physical_pack("p_pack_id" "uuid", "p_recipient_name" "text", "p_phone_number" "text", "p_city" "text", "p_zone" "text", "p_quantity" integer DEFAULT 1, "p_notes" "text" DEFAULT NULL::"text", "p_address_line1" "text" DEFAULT NULL::"text", "p_address_line2" "text" DEFAULT NULL::"text", "p_country" "text" DEFAULT NULL::"text") -> "uuid", submit_pack_for_review("p_pack_id" "uuid", "p_pay_fee" boolean DEFAULT false) -> "jsonb", transfer_earnings_to_wallet("p_wallet_id" "uuid", "p_amount_mru" integer) -> "void", idx_wallets_user (btree: "user_id") (+12 more)

### Community 16 - "Community 16"
Cohesion: 0.10
Nodes (20): idx_withdrawals_pending (btree: "status", "created_at"), idx_withdrawals_user (btree: "user_id", "created_at" DESC), withdrawals: no client update (FOR UPDATE), withdrawals: own insert (FOR INSERT), withdrawals: own read (FOR SELECT), withdrawals, withdrawals.amount_mru (integer NOT NULL), withdrawals.created_at (timestamp with time zone DEFAULT ") (+12 more)

### Community 17 - "Community 17"
Cohesion: 0.11
Nodes (19): idx_pack_analytics_date (btree: "date" DESC), idx_pack_analytics_pack (btree: "pack_id", "date" DESC), pack_analytics: no client access (FOR ALL), pack_analytics, pack_analytics.avg_new_rating (numeric(3,2)), pack_analytics.avg_session_mins (numeric(6,2)), pack_analytics.created_at (timestamp with time zone DEFAULT "), pack_analytics.date ("date") (+11 more)

### Community 18 - "Community 18"
Cohesion: 0.11
Nodes (18): moderation_action_type_enum (enum: warn, mute, room_ban, platform_ban, content_removed, account_suspended, verification_revoked), apply_moderation_to_profile() -> "trigger", idx_moderation_moderator (btree: "moderator_id", "created_at" DESC), idx_moderation_report (btree: "report_id"), idx_moderation_target_user (btree: "target_user_id", "created_at" DESC), moderation_actions: no client access (FOR ALL), moderation_actions, moderation_actions.action ("public") (+10 more)

### Community 19 - "Community 19"
Cohesion: 0.11
Nodes (18): report_status_enum (enum: open, under_review, resolved, dismissed), report_type_enum (enum: spam, harassment, inappropriate_content, hate_speech, cheating, impersonation, underage, other), idx_pack_reports_open (btree: "status", "created_at"), idx_pack_reports_pack (btree: "pack_id", "status"), pack_reports: authenticated insert (FOR INSERT), pack_reports: own read (FOR SELECT), pack_reports, pack_reports.created_at (timestamp with time zone DEFAULT ") (+10 more)

### Community 20 - "Community 20"
Cohesion: 0.12
Nodes (18): idx_chat_room_created (btree: "room_id", "created_at" DESC), idx_room_chat_reply_to (btree: "reply_to_id"), room_chat: member insert (FOR INSERT), room_chat: member read (FOR SELECT), room_chat: moderator soft delete (FOR UPDATE), room_messages: read for members (FOR SELECT), room_chat_messages, room_chat_messages.content ("text") (+10 more)

### Community 21 - "Community 21"
Cohesion: 0.11
Nodes (18): idx_gameplay_analytics_date (btree: ((("started_at" AT TIME ZONE 'UTC'::"text"), idx_gameplay_analytics_game_type (btree: "game_type", "started_at" DESC), idx_gameplay_analytics_pack (btree: "pack_id", "started_at" DESC), gameplay_analytics: no client access (FOR ALL), gameplay_analytics, gameplay_analytics.chat_messages (integer DEFAULT 0 NOT NULL), gameplay_analytics.created_at (timestamp with time zone DEFAULT "), gameplay_analytics.duration_secs (integer NOT NULL) (+10 more)

### Community 22 - "Community 22"
Cohesion: 0.12
Nodes (17): payment_methods_config: no client write (FOR INSERT), payment_methods_config: public read (FOR SELECT), payment_methods_config, payment_methods_config.account_name ("text"), payment_methods_config.account_number ("text"), payment_methods_config.created_at (timestamp with time zone DEFAULT "), payment_methods_config.instructions ("text"), payment_methods_config.is_active (boolean DEFAULT true NOT NULL) (+9 more)

### Community 23 - "Community 23"
Cohesion: 0.12
Nodes (16): friendship_status_enum (enum: pending, accepted, rejected, blocked), idx_friendships_accepted (btree: "requester_id", "addressee_id"), idx_friendships_addressee (btree: "addressee_id", "status"), idx_friendships_requester (btree: "requester_id", "status"), friendships: addressee update (FOR UPDATE), friendships: participant delete (FOR DELETE), friendships: participant read (FOR SELECT), friendships: requester insert (FOR INSERT) (+8 more)

### Community 24 - "Community 24"
Cohesion: 0.12
Nodes (16): idx_reports_open (btree: "status", "priority" DESC, "created_at"), idx_reports_reporter (btree: "reporter_id", "created_at" DESC), idx_reports_target (btree: "target_type", "target_id", "status"), reports: authenticated insert (FOR INSERT), reports: own read (FOR SELECT), moderation_actions.report_id ("uuid"), reports, reports.created_at (timestamp with time zone DEFAULT ") (+8 more)

### Community 25 - "Community 25"
Cohesion: 0.12
Nodes (16): idx_room_bans_room (btree: "room_id"), idx_room_bans_user (btree: "user_id"), room_bans: moderator or own read (FOR SELECT), room_bans: no client insert (FOR INSERT), room_bans: no client update (FOR UPDATE), room_bans: owner can insert (FOR INSERT), room_bans: owner can update (FOR UPDATE), room_bans (+8 more)

### Community 26 - "Community 26"
Cohesion: 0.14
Nodes (15): difficulty_enum (enum: mild, medium, spicy), refresh_pack_card_count() -> "trigger", idx_pack_cards_pack (btree: "pack_id", "sort_order", "difficulty"), pack_cards: creator write (FOR INSERT), pack_cards: read (FOR SELECT), game_turns.card_id ("uuid"), pack_cards, pack_cards.content ("jsonb") (+7 more)

### Community 27 - "Community 27"
Cohesion: 0.13
Nodes (15): transaction_type_enum (enum: deposit, withdrawal, purchase, refund, commission, payout, adjustment, bonus, transfer), idx_wallet_tx_reference (btree: "reference_id"), idx_wallet_tx_wallet (btree: "wallet_id", "created_at" DESC), wallet_transactions: no client write (FOR INSERT), wallet_transactions: own read (FOR SELECT), wallet_transactions, wallet_transactions.amount_mru (integer NOT NULL), wallet_transactions.balance_after (integer NOT NULL) (+7 more)

### Community 28 - "Community 28"
Cohesion: 0.13
Nodes (15): claim_room_ownership("p_room_id" "uuid") -> "uuid", idx_room_moderators_room (btree: "room_id"), idx_room_moderators_user (btree: "user_id"), room_moderators: member read (FOR SELECT), room_moderators: members can read (FOR SELECT), room_moderators: no client delete (FOR DELETE), room_moderators: no client write (FOR INSERT), room_moderators: owner can delete (FOR DELETE) (+7 more)

### Community 29 - "Community 29"
Cohesion: 0.14
Nodes (14): category_suggestion_status_enum (enum: pending, approved, rejected), pack_category_suggestions: no client update (FOR UPDATE), pack_category_suggestions: own insert (FOR INSERT), pack_category_suggestions: own read (FOR SELECT), pack_category_suggestions, pack_category_suggestions.created_at (timestamp with time zone DEFAULT "), pack_category_suggestions.id ("uuid"), pack_category_suggestions.rejection_reason ("text") (+6 more)

### Community 30 - "Community 30"
Cohesion: 0.14
Nodes (14): room_log_action_enum (enum: created, joined, left, kicked, banned, unbanned, muted, unmuted, game_started, game_ended, game_paused, game_resumed, settings_changed, ownership_transferred, chat_deleted, invite_created, invite_used), log_room_event("p_room_id" "uuid", "p_actor_id" "uuid", "p_target_id" "uuid", "p_action" "public"."room_log_action_enum", "p_metadata" "jsonb" DEFAULT NULL::"jsonb") -> "void", idx_room_logs_actor (btree: "actor_id", "created_at" DESC), idx_room_logs_room (btree: "room_id", "created_at" DESC), room_logs: moderator read (FOR SELECT), room_logs: no client write (FOR INSERT), room_logs, room_logs.action ("public") (+6 more)

### Community 31 - "Community 31"
Cohesion: 0.14
Nodes (14): sms_delivery_log: no client access (FOR ALL), sms_delivery_log, sms_delivery_log.created_at (timestamp with time zone DEFAULT "), sms_delivery_log.error_message ("text"), sms_delivery_log.id ("uuid"), sms_delivery_log.idempotency_key ("text"), sms_delivery_log.message_id ("text"), sms_delivery_log.message_type ("text") (+6 more)

### Community 32 - "Community 32"
Cohesion: 0.15
Nodes (13): turn_result_enum (enum: completed, skipped, timed_out, voted_out), idx_game_turns_player (btree: "player_id", "started_at" DESC), idx_game_turns_session (btree: "session_id", "turn_number"), game_turns: session player read (FOR SELECT), game_turns, game_turns.card_content ("text"), game_turns.completed_at (timestamp with time zone), game_turns.ended_at (timestamp with time zone) (+5 more)

### Community 33 - "Community 33"
Cohesion: 0.17
Nodes (12): add_updated_at_trigger("schema_name" "text", "table_name" "text") -> "void", set_updated_at() -> "trigger", trg_creator_verifications_updated_at, trg_deposits_updated_at, trg_game_sessions_updated_at, trg_packs_updated_at, trg_payment_methods_config_updated_at, trg_profiles_updated_at (+4 more)

### Community 34 - "Community 34"
Cohesion: 0.17
Nodes (12): apply_category_suggestion_decision() -> "trigger", pack_categories: public read (FOR SELECT), pack_categories, pack_categories.created_at (timestamp with time zone DEFAULT "), pack_categories.icon ("text"), pack_categories.id ("uuid"), pack_categories.is_active (boolean DEFAULT true NOT NULL), pack_categories.name_json ("jsonb") (+4 more)

### Community 35 - "Community 35"
Cohesion: 0.18
Nodes (12): trim_game_states() -> "trigger", idx_game_states_session (btree: "session_id", "snapshot_at" DESC), game_states: no client write (FOR INSERT), game_states: session player read (FOR SELECT), game_states, game_states.id (bigint NOT NULL), game_states.round_number (smallint), game_states.session_id ("uuid") (+4 more)

### Community 36 - "Community 36"
Cohesion: 0.17
Nodes (12): idx_game_votes_session (btree: "session_id", "voter_id"), idx_game_votes_turn (btree: "turn_id"), game_votes: own insert (FOR INSERT), game_votes: session player read (FOR SELECT), game_turns.id ("uuid"), game_votes, game_votes.created_at (timestamp with time zone DEFAULT "), game_votes.id ("uuid") (+4 more)

### Community 37 - "Community 37"
Cohesion: 0.17
Nodes (12): idx_join_requests_room_pending (btree: "room_id", "status"), idx_room_join_requests_room (btree: "room_id", "status"), join_requests_insert_own (FOR INSERT), join_requests_select (FOR SELECT), join_requests_update_moderator (FOR UPDATE), room_join_requests: own or room member (FOR ALL), room_join_requests, room_join_requests.created_at (timestamp with time zone DEFAULT ") (+4 more)

### Community 38 - "Community 38"
Cohesion: 0.17
Nodes (12): idx_room_return_timers_room (btree: "room_id"), room_return_timers: members can read (FOR SELECT), room_return_timers: own row (FOR ALL), room_return_timers: room members can read (FOR SELECT), room_return_timers, room_return_timers.created_at (timestamp with time zone DEFAULT "), room_return_timers.expired (boolean DEFAULT false NOT NULL), room_return_timers.id ("uuid") (+4 more)

### Community 39 - "Community 39"
Cohesion: 0.17
Nodes (12): pack_languages: no client write (FOR INSERT), pack_languages: public read (FOR SELECT), pack_languages, pack_languages.code ("text"), pack_languages.created_at (timestamp with time zone DEFAULT "), pack_languages.is_active (boolean DEFAULT true NOT NULL), pack_languages.is_rtl (boolean DEFAULT false NOT NULL), pack_languages.name ("text") (+4 more)

### Community 40 - "Community 40"
Cohesion: 0.18
Nodes (11): ban_room_member("p_room_id" "uuid", "p_target_user_id" "uuid", "p_reason" "text" DEFAULT NULL::"text", "p_duration_secs" integer DEFAULT NULL::integer) -> "void", create_game_session("p_room_id" "uuid", "p_pack_id" "uuid", "p_game_type" "text", "p_player_ids" "uuid"[], "p_max_rounds" smallint, "p_turn_timer_secs" smallint, "p_allow_skip" boolean, "p_allow_spicy" boolean, "p_state_snapshot" "jsonb" DEFAULT '{}'::"jsonb") -> "uuid", decide_game_rejoin_request("p_request_id" "uuid", "p_approve" boolean) -> "void", decide_join_request("p_request_id" "uuid", "p_approve" boolean) -> "void", decide_spectator_request("p_request_id" "uuid", "p_approve" boolean) -> "void", has_room_permission("p_room_id" "uuid", "p_user_id" "uuid", "p_permission" "text") -> boolean, is_room_moderator("p_room_id" "uuid", "p_user_id" "uuid") -> boolean, is_room_owner("p_room_id" "uuid", "p_user_id" "uuid") -> boolean (+3 more)

### Community 41 - "Community 41"
Cohesion: 0.18
Nodes (11): idx_payment_methods_user (btree: "user_id", "is_default" DESC), payment_methods: own access (FOR ALL), payment_methods, payment_methods.created_at (timestamp with time zone DEFAULT "), payment_methods.details ("jsonb"), payment_methods.id ("uuid"), payment_methods.is_default (boolean DEFAULT false NOT NULL), payment_methods.label ("text") (+3 more)

### Community 42 - "Community 42"
Cohesion: 0.18
Nodes (11): game_sessions.owner_id ("uuid"), moderation_actions.reversed_by ("uuid"), moderation_actions.target_user_id ("uuid"), packs.creator_id ("uuid"), packs.reviewed_by ("uuid"), profiles.id ("uuid"), reports.assigned_to ("uuid"), reports.reporter_id ("uuid") (+3 more)

### Community 43 - "Community 43"
Cohesion: 0.18
Nodes (11): game_sessions.room_id ("uuid"), gameplay_analytics.room_id ("uuid"), room_bans.room_id ("uuid"), room_chat_messages.room_id ("uuid"), room_invites.room_id ("uuid"), room_join_requests.room_id ("uuid"), room_members.room_id ("uuid"), room_moderators.room_id ("uuid") (+3 more)

### Community 44 - "Community 44"
Cohesion: 0.20
Nodes (10): get_closed_room_details("p_room_id" "uuid") -> "jsonb", start_game_session_checks("p_user_id" "uuid", "p_room_id" "uuid", "p_pack_id" "uuid", "p_is_premium" boolean) -> "text", idx_room_played_packs_room (btree: "room_id"), room_played_packs: member insert (FOR INSERT), room_played_packs: members read (FOR SELECT), room_played_packs, room_played_packs.id ("uuid"), room_played_packs.pack_id ("uuid") (+2 more)

### Community 45 - "Community 45"
Cohesion: 0.20
Nodes (10): request_game_rejoin("p_room_id" "uuid") -> "uuid", idx_game_rejoin_requests_room (btree: "room_id", "status"), game_rejoin_requests: own or room member (FOR SELECT), game_rejoin_requests: self insert (FOR INSERT), game_rejoin_requests, game_rejoin_requests.created_at (timestamp with time zone DEFAULT "), game_rejoin_requests.id ("uuid"), game_rejoin_requests.resolved_at (timestamp with time zone) (+2 more)

### Community 46 - "Community 46"
Cohesion: 0.20
Nodes (10): idx_blocked_users_blocked (btree: "blocked_id"), blocked_users: own delete (FOR DELETE), blocked_users: own insert (FOR INSERT), blocked_users: own read (FOR SELECT), blocked_users, blocked_users.blocked_id ("uuid"), blocked_users.blocker_id ("uuid"), blocked_users.created_at (timestamp with time zone DEFAULT ") (+2 more)

### Community 47 - "Community 47"
Cohesion: 0.20
Nodes (10): idx_fin_audit_action (btree: "action", "created_at" DESC), idx_fin_audit_actor (btree: "actor_id", "created_at" DESC), financial_audit_log: no client access (FOR ALL), financial_audit_log, financial_audit_log.action ("text"), financial_audit_log.actor_id ("uuid"), financial_audit_log.created_at (timestamp with time zone DEFAULT "), financial_audit_log.id (bigint NOT NULL) (+2 more)

### Community 48 - "Community 48"
Cohesion: 0.20
Nodes (10): idx_session_custom_cards_session (btree: "session_id"), session_custom_cards: room members (FOR ALL), session_custom_cards, session_custom_cards.added_by ("uuid"), session_custom_cards.card_type ("text"), session_custom_cards.content ("text"), session_custom_cards.created_at (timestamp with time zone DEFAULT "), session_custom_cards.difficulty ("text") (+2 more)

### Community 49 - "Community 49"
Cohesion: 0.20
Nodes (10): idx_spectator_requests_room (btree: "room_id", "status"), spectator_requests: member decide (FOR UPDATE), spectator_requests: own or room member (FOR SELECT), spectator_requests: self insert (FOR INSERT), spectator_requests, spectator_requests.created_at (timestamp with time zone DEFAULT "), spectator_requests.decided_at (timestamp with time zone), spectator_requests.decided_by ("uuid") (+2 more)

### Community 50 - "Community 50"
Cohesion: 0.22
Nodes (9): idx_follows_followee (btree: "followee_id"), follows: own delete (FOR DELETE), follows: own insert (FOR INSERT), follows: public read (FOR SELECT), follows, follows.created_at (timestamp with time zone DEFAULT "), follows.followee_id ("uuid"), follows.follower_id ("uuid") (+1 more)

### Community 51 - "Community 51"
Cohesion: 0.22
Nodes (9): idx_game_rounds_session (btree: "session_id", "round_number"), game_rounds: session player read (FOR SELECT), game_rounds, game_rounds.ended_at (timestamp with time zone), game_rounds.id ("uuid"), game_rounds.round_number (smallint NOT NULL), game_rounds.session_id ("uuid"), game_rounds.started_at (timestamp with time zone DEFAULT ") (+1 more)

### Community 52 - "Community 52"
Cohesion: 0.22
Nodes (9): pack_submissions: no client insert (FOR INSERT), pack_submissions: no client update (FOR UPDATE), pack_submissions: own read (FOR SELECT), pack_submissions, pack_submissions.creator_id ("uuid"), pack_submissions.fee_paid (boolean DEFAULT false NOT NULL), pack_submissions.id ("uuid"), pack_submissions.pack_id ("uuid") (+1 more)

### Community 53 - "Community 53"
Cohesion: 0.29
Nodes (7): auth.users (Supabase Auth — not defined in this schema.sql), game_rejoin_requests.user_id ("uuid"), room_chat_messages.real_sender_id ("uuid"), room_join_requests.user_id ("uuid"), room_return_timers.user_id ("uuid"), spectator_requests.user_id ("uuid"), subscriptions.user_id ("uuid")

### Community 54 - "Community 54"
Cohesion: 0.29
Nodes (7): app_settings: no client update (FOR UPDATE), app_settings: no client write (FOR INSERT), app_settings: public read (FOR SELECT), app_settings, app_settings.key ("text"), app_settings.updated_at (timestamp with time zone DEFAULT "), app_settings.value ("jsonb")

### Community 55 - "Community 55"
Cohesion: 0.29
Nodes (7): room_creation_quotas: own row (FOR ALL), room_creation_quotas, room_creation_quotas.is_premium (boolean DEFAULT false NOT NULL), room_creation_quotas.quota_date ("date"), room_creation_quotas.rooms_today (smallint DEFAULT 0 NOT NULL), room_creation_quotas.updated_at (timestamp with time zone DEFAULT "), room_creation_quotas.user_id ("uuid")

### Community 56 - "Community 56"
Cohesion: 0.29
Nodes (7): game_rejoin_requests.session_id ("uuid"), game_sessions.id ("uuid"), game_turns.session_id ("uuid"), game_votes.session_id ("uuid"), gameplay_analytics.session_id ("uuid"), session_custom_cards.session_id ("uuid"), tod_proof_views.session_id ("uuid")

### Community 57 - "Community 57"
Cohesion: 0.33
Nodes (6): deposits.tx_id ("uuid"), pack_submissions.fee_tx_id ("uuid"), physical_pack_requests.tx_id ("uuid"), wallet_transactions.id ("uuid"), withdrawals.hold_tx_id ("uuid"), withdrawals.tx_id ("uuid")

### Community 58 - "Community 58"
Cohesion: 0.40
Nodes (5): game_type_enum (enum: truth_or_dare, never_have_i_ever, meme_game), game_sessions.game_type ("public"), gameplay_analytics.game_type ("public"), packs.game_type ("public"), rooms.game_type ("public")

### Community 59 - "Community 59"
Cohesion: 0.50
Nodes (4): payment_method_type_enum (enum: bankily, masrivi, sedad, bimbank, cash, other), deposits.payment_method ("public"), payment_methods.type ("public"), withdrawals.payout_method ("public")

### Community 60 - "Community 60"
Cohesion: 0.50
Nodes (4): transaction_status_enum (enum: pending, processing, completed, failed, cancelled, reversed), deposits.status ("public"), wallet_transactions.status ("public"), withdrawals.status ("public")

### Community 61 - "Community 61"
Cohesion: 0.50
Nodes (4): deposits.wallet_id ("uuid"), wallet_transactions.wallet_id ("uuid"), wallets.id ("uuid"), withdrawals.wallet_id ("uuid")

### Community 62 - "Community 62"
Cohesion: 0.67
Nodes (3): card_type_enum (enum: truth, dare, statement, prompt), game_turns.card_type ("public"), pack_cards.card_type ("public")

### Community 63 - "Community 63"
Cohesion: 0.67
Nodes (3): deposits.payment_method_id ("uuid"), payment_methods_config.id ("uuid"), withdrawals.payment_method_id ("uuid")

## Knowledge Gaps
- **706 isolated node(s):** `category_suggestion_status_enum (enum: pending, approved, rejected)`, `difficulty_enum (enum: mild, medium, spicy)`, `friendship_status_enum (enum: pending, accepted, rejected, blocked)`, `game_session_status_enum (enum: active, paused, completed, aborted)`, `moderation_action_type_enum (enum: warn, mute, room_ban, platform_ban, content_removed, account_suspended, verification_revoked)` (+701 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `profiles` connect `Community 0` to `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 18`, `Community 19`, `Community 20`, `Community 23`, `Community 24`, `Community 25`, `Community 28`, `Community 29`, `Community 30`, `Community 32`, `Community 33`, `Community 36`, `Community 39`, `Community 41`, `Community 42`, `Community 44`, `Community 46`, `Community 47`, `Community 50`, `Community 52`, `Community 53`, `Community 64`?**
  _High betweenness centrality (0.580) - this node is a cross-community bridge._
- **Why does `packs` connect `Community 1` to `Community 0`, `Community 2`, `Community 5`, `Community 7`, `Community 9`, `Community 10`, `Community 11`, `Community 15`, `Community 17`, `Community 18`, `Community 19`, `Community 21`, `Community 26`, `Community 29`, `Community 33`, `Community 34`, `Community 39`, `Community 42`, `Community 44`, `Community 50`, `Community 52`, `Community 58`, `Community 65`?**
  _High betweenness centrality (0.217) - this node is a cross-community bridge._
- **Why does `rooms` connect `Community 5` to `Community 0`, `Community 1`, `Community 3`, `Community 6`, `Community 7`, `Community 8`, `Community 11`, `Community 20`, `Community 21`, `Community 25`, `Community 28`, `Community 30`, `Community 33`, `Community 37`, `Community 38`, `Community 40`, `Community 42`, `Community 43`, `Community 44`, `Community 45`, `Community 48`, `Community 49`, `Community 50`, `Community 58`?**
  _High betweenness centrality (0.217) - this node is a cross-community bridge._
- **What connects `category_suggestion_status_enum (enum: pending, approved, rejected)`, `difficulty_enum (enum: mild, medium, spicy)`, `friendship_status_enum (enum: pending, accepted, rejected, blocked)` to the rest of the system?**
  _706 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05263157894736842 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05714285714285714 - nodes in this community are weakly interconnected._