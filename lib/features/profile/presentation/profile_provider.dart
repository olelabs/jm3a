import 'dart:io';
import 'dart:async';

import '../../../core/errors/failures.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/base_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../data/profile_repository.dart';

/// Manages profile-specific state: editing, avatar upload, username change.
///
/// Scoped to the authenticated user's own profile.
/// The global user identity lives in AuthProvider — ProfileProvider syncs
/// any changes back to AuthProvider via [_syncToAuth].
class ProfileProvider extends BaseProvider {
  ProfileProvider({
    required ProfileRepository profileRepository,
    required AuthProvider authProvider,
  })  : _repository = profileRepository,
        _authProvider = authProvider;

  final ProfileRepository _repository;
  final AuthProvider _authProvider;

  // ── Edit form state ───────────────────────────────────────────────────────
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // ── Avatar upload ─────────────────────────────────────────────────────────
  bool _isUploadingAvatar = false;
  bool get isUploadingAvatar => _isUploadingAvatar;

  // ── Username change ───────────────────────────────────────────────────────
  bool _isChangingUsername = false;
  bool get isChangingUsername => _isChangingUsername;

  // For returning results to UI after operations
  Failure? _lastFailure;
  Failure? get lastFailure => _lastFailure;

  @override
  void onUserLoggedIn(String userId) {
    _lastFailure = null;
  }

  @override
  void onUserLoggedOut() {
    _isSaving = false;
    _isUploadingAvatar = false;
    _isChangingUsername = false;
    _lastFailure = null;
    super.onUserLoggedOut();
  }

  // ── Update profile ────────────────────────────────────────────────────────
  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? countryCode,
    int? age,
    String? phoneNumber,
    String? preferredLanguage,
  }) async {
    _isSaving = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) throw const AuthFailure();

      final updated = await _repository.updateProfile(
        userId: userId,
        displayName: displayName,
        bio: bio,
        countryCode: countryCode,
        age: age,
        phoneNumber: phoneNumber,
        preferredLanguage: preferredLanguage,
      );

      _syncToAuth(updated);
      return true;
    } on Failure catch (f) {
      _lastFailure = f;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ── Avatar upload ─────────────────────────────────────────────────────────
  Future<bool> uploadAvatar(File imageFile) async {
    _isUploadingAvatar = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) throw const AuthFailure();

      final updated = await _repository.uploadAvatar(
        userId: userId,
        imageFile: imageFile,
      );

      _syncToAuth(updated);
      return true;
    } on Failure catch (f) {
      _lastFailure = f;
      return false;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  // ── Username change ────────────────────────────────────────────────────────
  Future<({bool success, String? errorMessage, int? daysRemaining})>
      changeUsername(String newUsername) async {
    _isChangingUsername = true;
    _lastFailure = null;
    notifyListeners();

    try {
      final updated = await _repository.changeUsername(newUsername);
      _syncToAuth(updated);
      return (success: true, errorMessage: null, daysRemaining: null);
    } on Failure catch (f) {
      _lastFailure = f;
      final days = f.code == 'username_cooldown'
          ? _parseDaysRemaining(f.message)
          : null;
      return (success: false, errorMessage: f.message, daysRemaining: days);
    } finally {
      _isChangingUsername = false;
      notifyListeners();
    }
  }

  // ── Refresh profile from DB ────────────────────────────────────────────────
  Future<void> refreshProfile() async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return;

    final profile = await _repository.getProfile(userId);
    if (profile != null) _syncToAuth(profile);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _syncToAuth(UserEntity updated) {
    _authProvider.updateCurrentUser(updated);
    AppLogger.debug('ProfileProvider: synced to AuthProvider');
  }

  int? _parseDaysRemaining(String message) {
    final match = RegExp(r'(\d+) day').firstMatch(message);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  void clearLastFailure() {
    _lastFailure = null;
    notifyListeners();
  }
}
