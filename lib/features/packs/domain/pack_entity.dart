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

import '../../../core/constants/app_constants.dart';

/// Resolves localized text for [lang]: the requested language first, then
/// (if given) the entity's own declared language, then 'en' (legacy
/// default), then — critically — the first non-empty value under ANY key.
/// A pack authored in only one non-en/ar/fr language (e.g. 'hs'
/// Hassaniya, or any future pack_languages code) only ever populates ONE
/// key here; without the final resort, viewing it in a different app
/// language returns '' even though the pack's own content exists. Never
/// returns a raw id — callers substitute a localized fallback string when
/// this returns ''.
String pickLocalized(
  Map<String, dynamic> json,
  String lang, {
  String? declaredLanguage,
}) {
  String? nonEmpty(String? key) {
    if (key == null) return null;
    final v = json[key];
    return (v is String && v.trim().isNotEmpty) ? v : null;
  }

  final direct = nonEmpty(lang) ?? nonEmpty(declaredLanguage) ?? nonEmpty('en');
  if (direct != null) return direct;
  for (final v in json.values) {
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return '';
}

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
    this.isOfficialCreator = false,
    this.rejectionReason,
    this.minAge,
    this.maxAge,
    this.genderRestriction = 'everyone',
    this.minPlayers = 2,
    this.maxPlayers,
    List<String>? suggestedPunishments,
    this.platformManaged = false,
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

  /// True when this pack's creator (creator_id — the CURRENT owner, e.g.
  /// after an item-7 ownership transfer, not necessarily who originally
  /// made it) is the official Jma3a system account
  /// (profiles.is_official_account). Every "created by" UI must key off
  /// this, not off creatorName == 'Jma3a' — see profiles.is_official_account
  /// for why a name check isn't a reliable identifier.
  final bool isOfficialCreator;
  final String? rejectionReason;

  /// Audience restrictions — null age bounds mean "no restriction."
  /// Storage only; enforcement against a joining user happens elsewhere.
  final int? minAge;
  final int? maxAge;
  final String genderRestriction; // 'everyone' | 'male' | 'female'

  /// Minimum recommended player count for this pack (2-12).
  final int minPlayers;

  /// Maximum player count this pack supports, or null for "no limit"
  /// (the original, and still default, behavior — most packs work fine
  /// with any group size above minPlayers). When set, always >= minPlayers;
  /// minPlayers == maxPlayers means the pack requires an exact player
  /// count. Enforced against ACTIVE (non-spectator) room players at game
  /// start — see create_game_session's too_many_players check.
  final int? maxPlayers;

  /// Creator-authored Truth-or-Dare punishment options, empty or >=10.
  final List<String> suggestedPunishments;

  /// True once Jma3a has taken over management of this pack (its
  /// creator's Premium Plus lapsed — see item 7). creatorId still points
  /// at the original creator for provenance; this is the flag that
  /// actually gates whether they can still edit/submit/manage it.
  final bool platformManaged;

  bool get isFree => priceMru == 0;
  bool get isPublished => status.isPublished;

  /// Whether the ORIGINAL creator can still edit this pack — status alone
  /// isn't enough once Jma3a has taken over management.
  bool get isEditableByCreator => status.isEditable && !platformManaged;

  String titleFor(String lang) =>
      pickLocalized(titleJson, lang, declaredLanguage: language);

  String descriptionFor(String lang) {
    final d = descriptionJson;
    if (d == null) return '';
    return pickLocalized(d, lang, declaredLanguage: language);
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
    isOfficialCreator: isOfficialCreator,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    minAge: minAge,
    maxAge: maxAge,
    genderRestriction: genderRestriction,
    minPlayers: minPlayers,
    maxPlayers: maxPlayers,
    suggestedPunishments: suggestedPunishments,
    platformManaged: platformManaged,
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
    this.stickerId,
    this.stickerUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String packId;
  final Map<String, dynamic> contentJson;
  final CardType type;
  final CardDifficulty difficulty;
  final String? imageUrl;

  /// References sticker_library.id — see CardDraft.stickerId.
  final String? stickerId;

  /// sticker_library.public_url, resolved by a join at read time when
  /// [stickerId] is set (null if the referenced sticker was disabled —
  /// RLS hides inactive rows — or if this card has no sticker at all).
  final String? stickerUrl;
  final int sortOrder;
  final bool isActive;

  /// The image to actually display for this card — its own upload if any,
  /// else the resolved library sticker, else nothing.
  String? get effectiveImageUrl => imageUrl ?? stickerUrl;

  String contentFor(String lang) => pickLocalized(contentJson, lang);

  bool get isSpicy => difficulty == CardDifficulty.spicy;

  @override
  List<Object?> get props => [id, packId, type, difficulty];
}

/// One row from the centralized, admin-managed sticker library (task item
/// 3) — a pack creator browses/picks these for a meme card's [CardDraft.
/// stickerId] instead of always uploading a new image.
class StickerEntity extends Equatable {
  const StickerEntity({
    required this.id,
    required this.name,
    required this.publicUrl,
    this.category,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String publicUrl;
  final String? category;
  final int sortOrder;

  @override
  List<Object?> get props => [id];
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

  String nameFor(String lang) {
    final picked = pickLocalized(nameJson, lang);
    return picked.isNotEmpty ? picked : slug;
  }

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

/// A single blocking reason a draft can't yet be submitted for review. The UI
/// maps each to a localized, human-readable explanation so the Submit button is
/// never silently disabled without telling the creator why.
enum PackDraftIssue {
  title,
  cards,
  language,
  price,
  truthDareBalance,
  punishments,
  terms,
  playerRange,
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
    this.maxPlayers,
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
    this.termsAccepted = false,
  }) : titles = titles ?? {},
       descriptions = descriptions ?? {},
       tags = tags ?? [],
       // Deliberately NOT defaulted to ['en']: a brand-new draft has no
       // language until the creator explicitly picks one, so English is never
       // silently forced/required (the old ['en'] default was the root cause of
       // "Please fill content in en" after choosing another language). The
       // Language step requires at least one selection before advancing.
       selectedLanguages = selectedLanguages ?? [],
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

  /// Optional max player count — null means "no limit" (the default).
  /// When set, must be >= minPlayers; minPlayers == maxPlayers means an
  /// exact player count is required. Never defaults to 0 — a creator who
  /// never touches this leaves it null, not an accidentally-unplayable
  /// pack.
  int? maxPlayers;
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

  /// Explicit acceptance of the Pack Creation Terms — required before a pack
  /// can be submitted for review. Never inferred from merely opening the
  /// terms; only a real checkbox toggle sets this.
  bool termsAccepted;

  bool get isTruthOrDare => gameType == 'truth_or_dare';

  bool get hasTitle =>
      selectedLanguages.isNotEmpty &&
      selectedLanguages.every(
        (lang) => (titles[lang]?.trim().isNotEmpty ?? false),
      );

  /// Every card must carry content for EVERY selected language (the language
  /// the creator actually chose — never a hardcoded 'en'). An empty card list
  /// is handled by [hasSufficientCards]; this only checks filled cards.
  bool get hasContentForSelectedLanguages =>
      selectedLanguages.isNotEmpty &&
      cards.every((c) => selectedLanguages.every(c.hasContentFor));

  bool get hasSufficientCards => cards.length >= 20;
  bool get hasValidPunishments =>
      suggestedPunishments.isEmpty || suggestedPunishments.length >= 10;

  /// No limit (null) is always valid; otherwise maxPlayers must be at
  /// least minPlayers — min-only, exact (min==max), and range are all
  /// valid shapes, only max < min is rejected.
  bool get hasValidPlayerRange =>
      maxPlayers == null || maxPlayers! >= minPlayers;

  /// Minimum pack price is [AppConstants.minPaidPackPriceMru] (300 MRU). Free
  /// packs (0) and anything 1–299 are invalid.
  bool get hasValidPrice => priceMru >= AppConstants.minPaidPackPriceMru;

  int get truthCount => cards.where((c) => c.type == CardType.truth).length;
  int get dareCount => cards.where((c) => c.type == CardType.dare).length;

  /// Truth or Dare packs must have an EQUAL number of Truth and Dare cards
  /// (e.g. 10/10). Only enforced for truth_or_dare; other game types have no
  /// such constraint.
  bool get hasBalancedTruthDare => !isTruthOrDare || truthCount == dareCount;

  /// THE single authoritative validation. Returns the list of blocking issues
  /// (empty = ready to submit). UI, canPublish, and any submit-time re-check
  /// all consult this so no two layers can disagree. [requireTerms] lets the
  /// earlier steps reuse it without demanding terms acceptance yet.
  List<PackDraftIssue> validationIssues({bool requireTerms = true}) {
    final issues = <PackDraftIssue>[];
    if (!hasTitle) issues.add(PackDraftIssue.title);
    if (!hasSufficientCards) issues.add(PackDraftIssue.cards);
    if (!hasContentForSelectedLanguages) issues.add(PackDraftIssue.language);
    if (!hasValidPrice) issues.add(PackDraftIssue.price);
    if (!hasBalancedTruthDare) issues.add(PackDraftIssue.truthDareBalance);
    if (!hasValidPunishments) issues.add(PackDraftIssue.punishments);
    if (!hasValidPlayerRange) issues.add(PackDraftIssue.playerRange);
    if (requireTerms && !termsAccepted) issues.add(PackDraftIssue.terms);
    return issues;
  }

  bool get canPublish => validationIssues().isEmpty;

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
    Map<String, String>? content,
    String contentEn = '',
    String contentAr = '',
    String contentFr = '',
    this.type = CardType.truth,
    this.difficulty = CardDifficulty.mild,
    this.localImagePath,
    this.imageUrl,
    this.stickerId,
  }) : content = {
         if (content != null)
           for (final e in content.entries)
             if (e.value.trim().isNotEmpty) e.key: e.value,
         if (contentEn.trim().isNotEmpty) 'en': contentEn,
         if (contentAr.trim().isNotEmpty) 'ar': contentAr,
         if (contentFr.trim().isNotEmpty) 'fr': contentFr,
       };

  String? id;

  /// Card content keyed by language CODE (dynamic — supports any code the
  /// server offers, e.g. 'hs' for Hassaniya, not just en/ar/fr). Empty-valued
  /// entries are never stored. This is the single source of truth; the
  /// contentEn/Ar/Fr accessors below are backward-compatible views onto it.
  final Map<String, String> content;
  CardType type;
  CardDifficulty difficulty;
  String? localImagePath;
  String? imageUrl;

  /// References sticker_library.id — set when this card's image comes from
  /// the centralized library instead of a pack-owned upload. Mutually
  /// exclusive with [imageUrl] in practice: picking a library sticker
  /// clears [imageUrl] and vice versa (see create_pack_screen.dart's
  /// sticker-picker entry point).
  String? stickerId;

  /// Set/clear the content for one language code. Empty clears the entry so it
  /// never counts as present.
  void setContent(String lang, String value) {
    final v = value.trim();
    if (v.isEmpty) {
      content.remove(lang);
    } else {
      content[lang] = v;
    }
  }

  // ── Backward-compatible fixed-language accessors ─────────────────────────
  String get contentEn => content['en'] ?? '';
  set contentEn(String v) => setContent('en', v);
  String get contentAr => content['ar'] ?? '';
  set contentAr(String v) => setContent('ar', v);
  String get contentFr => content['fr'] ?? '';
  set contentFr(String v) => setContent('fr', v);

  bool get hasContent => content.values.any((v) => v.trim().isNotEmpty);

  /// Dynamic per-language check — uses the actual selected code with NO
  /// hardcoded 'en' fallback, so a Hassaniya-only (or any single-language)
  /// pack validates on its own selected language.
  bool hasContentFor(String lang) => (content[lang] ?? '').trim().isNotEmpty;

  Map<String, dynamic> get contentJson => {
    for (final e in content.entries)
      if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
  };
}

/// One authoritative pack-creation preflight round trip
/// (get_pack_creation_status RPC) — mirrors RoomCreationStatus's exact
/// shape/convention (rooms/domain/room_entity.dart). UX-only: the server
/// independently re-verifies every one of these conditions inside
/// submit_pack_for_review() regardless of what this says, so a stale or
/// unavailable status here can only ever produce a friendlier error
/// message, never a security gap.
class PackCreationStatus {
  const PackCreationStatus({
    required this.isVerifiedCreator,
    required this.hasActiveDraft,
    required this.canSubmitFree,
    required this.minGapDays,
    required this.extraPackPriceMru,
    this.nextFreeAt,
  });

  final bool isVerifiedCreator;
  final bool hasActiveDraft;
  final bool canSubmitFree;

  /// Null once free submission is available again (or on a brand-new
  /// creator with no submission history yet).
  final DateTime? nextFreeAt;
  final int minGapDays;
  final int extraPackPriceMru;

  static PackCreationStatus fromMap(Map<String, dynamic> m) =>
      PackCreationStatus(
        isVerifiedCreator: m['is_verified_creator'] as bool? ?? false,
        hasActiveDraft: m['has_active_draft'] as bool? ?? false,
        canSubmitFree: m['can_submit_free'] as bool? ?? false,
        nextFreeAt: m['next_free_at'] != null
            ? DateTime.tryParse(m['next_free_at'] as String)
            : null,
        minGapDays: (m['min_gap_days'] as num?)?.toInt() ?? 15,
        extraPackPriceMru: (m['extra_pack_price_mru'] as num?)?.toInt() ?? 0,
      );
}
