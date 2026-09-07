// // // import 'package:equatable/equatable.dart';

// // // /// Complete domain entity for a Jma3a user profile.
// // // /// Maps 1:1 with the `profiles` Supabase table.
// // // /// Never expose raw Supabase row maps outside the data layer.
// // // class UserEntity extends Equatable {
// // //   const UserEntity({
// // //     required this.id,
// // //     required this.email,
// // //     this.username,
// // //     this.displayName,
// // //     this.avatarUrl,
// // //     this.bio,
// // //     this.countryCode,
// // //     this.age,
// // //     this.phoneNumber,
// // //     this.preferredLanguage = 'en',
// // //     this.verificationStatus = 'unverified',
// // //     this.onlineStatus = 'offline',
// // //     this.inGameStatus = false,
// // //     this.isBanned = false,
// // //     this.usernameChangedAt,
// // //     this.lastSeenAt,
// // //     this.createdAt,
// // //     this.updatedAt,
// // //   });

// // //   final String id;
// // //   final String email;
// // //   final String? username;
// // //   final String? displayName;
// // //   final String? avatarUrl;
// // //   final String? bio;
// // //   final String? countryCode;
// // //   final int? age;
// // //   final String? phoneNumber;
// // //   final String preferredLanguage;
// // //   final String verificationStatus;
// // //   final String onlineStatus;
// // //   final bool inGameStatus;
// // //   final bool isBanned;
// // //   final DateTime? usernameChangedAt;
// // //   final DateTime? lastSeenAt;
// // //   final DateTime? createdAt;
// // //   final DateTime? updatedAt;

// // //   // ── Computed getters ──────────────────────────────────────────────────────
// // //   bool get isVerifiedCreator => verificationStatus == 'verified';
// // //   bool get hasCompletedProfile => username != null && displayName != null;
// // //   bool get isOnline => onlineStatus == 'online';

// // //   /// Days until username can be changed again (0 = can change now).
// // //   int get usernameChangeCooldownDaysLeft {
// // //     if (usernameChangedAt == null) return 0;
// // //     const cooldownDays = 30;
// // //     final nextAllowed = usernameChangedAt!.add(const Duration(days: cooldownDays));
// // //     final diff = nextAllowed.difference(DateTime.now());
// // //     return diff.isNegative ? 0 : diff.inDays + 1;
// // //   }

// // //   bool get canChangeUsername => usernameChangeCooldownDaysLeft == 0;

// // //   // ── copyWith ──────────────────────────────────────────────────────────────
// // //   UserEntity copyWith({
// // //     String? username,
// // //     String? displayName,
// // //     String? avatarUrl,
// // //     String? bio,
// // //     String? countryCode,
// // //     int? age,
// // //     String? phoneNumber,
// // //     String? preferredLanguage,
// // //     String? verificationStatus,
// // //     String? onlineStatus,
// // //     bool? inGameStatus,
// // //     bool? isBanned,
// // //     DateTime? usernameChangedAt,
// // //     DateTime? lastSeenAt,
// // //     DateTime? updatedAt,
// // //   }) {
// // //     return UserEntity(
// // //       id: id,
// // //       email: email,
// // //       username: username ?? this.username,
// // //       displayName: displayName ?? this.displayName,
// // //       avatarUrl: avatarUrl ?? this.avatarUrl,
// // //       bio: bio ?? this.bio,
// // //       countryCode: countryCode ?? this.countryCode,
// // //       age: age ?? this.age,
// // //       phoneNumber: phoneNumber ?? this.phoneNumber,
// // //       preferredLanguage: preferredLanguage ?? this.preferredLanguage,
// // //       verificationStatus: verificationStatus ?? this.verificationStatus,
// // //       onlineStatus: onlineStatus ?? this.onlineStatus,
// // //       inGameStatus: inGameStatus ?? this.inGameStatus,
// // //       isBanned: isBanned ?? this.isBanned,
// // //       usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
// // //       lastSeenAt: lastSeenAt ?? this.lastSeenAt,
// // //       createdAt: createdAt,
// // //       updatedAt: updatedAt ?? this.updatedAt,
// // //     );
// // //   }

// // //   @override
// // //   List<Object?> get props => [
// // //     id, email, username, displayName, avatarUrl, bio,
// // //     countryCode, age, phoneNumber, preferredLanguage,
// // //     verificationStatus, onlineStatus, inGameStatus, isBanned,
// // //     usernameChangedAt,
// // //   ];
// // // }

// // import 'package:equatable/equatable.dart';

// // /// Complete domain entity for a Jma3a user profile.
// // /// Maps 1:1 with the `profiles` Supabase table.
// // /// Never expose raw Supabase row maps outside the data layer.
// // class UserEntity extends Equatable {
// //   const UserEntity({
// //     required this.id,
// //     required this.email,
// //     this.username,
// //     this.displayName,
// //     this.avatarUrl,
// //     this.bio,
// //     this.countryCode,
// //     this.age,
// //     this.phoneNumber,
// //     this.preferredLanguage = 'en',
// //     this.verificationStatus = 'unverified',
// //     this.onlineStatus = 'offline',
// //     this.inGameStatus = false,
// //     this.isBanned = false,
// //     this.isPremium = false,
// //     this.usernameChangedAt,
// //     this.lastSeenAt,
// //     this.createdAt,
// //     this.updatedAt,
// //   });

// //   final String id;
// //   final String email;
// //   final String? username;
// //   final String? displayName;
// //   final String? avatarUrl;
// //   final String? bio;
// //   final String? countryCode;
// //   final int? age;
// //   final String? phoneNumber;
// //   final String preferredLanguage;
// //   final String verificationStatus;
// //   final String onlineStatus;
// //   final bool inGameStatus;
// //   final bool isBanned;
// //   final bool isPremium;
// //   final DateTime? usernameChangedAt;
// //   final DateTime? lastSeenAt;
// //   final DateTime? createdAt;
// //   final DateTime? updatedAt;

// //   // ── Computed getters ──────────────────────────────────────────────────────
// //   bool get isVerifiedCreator => verificationStatus == 'verified';
// //   bool get hasCompletedProfile => username != null && displayName != null;
// //   bool get isOnline => onlineStatus == 'online';

// //   /// Days until username can be changed again (0 = can change now).
// //   int get usernameChangeCooldownDaysLeft {
// //     if (usernameChangedAt == null) return 0;
// //     const cooldownDays = 30;
// //     final nextAllowed = usernameChangedAt!.add(
// //       const Duration(days: cooldownDays),
// //     );
// //     final diff = nextAllowed.difference(DateTime.now());
// //     return diff.isNegative ? 0 : diff.inDays + 1;
// //   }

// //   bool get canChangeUsername => usernameChangeCooldownDaysLeft == 0;

// //   // ── copyWith ──────────────────────────────────────────────────────────────
// //   UserEntity copyWith({
// //     String? username,
// //     String? displayName,
// //     String? avatarUrl,
// //     String? bio,
// //     String? countryCode,
// //     int? age,
// //     String? phoneNumber,
// //     String? preferredLanguage,
// //     String? verificationStatus,
// //     String? onlineStatus,
// //     bool? inGameStatus,
// //     bool? isBanned,
// //     bool? isPremium,
// //     DateTime? usernameChangedAt,
// //     DateTime? lastSeenAt,
// //     DateTime? updatedAt,
// //   }) {
// //     return UserEntity(
// //       id: id,
// //       email: email,
// //       username: username ?? this.username,
// //       displayName: displayName ?? this.displayName,
// //       avatarUrl: avatarUrl ?? this.avatarUrl,
// //       bio: bio ?? this.bio,
// //       countryCode: countryCode ?? this.countryCode,
// //       age: age ?? this.age,
// //       phoneNumber: phoneNumber ?? this.phoneNumber,
// //       preferredLanguage: preferredLanguage ?? this.preferredLanguage,
// //       verificationStatus: verificationStatus ?? this.verificationStatus,
// //       onlineStatus: onlineStatus ?? this.onlineStatus,
// //       inGameStatus: inGameStatus ?? this.inGameStatus,
// //       isBanned: isBanned ?? this.isBanned,
// //       isPremium: isPremium ?? this.isPremium,
// //       usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
// //       lastSeenAt: lastSeenAt ?? this.lastSeenAt,
// //       createdAt: createdAt,
// //       updatedAt: updatedAt ?? this.updatedAt,
// //     );
// //   }

// //   @override
// //   List<Object?> get props => [
// //     id,
// //     email,
// //     username,
// //     displayName,
// //     avatarUrl,
// //     bio,
// //     countryCode,
// //     age,
// //     phoneNumber,
// //     preferredLanguage,
// //     verificationStatus,
// //     onlineStatus,
// //     inGameStatus,
// //     isBanned,
// //     usernameChangedAt,
// //   ];
// // }

// import 'package:equatable/equatable.dart';

// class UserEntity extends Equatable {
//   const UserEntity({
//     required this.id,
//     required this.email,
//     this.username,
//     this.displayName,
//     this.avatarUrl,
//     this.bio,
//     this.countryCode,
//     this.age,
//     this.phoneNumber,
//     this.preferredLanguage = 'en',
//     this.verificationStatus = 'unverified',
//     this.onlineStatus = 'offline',
//     this.inGameStatus = false,
//     this.isBanned = false,
//     this.usernameChangedAt,
//     this.lastSeenAt,
//     this.createdAt,
//     this.updatedAt,
//     this.isPremium = false,
//     this.premiumTier,
//     this.premiumExpiresAt,
//   });

//   final String id;
//   final String email;
//   final String? username;
//   final String? displayName;
//   final String? avatarUrl;
//   final String? bio;
//   final String? countryCode;
//   final int? age;
//   final String? phoneNumber;
//   final String preferredLanguage;
//   final String verificationStatus;
//   final String onlineStatus;
//   final bool inGameStatus;
//   final bool isBanned;
//   final DateTime? usernameChangedAt;
//   final DateTime? lastSeenAt;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;

//   final bool isPremium;
//   final String? premiumTier;
//   final DateTime? premiumExpiresAt;

//   bool get isVerifiedCreator => verificationStatus == 'verified';
//   bool get hasCompletedProfile => username != null && displayName != null;
//   bool get isOnline => onlineStatus == 'online';

//   bool get isPremiumActive {
//     if (!isPremium) return false;
//     if (premiumExpiresAt == null) return true;
//     return premiumExpiresAt!.isAfter(DateTime.now());
//   }

//   int get usernameChangeCooldownDaysLeft {
//     if (usernameChangedAt == null) return 0;
//     const cooldownDays = 30;
//     final nextAllowed = usernameChangedAt!.add(
//       const Duration(days: cooldownDays),
//     );
//     final diff = nextAllowed.difference(DateTime.now());
//     return diff.isNegative ? 0 : diff.inDays + 1;
//   }

//   bool get canChangeUsername => usernameChangeCooldownDaysLeft == 0;

//   int get maxProofReplays => isPremiumActive ? 3 : 1;
//   int get proofHistoryDays => isPremiumActive ? 30 : 3;

//   UserEntity copyWith({
//     String? username,
//     String? displayName,
//     String? avatarUrl,
//     String? bio,
//     String? countryCode,
//     int? age,
//     String? phoneNumber,
//     String? preferredLanguage,
//     String? verificationStatus,
//     String? onlineStatus,
//     bool? inGameStatus,
//     bool? isBanned,
//     DateTime? usernameChangedAt,
//     DateTime? lastSeenAt,
//     DateTime? updatedAt,
//     bool? isPremium,
//     String? premiumTier,
//     DateTime? premiumExpiresAt,
//   }) {
//     return UserEntity(
//       id: id,
//       email: email,
//       username: username ?? this.username,
//       displayName: displayName ?? this.displayName,
//       avatarUrl: avatarUrl ?? this.avatarUrl,
//       bio: bio ?? this.bio,
//       countryCode: countryCode ?? this.countryCode,
//       age: age ?? this.age,
//       phoneNumber: phoneNumber ?? this.phoneNumber,
//       preferredLanguage: preferredLanguage ?? this.preferredLanguage,
//       verificationStatus: verificationStatus ?? this.verificationStatus,
//       onlineStatus: onlineStatus ?? this.onlineStatus,
//       inGameStatus: inGameStatus ?? this.inGameStatus,
//       isBanned: isBanned ?? this.isBanned,
//       usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
//       lastSeenAt: lastSeenAt ?? this.lastSeenAt,
//       createdAt: createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       isPremium: isPremium ?? this.isPremium,
//       premiumTier: premiumTier ?? this.premiumTier,
//       premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
//     );
//   }

//   @override
//   List<Object?> get props => [
//     id,
//     email,
//     username,
//     displayName,
//     avatarUrl,
//     bio,
//     countryCode,
//     age,
//     phoneNumber,
//     preferredLanguage,
//     verificationStatus,
//     onlineStatus,
//     inGameStatus,
//     isBanned,
//     usernameChangedAt,
//     isPremium,
//     premiumTier,
//     premiumExpiresAt,
//   ];
// }

import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.avatarConfig,
    this.bio,
    this.countryCode,
    this.age,
    this.gender,
    this.phoneNumber,
    this.preferredLanguage = 'en',
    this.verificationStatus = 'unverified',
    this.onlineStatus = 'offline',
    this.inGameStatus = false,
    this.isBanned = false,
    this.banReason,
    this.bannedUntil,
    this.usernameChangedAt,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
    this.isPremium = false,
    this.premiumTier,
    this.premiumExpiresAt,
    this.themeBackgroundColor,
    this.presenceMode = 'auto',
    this.creatorPrivilegesRemovedAt,
    this.hasPassword = false,
  });

  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final Map<String, dynamic>? avatarConfig;
  final String? bio;
  final String? countryCode;
  final int? age;

  /// 'male' or 'female' — required at registration (setup-profile),
  /// nullable here only because existing rows predate the field.
  final String? gender;
  final String? phoneNumber;
  final String preferredLanguage;
  final String verificationStatus;
  final String onlineStatus;
  final bool inGameStatus;
  final bool isBanned;

  /// Set together with isBanned by apply_moderation_to_profile() (see
  /// moderation_actions). Meaning depends on bannedUntil, not a separate
  /// flag: null = permanent ban; a future timestamp = temporary
  /// suspension that's auto-lifted by cleanup_expired_platform_bans().
  final String? banReason;
  final DateTime? bannedUntil;
  final DateTime? usernameChangedAt;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final bool isPremium;
  final String? premiumTier;
  final DateTime? premiumExpiresAt;

  /// Premium/Premium Plus: hex "#RRGGBB" solid background override applied
  /// on top of the selected theme, or null for the theme's default
  /// background. Written server-side only via set_theme_background_color()
  /// — see ProfileRepository.setThemeBackgroundColor.
  final String? themeBackgroundColor;

  /// Online-status preference: 'auto' (default, everyone), or a
  /// premium-only manual 'online'/'offline' override — see
  /// PresenceService.setManualMode / ProfileRepository.setPresenceMode.
  final String presenceMode;

  /// Set when this user's verified-creator status/privileges were
  /// automatically removed after their Premium Plus subscription lapsed
  /// (item 7). Cleared again on restoration — either by resubscribing
  /// during the 2-day grace period, or by an approved recovery complaint
  /// (item 8). A removed creator (verificationStatus == 'unverified' with
  /// this set) can submit exactly one such complaint.
  final DateTime? creatorPrivilegesRemovedAt;

  /// profiles.has_password, true once this user has established a real,
  /// user-chosen password (POST /v1/auth/set-password). Drives which
  /// error LoginScreen's password attempt surfaces (password_not_set
  /// points at Forgot password instead of a generic wrong-password
  /// error) and which step PasswordSettingsScreen opens with — but is
  /// deliberately NOT a global router gate: false here never by itself
  /// redirects an authenticated user anywhere. Set as part of signup, or
  /// via Forgot password/Settings' Update Password.
  final bool hasPassword;

  bool get isVerifiedCreator => verificationStatus == 'verified';

  bool get canSubmitCreatorRecoveryComplaint =>
      verificationStatus != 'verified' && creatorPrivilegesRemovedAt != null;
  bool get hasCompletedProfile => username != null && displayName != null;
  bool get isOnline => onlineStatus == 'online';

  /// Permanent ban/suspension — isBanned with no expiry.
  bool get isPermanentlyBanned => isBanned && bannedUntil == null;

  /// Temporary suspension still in effect (isBanned with a future expiry
  /// — cleanup_expired_platform_bans() clears isBanned once it's passed,
  /// so a non-null past bannedUntil shouldn't normally be observed, but
  /// checking isAfter(now) here is a harmless extra safety margin).
  bool get isTemporarilySuspended =>
      isBanned && bannedUntil != null && bannedUntil!.isAfter(DateTime.now());

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  /// An active Premium Plus subscription — the only tier allowed to unmask a
  /// hidden (anonymous) spectator's identity in a room they moderate.
  bool get isPremiumPlusActive =>
      isPremiumActive && premiumTier == 'premium_plus';

  int get usernameChangeCooldownDaysLeft {
    if (usernameChangedAt == null) return 0;
    const cooldownDays = 30;
    final nextAllowed = usernameChangedAt!.add(
      const Duration(days: cooldownDays),
    );
    final diff = nextAllowed.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays + 1;
  }

  bool get canChangeUsername => usernameChangeCooldownDaysLeft == 0;

  int get maxProofReplays => isPremiumActive ? 3 : 1;
  int get proofHistoryDays => isPremiumActive ? 30 : 3;

  /// Display-only — the authoritative cap is enforced server-side in the
  /// create_room RPC, which computes this same value from profiles.
  /// is_premium/premium_tier rather than trusting anything the client sends.
  int get roomPlayerCap {
    if (!isPremiumActive) return 3;
    return premiumTier == 'premium_plus' ? 12 : 8;
  }

  UserEntity copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    Map<String, dynamic>? avatarConfig,
    // copyWith's usual `field ?? this.field` can't ever set a nullable
    // field back to null (there'd be no way to distinguish "didn't pass
    // it" from "explicitly clearing it") — this is the one caller that
    // needs exactly that, when a premium avatar is deleted.
    bool clearAvatarConfig = false,
    String? bio,
    String? countryCode,
    int? age,
    String? gender,
    String? phoneNumber,
    String? preferredLanguage,
    String? verificationStatus,
    String? onlineStatus,
    bool? inGameStatus,
    bool? isBanned,
    String? banReason,
    DateTime? bannedUntil,
    DateTime? usernameChangedAt,
    DateTime? lastSeenAt,
    DateTime? updatedAt,
    bool? isPremium,
    String? premiumTier,
    DateTime? premiumExpiresAt,
    String? themeBackgroundColor,
    String? presenceMode,
    DateTime? creatorPrivilegesRemovedAt,
    bool clearCreatorPrivilegesRemovedAt = false,
    bool? hasPassword,
  }) {
    return UserEntity(
      id: id,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarConfig: clearAvatarConfig
          ? null
          : (avatarConfig ?? this.avatarConfig),
      bio: bio ?? this.bio,
      countryCode: countryCode ?? this.countryCode,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      inGameStatus: inGameStatus ?? this.inGameStatus,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      bannedUntil: bannedUntil ?? this.bannedUntil,
      usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPremium: isPremium ?? this.isPremium,
      premiumTier: premiumTier ?? this.premiumTier,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      themeBackgroundColor: themeBackgroundColor ?? this.themeBackgroundColor,
      presenceMode: presenceMode ?? this.presenceMode,
      creatorPrivilegesRemovedAt: clearCreatorPrivilegesRemovedAt
          ? null
          : (creatorPrivilegesRemovedAt ?? this.creatorPrivilegesRemovedAt),
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    displayName,
    avatarUrl,
    avatarConfig,
    bio,
    countryCode,
    age,
    gender,
    phoneNumber,
    preferredLanguage,
    verificationStatus,
    onlineStatus,
    inGameStatus,
    isBanned,
    banReason,
    bannedUntil,
    usernameChangedAt,
    isPremium,
    premiumTier,
    premiumExpiresAt,
    themeBackgroundColor,
    creatorPrivilegesRemovedAt,
    hasPassword,
  ];
}
