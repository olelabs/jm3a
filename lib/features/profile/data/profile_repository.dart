import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/domain/entities/user_entity.dart';

/// Repository for all profile read/write operations.
///
/// Read operations  → Supabase direct (RLS-protected, anon key safe)
/// Write operations → Node.js API (service-role, owns business logic)
///   Includes: create, update, avatar upload, username change
class ProfileRepository extends BaseRepository {
  ProfileRepository._();
  static final ProfileRepository _instance = ProfileRepository._();
  static ProfileRepository get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _api = ApiClient.instance;

  // ── Create / initial setup ────────────────────────────────────────────────
  /// Called by OnboardingScreen after first login.
  /// Routes through Node.js to enforce business rules (username uniqueness, etc.)
  Future<UserEntity> createOrUpdateProfile({
    required String userId,
    required String username,
    required String displayName,
    int? age,
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
          if (age != null) 'age': age,
          if (countryCode != null) 'country_code': countryCode,
          'preferred_lang': preferredLanguage,
        },
      );
      final profile =
          (resp.data!['data'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      return _rowToEntity(profile);
    },
  );

  // ── Update profile fields ─────────────────────────────────────────────────
  /// Partial update — only provided fields are changed.
  Future<UserEntity> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? countryCode,
    int? age,
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
      return _rowToEntity(profile);
    },
  );

  // ── Username change ───────────────────────────────────────────────────────
  /// Enforces 30-day cooldown and uniqueness via Node.js.
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
      return _rowToEntity(profile);
    },
  );

  // ── Avatar upload ─────────────────────────────────────────────────────────
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

      // Upload directly to Wasabi using presigned URL
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

      // Update avatar_url in profile via Node.js (keeps audit trail)
      final resp = await _api.patch<Map<String, dynamic>>(
        '/v1/auth/profile',
        data: {'avatar_url': publicUrl},
      );
      final profile =
          (resp.data!['data'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>;
      return _rowToEntity(profile);
    },
  );

  // ── Read operations ───────────────────────────────────────────────────────
  Future<UserEntity?> getProfile(String userId) => softCall(
    operationName: 'getProfile',
    operation: () async {
      final row = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      // if (row == null) return null;
      if (row == null)
        throw const NotFoundFailure(message: 'Profile not found.');
      return _rowToEntity(row);
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
      // if (row == null) return null;
      if (row == null)
        throw const NotFoundFailure(message: 'Profile not found.');
      return _rowToEntity(row);
    },
  );

  /// Quick DB-level username check (used by OnboardingScreen fallback).
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

  // ── Mapper ────────────────────────────────────────────────────────────────
  UserEntity _rowToEntity(Map<String, dynamic> row) {
    DateTime? _parseTs(dynamic v) =>
        v != null ? DateTime.tryParse(v as String) : null;

    return UserEntity(
      id: row['id'] as String,
      email: row['email'] as String? ?? '',
      username: row['username'] as String?,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String?,
      countryCode: row['country_code'] as String?,
      age: row['age'] as int?,
      phoneNumber: row['phone_number'] as String?,
      preferredLanguage: row['preferred_lang'] as String? ?? 'en',
      verificationStatus: row['verification_status'] as String? ?? 'unverified',
      onlineStatus: row['online_status'] as String? ?? 'offline',
      inGameStatus: row['in_game_status'] as bool? ?? false,
      isBanned: row['is_banned'] as bool? ?? false,
      usernameChangedAt: _parseTs(row['username_changed_at']),
      lastSeenAt: _parseTs(row['last_seen_at']),
      createdAt: _parseTs(row['created_at']),
      updatedAt: _parseTs(row['updated_at']),
    );
  }
}
