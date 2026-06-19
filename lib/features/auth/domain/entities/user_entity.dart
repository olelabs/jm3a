import 'package:equatable/equatable.dart';

/// Complete domain entity for a Jma3a user profile.
/// Maps 1:1 with the `profiles` Supabase table.
/// Never expose raw Supabase row maps outside the data layer.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.countryCode,
    this.age,
    this.phoneNumber,
    this.preferredLanguage = 'en',
    this.verificationStatus = 'unverified',
    this.onlineStatus = 'offline',
    this.inGameStatus = false,
    this.isBanned = false,
    this.usernameChangedAt,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? countryCode;
  final int? age;
  final String? phoneNumber;
  final String preferredLanguage;
  final String verificationStatus;
  final String onlineStatus;
  final bool inGameStatus;
  final bool isBanned;
  final DateTime? usernameChangedAt;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Computed getters ──────────────────────────────────────────────────────
  bool get isVerifiedCreator => verificationStatus == 'verified';
  bool get hasCompletedProfile => username != null && displayName != null;
  bool get isOnline => onlineStatus == 'online';

  /// Days until username can be changed again (0 = can change now).
  int get usernameChangeCooldownDaysLeft {
    if (usernameChangedAt == null) return 0;
    const cooldownDays = 30;
    final nextAllowed = usernameChangedAt!.add(const Duration(days: cooldownDays));
    final diff = nextAllowed.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays + 1;
  }

  bool get canChangeUsername => usernameChangeCooldownDaysLeft == 0;

  // ── copyWith ──────────────────────────────────────────────────────────────
  UserEntity copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? countryCode,
    int? age,
    String? phoneNumber,
    String? preferredLanguage,
    String? verificationStatus,
    String? onlineStatus,
    bool? inGameStatus,
    bool? isBanned,
    DateTime? usernameChangedAt,
    DateTime? lastSeenAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      countryCode: countryCode ?? this.countryCode,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      inGameStatus: inGameStatus ?? this.inGameStatus,
      isBanned: isBanned ?? this.isBanned,
      usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, email, username, displayName, avatarUrl, bio,
    countryCode, age, phoneNumber, preferredLanguage,
    verificationStatus, onlineStatus, inGameStatus, isBanned,
    usernameChangedAt,
  ];
}
