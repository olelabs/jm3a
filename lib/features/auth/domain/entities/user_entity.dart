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
    this.usernameChangedAt,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
    this.isPremium = false,
    this.premiumTier,
    this.premiumExpiresAt,
    this.themeBackgroundColor,
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

  bool get isVerifiedCreator => verificationStatus == 'verified';
  bool get hasCompletedProfile => username != null && displayName != null;
  bool get isOnline => onlineStatus == 'online';

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

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
    DateTime? usernameChangedAt,
    DateTime? lastSeenAt,
    DateTime? updatedAt,
    bool? isPremium,
    String? premiumTier,
    DateTime? premiumExpiresAt,
    String? themeBackgroundColor,
  }) {
    return UserEntity(
      id: id,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarConfig: avatarConfig ?? this.avatarConfig,
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
      usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPremium: isPremium ?? this.isPremium,
      premiumTier: premiumTier ?? this.premiumTier,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      themeBackgroundColor: themeBackgroundColor ?? this.themeBackgroundColor,
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
    usernameChangedAt,
    isPremium,
    premiumTier,
    premiumExpiresAt,
    themeBackgroundColor,
  ];
}
