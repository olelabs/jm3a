import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities/user_entity.dart';

class AuthRepository extends BaseRepository {
  AuthRepository._();
  static final AuthRepository _instance = AuthRepository._();
  static AuthRepository get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _api = ApiClient.instance;
  final _secure = SecureStorageService.instance;
  final _local = LocalStorageService.instance;

  Stream<AuthStateChangeEvent> get authStateStream => _supabase
      .auth
      .onAuthStateChange
      .map((e) => AuthStateChangeEvent(session: e.session, event: e.event));

  Future<(Session?, UserEntity?)> restoreSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return (null, null);

    if (session.isExpired) {
      try {
        final refreshed = await _supabase.auth.refreshSession();
        if (refreshed.session == null) return (null, null);
        final user = await _fetchCurrentProfile(refreshed.session!.user.id);
        if (user != null) await _rejectIfSuspended(user);
        AppLogger.info('AuthRepository: session restored via refresh');
        return (refreshed.session, user);
      } on SuspendedFailure {
        rethrow;
      } catch (e) {
        AppLogger.warning('AuthRepository: token refresh failed, $e');
        return (null, null);
      }
    }

    final user = await _fetchCurrentProfile(session.user.id);
    if (user != null) await _rejectIfSuspended(user);
    AppLogger.info('AuthRepository: session restored');
    return (session, user);
  }

  /// Startup/session-restore and login share this same check — a banned
  /// or still-suspended account never gets past either path. Kills the
  /// Supabase session immediately (not just returning an error) so a
  /// stale valid token can't be reused, then throws SuspendedFailure,
  /// which is already a Failure so it passes through guardedCall's
  /// ErrorHandler.handle unchanged (see error_handler.dart's `final
  /// Failure f => f` case).
  Future<void> _rejectIfSuspended(UserEntity user) async {
    if (!user.isBanned) return;
    await _supabase.auth.signOut();
    await _secure.deleteAll();
    throw SuspendedFailure(
      isPermanent: user.bannedUntil == null,
      bannedUntil: user.bannedUntil,
      banReason: user.banReason,
    );
  }

  Future<void> savePendingOtpEmail(String email) =>
      _secure.write(SecureKeys.pendingOtpEmail, email);

  Future<String?> getPendingOtpEmail() =>
      _secure.read(SecureKeys.pendingOtpEmail);

  Future<void> clearPendingOtpEmail() =>
      _secure.delete(SecureKeys.pendingOtpEmail);

  Future<void> sendOtp(String email) => guardedCall(
    operationName: 'sendOtp',
    operation: () async {
      await _api.post('/v1/auth/send-otp', data: {'email': email});
      await savePendingOtpEmail(email);
      AppLogger.info('OTP sent to $email');
    },
  );

  Future<String> sendPhoneOtp(String phone) => guardedCall(
    operationName: 'sendPhoneOtp',
    operation: () async {
      final response = await _api.post<Map<String, dynamic>>(
        '/v1/auth/send-phone-otp',
        data: {'phone_number': phone},
      );
      final syntheticEmail = response.data!['data']['syntheticEmail'] as String;
      await savePendingOtpEmail(syntheticEmail);
      AppLogger.info('Phone OTP sent to $phone');
      return syntheticEmail;
    },
  );

  Future<(Session, UserEntity)> verifyOtp(String email, String otp) =>
      guardedCall(
        operationName: 'verifyOtp',
        operation: () async {
          final response = await _api.post<Map<String, dynamic>>(
            '/v1/auth/verify-otp',
            data: {'email': email, 'otp': otp},
          );

          final data = response.data!['data'] as Map<String, dynamic>;
          final accessToken = data['access_token'] as String? ?? '';
          final refreshToken = data['refresh_token'] as String? ?? '';
          final isNewUser = data['is_new_user'] as bool? ?? false;

          if (accessToken.isEmpty || refreshToken.isEmpty) {
            throw const AuthFailure(
              message: 'No session token received from server.',
            );
          }

          final authResponse = await _supabase.auth.setSession(
            refreshToken,
            accessToken: accessToken,
          );

          final session = authResponse.session;
          if (session == null) {
            throw const AuthFailure(message: 'Failed to establish session.');
          }

          await clearPendingOtpEmail();

          UserEntity user;
          if (isNewUser) {
            user = _minimalUserEntity(session.user, email);
          } else {
            user =
                await _fetchCurrentProfile(session.user.id) ??
                _minimalUserEntity(session.user, email);
          }

          // The server's has_password verdict is fresher than whatever
          // the profile row (or the minimal fallback entity) carried —
          // it's computed at the exact moment of this OTP verification,
          // so it always wins.
          final hasPassword = data['has_password'] as bool? ?? user.hasPassword;
          user = user.copyWith(hasPassword: hasPassword);

          // A brand-new user can never already be banned, but an
          // existing one logging in again must be checked every time —
          // this is the "login protection" requirement, not just
          // session-restore.
          await _rejectIfSuspended(user);

          AppLogger.info('OTP verified, session created. isNewUser=$isNewUser');
          return (session, user);
        },
      );

  /// First-time password setup, and password reset after recovery-OTP
  /// verification, share this single endpoint — the backend treats both
  /// as "the caller already holds a valid session, set/replace the
  /// password on that account." Requires an authenticated session (the
  /// access token from either verifyOtp or a prior loginWithPassword).
  ///
  /// Root cause of the signup "Invalid or expired token" bug: Supabase
  /// revokes the caller's OWN current session as a side effect of any
  /// password change (admin API included), so the access token this
  /// very request authenticated with is already dead by the time it
  /// returns. The backend mints a fresh session for the same account
  /// (authService.setPassword, same mechanism verifyOtp uses) and hands
  /// it back here — adopted via setSession exactly like verifyOtp/
  /// loginWithPassword already do, so ApiClient's interceptor (which
  /// always reads Supabase.instance.client.auth.currentSession live)
  /// picks up the new token before the next request — e.g. onboarding's
  /// very next call, POST /setup-profile — is ever made.
  ///
  /// Returns the resynchronized [Session] (rather than void) so the
  /// caller (AuthProvider) can assign it to its own session field
  /// directly and deterministically — not just rely on the
  /// authStateStream eventually delivering the same update.
  Future<Session> setPassword(String password, String confirmation) =>
      guardedCall(
        operationName: 'setPassword',
        operation: () async {
          final response = await _api.post<Map<String, dynamic>>(
            '/v1/auth/set-password',
            data: {'password': password, 'password_confirmation': confirmation},
          );

          final data = response.data!['data'] as Map<String, dynamic>;
          final accessToken = data['access_token'] as String? ?? '';
          final refreshToken = data['refresh_token'] as String? ?? '';

          if (accessToken.isEmpty || refreshToken.isEmpty) {
            throw const AuthFailure(
              message: 'No session token received from server.',
            );
          }

          final authResponse = await _supabase.auth.setSession(
            refreshToken,
            accessToken: accessToken,
          );
          final session = authResponse.session;
          if (session == null) {
            throw const AuthFailure(message: 'Failed to refresh session.');
          }

          AppLogger.info('Password set, session resynchronized');
          return session;
        },
      );

  /// Settings' Update Password flow, step 2 — requires the CURRENT
  /// password (verified server-side, see authService.changePassword);
  /// never accepted on session validity alone. Distinct from
  /// [setPassword] above, which is for an account that has no real
  /// password yet. Never sends an OTP — Update Password and Forgot
  /// Password are deliberately separate flows.
  ///
  /// Same session-resync requirement as [setPassword]: changing the
  /// password revokes the session this call itself authenticated with,
  /// so the fresh session the backend now returns must be adopted here
  /// via setSession — otherwise the very next authenticated request
  /// (e.g. navigating anywhere else in Settings) would 401.
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmation,
  ) => guardedCall(
    operationName: 'changePassword',
    operation: () async {
      final response = await _api.post<Map<String, dynamic>>(
        '/v1/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmation,
        },
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final accessToken = data['access_token'] as String? ?? '';
      final refreshToken = data['refresh_token'] as String? ?? '';

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        throw const AuthFailure(
          message: 'No session token received from server.',
        );
      }

      final authResponse = await _supabase.auth.setSession(
        refreshToken,
        accessToken: accessToken,
      );
      if (authResponse.session == null) {
        throw const AuthFailure(message: 'Failed to refresh session.');
      }

      AppLogger.info('Password changed, session resynchronized');
    },
  );

  /// Update Password flow, step 1 — proves the CURRENT password is
  /// correct with no side effects (never writes anything). Only once
  /// this succeeds does the caller reveal the new-password fields and
  /// call [changePassword] — no OTP anywhere in this flow.
  Future<void> verifyCurrentPassword(String currentPassword) => guardedCall(
    operationName: 'verifyCurrentPassword',
    operation: () async {
      await _api.post(
        '/v1/auth/verify-password',
        data: {'password': currentPassword},
      );
    },
  );

  /// Signup existence check — deliberately reveals whether an account
  /// already exists for this identifier (unlike login, which never
  /// does), so the signup screen can redirect straight to login instead
  /// of letting someone attempt to create a second account.
  Future<bool> checkIdentifierExists(String identifier) => guardedCall(
    operationName: 'checkIdentifierExists',
    operation: () async {
      final response = await _api.post<Map<String, dynamic>>(
        '/v1/auth/check-identifier',
        data: {'identifier': identifier},
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return data['exists'] as bool? ?? false;
    },
  );

  /// Email/phone + password login for accounts that have already
  /// completed password setup. Mirrors verifyOtp's session-establishment
  /// shape exactly (setSession + suspension check) since the backend
  /// hands back the same access/refresh token pair either way.
  Future<(Session, UserEntity)> loginWithPassword(
    String identifier,
    String password,
  ) => guardedCall(
    operationName: 'loginWithPassword',
    operation: () async {
      final response = await _api.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: {'identifier': identifier, 'password': password},
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final accessToken = data['access_token'] as String? ?? '';
      final refreshToken = data['refresh_token'] as String? ?? '';

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        throw const AuthFailure(
          message: 'No session token received from server.',
        );
      }

      final authResponse = await _supabase.auth.setSession(
        refreshToken,
        accessToken: accessToken,
      );

      final session = authResponse.session;
      if (session == null) {
        throw const AuthFailure(message: 'Failed to establish session.');
      }

      var user =
          await _fetchCurrentProfile(session.user.id) ??
          _minimalUserEntity(session.user, identifier);

      final hasPassword = data['has_password'] as bool? ?? true;
      user = user.copyWith(hasPassword: hasPassword);

      await _rejectIfSuspended(user);

      AppLogger.info('Password login succeeded');
      return (session, user);
    },
  );

  Future<void> signOut() async {
    try {
      await _api.post('/v1/auth/sign-out', data: {});
    } catch (e) {
      AppLogger.warning('AuthRepository: sign-out API call failed, $e');
    }

    await _supabase.auth.signOut();
    await _secure.deleteAll();
    AppLogger.info('User signed out');
  }

  Future<UserEntity?> _fetchCurrentProfile(String userId) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row == null) return null;
      return _profileRowToEntity(row);
    } catch (e) {
      AppLogger.warning('AuthRepository: profile fetch failed, $e');
      return null;
    }
  }

  UserEntity _minimalUserEntity(User user, String email) {
    return UserEntity(id: user.id, email: user.email ?? email);
  }

  UserEntity _profileRowToEntity(Map<String, dynamic> row) {
    return UserEntity(
      id: row['id'] as String,
      email: row['email'] as String? ?? '',
      username: row['username'] as String?,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
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
      bannedUntil: row['banned_until'] != null
          ? DateTime.parse(row['banned_until'] as String)
          : null,
      usernameChangedAt: row['username_changed_at'] != null
          ? DateTime.parse(row['username_changed_at'] as String)
          : null,
      lastSeenAt: row['last_seen_at'] != null
          ? DateTime.parse(row['last_seen_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      isPremium: row['is_premium'] as bool? ?? false,
      premiumTier: row['premium_tier'] as String?,
      premiumExpiresAt: row['premium_expires_at'] != null
          ? DateTime.parse(row['premium_expires_at'] as String)
          : null,
      themeBackgroundColor: row['theme_background_color'] as String?,
      presenceMode: row['presence_mode'] as String? ?? 'auto',
      creatorPrivilegesRemovedAt: row['creator_privileges_removed_at'] != null
          ? DateTime.parse(row['creator_privileges_removed_at'] as String)
          : null,
      hasPassword: row['has_password'] as bool? ?? false,
      // Own-profile only — this mapper is never used for another user's
      // row (see UserEntity.playerId).
      playerId: row['player_id'] as String?,
    );
  }
}

class AuthStateChangeEvent {
  const AuthStateChangeEvent({required this.session, required this.event});
  final Session? session;
  final AuthChangeEvent event;
}
