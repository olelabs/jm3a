// import 'dart:io';

// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../core/data/base_repository.dart';
// import '../../../core/errors/failures.dart';
// import '../../../core/network/api_client.dart';
// import '../../../core/utils/app_logger.dart';
// import '../../auth/domain/entities/user_entity.dart';

// /// Repository for all profile read/write operations.
// ///
// /// Read operations  → Supabase direct (RLS-protected, anon key safe)
// /// Write operations → Node.js API (service-role, owns business logic)
// ///   Includes: create, update, avatar upload, username change
// class ProfileRepository extends BaseRepository {
//   ProfileRepository._();
//   static final ProfileRepository _instance = ProfileRepository._();
//   static ProfileRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;
//   final _api = ApiClient.instance;

//   // ── Create / initial setup ────────────────────────────────────────────────
//   /// Called by OnboardingScreen after first login.
//   /// Routes through Node.js to enforce business rules (username uniqueness, etc.)
//   Future<UserEntity> createOrUpdateProfile({
//     required String userId,
//     required String username,
//     required String displayName,
//     int? age,
//     String? countryCode,
//     String preferredLanguage = 'en',
//   }) => guardedCall(
//     operationName: 'createOrUpdateProfile',
//     operation: () async {
//       final resp = await _api.post<Map<String, dynamic>>(
//         '/v1/auth/setup-profile',
//         data: {
//           'username': username.toLowerCase(),
//           'display_name': displayName,
//           if (age != null) 'age': age,
//           if (countryCode != null) 'country_code': countryCode,
//           'preferred_lang': preferredLanguage,
//         },
//       );
//       final profile =
//           (resp.data!['data'] as Map<String, dynamic>)['profile']
//               as Map<String, dynamic>;
//       return rowToEntity(profile);
//     },
//   );

//   // ── Update profile fields ─────────────────────────────────────────────────
//   /// Partial update — only provided fields are changed.
//   Future<UserEntity> updateProfile({
//     required String userId,
//     String? displayName,
//     String? bio,
//     String? countryCode,
//     int? age,
//     String? phoneNumber,
//     String? preferredLanguage,
//   }) => guardedCall(
//     operationName: 'updateProfile',
//     operation: () async {
//       final body = <String, dynamic>{
//         if (displayName != null) 'display_name': displayName,
//         if (bio != null) 'bio': bio,
//         if (countryCode != null) 'country_code': countryCode,
//         if (age != null) 'age': age,
//         if (phoneNumber != null) 'phone_number': phoneNumber,
//         if (preferredLanguage != null) 'preferred_lang': preferredLanguage,
//       };

//       if (body.isEmpty)
//         throw const ValidationFailure(message: 'No fields to update.');

//       final resp = await _api.patch<Map<String, dynamic>>(
//         '/v1/auth/profile',
//         data: body,
//       );
//       final profile =
//           (resp.data!['data'] as Map<String, dynamic>)['profile']
//               as Map<String, dynamic>;
//       return rowToEntity(profile);
//     },
//   );

//   // ── Username change ───────────────────────────────────────────────────────
//   /// Enforces 30-day cooldown and uniqueness via Node.js.
//   Future<UserEntity> changeUsername(String newUsername) => guardedCall(
//     operationName: 'changeUsername',
//     operation: () async {
//       final resp = await _api.post<Map<String, dynamic>>(
//         '/v1/auth/change-username',
//         data: {'username': newUsername.toLowerCase().trim()},
//       );
//       final profile =
//           (resp.data!['data'] as Map<String, dynamic>)['profile']
//               as Map<String, dynamic>;
//       return rowToEntity(profile);
//     },
//   );

//   // ── Avatar upload ─────────────────────────────────────────────────────────
//   Future<UserEntity> uploadAvatar({
//     required String userId,
//     required File imageFile,
//   }) => guardedCall(
//     operationName: 'uploadAvatar',
//     operation: () async {
//       final fileSizeBytes = await imageFile.length();
//       final urlResp = await _api.post<Map<String, dynamic>>(
//         '/v1/storage/upload-url',
//         data: {
//           'file_type': 'avatar',
//           'content_type': 'image/jpeg',
//           'file_size_bytes': fileSizeBytes,
//         },
//       );

//       final uploadData = urlResp.data!['data'] as Map<String, dynamic>;
//       final uploadUrl = uploadData['upload_url'] as String;
//       final publicUrl = uploadData['public_url'] as String;

//       // Upload directly to Wasabi using presigned URL
//       final bytes = await imageFile.readAsBytes();
//       final httpClient = HttpClient();
//       try {
//         final request = await httpClient.putUrl(Uri.parse(uploadUrl));
//         request.headers.set('Content-Type', 'image/jpeg');
//         request.headers.set('Content-Length', bytes.length.toString());
//         request.add(bytes);
//         final response = await request.close();
//         await response.drain<void>();

//         if (response.statusCode != 200) {
//           throw ServerFailure(
//             message: 'Avatar upload failed (HTTP ${response.statusCode}).',
//           );
//         }
//       } finally {
//         httpClient.close();
//       }

//       // Update avatar_url in profile via Node.js (keeps audit trail)
//       final resp = await _api.patch<Map<String, dynamic>>(
//         '/v1/auth/profile',
//         data: {'avatar_url': publicUrl},
//       );
//       final profile =
//           (resp.data!['data'] as Map<String, dynamic>)['profile']
//               as Map<String, dynamic>;
//       return rowToEntity(profile);
//     },
//   );

//   // ── Read operations ───────────────────────────────────────────────────────
//   Future<UserEntity?> getProfile(String userId) => softCall(
//     operationName: 'getProfile',
//     operation: () async {
//       final row = await _supabase
//           .from('profiles')
//           .select()
//           .eq('id', userId)
//           .maybeSingle();
//       // if (row == null) return null;
//       if (row == null)
//         throw const NotFoundFailure(message: 'Profile not found.');
//       return rowToEntity(row);
//     },
//   );

//   Future<UserEntity?> getProfileByUsername(String username) => softCall(
//     operationName: 'getProfileByUsername',
//     operation: () async {
//       final row = await _supabase
//           .from('profiles')
//           .select()
//           .eq('username', username.toLowerCase().trim())
//           .maybeSingle();
//       // if (row == null) return null;
//       if (row == null)
//         throw const NotFoundFailure(message: 'Profile not found.');
//       return rowToEntity(row);
//     },
//   );

//   /// Quick DB-level username check (used by OnboardingScreen fallback).
//   Future<bool> isUsernameTaken(String username, {String? excludeUserId}) =>
//       guardedCall(
//         operationName: 'isUsernameTaken',
//         operation: () async {
//           var q = _supabase
//               .from('profiles')
//               .select('id')
//               .eq('username', username.toLowerCase().trim());
//           if (excludeUserId != null) {
//             q = q.neq('id', excludeUserId);
//           }
//           final row = await q.maybeSingle();
//           return row != null;
//         },
//       );

//   // ── Mapper ────────────────────────────────────────────────────────────────
//   UserEntity rowToEntity(Map<String, dynamic> row) {
//     DateTime? _parseTs(dynamic v) =>
//         v != null ? DateTime.tryParse(v as String) : null;

//     return UserEntity(
//       id: row['id'] as String,
//       email: row['email'] as String? ?? '',
//       username: row['username'] as String?,
//       displayName: row['display_name'] as String?,
//       avatarUrl: row['avatar_url'] as String?,
//       bio: row['bio'] as String?,
//       countryCode: row['country_code'] as String?,
//       age: row['age'] as int?,
//       phoneNumber: row['phone_number'] as String?,
//       preferredLanguage: row['preferred_lang'] as String? ?? 'en',
//       verificationStatus: row['verification_status'] as String? ?? 'unverified',
//       onlineStatus: row['online_status'] as String? ?? 'offline',
//       inGameStatus: row['in_game_status'] as bool? ?? false,
//       isBanned: row['is_banned'] as bool? ?? false,
//       usernameChangedAt: _parseTs(row['username_changed_at']),
//       lastSeenAt: _parseTs(row['last_seen_at']),
//       createdAt: _parseTs(row['created_at']),
//       updatedAt: _parseTs(row['updated_at']),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/presence_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/streak_flame.dart';
import '../../auth/domain/entities/user_entity.dart';

class ProfileRepository extends BaseRepository {
  ProfileRepository._();
  static final ProfileRepository _instance = ProfileRepository._();
  static ProfileRepository get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _api = ApiClient.instance;

  Future<UserEntity> createOrUpdateProfile({
    required String userId,
    required String username,
    required String displayName,
    required int age,
    required String gender,
    String? countryCode,
    String preferredLanguage = 'en',
  }) => guardedCall(
    operationName: 'createOrUpdateProfile',
    operation: () async {
      final resp = await _api.post<Map<String, dynamic>>(
        '/v1/auth/setup-profile',
        data: {
          'username': username.toLowerCase(),
          'display_name': displayName,
          'age': age,
          'gender': gender,
          if (countryCode != null) 'country_code': countryCode,
          'preferred_lang': preferredLanguage,
        },
      );
      final profile =
          (resp.data!['data'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      return rowToEntity(profile);
    },
  );

  Future<UserEntity> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? countryCode,
    int? age,
    String? gender,
    String? phoneNumber,
    String? preferredLanguage,
  }) => guardedCall(
    operationName: 'updateProfile',
    operation: () async {
      final body = <String, dynamic>{
        if (displayName != null) 'display_name': displayName,
        if (bio != null) 'bio': bio,
        if (countryCode != null) 'country_code': countryCode,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (preferredLanguage != null) 'preferred_lang': preferredLanguage,
      };

      if (body.isEmpty)
        throw const ValidationFailure(message: 'No fields to update.');

      final resp = await _api.patch<Map<String, dynamic>>(
        '/v1/auth/profile',
        data: body,
      );
      final profile =
          (resp.data!['data'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      return rowToEntity(profile);
    },
  );

  Future<UserEntity> changeUsername(String newUsername) => guardedCall(
    operationName: 'changeUsername',
    operation: () async {
      final resp = await _api.post<Map<String, dynamic>>(
        '/v1/auth/change-username',
        data: {'username': newUsername.toLowerCase().trim()},
      );
      final profile =
          (resp.data!['data'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      return rowToEntity(profile);
    },
  );

  Future<UserEntity> uploadAvatar({
    required String userId,
    required File imageFile,
  }) => guardedCall(
    operationName: 'uploadAvatar',
    operation: () async {
      final fileSizeBytes = await imageFile.length();
      final urlResp = await _api.post<Map<String, dynamic>>(
        '/v1/storage/upload-url',
        data: {
          'file_type': 'avatar',
          'content_type': 'image/jpeg',
          'file_size_bytes': fileSizeBytes,
        },
      );

      final uploadData = urlResp.data!['data'] as Map<String, dynamic>;
      final uploadUrl = uploadData['upload_url'] as String;
      final publicUrl = uploadData['public_url'] as String;

      final bytes = await imageFile.readAsBytes();
      final httpClient = HttpClient();
      try {
        final request = await httpClient.putUrl(Uri.parse(uploadUrl));
        request.headers.set('Content-Type', 'image/jpeg');
        request.headers.set('Content-Length', bytes.length.toString());
        request.add(bytes);
        final response = await request.close();
        await response.drain<void>();

        if (response.statusCode != 200) {
          throw ServerFailure(
            message: 'Avatar upload failed (HTTP ${response.statusCode}).',
          );
        }
      } finally {
        httpClient.close();
      }

      final resp = await _api.patch<Map<String, dynamic>>(
        '/v1/auth/profile',
        data: {'avatar_url': publicUrl},
      );
      final profile =
          (resp.data!['data'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      return rowToEntity(profile);
    },
  );

  Future<UserEntity?> getProfile(String userId) => softCall(
    operationName: 'getProfile',
    operation: () async {
      final row = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null)
        throw const NotFoundFailure(message: 'Profile not found.');
      return rowToEntity(row);
    },
  );

  Future<UserEntity?> getProfileByUsername(String username) => softCall(
    operationName: 'getProfileByUsername',
    operation: () async {
      final row = await _supabase
          .from('profiles')
          .select()
          .eq('username', username.toLowerCase().trim())
          .maybeSingle();
      if (row == null)
        throw const NotFoundFailure(message: 'Profile not found.');
      return rowToEntity(row);
    },
  );

  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) =>
      guardedCall(
        operationName: 'isUsernameTaken',
        operation: () async {
          var q = _supabase
              .from('profiles')
              .select('id')
              .eq('username', username.toLowerCase().trim());
          if (excludeUserId != null) {
            q = q.neq('id', excludeUserId);
          }
          final row = await q.maybeSingle();
          return row != null;
        },
      );

  /// Static and public (not the private instance method it used to be)
  /// purely so this can be unit-tested directly — it's a pure Map ->
  /// UserEntity mapper with no I/O, but ProfileRepository's other fields
  /// (`_supabase`, `_api`) require a real Supabase/ApiClient singleton to
  /// already be initialized just to construct an instance, which a plain
  /// unit test has no way to do. See the "has_password appears false for
  /// every account" regression this exists to guard: this mapper used to
  /// silently drop `has_password` entirely, defaulting every UserEntity
  /// it built to `hasPassword: false` — and since AuthProvider.
  /// updateCurrentUser() does a full replace (not a merge), that
  /// corrupted value overwrote whatever correct one an account already
  /// had the moment ANY profile mutation ran through this mapper
  /// (onboarding's own createOrUpdateProfile included).
  @visibleForTesting
  static UserEntity rowToEntity(Map<String, dynamic> row) {
    DateTime? _parseTs(dynamic v) =>
        v != null ? DateTime.tryParse(v as String) : null;

    return UserEntity(
      id: row['id'] as String,
      email: row['email'] as String? ?? '',
      username: row['username'] as String?,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      avatarConfig: row['avatar_config'] != null
          ? Map<String, dynamic>.from(row['avatar_config'] as Map)
          : null,
      bio: row['bio'] as String?,
      countryCode: row['country_code'] as String?,
      age: row['age'] as int?,
      gender: row['gender'] as String?,
      phoneNumber: row['phone_number'] as String?,
      preferredLanguage: row['preferred_lang'] as String? ?? 'en',
      verificationStatus: row['verification_status'] as String? ?? 'unverified',
      onlineStatus: row['online_status'] as String? ?? 'offline',
      inGameStatus: row['in_game_status'] as bool? ?? false,
      isBanned: row['is_banned'] as bool? ?? false,
      banReason: row['ban_reason'] as String?,
      bannedUntil: _parseTs(row['banned_until']),
      isPremium: row['is_premium'] as bool? ?? false,
      premiumTier: row['premium_tier'] as String?,
      premiumExpiresAt: _parseTs(row['premium_expires_at']),
      usernameChangedAt: _parseTs(row['username_changed_at']),
      lastSeenAt: _parseTs(row['last_seen_at']),
      createdAt: _parseTs(row['created_at']),
      updatedAt: _parseTs(row['updated_at']),
      themeBackgroundColor: row['theme_background_color'] as String?,
      presenceMode: row['presence_mode'] as String? ?? 'auto',
      creatorPrivilegesRemovedAt: _parseTs(
        row['creator_privileges_removed_at'],
      ),
      // Root cause of "Password & Security" showing every account as
      // passwordless: this field was missing here entirely, silently
      // defaulting to UserEntity's own `hasPassword = false`. Every call
      // through this mapper (onboarding's own createOrUpdateProfile
      // included) then overwrote AuthProvider.currentUser — via
      // updateCurrentUser's full replace, not a merge — with that
      // corrupted false, discarding whatever correct value the account
      // actually had from login/signup.
      hasPassword: row['has_password'] as bool? ?? false,
    );
  }

  /// Sets/clears the caller's premium background-color override. Server-
  /// side (set_theme_background_color RPC) re-verifies live premium status
  /// before allowing a non-null value — this is a real permission gate, not
  /// just a hidden button; a non-premium or expired caller gets
  /// 'premium_required' back as a PostgrestException.
  Future<UserEntity> setThemeBackgroundColor(String? hexColor) => guardedCall(
    operationName: 'setThemeBackgroundColor',
    operation: () async {
      // The RPC call itself is the real success/failure signal (a thrown
      // PostgrestException here means the write genuinely didn't happen —
      // e.g. premium_required, invalid_hex_color). By the time it returns
      // without throwing, `RETURNING * INTO v_row` has already committed
      // server-side — so a hiccup PARSING that response into a UserEntity
      // must never be reported back as a save failure (a false error the
      // user would see despite the color having actually saved). Falling
      // back to a fresh read of the just-written row keeps this correct
      // and up to date either way, without silently swallowing a genuine
      // parse-vs-server-shape drift (logged via AppLogger below).
      final result = await _supabase.rpc(
        'set_theme_background_color',
        params: {'p_hex_color': hexColor},
      );
      try {
        return rowToEntity(Map<String, dynamic>.from(result as Map));
      } catch (e, st) {
        AppLogger.error(
          'setThemeBackgroundColor: RPC succeeded but response parsing '
          'failed — falling back to a fresh profile read',
          error: e,
          stackTrace: st,
        );
        final userId = _supabase.auth.currentUser?.id;
        final fresh = userId != null ? await getProfile(userId) : null;
        if (fresh != null) return fresh;
        rethrow;
      }
    },
  );

  /// The counters shown on the user's own Profile screen (games/friends/
  /// packs/followers). All four are computed live by the `profiles_public`
  /// view (subqueries over follows/friendships/room_members/packs, not
  /// stored columns) — one cheap single-row read, reused for both the
  /// initial load and every subsequent refresh so there is exactly one
  /// query for "the stats section", not one per counter.
  Future<ProfileStats> getProfileStats(String userId) => guardedCall(
    operationName: 'getProfileStats',
    operation: () async {
      final results = await Future.wait<Object?>([
        _supabase
            .from('profiles_public')
            .select(
              'friends_count, games_played, packs_count, followers_count, following_count, general_score, honesty_points',
            )
            .eq('id', userId)
            .limit(1),
        _supabase
            .from('user_streaks')
            .select('current_streak, longest_streak, last_increment_date')
            .eq('user_id', userId)
            .maybeSingle(),
      ]);
      final profileRows = results[0] as List;
      final streakRow = results[1] as Map<String, dynamic>?;
      if (profileRows.isEmpty) return const ProfileStats();
      final r = profileRows.first as Map<String, dynamic>;
      return ProfileStats(
        friendsCount: (r['friends_count'] as num?)?.toInt() ?? 0,
        gamesPlayed: (r['games_played'] as num?)?.toInt() ?? 0,
        packsCount: (r['packs_count'] as num?)?.toInt() ?? 0,
        followersCount: (r['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (r['following_count'] as num?)?.toInt() ?? 0,
        generalScore: (r['general_score'] as num?)?.toInt() ?? 0,
        currentStreak: (streakRow?['current_streak'] as num?)?.toInt() ?? 0,
        longestStreak: (streakRow?['longest_streak'] as num?)?.toInt() ?? 0,
        lastStreakIncrementDate: streakRow?['last_increment_date'] != null
            ? DateTime.parse(streakRow!['last_increment_date'] as String)
            : null,
        honestyPoints: (r['honesty_points'] as num?)?.toInt() ?? 0,
      );
    },
  );

  /// Submits an account-deletion request for review — never deletes
  /// anything directly from the client. RLS ("account_deletion_requests:
  /// own insert") is the real gate, mirroring applyCreatorVerification
  /// below: it rejects this outright if the user already has a pending
  /// request, so "prevent duplicate pending requests" is enforced
  /// server-side, not just by disabling a button.
  Future<void> requestAccountDeletion({
    required String reasonCategory,
    String? reason,
  }) => guardedCall(
    operationName: 'requestAccountDeletion',
    operation: () async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const AuthFailure();
      await _supabase.from('account_deletion_requests').insert({
        'user_id': userId,
        'reason_category': reasonCategory,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    },
  );

  /// Null means no pending request exists yet — used to show the current
  /// request state (and keep the "Request account deletion" action
  /// disabled/labelled accordingly) without relying on client-side-only
  /// bookkeeping that could drift from the real server state.
  Future<DateTime?> getPendingAccountDeletionRequestedAt() => guardedCall(
    operationName: 'getPendingAccountDeletionRequestedAt',
    operation: () async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final rows = await _supabase
          .from('account_deletion_requests')
          .select('created_at')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      return DateTime.tryParse(rows.first['created_at'] as String);
    },
  );

  /// Item 12 (and its own follow-up fix) — cancels the CURRENT user's own
  /// still-pending account deletion request by flipping its status away
  /// from 'pending' (never a hard delete of the request row — the same
  /// "review, don't act directly" posture [requestAccountDeletion] already
  /// documents).
  ///
  /// ROOT CAUSE of "Cancel deletion doesn't work" (confirmed against the
  /// actual migration, not guessed): this used to attempt a direct client
  /// `.update({'status': 'cancelled'})` on account_deletion_requests, but
  /// that table's own RLS policy ("account_deletion_requests: no client
  /// update", USING (false) — see
  /// 20260805090200_account_deletion_requests.sql) unconditionally blocks
  /// EVERY client-side UPDATE, including the owner cancelling their own
  /// pending row — PostgREST returns zero rows for an RLS-filtered UPDATE
  /// rather than an error, so this method's own "only report success when
  /// a row actually came back" check could never see true. A second,
  /// independent bug: 'cancelled' wasn't even a legal value under the
  /// table's status CHECK constraint at the time.
  ///
  /// Fixed via a SECURITY DEFINER RPC (cancel_account_deletion_request,
  /// see 20260909090000_cancel_account_deletion_request_rpc.sql) that
  /// verifies ownership via auth.uid() internally and updates with the
  /// function owner's privileges — mirroring this codebase's own
  /// established "checked RPC instead of a raw RLS-gated table write"
  /// pattern (e.g. mute_player_in_game). The `.eq`-style
  /// `WHERE user_id = auth.uid() AND status = 'pending'` inside that RPC
  /// is deliberate, not just defensive: it's what makes this operation
  /// atomically refuse to "cancel" a request already processed past
  /// pending. Still returns a bool the caller MUST check — the RPC itself
  /// returns false (never throws) when there was nothing pending to
  /// cancel, so a stale "success" can never be reported here either.
  Future<bool> cancelAccountDeletionRequest() => guardedCall(
    operationName: 'cancelAccountDeletionRequest',
    operation: () async {
      if (_supabase.auth.currentUser?.id == null) return false;
      final result = await _supabase.rpc('cancel_account_deletion_request');
      return result as bool? ?? false;
    },
  );

  /// Requirement thresholds + this user's live progress toward becoming a
  /// verified creator, both computed server-side (get_creator_verification_
  /// progress RPC) from a DB-driven requirements row rather than hardcoded
  /// client constants — an admin can change the thresholds later without a
  /// client release.
  Future<CreatorVerificationProgress> getCreatorVerificationProgress(
    String userId,
  ) => guardedCall(
    operationName: 'getCreatorVerificationProgress',
    operation: () async {
      final result = await _supabase.rpc(
        'get_creator_verification_progress',
        params: {'p_user_id': userId},
      );
      return CreatorVerificationProgress.fromMap(
        Map<String, dynamic>.from(result as Map),
      );
    },
  );

  /// Sets the caller's online-status preference. Server-side
  /// (set_presence_mode RPC) re-verifies live premium status before
  /// allowing anything other than 'auto' — a real permission gate, not
  /// just a hidden control. Also applies the change immediately on the
  /// live presence channel via PresenceService, not just on next login.
  Future<void> setPresenceMode(String mode) => guardedCall(
    operationName: 'setPresenceMode',
    operation: () async {
      // The DB write is what actually determines success/failure — it's
      // fast and reliable, so this is what the caller awaits and what
      // surfaces a real error (e.g. premium_required).
      await _supabase.rpc('set_presence_mode', params: {'p_mode': mode});

      // Applying it live on the presence channel is best-effort: it's
      // already guarded against a not-yet-joined channel (see
      // PresenceService._isSubscribed), but a bounded timeout here is
      // cheap insurance against ever blocking the caller's loading state
      // on a slow/stalled realtime connection — the persisted DB value
      // is picked up correctly the next time PresenceService.start() runs
      // regardless.
      unawaited(
        PresenceService.instance
            .setManualMode(mode == 'auto' ? null : mode)
            .timeout(const Duration(seconds: 5), onTimeout: () {}),
      );
    },
  );

  /// Submits a creator-verification application. RLS ("creator_verifications:
  /// own insert") is the real gate — it already rejects this for a user who
  /// is already verified — this call doesn't re-check eligibility itself.
  Future<void> applyCreatorVerification({
    required String userId,
    required String realName,
    String? bio,
  }) => guardedCall(
    operationName: 'applyCreatorVerification',
    operation: () async {
      await _supabase.from('creator_verifications').insert({
        'user_id': userId,
        'real_name': realName,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
      });
    },
  );

  /// Submits an item-8 recovery complaint for a creator whose verified
  /// status/privileges were auto-removed after their Premium Plus lapsed.
  /// RLS ("creator_recovery_complaints: own insert") is the real
  /// eligibility gate (must currently be un-verified with a removal
  /// timestamp set) and the partial unique index on (user_id) WHERE
  /// status='pending' is what actually blocks a second concurrent
  /// complaint — this call doesn't re-check either itself, same division
  /// of responsibility as applyCreatorVerification above.
  Future<void> submitCreatorRecoveryComplaint({
    required String userId,
    required String reasonCategory,
    required String explanation,
    List<String> evidenceUrls = const [],
  }) => guardedCall(
    operationName: 'submitCreatorRecoveryComplaint',
    operation: () async {
      await _supabase.from('creator_recovery_complaints').insert({
        'user_id': userId,
        'reason_category': reasonCategory,
        'explanation': explanation,
        if (evidenceUrls.isNotEmpty) 'evidence_urls': evidenceUrls,
      });
    },
  );

  /// The caller's most recent recovery complaint (any status), or null if
  /// they've never submitted one — used to show its current state (and
  /// keep the submit action disabled/labelled accordingly) instead of
  /// relying on client-only bookkeeping that could drift from the server.
  Future<CreatorRecoveryComplaint?> getLatestCreatorRecoveryComplaint(
    String userId,
  ) => guardedCall(
    operationName: 'getLatestCreatorRecoveryComplaint',
    operation: () async {
      final rows = await _supabase
          .from('creator_recovery_complaints')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      return CreatorRecoveryComplaint.fromMap(rows.first);
    },
  );

  /// Minimal public display info for a room-invite deep link's "invited by"
  /// banner — just enough to show a name/avatar, not the full social-profile
  /// payload (follower counts etc.) FriendsRepository.getSocialProfile
  /// fetches for a real profile visit.
  Future<InviterInfo?> getInviterInfo(String userId) => guardedCall(
    operationName: 'getInviterInfo',
    operation: () async {
      final rows = await _supabase
          .from('profiles')
          .select('display_name, username, avatar_url')
          .eq('id', userId)
          .limit(1);
      if (rows.isEmpty) return null;
      final row = rows.first;
      return InviterInfo(
        displayName:
            row['display_name'] as String? ?? row['username'] as String?,
        avatarUrl: row['avatar_url'] as String?,
      );
    },
  );
}

class InviterInfo {
  const InviterInfo({this.displayName, this.avatarUrl});
  final String? displayName;
  final String? avatarUrl;
}

class CreatorRecoveryComplaint {
  const CreatorRecoveryComplaint({
    required this.id,
    required this.reasonCategory,
    required this.explanation,
    required this.evidenceUrls,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory CreatorRecoveryComplaint.fromMap(Map<String, dynamic> m) =>
      CreatorRecoveryComplaint(
        id: m['id'] as String,
        reasonCategory: m['reason_category'] as String,
        explanation: m['explanation'] as String,
        evidenceUrls:
            (m['evidence_urls'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        status: m['status'] as String,
        adminNotes: m['admin_notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  final String id;
  final String reasonCategory;
  final String explanation;
  final List<String> evidenceUrls;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? adminNotes;
  final DateTime createdAt;

  bool get isPending => status == 'pending';
}

class ProfileStats {
  const ProfileStats({
    this.friendsCount = 0,
    this.gamesPlayed = 0,
    this.packsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.generalScore = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakIncrementDate,
    this.honestyPoints = 0,
  });

  final int friendsCount;
  final int gamesPlayed;
  final int packsCount;
  final int followersCount;
  final int followingCount;

  /// Task item 4 — server-authoritative, awarded via score_events
  /// (game completions, pack votes, streak days). Read-only here; Flutter
  /// never computes or writes this.
  final int generalScore;

  /// Task item 5 — from user_streaks, same visibility as the rest of this
  /// public-facing stats bucket (profiles_public has no per-viewer
  /// restriction beyond banned/deleted). [currentStreak] survives an
  /// inactive period unchanged (it only ever changes on the next
  /// qualifying completion — see on_game_session_completed()); use
  /// [streakFlameOn] to know whether that number is currently "live".
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStreakIncrementDate;

  /// ON while [currentStreak] is still live (today or yesterday's UTC day
  /// had a qualifying completion — see isStreakFlameOn), OFF once a day
  /// has been missed. [currentStreak] itself is untouched either way.
  bool get streakFlameOn =>
      isStreakFlameOn(lastIncrementDate: lastStreakIncrementDate);

  /// Server-authoritative, awarded via honesty_events (Honest/Not-honest
  /// votes cast by other genuine game participants) — a fully separate
  /// ledger from [generalScore], can be negative. Read-only here.
  final int honestyPoints;

  /// Cheap live-update from a profiles-CDC payload (see ProfileProvider's
  /// own-profile moderation channel) — avoids a full getProfileStats()
  /// round trip just to reflect a score/honesty change the payload
  /// already carries inline.
  ProfileStats copyWith({
    int? generalScore,
    int? honestyPoints,
    int? followersCount,
  }) => ProfileStats(
    friendsCount: friendsCount,
    gamesPlayed: gamesPlayed,
    packsCount: packsCount,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount,
    generalScore: generalScore ?? this.generalScore,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastStreakIncrementDate: lastStreakIncrementDate,
    honestyPoints: honestyPoints ?? this.honestyPoints,
  );
}

class CreatorVerificationProgress {
  const CreatorVerificationProgress({
    required this.requiresPremiumPlus,
    required this.minGamesPlayed,
    required this.minPacksUsed,
    required this.minFollowers,
    required this.isPremiumPlus,
    required this.gamesPlayed,
    required this.packsUsed,
    required this.followersCount,
    required this.isEligible,
    required this.requiredStreakDays,
    required this.requiredDailyPackGames,
    required this.requirePlayedWithOthers,
    required this.loginStreakDays,
    required this.roomCreationStreakDays,
    required this.packGamesStreakDays,
    required this.hasPlayedWithOthers,
  });

  final bool requiresPremiumPlus;
  final int minGamesPlayed;
  final int minPacksUsed;
  final int minFollowers;

  final bool isPremiumPlus;
  final int gamesPlayed;
  final int packsUsed;
  final int followersCount;

  final bool isEligible;

  // Daily-activity requirements: a 10-day (configurable) streak of app
  // entry, room creation, and finishing enough pack games each of those
  // days, plus having played with other real users at least once — see
  // get_creator_verification_progress()/get_creator_activity_progress().
  final int requiredStreakDays;
  final int requiredDailyPackGames;
  final bool requirePlayedWithOthers;
  final int loginStreakDays;
  final int roomCreationStreakDays;
  final int packGamesStreakDays;
  final bool hasPlayedWithOthers;

  factory CreatorVerificationProgress.fromMap(Map<String, dynamic> m) {
    final req = Map<String, dynamic>.from(m['requirements'] as Map);
    final prog = Map<String, dynamic>.from(m['progress'] as Map);
    return CreatorVerificationProgress(
      requiresPremiumPlus: req['requires_premium_plus'] as bool? ?? true,
      minGamesPlayed: (req['min_games_played'] as num?)?.toInt() ?? 0,
      minPacksUsed: (req['min_packs_used'] as num?)?.toInt() ?? 0,
      minFollowers: (req['min_followers'] as num?)?.toInt() ?? 0,
      isPremiumPlus: prog['is_premium_plus'] as bool? ?? false,
      gamesPlayed: (prog['games_played'] as num?)?.toInt() ?? 0,
      packsUsed: (prog['packs_used'] as num?)?.toInt() ?? 0,
      followersCount: (prog['followers_count'] as num?)?.toInt() ?? 0,
      isEligible: m['is_eligible'] as bool? ?? false,
      requiredStreakDays: (req['required_streak_days'] as num?)?.toInt() ?? 10,
      requiredDailyPackGames:
          (req['required_daily_pack_games'] as num?)?.toInt() ?? 2,
      requirePlayedWithOthers:
          req['require_played_with_others'] as bool? ?? true,
      loginStreakDays: (prog['login_streak_days'] as num?)?.toInt() ?? 0,
      roomCreationStreakDays:
          (prog['room_creation_streak_days'] as num?)?.toInt() ?? 0,
      packGamesStreakDays:
          (prog['pack_games_streak_days'] as num?)?.toInt() ?? 0,
      hasPlayedWithOthers: prog['has_played_with_others'] as bool? ?? false,
    );
  }
}
