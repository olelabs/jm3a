// // // import 'package:equatable/equatable.dart';

// // // /// Complete domain model for marketplace entities.
// // // /// All monetary values in MRU (Mauritanian Ouguiya, integer units).

// // // // ── Pack ──────────────────────────────────────────────────────────────────────

// // // enum PackStatus {
// // //   draft, pendingReview, approved, rejected, suspended, archived;

// // //   static PackStatus fromString(String s) => switch (s) {
// // //     'draft'          => draft,
// // //     'pending_review' => pendingReview,
// // //     'rejected'       => rejected,
// // //     'suspended'      => suspended,
// // //     'archived'       => archived,
// // //     _                => approved,
// // //   };

// // //   bool get isPublished => this == approved;
// // //   bool get isEditable  => this == draft || this == rejected;
// // // }

// // // class PackEntity extends Equatable {
// // //   const PackEntity({
// // //     required this.id,
// // //     required this.creatorId,
// // //     required this.titleJson,
// // //     this.descriptionJson,
// // //     this.coverImageUrl,
// // //     required this.status,
// // //     required this.gameType,
// // //     required this.language,
// // //     this.isMultilang = false,
// // //     required this.priceMru,
// // //     required this.cardCount,
// // //     required this.avgRating,
// // //     required this.totalRatings,
// // //     required this.totalPurchases,
// // //     required this.totalPlays,
// // //     this.downloadUrl,
// // //     this.version = 1,
// // //     this.hasSpicy = false,
// // //     this.isFeatured = false,
// // //     this.isPromoted = false,
// // //     this.categoryId,
// // //     this.tags = const [],
// // //     this.reactionImageUrls = const [],
// // //     this.publishedAt,
// // //     this.createdAt,
// // //     this.updatedAt,
// // //     // Populated via join when fetched with creator profile
// // //     this.creatorName,
// // //     this.creatorAvatarUrl,
// // //     this.isVerifiedCreator = false,
// // //   });

// // //   final String id;
// // //   final String creatorId;
// // //   final Map<String, dynamic> titleJson;
// // //   final Map<String, dynamic>? descriptionJson;
// // //   final String? coverImageUrl;
// // //   final PackStatus status;
// // //   final String gameType;
// // //   final String language;
// // //   final bool isMultilang;
// // //   final int priceMru;
// // //   final int cardCount;
// // //   final double avgRating;
// // //   final int totalRatings;
// // //   final int totalPurchases;
// // //   final int totalPlays;
// // //   final String? downloadUrl;
// // //   final int version;
// // //   final bool hasSpicy;
// // //   final bool isFeatured;
// // //   final bool isPromoted;
// // //   final String? categoryId;
// // //   final List<String> tags;
// // //   final List<String> reactionImageUrls;  // custom meme pack reaction images
// // //   final DateTime? publishedAt;
// // //   final DateTime? createdAt;
// // //   final DateTime? updatedAt;

// // //   // Joined creator fields
// // //   final String? creatorName;
// // //   final String? creatorAvatarUrl;
// // //   final bool isVerifiedCreator;

// // //   bool get isFree => priceMru == 0;
// // //   bool get isPublished => status.isPublished;

// // //   /// Title in the given language, falling back to English.
// // //   String titleFor(String lang) =>
// // //       titleJson[lang] as String? ?? titleJson['en'] as String? ?? '';

// // //   String descriptionFor(String lang) {
// // //     final d = descriptionJson;
// // //     if (d == null) return '';
// // //     return d[lang] as String? ?? d['en'] as String? ?? '';
// // //   }

// // //   PackEntity copyWith({
// // //     PackStatus? status,
// // //     String? coverImageUrl,
// // //     double? avgRating,
// // //     int? totalRatings,
// // //     int? totalPurchases,
// // //     bool? isFeatured,
// // //     bool? isPromoted,
// // //     String? creatorName,
// // //     String? creatorAvatarUrl,
// // //     bool? isVerifiedCreator,
// // //     List<String>? tags,
// // //   }) =>
// // //       PackEntity(
// // //         id: id, creatorId: creatorId, titleJson: titleJson,
// // //         descriptionJson: descriptionJson,
// // //         coverImageUrl:   coverImageUrl ?? this.coverImageUrl,
// // //         status:          status        ?? this.status,
// // //         gameType: gameType, language: language, isMultilang: isMultilang,
// // //         priceMru: priceMru,
// // //         cardCount: cardCount,
// // //         avgRating:      avgRating      ?? this.avgRating,
// // //         totalRatings:   totalRatings   ?? this.totalRatings,
// // //         totalPurchases: totalPurchases ?? this.totalPurchases,
// // //         totalPlays: totalPlays,
// // //         downloadUrl: downloadUrl, version: version,
// // //         hasSpicy: hasSpicy, isFeatured: isFeatured ?? this.isFeatured,
// // //         isPromoted: isPromoted ?? this.isPromoted,
// // //         categoryId: categoryId,
// // //         tags: tags ?? this.tags,
// // //         publishedAt: publishedAt, createdAt: createdAt, updatedAt: updatedAt,
// // //         creatorName:       creatorName       ?? this.creatorName,
// // //         creatorAvatarUrl:  creatorAvatarUrl  ?? this.creatorAvatarUrl,
// // //         isVerifiedCreator: isVerifiedCreator ?? this.isVerifiedCreator,
// // //       );

// // //   @override
// // //   List<Object?> get props => [id, status, avgRating, version, cardCount];
// // // }

// // // // ── Card ──────────────────────────────────────────────────────────────────────

// // // enum CardType { truth, dare, statement, prompt }
// // // enum CardDifficulty { mild, medium, spicy }

// // // class PackCardEntity extends Equatable {
// // //   const PackCardEntity({
// // //     required this.id,
// // //     required this.packId,
// // //     required this.contentJson,
// // //     required this.type,
// // //     required this.difficulty,
// // //     this.imageUrl,
// // //     this.sortOrder = 0,
// // //     this.isActive = true,
// // //   });

// // //   final String id;
// // //   final String packId;
// // //   final Map<String, dynamic> contentJson; // {"en":"...", "ar":"...", "fr":"..."}
// // //   final CardType type;
// // //   final CardDifficulty difficulty;
// // //   final String? imageUrl;
// // //   final int sortOrder;
// // //   final bool isActive;

// // //   String contentFor(String lang) =>
// // //       contentJson[lang] as String? ?? contentJson['en'] as String? ?? '';

// // //   bool get isSpicy => difficulty == CardDifficulty.spicy;

// // //   @override
// // //   List<Object?> get props => [id, packId, type, difficulty];
// // // }

// // // // ── Category ──────────────────────────────────────────────────────────────────

// // // class PackCategory extends Equatable {
// // //   const PackCategory({
// // //     required this.id,
// // //     required this.nameJson,
// // //     required this.slug,
// // //     this.icon = '📦',
// // //     this.sortOrder = 0,
// // //   });

// // //   final String id;
// // //   final Map<String, dynamic> nameJson;
// // //   final String slug;
// // //   final String icon;
// // //   final int sortOrder;

// // //   String nameFor(String lang) =>
// // //       nameJson[lang] as String? ?? nameJson['en'] as String? ?? slug;

// // //   @override
// // //   List<Object?> get props => [id, slug];
// // // }

// // // // ── Purchase ──────────────────────────────────────────────────────────────────

// // // class PackPurchase extends Equatable {
// // //   const PackPurchase({
// // //     required this.packId,
// // //     required this.purchasedAt,
// // //     required this.expiresAt,
// // //     this.pricePaidMru = 0,
// // //   });

// // //   final String packId;
// // //   final DateTime purchasedAt;
// // //   final DateTime expiresAt;
// // //   final int pricePaidMru;

// // //   bool get isExpired => expiresAt.isBefore(DateTime.now());
// // //   bool get isActive  => !isExpired;

// // //   /// Days remaining before expiry (0 = expired).
// // //   int get daysRemaining {
// // //     final diff = expiresAt.difference(DateTime.now());
// // //     return diff.isNegative ? 0 : diff.inDays;
// // //   }

// // //   @override
// // //   List<Object?> get props => [packId, expiresAt];
// // // }

// // // // ── Rating ────────────────────────────────────────────────────────────────────

// // // class PackRating extends Equatable {
// // //   const PackRating({
// // //     required this.packId,
// // //     required this.userId,
// // //     required this.rating,
// // //     this.updatedAt,
// // //   });

// // //   final String packId;
// // //   final String userId;
// // //   final int rating; // 1–5
// // //   final DateTime? updatedAt;

// // //   @override
// // //   List<Object?> get props => [packId, userId, rating];
// // // }

// // // // ── Review ────────────────────────────────────────────────────────────────────

// // // class PackReview extends Equatable {
// // //   const PackReview({
// // //     required this.id,
// // //     required this.packId,
// // //     required this.userId,
// // //     required this.content,
// // //     this.rating,
// // //     this.authorName,
// // //     this.authorAvatarUrl,
// // //     required this.createdAt,
// // //     this.isVisible = true,
// // //   });

// // //   final String id;
// // //   final String packId;
// // //   final String userId;
// // //   final String content;
// // //   final int? rating;
// // //   final String? authorName;
// // //   final String? authorAvatarUrl;
// // //   final DateTime createdAt;
// // //   final bool isVisible;

// // //   @override
// // //   List<Object?> get props => [id, packId, userId];
// // // }

// // // // ── Download state ────────────────────────────────────────────────────────────

// // // enum DownloadStatus { notDownloaded, downloading, downloaded, failed, expired }

// // // class PackDownloadState extends Equatable {
// // //   const PackDownloadState({
// // //     required this.packId,
// // //     required this.status,
// // //     this.progress = 0.0,
// // //     this.errorMessage,
// // //     this.downloadedAt,
// // //     this.localVersion,
// // //   });

// // //   const PackDownloadState.initial(String packId)
// // //       : this(packId: packId, status: DownloadStatus.notDownloaded);

// // //   final String packId;
// // //   final DownloadStatus status;
// // //   final double progress;    // 0.0 – 1.0
// // //   final String? errorMessage;
// // //   final DateTime? downloadedAt;
// // //   final int? localVersion;

// // //   bool get isDownloaded => status == DownloadStatus.downloaded;
// // //   bool get isDownloading => status == DownloadStatus.downloading;
// // //   bool get isFailed      => status == DownloadStatus.failed;
// // //   bool get isAvailableOffline => isDownloaded;

// // //   PackDownloadState copyWith({
// // //     DownloadStatus? status,
// // //     double? progress,
// // //     String? errorMessage,
// // //     DateTime? downloadedAt,
// // //     int? localVersion,
// // //   }) =>
// // //       PackDownloadState(
// // //         packId:       packId,
// // //         status:       status       ?? this.status,
// // //         progress:     progress     ?? this.progress,
// // //         errorMessage: errorMessage ?? this.errorMessage,
// // //         downloadedAt: downloadedAt ?? this.downloadedAt,
// // //         localVersion: localVersion ?? this.localVersion,
// // //       );

// // //   @override
// // //   List<Object?> get props => [packId, status, progress, localVersion];
// // // }

// // // // ── Creator draft (for pack creation flow) ────────────────────────────────────

// // // class PackDraft {
// // //   PackDraft({
// // //     this.id,
// // //     this.titleEn = '',
// // //     this.titleAr = '',
// // //     this.titleFr = '',
// // //     this.descriptionEn = '',
// // //     this.gameType = 'truth_or_dare',
// // //     this.language = 'en',
// // //     this.priceMru = 0,
// // //     this.categoryId,
// // //     List<String>?    tags,
// // //     this.allowSpicy = false,
// // //     this.coverImagePath,
// // //     this.coverImageUrl,
// // //     List<CardDraft>? cards,
// // //     List<String>?    reactionImageUrls,
// // //   })  : tags              = tags              ?? [],
// // //         cards             = cards             ?? [],
// // //         reactionImageUrls = reactionImageUrls ?? [];

// // //   String? id;
// // //   String titleEn;
// // //   String titleAr;
// // //   String titleFr;
// // //   String descriptionEn;
// // //   String gameType;
// // //   String language;
// // //   int priceMru;
// // //   String? categoryId;
// // //   List<String> tags;
// // //   bool allowSpicy;
// // //   String? coverImagePath;
// // //   String? coverImageUrl;
// // //   List<String> reactionImageUrls;  // uploaded Wasabi URLs for meme reactions
// // //   List<CardDraft> cards;

// // //   bool get hasTitle => titleEn.trim().isNotEmpty;
// // //   bool get hasSufficientCards => cards.length >= 20;
// // //   bool get canPublish => hasTitle && hasSufficientCards;

// // //   int get truthCount => cards.where((c) => c.type == CardType.truth).length;
// // //   int get dareCount  => cards.where((c) => c.type == CardType.dare).length;

// // //   Map<String, dynamic> get titleJson => {
// // //     if (titleEn.isNotEmpty) 'en': titleEn,
// // //     if (titleAr.isNotEmpty) 'ar': titleAr,
// // //     if (titleFr.isNotEmpty) 'fr': titleFr,
// // //   };
// // // }

// // // class CardDraft {
// // //   CardDraft({
// // //     this.id,
// // //     this.contentEn = '',
// // //     this.contentAr = '',
// // //     this.contentFr = '',
// // //     this.type = CardType.truth,
// // //     this.difficulty = CardDifficulty.mild,
// // //     this.localImagePath,
// // //     this.imageUrl,
// // //   });

// // //   String? id;
// // //   String contentEn;
// // //   String contentAr;
// // //   String contentFr;
// // //   CardType type;
// // //   CardDifficulty difficulty;
// // //   String? localImagePath;
// // //   String? imageUrl;

// // //   bool get hasContent => contentEn.trim().isNotEmpty;

// // //   Map<String, dynamic> get contentJson => {
// // //     if (contentEn.isNotEmpty) 'en': contentEn,
// // //     if (contentAr.isNotEmpty) 'ar': contentAr,
// // //     if (contentFr.isNotEmpty) 'fr': contentFr,
// // //   };
// // // }

// // import 'package:equatable/equatable.dart';

// // /// Complete domain model for marketplace entities.
// // /// All monetary values in MRU (Mauritanian Ouguiya, integer units).

// // // ── Pack ──────────────────────────────────────────────────────────────────────

// // enum PackStatus {
// //   draft,
// //   pendingReview,
// //   approved,
// //   rejected,
// //   suspended,
// //   archived;

// //   static PackStatus fromString(String s) => switch (s) {
// //     'draft' => draft,
// //     'pending_review' => pendingReview,
// //     'rejected' => rejected,
// //     'suspended' => suspended,
// //     'archived' => archived,
// //     _ => approved,
// //   };

// //   bool get isPublished => this == approved;
// //   bool get isEditable => this == draft || this == rejected;
// // }

// // class PackEntity extends Equatable {
// //   const PackEntity({
// //     required this.id,
// //     required this.creatorId,
// //     required this.titleJson,
// //     this.descriptionJson,
// //     this.coverImageUrl,
// //     required this.status,
// //     required this.gameType,
// //     required this.language,
// //     this.isMultilang = false,
// //     required this.priceMru,
// //     required this.cardCount,
// //     required this.avgRating,
// //     required this.totalRatings,
// //     required this.totalPurchases,
// //     required this.totalPlays,
// //     this.downloadUrl,
// //     this.version = 1,
// //     this.hasSpicy = false,
// //     this.isFeatured = false,
// //     this.isPromoted = false,
// //     this.categoryId,
// //     this.tags = const [],
// //     this.reactionImageUrls = const [],
// //     this.publishedAt,
// //     this.createdAt,
// //     this.updatedAt,
// //     // Populated via join when fetched with creator profile
// //     this.creatorName,
// //     this.creatorAvatarUrl,
// //     this.isVerifiedCreator = false,
// //   });

// //   final String id;
// //   final String creatorId;
// //   final Map<String, dynamic> titleJson;
// //   final Map<String, dynamic>? descriptionJson;
// //   final String? coverImageUrl;
// //   final PackStatus status;
// //   final String gameType;
// //   final String language;
// //   final bool isMultilang;
// //   final int priceMru;
// //   final int cardCount;
// //   final double avgRating;
// //   final int totalRatings;
// //   final int totalPurchases;
// //   final int totalPlays;
// //   final String? downloadUrl;
// //   final int version;
// //   final bool hasSpicy;
// //   final bool isFeatured;
// //   final bool isPromoted;
// //   final String? categoryId;
// //   final List<String> tags;
// //   final List<String> reactionImageUrls; // custom meme pack reaction images
// //   final DateTime? publishedAt;
// //   final DateTime? createdAt;
// //   final DateTime? updatedAt;

// //   // Joined creator fields
// //   final String? creatorName;
// //   final String? creatorAvatarUrl;
// //   final bool isVerifiedCreator;

// //   bool get isFree => priceMru == 0;
// //   bool get isPublished => status.isPublished;

// //   /// Title in the given language, falling back to English.
// //   String titleFor(String lang) =>
// //       titleJson[lang] as String? ?? titleJson['en'] as String? ?? '';

// //   String descriptionFor(String lang) {
// //     final d = descriptionJson;
// //     if (d == null) return '';
// //     return d[lang] as String? ?? d['en'] as String? ?? '';
// //   }

// //   PackEntity copyWith({
// //     PackStatus? status,
// //     String? coverImageUrl,
// //     double? avgRating,
// //     int? totalRatings,
// //     int? totalPurchases,
// //     bool? isFeatured,
// //     bool? isPromoted,
// //     String? creatorName,
// //     String? creatorAvatarUrl,
// //     bool? isVerifiedCreator,
// //     List<String>? tags,
// //   }) => PackEntity(
// //     id: id,
// //     creatorId: creatorId,
// //     titleJson: titleJson,
// //     descriptionJson: descriptionJson,
// //     coverImageUrl: coverImageUrl ?? this.coverImageUrl,
// //     status: status ?? this.status,
// //     gameType: gameType,
// //     language: language,
// //     isMultilang: isMultilang,
// //     priceMru: priceMru,
// //     cardCount: cardCount,
// //     avgRating: avgRating ?? this.avgRating,
// //     totalRatings: totalRatings ?? this.totalRatings,
// //     totalPurchases: totalPurchases ?? this.totalPurchases,
// //     totalPlays: totalPlays,
// //     downloadUrl: downloadUrl,
// //     version: version,
// //     hasSpicy: hasSpicy,
// //     isFeatured: isFeatured ?? this.isFeatured,
// //     isPromoted: isPromoted ?? this.isPromoted,
// //     categoryId: categoryId,
// //     tags: tags ?? this.tags,
// //     publishedAt: publishedAt,
// //     createdAt: createdAt,
// //     updatedAt: updatedAt,
// //     creatorName: creatorName ?? this.creatorName,
// //     creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
// //     isVerifiedCreator: isVerifiedCreator ?? this.isVerifiedCreator,
// //   );

// //   @override
// //   List<Object?> get props => [id, status, avgRating, version, cardCount];
// // }

// // // ── Card ──────────────────────────────────────────────────────────────────────

// // enum CardType { truth, dare, statement, prompt }

// // enum CardDifficulty { mild, medium, spicy }

// // class PackCardEntity extends Equatable {
// //   const PackCardEntity({
// //     required this.id,
// //     required this.packId,
// //     required this.contentJson,
// //     required this.type,
// //     required this.difficulty,
// //     this.imageUrl,
// //     this.sortOrder = 0,
// //     this.isActive = true,
// //   });

// //   final String id;
// //   final String packId;
// //   final Map<String, dynamic>
// //   contentJson; // {"en":"...", "ar":"...", "fr":"..."}
// //   final CardType type;
// //   final CardDifficulty difficulty;
// //   final String? imageUrl;
// //   final int sortOrder;
// //   final bool isActive;

// //   String contentFor(String lang) =>
// //       contentJson[lang] as String? ?? contentJson['en'] as String? ?? '';

// //   bool get isSpicy => difficulty == CardDifficulty.spicy;

// //   @override
// //   List<Object?> get props => [id, packId, type, difficulty];
// // }

// // // ── Category ──────────────────────────────────────────────────────────────────

// // class PackCategory extends Equatable {
// //   const PackCategory({
// //     required this.id,
// //     required this.nameJson,
// //     required this.slug,
// //     this.icon = '📦',
// //     this.sortOrder = 0,
// //   });

// //   final String id;
// //   final Map<String, dynamic> nameJson;
// //   final String slug;
// //   final String icon;
// //   final int sortOrder;

// //   String nameFor(String lang) =>
// //       nameJson[lang] as String? ?? nameJson['en'] as String? ?? slug;

// //   @override
// //   List<Object?> get props => [id, slug];
// // }

// // // ── Purchase ──────────────────────────────────────────────────────────────────

// // class PackPurchase extends Equatable {
// //   const PackPurchase({
// //     required this.packId,
// //     required this.purchasedAt,
// //     required this.expiresAt,
// //     this.pricePaidMru = 0,
// //   });

// //   final String packId;
// //   final DateTime purchasedAt;
// //   final DateTime expiresAt;
// //   final int pricePaidMru;

// //   bool get isExpired => expiresAt.isBefore(DateTime.now());
// //   bool get isActive => !isExpired;

// //   /// Days remaining before expiry (0 = expired).
// //   int get daysRemaining {
// //     final diff = expiresAt.difference(DateTime.now());
// //     return diff.isNegative ? 0 : diff.inDays;
// //   }

// //   @override
// //   List<Object?> get props => [packId, expiresAt];
// // }

// // // ── Rating ────────────────────────────────────────────────────────────────────

// // class PackRating extends Equatable {
// //   const PackRating({
// //     required this.packId,
// //     required this.userId,
// //     required this.rating,
// //     this.updatedAt,
// //   });

// //   final String packId;
// //   final String userId;
// //   final int rating; // 1–5
// //   final DateTime? updatedAt;

// //   @override
// //   List<Object?> get props => [packId, userId, rating];
// // }

// // // ── Review ────────────────────────────────────────────────────────────────────

// // class PackReview extends Equatable {
// //   const PackReview({
// //     required this.id,
// //     required this.packId,
// //     required this.userId,
// //     required this.content,
// //     this.rating,
// //     this.authorName,
// //     this.authorAvatarUrl,
// //     required this.createdAt,
// //     this.isVisible = true,
// //   });

// //   final String id;
// //   final String packId;
// //   final String userId;
// //   final String content;
// //   final int? rating;
// //   final String? authorName;
// //   final String? authorAvatarUrl;
// //   final DateTime createdAt;
// //   final bool isVisible;

// //   @override
// //   List<Object?> get props => [id, packId, userId];
// // }

// // // ── Download state ────────────────────────────────────────────────────────────

// // enum DownloadStatus { notDownloaded, downloading, downloaded, failed, expired }

// // class PackDownloadState extends Equatable {
// //   const PackDownloadState({
// //     required this.packId,
// //     required this.status,
// //     this.progress = 0.0,
// //     this.errorMessage,
// //     this.downloadedAt,
// //     this.localVersion,
// //   });

// //   const PackDownloadState.initial(String packId)
// //     : this(packId: packId, status: DownloadStatus.notDownloaded);

// //   final String packId;
// //   final DownloadStatus status;
// //   final double progress; // 0.0 – 1.0
// //   final String? errorMessage;
// //   final DateTime? downloadedAt;
// //   final int? localVersion;

// //   bool get isDownloaded => status == DownloadStatus.downloaded;
// //   bool get isDownloading => status == DownloadStatus.downloading;
// //   bool get isFailed => status == DownloadStatus.failed;
// //   bool get isAvailableOffline => isDownloaded;

// //   PackDownloadState copyWith({
// //     DownloadStatus? status,
// //     double? progress,
// //     String? errorMessage,
// //     DateTime? downloadedAt,
// //     int? localVersion,
// //   }) => PackDownloadState(
// //     packId: packId,
// //     status: status ?? this.status,
// //     progress: progress ?? this.progress,
// //     errorMessage: errorMessage ?? this.errorMessage,
// //     downloadedAt: downloadedAt ?? this.downloadedAt,
// //     localVersion: localVersion ?? this.localVersion,
// //   );

// //   @override
// //   List<Object?> get props => [packId, status, progress, localVersion];
// // }

// // // ── Creator draft (for pack creation flow) ────────────────────────────────────

// // class PackDraft {
// //   PackDraft({
// //     this.id,
// //     this.titleEn = '',
// //     this.titleAr = '',
// //     this.titleFr = '',
// //     this.descriptionEn = '',
// //     this.gameType = 'truth_or_dare',
// //     this.language = 'en',
// //     this.priceMru = 0,
// //     this.categoryId,
// //     this.minPlayers = 2,
// //     List<String>? tags,
// //     this.allowSpicy = false,
// //     this.coverImagePath,
// //     this.coverImageUrl,
// //     List<CardDraft>? cards,
// //     List<String>? reactionImageUrls,
// //   }) : tags = tags ?? [],
// //        cards = cards ?? [],
// //        reactionImageUrls = reactionImageUrls ?? [];

// //   String? id;
// //   String titleEn;
// //   String titleAr;
// //   String titleFr;
// //   String descriptionEn;
// //   String gameType;
// //   String language;
// //   int priceMru;
// //   String? categoryId;
// //   int minPlayers; // 2 = everyone, higher = only for groups
// //   List<String> tags;
// //   bool allowSpicy;
// //   String? coverImagePath;
// //   String? coverImageUrl;
// //   List<String> reactionImageUrls; // uploaded Wasabi URLs for meme reactions
// //   List<CardDraft> cards;

// //   bool get hasTitle => titleEn.trim().isNotEmpty;
// //   bool get hasSufficientCards => cards.length >= 20;
// //   bool get canPublish => hasTitle && hasSufficientCards;

// //   int get truthCount => cards.where((c) => c.type == CardType.truth).length;
// //   int get dareCount => cards.where((c) => c.type == CardType.dare).length;

// //   Map<String, dynamic> get titleJson => {
// //     if (titleEn.isNotEmpty) 'en': titleEn,
// //     if (titleAr.isNotEmpty) 'ar': titleAr,
// //     if (titleFr.isNotEmpty) 'fr': titleFr,
// //   };
// // }

// // class CardDraft {
// //   CardDraft({
// //     this.id,
// //     this.contentEn = '',
// //     this.contentAr = '',
// //     this.contentFr = '',
// //     this.type = CardType.truth,
// //     this.difficulty = CardDifficulty.mild,
// //     this.localImagePath,
// //     this.imageUrl,
// //   });

// //   String? id;
// //   String contentEn;
// //   String contentAr;
// //   String contentFr;
// //   CardType type;
// //   CardDifficulty difficulty;
// //   String? localImagePath;
// //   String? imageUrl;

// //   bool get hasContent => contentEn.trim().isNotEmpty;

// //   Map<String, dynamic> get contentJson => {
// //     if (contentEn.isNotEmpty) 'en': contentEn,
// //     if (contentAr.isNotEmpty) 'ar': contentAr,
// //     if (contentFr.isNotEmpty) 'fr': contentFr,
// //   };
// // }

// import 'package:equatable/equatable.dart';

// /// Complete domain model for marketplace entities.
// /// All monetary values in MRU (Mauritanian Ouguiya, integer units).

// // ── Pack ──────────────────────────────────────────────────────────────────────

// enum PackStatus {
//   draft,
//   pendingReview,
//   approved,
//   rejected,
//   suspended,
//   archived;

//   static PackStatus fromString(String s) => switch (s) {
//     'draft' => draft,
//     'pending_review' => pendingReview,
//     'rejected' => rejected,
//     'suspended' => suspended,
//     'archived' => archived,
//     _ => approved,
//   };

//   bool get isPublished => this == approved;
//   bool get isEditable => this == draft || this == rejected;
// }

// class PackEntity extends Equatable {
//   const PackEntity({
//     required this.id,
//     required this.creatorId,
//     required this.titleJson,
//     this.descriptionJson,
//     this.coverImageUrl,
//     required this.status,
//     required this.gameType,
//     required this.language,
//     this.isMultilang = false,
//     List<String>? availableLanguages,
//     required this.priceMru,
//     required this.cardCount,
//     required this.avgRating,
//     required this.totalRatings,
//     required this.totalPurchases,
//     required this.totalPlays,
//     this.downloadUrl,
//     this.version = 1,
//     this.hasSpicy = false,
//     this.isFeatured = false,
//     this.isPromoted = false,
//     this.categoryId,
//     this.tags = const [],
//     this.reactionImageUrls = const [],
//     this.publishedAt,
//     this.createdAt,
//     this.updatedAt,
//     // Populated via join when fetched with creator profile
//     this.creatorName,
//     this.creatorAvatarUrl,
//     // this.availableLanguages,
//     this.isVerifiedCreator = false,
//   }) : availableLanguages = availableLanguages ?? const [];

//   final String id;
//   final String creatorId;
//   final Map<String, dynamic> titleJson;
//   final Map<String, dynamic>? descriptionJson;
//   final String? coverImageUrl;
//   final PackStatus status;
//   final String gameType;
//   final String language;
//   final bool isMultilang;
//   // final List<String> availableLanguages;
//   final List<String> availableLanguages;
//   final int priceMru;
//   final int cardCount;
//   final double avgRating;
//   final int totalRatings;
//   final int totalPurchases;
//   final int totalPlays;
//   final String? downloadUrl;
//   final int version;
//   final bool hasSpicy;
//   final bool isFeatured;
//   final bool isPromoted;
//   final String? categoryId;
//   final List<String> tags;
//   final List<String> reactionImageUrls; // custom meme pack reaction images
//   final DateTime? publishedAt;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;

//   // Joined creator fields
//   final String? creatorName;
//   final String? creatorAvatarUrl;
//   final bool isVerifiedCreator;

//   bool get isFree => priceMru == 0;
//   bool get isPublished => status.isPublished;

//   /// Title in the given language, falling back to English.
//   String titleFor(String lang) =>
//       titleJson[lang] as String? ?? titleJson['en'] as String? ?? '';

//   String descriptionFor(String lang) {
//     final d = descriptionJson;
//     if (d == null) return '';
//     return d[lang] as String? ?? d['en'] as String? ?? '';
//   }

//   PackEntity copyWith({
//     PackStatus? status,
//     String? coverImageUrl,
//     double? avgRating,
//     int? totalRatings,
//     int? totalPurchases,
//     bool? isFeatured,
//     bool? isPromoted,
//     String? creatorName,
//     String? creatorAvatarUrl,
//     bool? isVerifiedCreator,
//     List<String>? tags,
//   }) => PackEntity(
//     id: id,
//     creatorId: creatorId,
//     titleJson: titleJson,
//     descriptionJson: descriptionJson,
//     coverImageUrl: coverImageUrl ?? this.coverImageUrl,
//     status: status ?? this.status,
//     gameType: gameType,
//     language: language,
//     isMultilang: isMultilang,
//     priceMru: priceMru,
//     cardCount: cardCount,
//     avgRating: avgRating ?? this.avgRating,
//     totalRatings: totalRatings ?? this.totalRatings,
//     totalPurchases: totalPurchases ?? this.totalPurchases,
//     totalPlays: totalPlays,
//     downloadUrl: downloadUrl,
//     version: version,
//     hasSpicy: hasSpicy,
//     isFeatured: isFeatured ?? this.isFeatured,
//     isPromoted: isPromoted ?? this.isPromoted,
//     categoryId: categoryId,
//     tags: tags ?? this.tags,
//     publishedAt: publishedAt,
//     createdAt: createdAt,
//     updatedAt: updatedAt,
//     creatorName: creatorName ?? this.creatorName,
//     creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
//     isVerifiedCreator: isVerifiedCreator ?? this.isVerifiedCreator,
//   );

//   @override
//   List<Object?> get props => [id, status, avgRating, version, cardCount];
// }

// // ── Card ──────────────────────────────────────────────────────────────────────

// enum CardType { truth, dare, statement, prompt }

// enum CardDifficulty { mild, medium, spicy }

// class PackCardEntity extends Equatable {
//   const PackCardEntity({
//     required this.id,
//     required this.packId,
//     required this.contentJson,
//     required this.type,
//     required this.difficulty,
//     this.imageUrl,
//     this.sortOrder = 0,
//     this.isActive = true,
//   });

//   final String id;
//   final String packId;
//   final Map<String, dynamic>
//   contentJson; // {"en":"...", "ar":"...", "fr":"..."}
//   final CardType type;
//   final CardDifficulty difficulty;
//   final String? imageUrl;
//   final int sortOrder;
//   final bool isActive;

//   String contentFor(String lang) =>
//       contentJson[lang] as String? ?? contentJson['en'] as String? ?? '';

//   bool get isSpicy => difficulty == CardDifficulty.spicy;

//   @override
//   List<Object?> get props => [id, packId, type, difficulty];
// }

// // ── Category ──────────────────────────────────────────────────────────────────

// class PackCategory extends Equatable {
//   const PackCategory({
//     required this.id,
//     required this.nameJson,
//     required this.slug,
//     this.icon = '📦',
//     this.sortOrder = 0,
//   });

//   final String id;
//   final Map<String, dynamic> nameJson;
//   final String slug;
//   final String icon;
//   final int sortOrder;

//   String nameFor(String lang) =>
//       nameJson[lang] as String? ?? nameJson['en'] as String? ?? slug;

//   @override
//   List<Object?> get props => [id, slug];
// }

// // ── Purchase ──────────────────────────────────────────────────────────────────

// class PackPurchase extends Equatable {
//   const PackPurchase({
//     required this.packId,
//     required this.purchasedAt,
//     required this.expiresAt,
//     this.pricePaidMru = 0,
//   });

//   final String packId;
//   final DateTime purchasedAt;
//   final DateTime expiresAt;
//   final int pricePaidMru;

//   bool get isExpired => expiresAt.isBefore(DateTime.now());
//   bool get isActive => !isExpired;

//   /// Days remaining before expiry (0 = expired).
//   int get daysRemaining {
//     final diff = expiresAt.difference(DateTime.now());
//     return diff.isNegative ? 0 : diff.inDays;
//   }

//   @override
//   List<Object?> get props => [packId, expiresAt];
// }

// // ── Rating ────────────────────────────────────────────────────────────────────

// class PackRating extends Equatable {
//   const PackRating({
//     required this.packId,
//     required this.userId,
//     required this.rating,
//     this.updatedAt,
//   });

//   final String packId;
//   final String userId;
//   final int rating; // 1–5
//   final DateTime? updatedAt;

//   @override
//   List<Object?> get props => [packId, userId, rating];
// }

// // ── Review ────────────────────────────────────────────────────────────────────

// class PackReview extends Equatable {
//   const PackReview({
//     required this.id,
//     required this.packId,
//     required this.userId,
//     required this.content,
//     this.rating,
//     this.authorName,
//     this.authorAvatarUrl,
//     required this.createdAt,
//     this.isVisible = true,
//   });

//   final String id;
//   final String packId;
//   final String userId;
//   final String content;
//   final int? rating;
//   final String? authorName;
//   final String? authorAvatarUrl;
//   final DateTime createdAt;
//   final bool isVisible;

//   @override
//   List<Object?> get props => [id, packId, userId];
// }

// // ── Download state ────────────────────────────────────────────────────────────

// enum DownloadStatus { notDownloaded, downloading, downloaded, failed, expired }

// class PackDownloadState extends Equatable {
//   const PackDownloadState({
//     required this.packId,
//     required this.status,
//     this.progress = 0.0,
//     this.errorMessage,
//     this.downloadedAt,
//     this.localVersion,
//   });

//   const PackDownloadState.initial(String packId)
//     : this(packId: packId, status: DownloadStatus.notDownloaded);

//   final String packId;
//   final DownloadStatus status;
//   final double progress; // 0.0 – 1.0
//   final String? errorMessage;
//   final DateTime? downloadedAt;
//   final int? localVersion;

//   bool get isDownloaded => status == DownloadStatus.downloaded;
//   bool get isDownloading => status == DownloadStatus.downloading;
//   bool get isFailed => status == DownloadStatus.failed;
//   bool get isAvailableOffline => isDownloaded;

//   PackDownloadState copyWith({
//     DownloadStatus? status,
//     double? progress,
//     String? errorMessage,
//     DateTime? downloadedAt,
//     int? localVersion,
//   }) => PackDownloadState(
//     packId: packId,
//     status: status ?? this.status,
//     progress: progress ?? this.progress,
//     errorMessage: errorMessage ?? this.errorMessage,
//     downloadedAt: downloadedAt ?? this.downloadedAt,
//     localVersion: localVersion ?? this.localVersion,
//   );

//   @override
//   List<Object?> get props => [packId, status, progress, localVersion];
// }

// // ── Creator draft (for pack creation flow) ────────────────────────────────────

// class PackDraft {
//   PackDraft({
//     this.id,
//     this.titleEn = '',
//     this.titleAr = '',
//     this.titleFr = '',
//     this.descriptionEn = '',
//     this.gameType = 'truth_or_dare',
//     this.language = 'en',
//     List<String>? selectedLanguages,
//     this.priceMru = 0,
//     this.categoryId,
//     this.minPlayers = 2,
//     List<String>? tags,
//     this.allowSpicy = false,
//     this.coverImagePath,
//     this.coverImageUrl,
//     List<CardDraft>? cards,
//     List<String>? reactionImageUrls,
//   }) : tags = tags ?? [],
//        selectedLanguages = selectedLanguages ?? ['en'],
//        cards = cards ?? [],
//        reactionImageUrls = reactionImageUrls ?? [];

//   String? id;
//   String titleEn;
//   String titleAr;
//   String titleFr;
//   String descriptionEn;
//   String gameType;
//   String language;
//   List<String> selectedLanguages; // which langs the creator fills cards in
//   int priceMru;
//   String? categoryId;
//   int minPlayers; // 2 = everyone, higher = only for groups
//   List<String> tags;
//   bool allowSpicy;
//   String? coverImagePath;
//   String? coverImageUrl;
//   List<String> reactionImageUrls; // uploaded Wasabi URLs for meme reactions
//   List<CardDraft> cards;

//   bool get hasTitle => titleEn.trim().isNotEmpty;
//   bool get hasSufficientCards => cards.length >= 20;
//   bool get canPublish => hasTitle && hasSufficientCards;

//   int get truthCount => cards.where((c) => c.type == CardType.truth).length;
//   int get dareCount => cards.where((c) => c.type == CardType.dare).length;

//   Map<String, dynamic> get titleJson => {
//     if (titleEn.isNotEmpty) 'en': titleEn,
//     if (titleAr.isNotEmpty) 'ar': titleAr,
//     if (titleFr.isNotEmpty) 'fr': titleFr,
//   };
// }

// class CardDraft {
//   CardDraft({
//     this.id,
//     this.contentEn = '',
//     this.contentAr = '',
//     this.contentFr = '',
//     this.type = CardType.truth,
//     this.difficulty = CardDifficulty.mild,
//     this.localImagePath,
//     this.imageUrl,
//   });

//   String? id;
//   String contentEn;
//   String contentAr;
//   String contentFr;
//   CardType type;
//   CardDifficulty difficulty;
//   String? localImagePath;
//   String? imageUrl;

//   bool get hasContent => contentEn.trim().isNotEmpty;
//   bool hasContentFor(String lang) => switch (lang) {
//     'ar' => contentAr.trim().isNotEmpty,
//     'fr' => contentFr.trim().isNotEmpty,
//     _ => contentEn.trim().isNotEmpty,
//   };

//   Map<String, dynamic> get contentJson => {
//     if (contentEn.isNotEmpty) 'en': contentEn,
//     if (contentAr.isNotEmpty) 'ar': contentAr,
//     if (contentFr.isNotEmpty) 'fr': contentFr,
//   };
// }

import 'package:equatable/equatable.dart';

enum PackStatus {
  draft,
  pendingReview,
  approved,
  rejected,
  suspended,
  archived;

  static PackStatus fromString(String s) => switch (s) {
    'draft' => draft,
    'pending_review' => pendingReview,
    'rejected' => rejected,
    'suspended' => suspended,
    'archived' => archived,
    _ => approved,
  };

  bool get isPublished => this == approved;
  bool get isEditable => this == draft || this == rejected;
}

class PackEntity extends Equatable {
  const PackEntity({
    required this.id,
    required this.creatorId,
    required this.titleJson,
    this.descriptionJson,
    this.coverImageUrl,
    required this.status,
    required this.gameType,
    required this.language,
    this.isMultilang = false,
    List<String>? availableLanguages,
    required this.priceMru,
    required this.cardCount,
    required this.avgRating,
    required this.totalRatings,
    required this.totalPurchases,
    required this.totalPlays,
    this.downloadUrl,
    this.version = 1,
    this.hasSpicy = false,
    this.isFeatured = false,
    this.isPromoted = false,
    this.categoryId,
    this.tags = const [],
    this.reactionImageUrls = const [],
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.creatorName,
    this.creatorAvatarUrl,
    this.isVerifiedCreator = false,
    this.rejectionReason,
    this.minAge,
    this.maxAge,
    this.genderRestriction = 'everyone',
    this.minPlayers = 2,
    List<String>? suggestedPunishments,
  }) : availableLanguages = availableLanguages ?? const [],
       suggestedPunishments = suggestedPunishments ?? const [];

  final String id;
  final String creatorId;
  final Map<String, dynamic> titleJson;
  final Map<String, dynamic>? descriptionJson;
  final String? coverImageUrl;
  final PackStatus status;
  final String gameType;
  final String language;
  final bool isMultilang;
  final List<String> availableLanguages;
  final int priceMru;
  final int cardCount;
  final double avgRating;
  final int totalRatings;
  final int totalPurchases;
  final int totalPlays;
  final String? downloadUrl;
  final int version;
  final bool hasSpicy;
  final bool isFeatured;
  final bool isPromoted;
  final String? categoryId;
  final List<String> tags;
  final List<String> reactionImageUrls;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? creatorName;
  final String? creatorAvatarUrl;
  final bool isVerifiedCreator;
  final String? rejectionReason;

  /// Audience restrictions — null age bounds mean "no restriction."
  /// Storage only; enforcement against a joining user happens elsewhere.
  final int? minAge;
  final int? maxAge;
  final String genderRestriction; // 'everyone' | 'male' | 'female'

  /// Minimum recommended player count for this pack (2-12).
  final int minPlayers;

  /// Creator-authored Truth-or-Dare punishment options, empty or >=10.
  final List<String> suggestedPunishments;

  bool get isFree => priceMru == 0;
  bool get isPublished => status.isPublished;

  String titleFor(String lang) =>
      titleJson[lang] as String? ?? titleJson['en'] as String? ?? '';

  String descriptionFor(String lang) {
    final d = descriptionJson;
    if (d == null) return '';
    return d[lang] as String? ?? d['en'] as String? ?? '';
  }

  PackEntity copyWith({
    PackStatus? status,
    String? coverImageUrl,
    double? avgRating,
    int? totalRatings,
    int? totalPurchases,
    bool? isFeatured,
    bool? isPromoted,
    String? creatorName,
    String? creatorAvatarUrl,
    bool? isVerifiedCreator,
    List<String>? tags,
    String? rejectionReason,
  }) => PackEntity(
    id: id,
    creatorId: creatorId,
    titleJson: titleJson,
    descriptionJson: descriptionJson,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    status: status ?? this.status,
    gameType: gameType,
    language: language,
    isMultilang: isMultilang,
    priceMru: priceMru,
    cardCount: cardCount,
    avgRating: avgRating ?? this.avgRating,
    totalRatings: totalRatings ?? this.totalRatings,
    totalPurchases: totalPurchases ?? this.totalPurchases,
    totalPlays: totalPlays,
    downloadUrl: downloadUrl,
    version: version,
    hasSpicy: hasSpicy,
    isFeatured: isFeatured ?? this.isFeatured,
    isPromoted: isPromoted ?? this.isPromoted,
    categoryId: categoryId,
    tags: tags ?? this.tags,
    publishedAt: publishedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    creatorName: creatorName ?? this.creatorName,
    creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
    isVerifiedCreator: isVerifiedCreator ?? this.isVerifiedCreator,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    minAge: minAge,
    maxAge: maxAge,
    genderRestriction: genderRestriction,
    minPlayers: minPlayers,
    suggestedPunishments: suggestedPunishments,
  );

  @override
  List<Object?> get props => [id, status, avgRating, version, cardCount];
}

enum CardType { truth, dare, statement, prompt }

enum CardDifficulty { mild, medium, spicy }

class PackCardEntity extends Equatable {
  const PackCardEntity({
    required this.id,
    required this.packId,
    required this.contentJson,
    required this.type,
    required this.difficulty,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String packId;
  final Map<String, dynamic> contentJson;
  final CardType type;
  final CardDifficulty difficulty;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  String contentFor(String lang) =>
      contentJson[lang] as String? ?? contentJson['en'] as String? ?? '';

  bool get isSpicy => difficulty == CardDifficulty.spicy;

  @override
  List<Object?> get props => [id, packId, type, difficulty];
}

class PackCategory extends Equatable {
  const PackCategory({
    required this.id,
    required this.nameJson,
    required this.slug,
    this.icon = '📦',
    this.sortOrder = 0,
  });

  final String id;
  final Map<String, dynamic> nameJson;
  final String slug;
  final String icon;
  final int sortOrder;

  String nameFor(String lang) =>
      nameJson[lang] as String? ?? nameJson['en'] as String? ?? slug;

  @override
  List<Object?> get props => [id, slug];
}

class PackPurchase extends Equatable {
  const PackPurchase({
    required this.packId,
    required this.purchasedAt,
    this.expiresAt,
    this.pricePaidMru = 0,
  });

  final String packId;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final int pricePaidMru;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isActive => !isExpired;

  int get daysRemaining {
    if (expiresAt == null) return 999999;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  @override
  List<Object?> get props => [packId, expiresAt];
}

class PackRating extends Equatable {
  const PackRating({
    required this.packId,
    required this.userId,
    required this.rating,
    this.updatedAt,
  });

  final String packId;
  final String userId;
  final int rating;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [packId, userId, rating];
}

class PackReview extends Equatable {
  const PackReview({
    required this.id,
    required this.packId,
    required this.userId,
    required this.content,
    this.rating,
    this.authorName,
    this.authorAvatarUrl,
    required this.createdAt,
    this.isVisible = true,
  });

  final String id;
  final String packId;
  final String userId;
  final String content;
  final int? rating;
  final String? authorName;
  final String? authorAvatarUrl;
  final DateTime createdAt;
  final bool isVisible;

  @override
  List<Object?> get props => [id, packId, userId];
}

enum DownloadStatus { notDownloaded, downloading, downloaded, failed, expired }

class PackDownloadState extends Equatable {
  const PackDownloadState({
    required this.packId,
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
    this.downloadedAt,
    this.localVersion,
  });

  const PackDownloadState.initial(String packId)
    : this(packId: packId, status: DownloadStatus.notDownloaded);

  final String packId;
  final DownloadStatus status;
  final double progress;
  final String? errorMessage;
  final DateTime? downloadedAt;
  final int? localVersion;

  bool get isDownloaded => status == DownloadStatus.downloaded;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isAvailableOffline => isDownloaded;

  PackDownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? errorMessage,
    DateTime? downloadedAt,
    int? localVersion,
  }) => PackDownloadState(
    packId: packId,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    errorMessage: errorMessage ?? this.errorMessage,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    localVersion: localVersion ?? this.localVersion,
  );

  @override
  List<Object?> get props => [packId, status, progress, localVersion];
}

class PackDraft {
  PackDraft({
    this.id,
    Map<String, String>? titles,
    Map<String, String>? descriptions,
    this.gameType = 'truth_or_dare',
    this.language = 'en',
    List<String>? selectedLanguages,
    this.priceMru = 0,
    this.categoryId,
    this.pendingCategorySuggestionId,
    this.minPlayers = 2,
    List<String>? tags,
    this.allowSpicy = false,
    this.coverImagePath,
    this.coverImageUrl,
    List<CardDraft>? cards,
    List<String>? reactionImageUrls,
    this.minAge,
    this.maxAge,
    this.genderRestriction = 'everyone',
    List<String>? suggestedPunishments,
  }) : titles = titles ?? {},
       descriptions = descriptions ?? {},
       tags = tags ?? [],
       selectedLanguages = selectedLanguages ?? ['en'],
       cards = cards ?? [],
       reactionImageUrls = reactionImageUrls ?? [],
       suggestedPunishments = suggestedPunishments ?? [];

  String? id;

  /// Name per language code, e.g. {'en': 'Wild Friday', 'ar': '...'}. One
  /// entry expected per selectedLanguages entry — a generic map (not fixed
  /// en/ar/fr fields) so adding a language to pack_languages needs no Dart
  /// model change.
  Map<String, String> titles;

  /// Description per language code, same shape as [titles]. Optional per
  /// language (unlike titles, which are required for every selected
  /// language).
  Map<String, String> descriptions;
  String gameType;
  String language;
  List<String> selectedLanguages;
  int priceMru;
  String? categoryId;
  String? pendingCategorySuggestionId;
  int minPlayers;
  List<String> tags;
  bool allowSpicy;
  String? coverImagePath;
  String? coverImageUrl;
  List<String> reactionImageUrls;
  List<CardDraft> cards;

  /// Audience restrictions — null means "no restriction" (Everyone).
  /// Enforcement against a joining user happens elsewhere/later; this is
  /// storage only.
  int? minAge;
  int? maxAge;
  String genderRestriction; // 'everyone' | 'male' | 'female'

  /// Optional creator-authored punishment options for Truth or Dare packs.
  /// Must be empty or contain >=10 entries (enforced both here via
  /// [hasValidPunishments] and server-side via a CHECK constraint).
  List<String> suggestedPunishments;

  bool get hasTitle =>
      selectedLanguages.isNotEmpty &&
      selectedLanguages.every((lang) => (titles[lang]?.trim().isNotEmpty ?? false));
  bool get hasSufficientCards => cards.length >= 20;
  bool get hasValidPunishments =>
      suggestedPunishments.isEmpty || suggestedPunishments.length >= 10;
  bool get canPublish => hasTitle && hasSufficientCards && hasValidPunishments;

  int get truthCount => cards.where((c) => c.type == CardType.truth).length;
  int get dareCount => cards.where((c) => c.type == CardType.dare).length;

  Map<String, dynamic> get titleJson => {
    for (final entry in titles.entries)
      if (entry.value.trim().isNotEmpty) entry.key: entry.value,
  };

  Map<String, dynamic> get descriptionJson => {
    for (final entry in descriptions.entries)
      if (entry.value.trim().isNotEmpty) entry.key: entry.value,
  };
}

class CardDraft {
  CardDraft({
    this.id,
    this.contentEn = '',
    this.contentAr = '',
    this.contentFr = '',
    this.type = CardType.truth,
    this.difficulty = CardDifficulty.mild,
    this.localImagePath,
    this.imageUrl,
  });

  String? id;
  String contentEn;
  String contentAr;
  String contentFr;
  CardType type;
  CardDifficulty difficulty;
  String? localImagePath;
  String? imageUrl;

  bool get hasContent => contentEn.trim().isNotEmpty;
  bool hasContentFor(String lang) => switch (lang) {
    'ar' => contentAr.trim().isNotEmpty,
    'fr' => contentFr.trim().isNotEmpty,
    _ => contentEn.trim().isNotEmpty,
  };

  Map<String, dynamic> get contentJson => {
    if (contentEn.isNotEmpty) 'en': contentEn,
    if (contentAr.isNotEmpty) 'ar': contentAr,
    if (contentFr.isNotEmpty) 'fr': contentFr,
  };
}
