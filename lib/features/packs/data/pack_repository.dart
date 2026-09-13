// // // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // // import 'package:uuid/uuid.dart';

// // // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // // import '../../../core/network/api_client.dart';
// // // // // // // // // import '../domain/pack_entity.dart';

// // // // // // // // // export '../domain/pack_entity.dart'; // Barrel re-export for convenience

// // // // // // // // // const _uuid = Uuid();

// // // // // // // // // /// All marketplace and pack data operations.
// // // // // // // // // ///
// // // // // // // // // /// Read  → Supabase direct (RLS-protected anon key)
// // // // // // // // // /// Write → Node.js API (service_role business rules)
// // // // // // // // // class PackRepository extends BaseRepository {
// // // // // // // // //   PackRepository._();
// // // // // // // // //   static final PackRepository _instance = PackRepository._();
// // // // // // // // //   static PackRepository get instance => _instance;

// // // // // // // // //   final _supabase = Supabase.instance.client;
// // // // // // // // //   final _api = ApiClient.instance;

// // // // // // // // //   // ── Browse ─────────────────────────────────────────────────────────────────

// // // // // // // // //   Future<List<PackEntity>> browsePacks({
// // // // // // // // //     String? query,
// // // // // // // // //     String? gameType,
// // // // // // // // //     String? categoryId,
// // // // // // // // //     bool freeOnly = false,
// // // // // // // // //     String? language,
// // // // // // // // //     String sortBy = 'avg_rating',
// // // // // // // // //     int page = 0,
// // // // // // // // //     int perPage = 20,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'browsePacks',
// // // // // // // // //     operation: () async {
// // // // // // // // //       var q = _supabase
// // // // // // // // //           .from('packs')
// // // // // // // // //           .select('''
// // // // // // // // //                 id, creator_id, title, description, cover_image_url,
// // // // // // // // //                 status, game_type, language, is_multilang, price_mru,
// // // // // // // // //                 card_count, avg_rating, total_ratings, total_purchases,
// // // // // // // // //                 total_plays, version, has_spicy, is_featured, is_promoted,
// // // // // // // // //                 category_id, download_url, published_at, created_at,
// // // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // // // // // //               ''')
// // // // // // // // //           .eq('status', 'approved')
// // // // // // // // //           .isFilter('deleted_at', null);

// // // // // // // // //       if (gameType != null) q = q.eq('game_type', gameType);
// // // // // // // // //       if (categoryId != null) q = q.eq('category_id', categoryId);
// // // // // // // // //       if (freeOnly) q = q.eq('price_mru', 0);
// // // // // // // // //       if (language != null && language != 'multi') {
// // // // // // // // //         q = q.or('language.eq.$language,is_multilang.eq.true');
// // // // // // // // //       }

// // // // // // // // //       final rows = await q
// // // // // // // // //           .order(sortBy, ascending: false)
// // // // // // // // //           .range(page * perPage, (page + 1) * perPage - 1);

// // // // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
// // // // // // // // //     operationName: 'getFeaturedPacks',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('packs')
// // // // // // // // //           .select('''
// // // // // // // // //                 id, creator_id, title, description, cover_image_url,
// // // // // // // // //                 status, game_type, language, price_mru, card_count,
// // // // // // // // //                 avg_rating, total_ratings, total_purchases, total_plays,
// // // // // // // // //                 version, has_spicy, is_featured, is_promoted,
// // // // // // // // //                 category_id, download_url,
// // // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // // // // // //               ''')
// // // // // // // // //           .eq('status', 'approved')
// // // // // // // // //           .eq('is_featured', true)
// // // // // // // // //           .isFilter('deleted_at', null)
// // // // // // // // //           .order('avg_rating', ascending: false)
// // // // // // // // //           .limit(10);
// // // // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
// // // // // // // // //     operationName: 'getPromotedPacks',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('promoted_packs')
// // // // // // // // //           .select('packs!pack_id(*), position')
// // // // // // // // //           .lte('starts_at', DateTime.now().toIso8601String())
// // // // // // // // //           .gte('ends_at', DateTime.now().toIso8601String())
// // // // // // // // //           .order('position');

// // // // // // // // //       return rows
// // // // // // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // // // // // //           .toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<PackCategory>> getCategories() => guardedCall(
// // // // // // // // //     operationName: 'getCategories',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('pack_categories')
// // // // // // // // //           .select()
// // // // // // // // //           .eq('is_active', true)
// // // // // // // // //           .order('sort_order');
// // // // // // // // //       return rows.map(_rowToCategory).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Detail ─────────────────────────────────────────────────────────────────

// // // // // // // // //   Future<PackEntity> getPackDetail(String packId) => guardedCall(
// // // // // // // // //     operationName: 'getPackDetail',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final row = await _supabase
// // // // // // // // //           .from('packs')
// // // // // // // // //           .select('''
// // // // // // // // //                 *,
// // // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
// // // // // // // // //                 pack_tags(tag)
// // // // // // // // //               ''')
// // // // // // // // //           .eq('id', packId)
// // // // // // // // //           .single();
// // // // // // // // //       return _rowToEntity(row);
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<PackReview>> getPackReviews(
// // // // // // // // //     String packId, {
// // // // // // // // //     int limit = 20,
// // // // // // // // //     int page = 0,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'getPackReviews',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('pack_reviews')
// // // // // // // // //           .select('''
// // // // // // // // //                 id, pack_id, user_id, content, created_at,
// // // // // // // // //                 profiles!user_id(display_name, avatar_url),
// // // // // // // // //                 pack_ratings!rating_id(rating)
// // // // // // // // //               ''')
// // // // // // // // //           .eq('pack_id', packId)
// // // // // // // // //           .eq('is_visible', true)
// // // // // // // // //           .order('created_at', ascending: false)
// // // // // // // // //           .range(page * limit, (page + 1) * limit - 1);

// // // // // // // // //       return rows.map(_rowToReview).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<PackRating?> getMyRating(String packId, String userId) =>
// // // // // // // // //       softCall<PackRating?>(
// // // // // // // // //         operationName: 'getMyRating',
// // // // // // // // //         operation: () async {
// // // // // // // // //           final row = await _supabase
// // // // // // // // //               .from('pack_ratings')
// // // // // // // // //               .select()
// // // // // // // // //               .eq('pack_id', packId)
// // // // // // // // //               .eq('user_id', userId)
// // // // // // // // //               .maybeSingle();
// // // // // // // // //           if (row == null) return null;
// // // // // // // // //           return PackRating(
// // // // // // // // //             packId: row['pack_id'] as String,
// // // // // // // // //             userId: row['user_id'] as String,
// // // // // // // // //             rating: row['rating'] as int,
// // // // // // // // //           );
// // // // // // // // //         },
// // // // // // // // //       );

// // // // // // // // //   // ── Purchases ──────────────────────────────────────────────────────────────

// // // // // // // // //   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
// // // // // // // // //     operationName: 'getMyPurchasedPacks',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('pack_purchases')
// // // // // // // // //           .select('pack_id, purchased_at, expires_at, packs(*)')
// // // // // // // // //           .eq('buyer_id', userId)
// // // // // // // // //           .eq('status', 'completed')
// // // // // // // // //           // Include rows where expires_at is null (permanent) OR in the future
// // // // // // // // //           .or(
// // // // // // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // // // // // //           )
// // // // // // // // //           .order('purchased_at', ascending: false);

// // // // // // // // //       return rows
// // // // // // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // // // // // //           .toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
// // // // // // // // //     operationName: 'getPurchaseRecords',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('pack_purchases')
// // // // // // // // //           .select('pack_id, purchased_at, expires_at, price_paid_mru')
// // // // // // // // //           .eq('buyer_id', userId)
// // // // // // // // //           .eq('status', 'completed')
// // // // // // // // //           .or(
// // // // // // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // // // // // //           );

// // // // // // // // //       return rows
// // // // // // // // //           .map(
// // // // // // // // //             (r) => PackPurchase(
// // // // // // // // //               packId: r['pack_id'] as String,
// // // // // // // // //               purchasedAt: DateTime.parse(r['purchased_at'] as String),
// // // // // // // // //               expiresAt: DateTime.parse(r['expires_at'] as String),
// // // // // // // // //               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// // // // // // // // //             ),
// // // // // // // // //           )
// // // // // // // // //           .toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
// // // // // // // // //     operationName: 'hasPurchased',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final row = await _supabase
// // // // // // // // //           .from('pack_purchases')
// // // // // // // // //           .select('id')
// // // // // // // // //           .eq('pack_id', packId)
// // // // // // // // //           .eq('buyer_id', userId)
// // // // // // // // //           .eq('status', 'completed')
// // // // // // // // //           .gt('expires_at', DateTime.now().toIso8601String())
// // // // // // // // //           .maybeSingle();
// // // // // // // // //       return row != null;
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   /// Purchase a pack via Node.js API (uses service_role to bypass RLS).
// // // // // // // // //   /// RLS policy "pack_purchases: no client insert" blocks direct Supabase writes.
// // // // // // // // //   Future<void> purchasePack(String packId) => guardedCall(
// // // // // // // // //     operationName: 'purchasePack',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final response = await _api.post(
// // // // // // // // //         '/v1/packs/purchase',
// // // // // // // // //         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
// // // // // // // // //       );
// // // // // // // // //       final data = response.data as Map<String, dynamic>?;
// // // // // // // // //       final error = data?['error'] as String?;
// // // // // // // // //       if (error != null) throw Exception(error);
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Ratings & Reviews ──────────────────────────────────────────────────────

// // // // // // // // //   Future<void> ratePack({
// // // // // // // // //     required String packId,
// // // // // // // // //     required String userId,
// // // // // // // // //     required int rating,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'ratePack',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase.from('pack_ratings').upsert({
// // // // // // // // //         'user_id': userId,
// // // // // // // // //         'pack_id': packId,
// // // // // // // // //         'rating': rating,
// // // // // // // // //       }, onConflict: 'pack_id,user_id');
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> submitReview({
// // // // // // // // //     required String packId,
// // // // // // // // //     required String userId,
// // // // // // // // //     required String content,
// // // // // // // // //     int? rating,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'submitReview',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase.from('pack_reviews').upsert({
// // // // // // // // //         'id': _uuid.v4(),
// // // // // // // // //         'pack_id': packId,
// // // // // // // // //         'user_id': userId,
// // // // // // // // //         'content': content,
// // // // // // // // //       }, onConflict: 'pack_id,user_id');
// // // // // // // // //       if (rating != null) {
// // // // // // // // //         await ratePack(packId: packId, userId: userId, rating: rating);
// // // // // // // // //       }
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> reportPack({
// // // // // // // // //     required String packId,
// // // // // // // // //     required String reporterId,
// // // // // // // // //     required String reason,
// // // // // // // // //     String? details,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'reportPack',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase.from('pack_reports').upsert({
// // // // // // // // //         'pack_id': packId,
// // // // // // // // //         'reporter_id': reporterId,
// // // // // // // // //         'reason': reason,
// // // // // // // // //         'details': details,
// // // // // // // // //       }, onConflict: 'pack_id,reporter_id');
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Creator operations ─────────────────────────────────────────────────────

// // // // // // // // //   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
// // // // // // // // //       guardedCall(
// // // // // // // // //         operationName: 'savePackReactions',
// // // // // // // // //         operation: () async {
// // // // // // // // //           await _api.post(
// // // // // // // // //             '/v1/packs/$packId/reactions',
// // // // // // // // //             data: {
// // // // // // // // //               'reactions': imageUrls
// // // // // // // // //                   .asMap()
// // // // // // // // //                   .entries
// // // // // // // // //                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
// // // // // // // // //                   .toList(),
// // // // // // // // //             },
// // // // // // // // //           );
// // // // // // // // //         },
// // // // // // // // //       );

// // // // // // // // //   Future<List<String>> getPackReactions(String packId) => guardedCall(
// // // // // // // // //     operationName: 'getPackReactions',
// // // // // // // // //     operation: () async {
// // // // // // // // //       try {
// // // // // // // // //         // Try API first (bypasses RLS — works for all pack statuses)
// // // // // // // // //         final response = await _api.get('/v1/packs/$packId/reactions');
// // // // // // // // //         final data = response.data as Map<String, dynamic>?;
// // // // // // // // //         final reactions = data?['data']?['reactions'] as List?;
// // // // // // // // //         if (reactions != null) {
// // // // // // // // //           return reactions.map((r) => r['image_url'] as String).toList();
// // // // // // // // //         }
// // // // // // // // //       } catch (_) {
// // // // // // // // //         // Fallback to direct Supabase if API fails
// // // // // // // // //       }
// // // // // // // // //       // Fallback: direct Supabase (works if RLS allows it)
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('pack_reactions')
// // // // // // // // //           .select('image_url')
// // // // // // // // //           .eq('pack_id', packId)
// // // // // // // // //           .order('sort_order');
// // // // // // // // //       return (rows as List).map((r) => r['image_url'] as String).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
// // // // // // // // //     operationName: 'getMyCreatedPacks',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final rows = await _supabase
// // // // // // // // //           .from('packs')
// // // // // // // // //           .select()
// // // // // // // // //           .eq('creator_id', creatorId)
// // // // // // // // //           .isFilter('deleted_at', null)
// // // // // // // // //           .order('created_at', ascending: false);
// // // // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   /// Create a pack draft (via Node.js for service_role insert).
// // // // // // // // //   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
// // // // // // // // //       guardedCall(
// // // // // // // // //         operationName: 'createPackDraft',
// // // // // // // // //         operation: () async {
// // // // // // // // //           final resp = await _api.post<Map<String, dynamic>>(
// // // // // // // // //             '/v1/packs/create',
// // // // // // // // //             data: {
// // // // // // // // //               'title': draft.titleJson,
// // // // // // // // //               'description': {'en': draft.descriptionEn},
// // // // // // // // //               'game_type': draft.gameType,
// // // // // // // // //               'language': draft.language,
// // // // // // // // //               'price_mru': draft.priceMru,
// // // // // // // // //               'category_id': draft.categoryId,
// // // // // // // // //               'has_spicy': draft.allowSpicy,
// // // // // // // // //               'tags': draft.tags,
// // // // // // // // //               'cover_image_url': draft.coverImageUrl,
// // // // // // // // //             },
// // // // // // // // //           );
// // // // // // // // //           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
// // // // // // // // //           return _rowToEntity(row);
// // // // // // // // //         },
// // // // // // // // //       );

// // // // // // // // //   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
// // // // // // // // //       guardedCall(
// // // // // // // // //         operationName: 'updatePackDraft',
// // // // // // // // //         operation: () async {
// // // // // // // // //           final resp = await _api.patch<Map<String, dynamic>>(
// // // // // // // // //             '/v1/packs/$packId',
// // // // // // // // //             data: {
// // // // // // // // //               'title': draft.titleJson,
// // // // // // // // //               'description': {'en': draft.descriptionEn},
// // // // // // // // //               'price_mru': draft.priceMru,
// // // // // // // // //               'category_id': draft.categoryId,
// // // // // // // // //               'has_spicy': draft.allowSpicy,
// // // // // // // // //               'tags': draft.tags,
// // // // // // // // //               'cover_image_url': draft.coverImageUrl,
// // // // // // // // //             },
// // // // // // // // //           );
// // // // // // // // //           return _rowToEntity(
// // // // // // // // //             resp.data!['data']['pack'] as Map<String, dynamic>,
// // // // // // // // //           );
// // // // // // // // //         },
// // // // // // // // //       );

// // // // // // // // //   Future<PackEntity> submitForReview(String packId) => guardedCall(
// // // // // // // // //     operationName: 'submitForReview',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // // // // // //         '/v1/packs/$packId/submit',
// // // // // // // // //       );
// // // // // // // // //       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
// // // // // // // // //     operationName: 'addCards',
// // // // // // // // //     operation: () async {
// // // // // // // // //       // Delete existing cards then re-insert (replace all)
// // // // // // // // //       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

// // // // // // // // //       if (cards.isEmpty) return;

// // // // // // // // //       final rows = cards
// // // // // // // // //           .asMap()
// // // // // // // // //           .entries
// // // // // // // // //           .map(
// // // // // // // // //             (e) => {
// // // // // // // // //               'pack_id': packId,
// // // // // // // // //               'content': e.value.contentJson,
// // // // // // // // //               'card_type': e.value.type.name,
// // // // // // // // //               'difficulty': e.value.difficulty.name,
// // // // // // // // //               'sort_order': e.key,
// // // // // // // // //               'is_active': true,
// // // // // // // // //             },
// // // // // // // // //           )
// // // // // // // // //           .toList();

// // // // // // // // //       await _supabase.from('pack_cards').insert(rows);
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   Future<void> deleteCard(String packId, String cardId) => guardedCall(
// // // // // // // // //     operationName: 'deleteCard',
// // // // // // // // //     operation: () async {
// // // // // // // // //       await _supabase
// // // // // // // // //           .from('pack_cards')
// // // // // // // // //           .delete()
// // // // // // // // //           .eq('id', cardId)
// // // // // // // // //           .eq('pack_id', packId);
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   /// Request a presigned upload URL from Node.js for Wasabi.
// // // // // // // // //   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
// // // // // // // // //     required String contentType,
// // // // // // // // //     required String fileType, // 'cover' or 'card_image'
// // // // // // // // //     required int fileSizeBytes,
// // // // // // // // //   }) => guardedCall(
// // // // // // // // //     operationName: 'getUploadUrl',
// // // // // // // // //     operation: () async {
// // // // // // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // // // // // //         '/v1/storage/upload-url',
// // // // // // // // //         data: {
// // // // // // // // //           'file_type': fileType,
// // // // // // // // //           'content_type': contentType,
// // // // // // // // //           'file_size_bytes': fileSizeBytes,
// // // // // // // // //         },
// // // // // // // // //       );
// // // // // // // // //       final data = resp.data!['data'] as Map<String, dynamic>;
// // // // // // // // //       return (
// // // // // // // // //         uploadUrl: data['upload_url'] as String,
// // // // // // // // //         publicUrl: data['public_url'] as String,
// // // // // // // // //       );
// // // // // // // // //     },
// // // // // // // // //   );

// // // // // // // // //   // ── Mappers ────────────────────────────────────────────────────────────────

// // // // // // // // //   PackEntity _rowToEntity(Map<String, dynamic> r) {
// // // // // // // // //     // Creator profile (joined)
// // // // // // // // //     final creator = r['profiles'] as Map<String, dynamic>?;
// // // // // // // // //     // Tags (joined)
// // // // // // // // //     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
// // // // // // // // //     final tags = tagRows.map((t) => t['tag'] as String).toList();

// // // // // // // // //     return PackEntity(
// // // // // // // // //       id: r['id'] as String,
// // // // // // // // //       creatorId: r['creator_id'] as String,
// // // // // // // // //       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // // // // // //       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
// // // // // // // // //       coverImageUrl: r['cover_image_url'] as String?,
// // // // // // // // //       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
// // // // // // // // //       gameType: r['game_type'] as String? ?? 'truth_or_dare',
// // // // // // // // //       language: r['language'] as String? ?? 'en',
// // // // // // // // //       isMultilang: r['is_multilang'] as bool? ?? false,
// // // // // // // // //       priceMru: r['price_mru'] as int? ?? 0,
// // // // // // // // //       cardCount: r['card_count'] as int? ?? 0,
// // // // // // // // //       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
// // // // // // // // //       totalRatings: r['total_ratings'] as int? ?? 0,
// // // // // // // // //       totalPurchases: r['total_purchases'] as int? ?? 0,
// // // // // // // // //       totalPlays: r['total_plays'] as int? ?? 0,
// // // // // // // // //       downloadUrl: r['download_url'] as String?,
// // // // // // // // //       version: r['version'] as int? ?? 1,
// // // // // // // // //       hasSpicy: r['has_spicy'] as bool? ?? false,
// // // // // // // // //       isFeatured: r['is_featured'] as bool? ?? false,
// // // // // // // // //       isPromoted: r['is_promoted'] as bool? ?? false,
// // // // // // // // //       categoryId: r['category_id'] as String?,
// // // // // // // // //       tags: tags,
// // // // // // // // //       publishedAt: r['published_at'] != null
// // // // // // // // //           ? DateTime.tryParse(r['published_at'] as String)
// // // // // // // // //           : null,
// // // // // // // // //       createdAt: r['created_at'] != null
// // // // // // // // //           ? DateTime.tryParse(r['created_at'] as String)
// // // // // // // // //           : null,
// // // // // // // // //       updatedAt: r['updated_at'] != null
// // // // // // // // //           ? DateTime.tryParse(r['updated_at'] as String)
// // // // // // // // //           : null,
// // // // // // // // //       creatorName:
// // // // // // // // //           creator?['display_name'] as String? ??
// // // // // // // // //           creator?['username'] as String?,
// // // // // // // // //       creatorAvatarUrl: creator?['avatar_url'] as String?,
// // // // // // // // //       isVerifiedCreator: creator?['verification_status'] == 'verified',
// // // // // // // // //     );
// // // // // // // // //   }

// // // // // // // // //   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
// // // // // // // // //     id: r['id'] as String,
// // // // // // // // //     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // // // // // //     slug: r['slug'] as String,
// // // // // // // // //     icon: r['icon'] as String? ?? '📦',
// // // // // // // // //     sortOrder: r['sort_order'] as int? ?? 0,
// // // // // // // // //   );

// // // // // // // // //   PackReview _rowToReview(Map<String, dynamic> r) {
// // // // // // // // //     final author = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // // //     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
// // // // // // // // //     return PackReview(
// // // // // // // // //       id: r['id'] as String,
// // // // // // // // //       packId: r['pack_id'] as String,
// // // // // // // // //       userId: r['user_id'] as String,
// // // // // // // // //       content: r['content'] as String,
// // // // // // // // //       rating: ratingRow?['rating'] as int?,
// // // // // // // // //       authorName: author['display_name'] as String?,
// // // // // // // // //       authorAvatarUrl: author['avatar_url'] as String?,
// // // // // // // // //       createdAt: DateTime.parse(r['created_at'] as String),
// // // // // // // // //     );
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // // import 'package:uuid/uuid.dart';

// // // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // // import '../../../core/network/api_client.dart';
// // // // // // // // import '../domain/pack_entity.dart';

// // // // // // // // export '../domain/pack_entity.dart'; // Barrel re-export for convenience

// // // // // // // // const _uuid = Uuid();

// // // // // // // // /// All marketplace and pack data operations.
// // // // // // // // ///
// // // // // // // // /// Read  → Supabase direct (RLS-protected anon key)
// // // // // // // // /// Write → Node.js API (service_role business rules)
// // // // // // // // class PackRepository extends BaseRepository {
// // // // // // // //   PackRepository._();
// // // // // // // //   static final PackRepository _instance = PackRepository._();
// // // // // // // //   static PackRepository get instance => _instance;

// // // // // // // //   final _supabase = Supabase.instance.client;
// // // // // // // //   final _api = ApiClient.instance;

// // // // // // // //   // ── Browse ─────────────────────────────────────────────────────────────────

// // // // // // // //   Future<List<PackEntity>> browsePacks({
// // // // // // // //     String? query,
// // // // // // // //     String? gameType,
// // // // // // // //     String? categoryId,
// // // // // // // //     bool freeOnly = false,
// // // // // // // //     String? language,
// // // // // // // //     String sortBy = 'avg_rating',
// // // // // // // //     int page = 0,
// // // // // // // //     int perPage = 20,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'browsePacks',
// // // // // // // //     operation: () async {
// // // // // // // //       var q = _supabase
// // // // // // // //           .from('packs')
// // // // // // // //           .select('''
// // // // // // // //                 id, creator_id, title, description, cover_image_url,
// // // // // // // //                 status, game_type, language, is_multilang, price_mru,
// // // // // // // //                 card_count, avg_rating, total_ratings, total_purchases,
// // // // // // // //                 total_plays, version, has_spicy, is_featured, is_promoted,
// // // // // // // //                 category_id, download_url, published_at, created_at,
// // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // // // // //               ''')
// // // // // // // //           .eq('status', 'approved')
// // // // // // // //           .isFilter('deleted_at', null);

// // // // // // // //       if (gameType != null) q = q.eq('game_type', gameType);
// // // // // // // //       if (categoryId != null) q = q.eq('category_id', categoryId);
// // // // // // // //       if (freeOnly) q = q.eq('price_mru', 0);
// // // // // // // //       if (language != null && language != 'multi') {
// // // // // // // //         q = q.or('language.eq.$language,is_multilang.eq.true');
// // // // // // // //       }

// // // // // // // //       final rows = await q
// // // // // // // //           .order(sortBy, ascending: false)
// // // // // // // //           .range(page * perPage, (page + 1) * perPage - 1);

// // // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
// // // // // // // //     operationName: 'getFeaturedPacks',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('packs')
// // // // // // // //           .select('''
// // // // // // // //                 id, creator_id, title, description, cover_image_url,
// // // // // // // //                 status, game_type, language, price_mru, card_count,
// // // // // // // //                 avg_rating, total_ratings, total_purchases, total_plays,
// // // // // // // //                 version, has_spicy, is_featured, is_promoted,
// // // // // // // //                 category_id, download_url,
// // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // // // // //               ''')
// // // // // // // //           .eq('status', 'approved')
// // // // // // // //           .eq('is_featured', true)
// // // // // // // //           .isFilter('deleted_at', null)
// // // // // // // //           .order('avg_rating', ascending: false)
// // // // // // // //           .limit(10);
// // // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
// // // // // // // //     operationName: 'getPromotedPacks',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('promoted_packs')
// // // // // // // //           .select('packs!pack_id(*), position')
// // // // // // // //           .lte('starts_at', DateTime.now().toIso8601String())
// // // // // // // //           .gte('ends_at', DateTime.now().toIso8601String())
// // // // // // // //           .order('position');

// // // // // // // //       return rows
// // // // // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // // // // //           .toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<PackCategory>> getCategories() => guardedCall(
// // // // // // // //     operationName: 'getCategories',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('pack_categories')
// // // // // // // //           .select()
// // // // // // // //           .eq('is_active', true)
// // // // // // // //           .order('sort_order');
// // // // // // // //       return rows.map(_rowToCategory).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Detail ─────────────────────────────────────────────────────────────────

// // // // // // // //   Future<PackEntity> getPackDetail(String packId) => guardedCall(
// // // // // // // //     operationName: 'getPackDetail',
// // // // // // // //     operation: () async {
// // // // // // // //       final row = await _supabase
// // // // // // // //           .from('packs')
// // // // // // // //           .select('''
// // // // // // // //                 *,
// // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
// // // // // // // //                 pack_tags(tag)
// // // // // // // //               ''')
// // // // // // // //           .eq('id', packId)
// // // // // // // //           .single();
// // // // // // // //       return _rowToEntity(row);
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<PackReview>> getPackReviews(
// // // // // // // //     String packId, {
// // // // // // // //     int limit = 20,
// // // // // // // //     int page = 0,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'getPackReviews',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('pack_reviews')
// // // // // // // //           .select('''
// // // // // // // //                 id, pack_id, user_id, content, created_at,
// // // // // // // //                 profiles!user_id(display_name, avatar_url),
// // // // // // // //                 pack_ratings!rating_id(rating)
// // // // // // // //               ''')
// // // // // // // //           .eq('pack_id', packId)
// // // // // // // //           .eq('is_visible', true)
// // // // // // // //           .order('created_at', ascending: false)
// // // // // // // //           .range(page * limit, (page + 1) * limit - 1);

// // // // // // // //       return rows.map(_rowToReview).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<PackRating?> getMyRating(String packId, String userId) =>
// // // // // // // //       softCall<PackRating?>(
// // // // // // // //         operationName: 'getMyRating',
// // // // // // // //         operation: () async {
// // // // // // // //           final row = await _supabase
// // // // // // // //               .from('pack_ratings')
// // // // // // // //               .select()
// // // // // // // //               .eq('pack_id', packId)
// // // // // // // //               .eq('user_id', userId)
// // // // // // // //               .maybeSingle();
// // // // // // // //           if (row == null) return null;
// // // // // // // //           return PackRating(
// // // // // // // //             packId: row['pack_id'] as String,
// // // // // // // //             userId: row['user_id'] as String,
// // // // // // // //             rating: row['rating'] as int,
// // // // // // // //           );
// // // // // // // //         },
// // // // // // // //       );

// // // // // // // //   // ── Purchases ──────────────────────────────────────────────────────────────

// // // // // // // //   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
// // // // // // // //     operationName: 'getMyPurchasedPacks',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('pack_purchases')
// // // // // // // //           .select('pack_id, purchased_at, expires_at, packs(*)')
// // // // // // // //           .eq('buyer_id', userId)
// // // // // // // //           .eq('status', 'completed')
// // // // // // // //           // Include rows where expires_at is null (permanent) OR in the future
// // // // // // // //           .or(
// // // // // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // // // // //           )
// // // // // // // //           .order('purchased_at', ascending: false);

// // // // // // // //       return rows
// // // // // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // // // // //           .toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
// // // // // // // //     operationName: 'getPurchaseRecords',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('pack_purchases')
// // // // // // // //           .select('pack_id, purchased_at, expires_at, price_paid_mru')
// // // // // // // //           .eq('buyer_id', userId)
// // // // // // // //           .eq('status', 'completed')
// // // // // // // //           .or(
// // // // // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // // // // //           );

// // // // // // // //       return rows
// // // // // // // //           .map(
// // // // // // // //             (r) => PackPurchase(
// // // // // // // //               packId: r['pack_id'] as String,
// // // // // // // //               purchasedAt: DateTime.parse(r['purchased_at'] as String),
// // // // // // // //               expiresAt: DateTime.parse(r['expires_at'] as String),
// // // // // // // //               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// // // // // // // //             ),
// // // // // // // //           )
// // // // // // // //           .toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
// // // // // // // //     operationName: 'hasPurchased',
// // // // // // // //     operation: () async {
// // // // // // // //       final row = await _supabase
// // // // // // // //           .from('pack_purchases')
// // // // // // // //           .select('id')
// // // // // // // //           .eq('pack_id', packId)
// // // // // // // //           .eq('buyer_id', userId)
// // // // // // // //           .eq('status', 'completed')
// // // // // // // //           .gt('expires_at', DateTime.now().toIso8601String())
// // // // // // // //           .maybeSingle();
// // // // // // // //       return row != null;
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   /// Purchase a pack via Node.js API (uses service_role to bypass RLS).
// // // // // // // //   /// RLS policy "pack_purchases: no client insert" blocks direct Supabase writes.
// // // // // // // //   Future<void> purchasePack(String packId) => guardedCall(
// // // // // // // //     operationName: 'purchasePack',
// // // // // // // //     operation: () async {
// // // // // // // //       final response = await _api.post(
// // // // // // // //         '/v1/packs/purchase',
// // // // // // // //         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
// // // // // // // //       );
// // // // // // // //       final data = response.data as Map<String, dynamic>?;
// // // // // // // //       final error = data?['error'] as String?;
// // // // // // // //       if (error != null) throw Exception(error);
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Ratings & Reviews ──────────────────────────────────────────────────────

// // // // // // // //   Future<void> ratePack({
// // // // // // // //     required String packId,
// // // // // // // //     required String userId,
// // // // // // // //     required int rating,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'ratePack',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase.from('pack_ratings').upsert({
// // // // // // // //         'user_id': userId,
// // // // // // // //         'pack_id': packId,
// // // // // // // //         'rating': rating,
// // // // // // // //       }, onConflict: 'pack_id,user_id');
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> submitReview({
// // // // // // // //     required String packId,
// // // // // // // //     required String userId,
// // // // // // // //     required String content,
// // // // // // // //     int? rating,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'submitReview',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase.from('pack_reviews').upsert({
// // // // // // // //         'id': _uuid.v4(),
// // // // // // // //         'pack_id': packId,
// // // // // // // //         'user_id': userId,
// // // // // // // //         'content': content,
// // // // // // // //       }, onConflict: 'pack_id,user_id');
// // // // // // // //       if (rating != null) {
// // // // // // // //         await ratePack(packId: packId, userId: userId, rating: rating);
// // // // // // // //       }
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> reportPack({
// // // // // // // //     required String packId,
// // // // // // // //     required String reporterId,
// // // // // // // //     required String reason,
// // // // // // // //     String? details,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'reportPack',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase.from('pack_reports').upsert({
// // // // // // // //         'pack_id': packId,
// // // // // // // //         'reporter_id': reporterId,
// // // // // // // //         'reason': reason,
// // // // // // // //         'details': details,
// // // // // // // //       }, onConflict: 'pack_id,reporter_id');
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Creator operations ─────────────────────────────────────────────────────

// // // // // // // //   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
// // // // // // // //       guardedCall(
// // // // // // // //         operationName: 'savePackReactions',
// // // // // // // //         operation: () async {
// // // // // // // //           await _api.post(
// // // // // // // //             '/v1/packs/$packId/reactions',
// // // // // // // //             data: {
// // // // // // // //               'reactions': imageUrls
// // // // // // // //                   .asMap()
// // // // // // // //                   .entries
// // // // // // // //                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
// // // // // // // //                   .toList(),
// // // // // // // //             },
// // // // // // // //           );
// // // // // // // //         },
// // // // // // // //       );

// // // // // // // //   Future<List<String>> getPackReactions(String packId) => guardedCall(
// // // // // // // //     operationName: 'getPackReactions',
// // // // // // // //     operation: () async {
// // // // // // // //       try {
// // // // // // // //         // Try API first (bypasses RLS — works for all pack statuses)
// // // // // // // //         final response = await _api.get('/v1/packs/$packId/reactions');
// // // // // // // //         final data = response.data as Map<String, dynamic>?;
// // // // // // // //         final reactions = data?['data']?['reactions'] as List?;
// // // // // // // //         if (reactions != null) {
// // // // // // // //           return reactions.map((r) => r['image_url'] as String).toList();
// // // // // // // //         }
// // // // // // // //       } catch (_) {
// // // // // // // //         // Fallback to direct Supabase if API fails
// // // // // // // //       }
// // // // // // // //       // Fallback: direct Supabase (works if RLS allows it)
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('pack_reactions')
// // // // // // // //           .select('image_url')
// // // // // // // //           .eq('pack_id', packId)
// // // // // // // //           .order('sort_order');
// // // // // // // //       return (rows as List).map((r) => r['image_url'] as String).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
// // // // // // // //     operationName: 'getMyCreatedPacks',
// // // // // // // //     operation: () async {
// // // // // // // //       final rows = await _supabase
// // // // // // // //           .from('packs')
// // // // // // // //           .select()
// // // // // // // //           .eq('creator_id', creatorId)
// // // // // // // //           .isFilter('deleted_at', null)
// // // // // // // //           .order('created_at', ascending: false);
// // // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   /// Create a pack draft (via Node.js for service_role insert).
// // // // // // // //   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
// // // // // // // //       guardedCall(
// // // // // // // //         operationName: 'createPackDraft',
// // // // // // // //         operation: () async {
// // // // // // // //           final resp = await _api.post<Map<String, dynamic>>(
// // // // // // // //             '/v1/packs/create',
// // // // // // // //             data: {
// // // // // // // //               'title': draft.titleJson,
// // // // // // // //               'description': {'en': draft.descriptionEn},
// // // // // // // //               'game_type': draft.gameType,
// // // // // // // //               'language': draft.language,
// // // // // // // //               'price_mru': draft.priceMru,
// // // // // // // //               'category_id': draft.categoryId,
// // // // // // // //               'has_spicy': draft.allowSpicy,
// // // // // // // //               'min_players': draft.minPlayers,
// // // // // // // //               'tags': draft.tags,
// // // // // // // //               'cover_image_url': draft.coverImageUrl,
// // // // // // // //             },
// // // // // // // //           );
// // // // // // // //           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
// // // // // // // //           return _rowToEntity(row);
// // // // // // // //         },
// // // // // // // //       );

// // // // // // // //   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
// // // // // // // //       guardedCall(
// // // // // // // //         operationName: 'updatePackDraft',
// // // // // // // //         operation: () async {
// // // // // // // //           final resp = await _api.patch<Map<String, dynamic>>(
// // // // // // // //             '/v1/packs/$packId',
// // // // // // // //             data: {
// // // // // // // //               'title': draft.titleJson,
// // // // // // // //               'description': {'en': draft.descriptionEn},
// // // // // // // //               'price_mru': draft.priceMru,
// // // // // // // //               'category_id': draft.categoryId,
// // // // // // // //               'has_spicy': draft.allowSpicy,
// // // // // // // //               'min_players': draft.minPlayers,
// // // // // // // //               'tags': draft.tags,
// // // // // // // //               'cover_image_url': draft.coverImageUrl,
// // // // // // // //             },
// // // // // // // //           );
// // // // // // // //           return _rowToEntity(
// // // // // // // //             resp.data!['data']['pack'] as Map<String, dynamic>,
// // // // // // // //           );
// // // // // // // //         },
// // // // // // // //       );

// // // // // // // //   Future<PackEntity> submitForReview(String packId) => guardedCall(
// // // // // // // //     operationName: 'submitForReview',
// // // // // // // //     operation: () async {
// // // // // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // // // // //         '/v1/packs/$packId/submit',
// // // // // // // //       );
// // // // // // // //       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
// // // // // // // //     operationName: 'addCards',
// // // // // // // //     operation: () async {
// // // // // // // //       // Delete existing cards then re-insert (replace all)
// // // // // // // //       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

// // // // // // // //       if (cards.isEmpty) return;

// // // // // // // //       final rows = cards
// // // // // // // //           .asMap()
// // // // // // // //           .entries
// // // // // // // //           .map(
// // // // // // // //             (e) => {
// // // // // // // //               'pack_id': packId,
// // // // // // // //               'content': e.value.contentJson,
// // // // // // // //               'card_type': e.value.type.name,
// // // // // // // //               'difficulty': e.value.difficulty.name,
// // // // // // // //               'sort_order': e.key,
// // // // // // // //               'is_active': true,
// // // // // // // //             },
// // // // // // // //           )
// // // // // // // //           .toList();

// // // // // // // //       await _supabase.from('pack_cards').insert(rows);
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   Future<void> deleteCard(String packId, String cardId) => guardedCall(
// // // // // // // //     operationName: 'deleteCard',
// // // // // // // //     operation: () async {
// // // // // // // //       await _supabase
// // // // // // // //           .from('pack_cards')
// // // // // // // //           .delete()
// // // // // // // //           .eq('id', cardId)
// // // // // // // //           .eq('pack_id', packId);
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   /// Request a presigned upload URL from Node.js for Wasabi.
// // // // // // // //   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
// // // // // // // //     required String contentType,
// // // // // // // //     required String fileType, // 'cover' or 'card_image'
// // // // // // // //     required int fileSizeBytes,
// // // // // // // //   }) => guardedCall(
// // // // // // // //     operationName: 'getUploadUrl',
// // // // // // // //     operation: () async {
// // // // // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // // // // //         '/v1/storage/upload-url',
// // // // // // // //         data: {
// // // // // // // //           'file_type': fileType,
// // // // // // // //           'content_type': contentType,
// // // // // // // //           'file_size_bytes': fileSizeBytes,
// // // // // // // //         },
// // // // // // // //       );
// // // // // // // //       final data = resp.data!['data'] as Map<String, dynamic>;
// // // // // // // //       return (
// // // // // // // //         uploadUrl: data['upload_url'] as String,
// // // // // // // //         publicUrl: data['public_url'] as String,
// // // // // // // //       );
// // // // // // // //     },
// // // // // // // //   );

// // // // // // // //   // ── Mappers ────────────────────────────────────────────────────────────────

// // // // // // // //   PackEntity _rowToEntity(Map<String, dynamic> r) {
// // // // // // // //     // Creator profile (joined)
// // // // // // // //     final creator = r['profiles'] as Map<String, dynamic>?;
// // // // // // // //     // Tags (joined)
// // // // // // // //     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
// // // // // // // //     final tags = tagRows.map((t) => t['tag'] as String).toList();

// // // // // // // //     return PackEntity(
// // // // // // // //       id: r['id'] as String,
// // // // // // // //       creatorId: r['creator_id'] as String,
// // // // // // // //       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // // // // //       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
// // // // // // // //       coverImageUrl: r['cover_image_url'] as String?,
// // // // // // // //       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
// // // // // // // //       gameType: r['game_type'] as String? ?? 'truth_or_dare',
// // // // // // // //       language: r['language'] as String? ?? 'en',
// // // // // // // //       isMultilang: r['is_multilang'] as bool? ?? false,
// // // // // // // //       priceMru: r['price_mru'] as int? ?? 0,
// // // // // // // //       cardCount: r['card_count'] as int? ?? 0,
// // // // // // // //       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
// // // // // // // //       totalRatings: r['total_ratings'] as int? ?? 0,
// // // // // // // //       totalPurchases: r['total_purchases'] as int? ?? 0,
// // // // // // // //       totalPlays: r['total_plays'] as int? ?? 0,
// // // // // // // //       downloadUrl: r['download_url'] as String?,
// // // // // // // //       version: r['version'] as int? ?? 1,
// // // // // // // //       hasSpicy: r['has_spicy'] as bool? ?? false,
// // // // // // // //       isFeatured: r['is_featured'] as bool? ?? false,
// // // // // // // //       isPromoted: r['is_promoted'] as bool? ?? false,
// // // // // // // //       categoryId: r['category_id'] as String?,
// // // // // // // //       tags: tags,
// // // // // // // //       publishedAt: r['published_at'] != null
// // // // // // // //           ? DateTime.tryParse(r['published_at'] as String)
// // // // // // // //           : null,
// // // // // // // //       createdAt: r['created_at'] != null
// // // // // // // //           ? DateTime.tryParse(r['created_at'] as String)
// // // // // // // //           : null,
// // // // // // // //       updatedAt: r['updated_at'] != null
// // // // // // // //           ? DateTime.tryParse(r['updated_at'] as String)
// // // // // // // //           : null,
// // // // // // // //       creatorName:
// // // // // // // //           creator?['display_name'] as String? ??
// // // // // // // //           creator?['username'] as String?,
// // // // // // // //       creatorAvatarUrl: creator?['avatar_url'] as String?,
// // // // // // // //       isVerifiedCreator: creator?['verification_status'] == 'verified',
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
// // // // // // // //     id: r['id'] as String,
// // // // // // // //     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // // // // //     slug: r['slug'] as String,
// // // // // // // //     icon: r['icon'] as String? ?? '📦',
// // // // // // // //     sortOrder: r['sort_order'] as int? ?? 0,
// // // // // // // //   );

// // // // // // // //   PackReview _rowToReview(Map<String, dynamic> r) {
// // // // // // // //     final author = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // // //     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
// // // // // // // //     return PackReview(
// // // // // // // //       id: r['id'] as String,
// // // // // // // //       packId: r['pack_id'] as String,
// // // // // // // //       userId: r['user_id'] as String,
// // // // // // // //       content: r['content'] as String,
// // // // // // // //       rating: ratingRow?['rating'] as int?,
// // // // // // // //       authorName: author['display_name'] as String?,
// // // // // // // //       authorAvatarUrl: author['avatar_url'] as String?,
// // // // // // // //       createdAt: DateTime.parse(r['created_at'] as String),
// // // // // // // //     );
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // // import 'package:uuid/uuid.dart';

// // // // // // // import '../../../core/data/base_repository.dart';
// // // // // // // import '../../../core/errors/failures.dart';
// // // // // // // import '../../../core/network/api_client.dart';
// // // // // // // import '../domain/pack_entity.dart';

// // // // // // // export '../domain/pack_entity.dart'; // Barrel re-export for convenience

// // // // // // // const _uuid = Uuid();

// // // // // // // /// All marketplace and pack data operations.
// // // // // // // ///
// // // // // // // /// Read  → Supabase direct (RLS-protected anon key)
// // // // // // // /// Write → Node.js API (service_role business rules)
// // // // // // // class PackRepository extends BaseRepository {
// // // // // // //   PackRepository._();
// // // // // // //   static final PackRepository _instance = PackRepository._();
// // // // // // //   static PackRepository get instance => _instance;

// // // // // // //   final _supabase = Supabase.instance.client;
// // // // // // //   final _api = ApiClient.instance;

// // // // // // //   // ── Browse ─────────────────────────────────────────────────────────────────

// // // // // // //   Future<List<PackEntity>> browsePacks({
// // // // // // //     String? query,
// // // // // // //     String? gameType,
// // // // // // //     String? categoryId,
// // // // // // //     bool freeOnly = false,
// // // // // // //     String? language,
// // // // // // //     String sortBy = 'avg_rating',
// // // // // // //     int page = 0,
// // // // // // //     int perPage = 20,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'browsePacks',
// // // // // // //     operation: () async {
// // // // // // //       var q = _supabase
// // // // // // //           .from('packs')
// // // // // // //           .select('''
// // // // // // //                 id, creator_id, title, description, cover_image_url,
// // // // // // //                 status, game_type, language, is_multilang, price_mru,
// // // // // // //                 card_count, avg_rating, total_ratings, total_purchases,
// // // // // // //                 total_plays, version, has_spicy, is_featured, is_promoted,
// // // // // // //                 category_id, download_url, published_at, created_at,
// // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // // // //               ''')
// // // // // // //           .eq('status', 'approved')
// // // // // // //           .isFilter('deleted_at', null);

// // // // // // //       if (gameType != null) q = q.eq('game_type', gameType);
// // // // // // //       if (categoryId != null) q = q.eq('category_id', categoryId);
// // // // // // //       if (freeOnly) q = q.eq('price_mru', 0);
// // // // // // //       if (language != null && language != 'multi') {
// // // // // // //         q = q.or('language.eq.$language,is_multilang.eq.true');
// // // // // // //       }

// // // // // // //       final rows = await q
// // // // // // //           .order(sortBy, ascending: false)
// // // // // // //           .range(page * perPage, (page + 1) * perPage - 1);

// // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
// // // // // // //     operationName: 'getFeaturedPacks',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('packs')
// // // // // // //           .select('''
// // // // // // //                 id, creator_id, title, description, cover_image_url,
// // // // // // //                 status, game_type, language, price_mru, card_count,
// // // // // // //                 avg_rating, total_ratings, total_purchases, total_plays,
// // // // // // //                 version, has_spicy, is_featured, is_promoted,
// // // // // // //                 category_id, download_url,
// // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // // // //               ''')
// // // // // // //           .eq('status', 'approved')
// // // // // // //           .eq('is_featured', true)
// // // // // // //           .isFilter('deleted_at', null)
// // // // // // //           .order('avg_rating', ascending: false)
// // // // // // //           .limit(10);
// // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
// // // // // // //     operationName: 'getPromotedPacks',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('promoted_packs')
// // // // // // //           .select('packs!pack_id(*), position')
// // // // // // //           .lte('starts_at', DateTime.now().toIso8601String())
// // // // // // //           .gte('ends_at', DateTime.now().toIso8601String())
// // // // // // //           .order('position');

// // // // // // //       return rows
// // // // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // // // //           .toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<PackCategory>> getCategories() => guardedCall(
// // // // // // //     operationName: 'getCategories',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('pack_categories')
// // // // // // //           .select()
// // // // // // //           .eq('is_active', true)
// // // // // // //           .order('sort_order');
// // // // // // //       return rows.map(_rowToCategory).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Detail ─────────────────────────────────────────────────────────────────

// // // // // // //   Future<PackEntity> getPackDetail(String packId) => guardedCall(
// // // // // // //     operationName: 'getPackDetail',
// // // // // // //     operation: () async {
// // // // // // //       final row = await _supabase
// // // // // // //           .from('packs')
// // // // // // //           .select('''
// // // // // // //                 *,
// // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
// // // // // // //                 pack_tags(tag)
// // // // // // //               ''')
// // // // // // //           .eq('id', packId)
// // // // // // //           .single();
// // // // // // //       return _rowToEntity(row);
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<PackReview>> getPackReviews(
// // // // // // //     String packId, {
// // // // // // //     int limit = 20,
// // // // // // //     int page = 0,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'getPackReviews',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('pack_reviews')
// // // // // // //           .select('''
// // // // // // //                 id, pack_id, user_id, content, created_at,
// // // // // // //                 profiles!user_id(display_name, avatar_url),
// // // // // // //                 pack_ratings!rating_id(rating)
// // // // // // //               ''')
// // // // // // //           .eq('pack_id', packId)
// // // // // // //           .eq('is_visible', true)
// // // // // // //           .order('created_at', ascending: false)
// // // // // // //           .range(page * limit, (page + 1) * limit - 1);

// // // // // // //       return rows.map(_rowToReview).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<PackRating?> getMyRating(String packId, String userId) =>
// // // // // // //       softCall<PackRating?>(
// // // // // // //         operationName: 'getMyRating',
// // // // // // //         operation: () async {
// // // // // // //           final row = await _supabase
// // // // // // //               .from('pack_ratings')
// // // // // // //               .select()
// // // // // // //               .eq('pack_id', packId)
// // // // // // //               .eq('user_id', userId)
// // // // // // //               .maybeSingle();
// // // // // // //           if (row == null) return null;
// // // // // // //           return PackRating(
// // // // // // //             packId: row['pack_id'] as String,
// // // // // // //             userId: row['user_id'] as String,
// // // // // // //             rating: row['rating'] as int,
// // // // // // //           );
// // // // // // //         },
// // // // // // //       );

// // // // // // //   // ── Purchases ──────────────────────────────────────────────────────────────

// // // // // // //   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
// // // // // // //     operationName: 'getMyPurchasedPacks',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('pack_purchases')
// // // // // // //           .select('pack_id, purchased_at, expires_at, packs(*)')
// // // // // // //           .eq('buyer_id', userId)
// // // // // // //           .eq('status', 'completed')
// // // // // // //           // Include rows where expires_at is null (permanent) OR in the future
// // // // // // //           .or(
// // // // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // // // //           )
// // // // // // //           .order('purchased_at', ascending: false);

// // // // // // //       return rows
// // // // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // // // //           .toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
// // // // // // //     operationName: 'getPurchaseRecords',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('pack_purchases')
// // // // // // //           .select('pack_id, purchased_at, expires_at, price_paid_mru')
// // // // // // //           .eq('buyer_id', userId)
// // // // // // //           .eq('status', 'completed')
// // // // // // //           .or(
// // // // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // // // //           );

// // // // // // //       return rows
// // // // // // //           .map(
// // // // // // //             (r) => PackPurchase(
// // // // // // //               packId: r['pack_id'] as String,
// // // // // // //               purchasedAt: DateTime.parse(r['purchased_at'] as String),
// // // // // // //               expiresAt: DateTime.parse(r['expires_at'] as String),
// // // // // // //               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// // // // // // //             ),
// // // // // // //           )
// // // // // // //           .toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
// // // // // // //     operationName: 'hasPurchased',
// // // // // // //     operation: () async {
// // // // // // //       final row = await _supabase
// // // // // // //           .from('pack_purchases')
// // // // // // //           .select('id')
// // // // // // //           .eq('pack_id', packId)
// // // // // // //           .eq('buyer_id', userId)
// // // // // // //           .eq('status', 'completed')
// // // // // // //           .gt('expires_at', DateTime.now().toIso8601String())
// // // // // // //           .maybeSingle();
// // // // // // //       return row != null;
// // // // // // //     },
// // // // // // //   );

// // // // // // //   /// Purchase a pack via Node.js API (uses service_role to bypass RLS).
// // // // // // //   /// RLS policy "pack_purchases: no client insert" blocks direct Supabase writes.
// // // // // // //   Future<void> purchasePack(String packId) => guardedCall(
// // // // // // //     operationName: 'purchasePack',
// // // // // // //     operation: () async {
// // // // // // //       final response = await _api.post(
// // // // // // //         '/v1/packs/purchase',
// // // // // // //         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
// // // // // // //       );
// // // // // // //       final data = response.data as Map<String, dynamic>?;
// // // // // // //       final error = data?['error'] as String?;
// // // // // // //       if (error != null) throw Exception(error);
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Ratings & Reviews ──────────────────────────────────────────────────────

// // // // // // //   Future<void> ratePack({
// // // // // // //     required String packId,
// // // // // // //     required String userId,
// // // // // // //     required int rating,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'ratePack',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase.from('pack_ratings').upsert({
// // // // // // //         'user_id': userId,
// // // // // // //         'pack_id': packId,
// // // // // // //         'rating': rating,
// // // // // // //       }, onConflict: 'pack_id,user_id');
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> submitReview({
// // // // // // //     required String packId,
// // // // // // //     required String userId,
// // // // // // //     required String content,
// // // // // // //     int? rating,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'submitReview',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase.from('pack_reviews').upsert({
// // // // // // //         'id': _uuid.v4(),
// // // // // // //         'pack_id': packId,
// // // // // // //         'user_id': userId,
// // // // // // //         'content': content,
// // // // // // //       }, onConflict: 'pack_id,user_id');
// // // // // // //       if (rating != null) {
// // // // // // //         await ratePack(packId: packId, userId: userId, rating: rating);
// // // // // // //       }
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> reportPack({
// // // // // // //     required String packId,
// // // // // // //     required String reporterId,
// // // // // // //     required String reason,
// // // // // // //     String? details,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'reportPack',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase.from('pack_reports').upsert({
// // // // // // //         'pack_id': packId,
// // // // // // //         'reporter_id': reporterId,
// // // // // // //         'reason': reason,
// // // // // // //         'details': details,
// // // // // // //       }, onConflict: 'pack_id,reporter_id');
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Creator operations ─────────────────────────────────────────────────────

// // // // // // //   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
// // // // // // //       guardedCall(
// // // // // // //         operationName: 'savePackReactions',
// // // // // // //         operation: () async {
// // // // // // //           await _api.post(
// // // // // // //             '/v1/packs/$packId/reactions',
// // // // // // //             data: {
// // // // // // //               'reactions': imageUrls
// // // // // // //                   .asMap()
// // // // // // //                   .entries
// // // // // // //                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
// // // // // // //                   .toList(),
// // // // // // //             },
// // // // // // //           );
// // // // // // //         },
// // // // // // //       );

// // // // // // //   Future<List<String>> getPackReactions(String packId) => guardedCall(
// // // // // // //     operationName: 'getPackReactions',
// // // // // // //     operation: () async {
// // // // // // //       try {
// // // // // // //         // Try API first (bypasses RLS — works for all pack statuses)
// // // // // // //         final response = await _api.get('/v1/packs/$packId/reactions');
// // // // // // //         final data = response.data as Map<String, dynamic>?;
// // // // // // //         final reactions = data?['data']?['reactions'] as List?;
// // // // // // //         if (reactions != null) {
// // // // // // //           return reactions.map((r) => r['image_url'] as String).toList();
// // // // // // //         }
// // // // // // //       } catch (_) {
// // // // // // //         // Fallback to direct Supabase if API fails
// // // // // // //       }
// // // // // // //       // Fallback: direct Supabase (works if RLS allows it)
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('pack_reactions')
// // // // // // //           .select('image_url')
// // // // // // //           .eq('pack_id', packId)
// // // // // // //           .order('sort_order');
// // // // // // //       return (rows as List).map((r) => r['image_url'] as String).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
// // // // // // //     operationName: 'getMyCreatedPacks',
// // // // // // //     operation: () async {
// // // // // // //       final rows = await _supabase
// // // // // // //           .from('packs')
// // // // // // //           .select()
// // // // // // //           .eq('creator_id', creatorId)
// // // // // // //           .isFilter('deleted_at', null)
// // // // // // //           .order('created_at', ascending: false);
// // // // // // //       return rows.map(_rowToEntity).toList();
// // // // // // //     },
// // // // // // //   );

// // // // // // //   /// Create a pack draft (via Node.js for service_role insert).
// // // // // // //   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
// // // // // // //       guardedCall(
// // // // // // //         operationName: 'createPackDraft',
// // // // // // //         operation: () async {
// // // // // // //           final resp = await _api.post<Map<String, dynamic>>(
// // // // // // //             '/v1/packs/create',
// // // // // // //             data: {
// // // // // // //               'title': draft.titleJson,
// // // // // // //               'description': {'en': draft.descriptionEn},
// // // // // // //               'game_type': draft.gameType,
// // // // // // //               'language': draft.language,
// // // // // // //               'price_mru': draft.priceMru,
// // // // // // //               'category_id': draft.categoryId,
// // // // // // //               'has_spicy': draft.allowSpicy,
// // // // // // //               'min_players': draft.minPlayers,
// // // // // // //               'tags': draft.tags,
// // // // // // //               'cover_image_url': draft.coverImageUrl,
// // // // // // //             },
// // // // // // //           );
// // // // // // //           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
// // // // // // //           return _rowToEntity(row);
// // // // // // //         },
// // // // // // //       );

// // // // // // //   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
// // // // // // //       guardedCall(
// // // // // // //         operationName: 'updatePackDraft',
// // // // // // //         operation: () async {
// // // // // // //           final resp = await _api.patch<Map<String, dynamic>>(
// // // // // // //             '/v1/packs/$packId',
// // // // // // //             data: {
// // // // // // //               'title': draft.titleJson,
// // // // // // //               'description': {'en': draft.descriptionEn},
// // // // // // //               'price_mru': draft.priceMru,
// // // // // // //               'category_id': draft.categoryId,
// // // // // // //               'has_spicy': draft.allowSpicy,
// // // // // // //               'min_players': draft.minPlayers,
// // // // // // //               'tags': draft.tags,
// // // // // // //               'cover_image_url': draft.coverImageUrl,
// // // // // // //             },
// // // // // // //           );
// // // // // // //           return _rowToEntity(
// // // // // // //             resp.data!['data']['pack'] as Map<String, dynamic>,
// // // // // // //           );
// // // // // // //         },
// // // // // // //       );

// // // // // // //   Future<PackEntity> submitForReview(String packId) => guardedCall(
// // // // // // //     operationName: 'submitForReview',
// // // // // // //     operation: () async {
// // // // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // // // //         '/v1/packs/$packId/submit',
// // // // // // //       );
// // // // // // //       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
// // // // // // //     operationName: 'addCards',
// // // // // // //     operation: () async {
// // // // // // //       // Delete existing cards then re-insert (replace all)
// // // // // // //       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

// // // // // // //       if (cards.isEmpty) return;

// // // // // // //       final rows = cards
// // // // // // //           .asMap()
// // // // // // //           .entries
// // // // // // //           .map(
// // // // // // //             (e) => {
// // // // // // //               'pack_id': packId,
// // // // // // //               'content': e.value.contentJson,
// // // // // // //               'card_type': e.value.type.name,
// // // // // // //               'difficulty': e.value.difficulty.name,
// // // // // // //               'sort_order': e.key,
// // // // // // //               'is_active': true,
// // // // // // //             },
// // // // // // //           )
// // // // // // //           .toList();

// // // // // // //       await _supabase.from('pack_cards').insert(rows);
// // // // // // //     },
// // // // // // //   );

// // // // // // //   Future<void> deleteCard(String packId, String cardId) => guardedCall(
// // // // // // //     operationName: 'deleteCard',
// // // // // // //     operation: () async {
// // // // // // //       await _supabase
// // // // // // //           .from('pack_cards')
// // // // // // //           .delete()
// // // // // // //           .eq('id', cardId)
// // // // // // //           .eq('pack_id', packId);
// // // // // // //     },
// // // // // // //   );

// // // // // // //   /// Request a presigned upload URL from Node.js for Wasabi.
// // // // // // //   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
// // // // // // //     required String contentType,
// // // // // // //     required String fileType, // 'cover' or 'card_image'
// // // // // // //     required int fileSizeBytes,
// // // // // // //   }) => guardedCall(
// // // // // // //     operationName: 'getUploadUrl',
// // // // // // //     operation: () async {
// // // // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // // // //         '/v1/storage/upload-url',
// // // // // // //         data: {
// // // // // // //           'file_type': fileType,
// // // // // // //           'content_type': contentType,
// // // // // // //           'file_size_bytes': fileSizeBytes,
// // // // // // //         },
// // // // // // //       );
// // // // // // //       final data = resp.data!['data'] as Map<String, dynamic>;
// // // // // // //       return (
// // // // // // //         uploadUrl: data['upload_url'] as String,
// // // // // // //         publicUrl: data['public_url'] as String,
// // // // // // //       );
// // // // // // //     },
// // // // // // //   );

// // // // // // //   // ── Mappers ────────────────────────────────────────────────────────────────

// // // // // // //   PackEntity _rowToEntity(Map<String, dynamic> r) {
// // // // // // //     // Creator profile (joined)
// // // // // // //     final creator = r['profiles'] as Map<String, dynamic>?;
// // // // // // //     // Tags (joined)
// // // // // // //     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
// // // // // // //     final tags = tagRows.map((t) => t['tag'] as String).toList();

// // // // // // //     return PackEntity(
// // // // // // //       id: r['id'] as String,
// // // // // // //       creatorId: r['creator_id'] as String,
// // // // // // //       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // // // //       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
// // // // // // //       coverImageUrl: r['cover_image_url'] as String?,
// // // // // // //       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
// // // // // // //       gameType: r['game_type'] as String? ?? 'truth_or_dare',
// // // // // // //       language: r['language'] as String? ?? 'en',
// // // // // // //       isMultilang: r['is_multilang'] as bool? ?? false,
// // // // // // //       availableLanguages: _parseAvailableLanguages(r),
// // // // // // //       priceMru: r['price_mru'] as int? ?? 0,
// // // // // // //       cardCount: r['card_count'] as int? ?? 0,
// // // // // // //       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
// // // // // // //       totalRatings: r['total_ratings'] as int? ?? 0,
// // // // // // //       totalPurchases: r['total_purchases'] as int? ?? 0,
// // // // // // //       totalPlays: r['total_plays'] as int? ?? 0,
// // // // // // //       downloadUrl: r['download_url'] as String?,
// // // // // // //       version: r['version'] as int? ?? 1,
// // // // // // //       hasSpicy: r['has_spicy'] as bool? ?? false,
// // // // // // //       isFeatured: r['is_featured'] as bool? ?? false,
// // // // // // //       isPromoted: r['is_promoted'] as bool? ?? false,
// // // // // // //       categoryId: r['category_id'] as String?,
// // // // // // //       tags: tags,
// // // // // // //       publishedAt: r['published_at'] != null
// // // // // // //           ? DateTime.tryParse(r['published_at'] as String)
// // // // // // //           : null,
// // // // // // //       createdAt: r['created_at'] != null
// // // // // // //           ? DateTime.tryParse(r['created_at'] as String)
// // // // // // //           : null,
// // // // // // //       updatedAt: r['updated_at'] != null
// // // // // // //           ? DateTime.tryParse(r['updated_at'] as String)
// // // // // // //           : null,
// // // // // // //       creatorName:
// // // // // // //           creator?['display_name'] as String? ??
// // // // // // //           creator?['username'] as String?,
// // // // // // //       creatorAvatarUrl: creator?['avatar_url'] as String?,
// // // // // // //       isVerifiedCreator: creator?['verification_status'] == 'verified',
// // // // // // //     );
// // // // // // //   }

// // // // // // //   /// Parse available_languages from DB row.
// // // // // // //   /// Falls back to computing from language/is_multilang if column not present.
// // // // // // //   List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
// // // // // // //     final raw = r['available_languages'];
// // // // // // //     if (raw is List && raw.isNotEmpty) {
// // // // // // //       return raw.map((e) => e.toString()).toList();
// // // // // // //     }
// // // // // // //     // Fallback: derive from language field
// // // // // // //     final lang = r['language'] as String? ?? 'en';
// // // // // // //     final multilang = r['is_multilang'] as bool? ?? false;
// // // // // // //     if (multilang || lang == 'multi') return ['en', 'ar', 'fr'];
// // // // // // //     return [lang];
// // // // // // //   }

// // // // // // //   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
// // // // // // //     id: r['id'] as String,
// // // // // // //     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // // // //     slug: r['slug'] as String,
// // // // // // //     icon: r['icon'] as String? ?? '📦',
// // // // // // //     sortOrder: r['sort_order'] as int? ?? 0,
// // // // // // //   );

// // // // // // //   PackReview _rowToReview(Map<String, dynamic> r) {
// // // // // // //     final author = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // // //     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
// // // // // // //     return PackReview(
// // // // // // //       id: r['id'] as String,
// // // // // // //       packId: r['pack_id'] as String,
// // // // // // //       userId: r['user_id'] as String,
// // // // // // //       content: r['content'] as String,
// // // // // // //       rating: ratingRow?['rating'] as int?,
// // // // // // //       authorName: author['display_name'] as String?,
// // // // // // //       authorAvatarUrl: author['avatar_url'] as String?,
// // // // // // //       createdAt: DateTime.parse(r['created_at'] as String),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // // import 'package:uuid/uuid.dart';

// // // // // // import '../../../core/data/base_repository.dart';
// // // // // // import '../../../core/errors/failures.dart';
// // // // // // import '../../../core/network/api_client.dart';
// // // // // // import '../domain/pack_entity.dart';

// // // // // // export '../domain/pack_entity.dart'; // Barrel re-export for convenience

// // // // // // const _uuid = Uuid();

// // // // // // /// All marketplace and pack data operations.
// // // // // // ///
// // // // // // /// Read  → Supabase direct (RLS-protected anon key)
// // // // // // /// Write → Node.js API (service_role business rules)
// // // // // // class PackRepository extends BaseRepository {
// // // // // //   PackRepository._();
// // // // // //   static final PackRepository _instance = PackRepository._();
// // // // // //   static PackRepository get instance => _instance;

// // // // // //   final _supabase = Supabase.instance.client;
// // // // // //   final _api = ApiClient.instance;

// // // // // //   // ── Browse ─────────────────────────────────────────────────────────────────

// // // // // //   Future<List<PackEntity>> browsePacks({
// // // // // //     String? query,
// // // // // //     String? gameType,
// // // // // //     String? categoryId,
// // // // // //     bool freeOnly = false,
// // // // // //     String? language,
// // // // // //     String sortBy = 'avg_rating',
// // // // // //     int page = 0,
// // // // // //     int perPage = 20,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'browsePacks',
// // // // // //     operation: () async {
// // // // // //       var q = _supabase
// // // // // //           .from('packs')
// // // // // //           .select('''
// // // // // //                 id, creator_id, title, description, cover_image_url,
// // // // // //                 status, game_type, language, is_multilang, price_mru,
// // // // // //                 card_count, avg_rating, total_ratings, total_purchases,
// // // // // //                 total_plays, version, has_spicy, is_featured, is_promoted,
// // // // // //                 category_id, download_url, published_at, created_at,
// // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // // //               ''')
// // // // // //           .eq('status', 'approved')
// // // // // //           .isFilter('deleted_at', null);

// // // // // //       if (gameType != null) q = q.eq('game_type', gameType);
// // // // // //       if (categoryId != null) q = q.eq('category_id', categoryId);
// // // // // //       if (freeOnly) q = q.eq('price_mru', 0);
// // // // // //       if (language != null && language != 'multi') {
// // // // // //         q = q.or('language.eq.$language,is_multilang.eq.true');
// // // // // //       }

// // // // // //       final rows = await q
// // // // // //           .order(sortBy, ascending: false)
// // // // // //           .range(page * perPage, (page + 1) * perPage - 1);

// // // // // //       return rows.map(_rowToEntity).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
// // // // // //     operationName: 'getFeaturedPacks',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('packs')
// // // // // //           .select('''
// // // // // //                 id, creator_id, title, description, cover_image_url,
// // // // // //                 status, game_type, language, price_mru, card_count,
// // // // // //                 avg_rating, total_ratings, total_purchases, total_plays,
// // // // // //                 version, has_spicy, is_featured, is_promoted,
// // // // // //                 category_id, download_url,
// // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // // //               ''')
// // // // // //           .eq('status', 'approved')
// // // // // //           .eq('is_featured', true)
// // // // // //           .isFilter('deleted_at', null)
// // // // // //           .order('avg_rating', ascending: false)
// // // // // //           .limit(10);
// // // // // //       return rows.map(_rowToEntity).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
// // // // // //     operationName: 'getPromotedPacks',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('promoted_packs')
// // // // // //           .select('packs!pack_id(*), position')
// // // // // //           .lte('starts_at', DateTime.now().toIso8601String())
// // // // // //           .gte('ends_at', DateTime.now().toIso8601String())
// // // // // //           .order('position');

// // // // // //       return rows
// // // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // // //           .toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<PackCategory>> getCategories() => guardedCall(
// // // // // //     operationName: 'getCategories',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('pack_categories')
// // // // // //           .select()
// // // // // //           .eq('is_active', true)
// // // // // //           .order('sort_order');
// // // // // //       return rows.map(_rowToCategory).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Detail ─────────────────────────────────────────────────────────────────

// // // // // //   Future<PackEntity> getPackDetail(String packId) => guardedCall(
// // // // // //     operationName: 'getPackDetail',
// // // // // //     operation: () async {
// // // // // //       final row = await _supabase
// // // // // //           .from('packs')
// // // // // //           .select('''
// // // // // //                 *,
// // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
// // // // // //                 pack_tags(tag)
// // // // // //               ''')
// // // // // //           .eq('id', packId)
// // // // // //           .single();
// // // // // //       return _rowToEntity(row);
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<PackReview>> getPackReviews(
// // // // // //     String packId, {
// // // // // //     int limit = 20,
// // // // // //     int page = 0,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'getPackReviews',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('pack_reviews')
// // // // // //           .select('''
// // // // // //                 id, pack_id, user_id, content, created_at,
// // // // // //                 profiles!user_id(display_name, avatar_url),
// // // // // //                 pack_ratings!rating_id(rating)
// // // // // //               ''')
// // // // // //           .eq('pack_id', packId)
// // // // // //           .eq('is_visible', true)
// // // // // //           .order('created_at', ascending: false)
// // // // // //           .range(page * limit, (page + 1) * limit - 1);

// // // // // //       return rows.map(_rowToReview).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<PackRating?> getMyRating(String packId, String userId) =>
// // // // // //       softCall<PackRating?>(
// // // // // //         operationName: 'getMyRating',
// // // // // //         operation: () async {
// // // // // //           final row = await _supabase
// // // // // //               .from('pack_ratings')
// // // // // //               .select()
// // // // // //               .eq('pack_id', packId)
// // // // // //               .eq('user_id', userId)
// // // // // //               .maybeSingle();
// // // // // //           if (row == null) return null;
// // // // // //           return PackRating(
// // // // // //             packId: row['pack_id'] as String,
// // // // // //             userId: row['user_id'] as String,
// // // // // //             rating: row['rating'] as int,
// // // // // //           );
// // // // // //         },
// // // // // //       );

// // // // // //   // ── Purchases ──────────────────────────────────────────────────────────────

// // // // // //   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
// // // // // //     operationName: 'getMyPurchasedPacks',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('pack_purchases')
// // // // // //           .select('pack_id, purchased_at, expires_at, packs(*)')
// // // // // //           .eq('buyer_id', userId)
// // // // // //           .eq('status', 'completed')
// // // // // //           // Include rows where expires_at is null (permanent) OR in the future
// // // // // //           .or(
// // // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // // //           )
// // // // // //           .order('purchased_at', ascending: false);

// // // // // //       return rows
// // // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // // //           .toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
// // // // // //     operationName: 'getPurchaseRecords',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('pack_purchases')
// // // // // //           .select('pack_id, purchased_at, expires_at, price_paid_mru')
// // // // // //           .eq('buyer_id', userId)
// // // // // //           .eq('status', 'completed')
// // // // // //           .or(
// // // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // // //           );

// // // // // //       return rows
// // // // // //           .map(
// // // // // //             (r) => PackPurchase(
// // // // // //               packId: r['pack_id'] as String,
// // // // // //               purchasedAt: DateTime.parse(r['purchased_at'] as String),
// // // // // //               expiresAt: DateTime.parse(r['expires_at'] as String),
// // // // // //               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// // // // // //             ),
// // // // // //           )
// // // // // //           .toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
// // // // // //     operationName: 'hasPurchased',
// // // // // //     operation: () async {
// // // // // //       final row = await _supabase
// // // // // //           .from('pack_purchases')
// // // // // //           .select('id')
// // // // // //           .eq('pack_id', packId)
// // // // // //           .eq('buyer_id', userId)
// // // // // //           .eq('status', 'completed')
// // // // // //           .gt('expires_at', DateTime.now().toIso8601String())
// // // // // //           .maybeSingle();
// // // // // //       return row != null;
// // // // // //     },
// // // // // //   );

// // // // // //   /// Purchase a pack via Node.js API (uses service_role to bypass RLS).
// // // // // //   /// RLS policy "pack_purchases: no client insert" blocks direct Supabase writes.
// // // // // //   Future<void> purchasePack(String packId) => guardedCall(
// // // // // //     operationName: 'purchasePack',
// // // // // //     operation: () async {
// // // // // //       final response = await _api.post(
// // // // // //         '/v1/packs/purchase',
// // // // // //         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
// // // // // //       );
// // // // // //       final data = response.data as Map<String, dynamic>?;
// // // // // //       final error = data?['error'] as String?;
// // // // // //       if (error != null) throw Exception(error);
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Ratings & Reviews ──────────────────────────────────────────────────────

// // // // // //   Future<void> ratePack({
// // // // // //     required String packId,
// // // // // //     required String userId,
// // // // // //     required int rating,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'ratePack',
// // // // // //     operation: () async {
// // // // // //       await _supabase.from('pack_ratings').upsert({
// // // // // //         'user_id': userId,
// // // // // //         'pack_id': packId,
// // // // // //         'rating': rating,
// // // // // //       }, onConflict: 'pack_id,user_id');
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> submitReview({
// // // // // //     required String packId,
// // // // // //     required String userId,
// // // // // //     required String content,
// // // // // //     int? rating,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'submitReview',
// // // // // //     operation: () async {
// // // // // //       await _supabase.from('pack_reviews').upsert({
// // // // // //         'id': _uuid.v4(),
// // // // // //         'pack_id': packId,
// // // // // //         'user_id': userId,
// // // // // //         'content': content,
// // // // // //       }, onConflict: 'pack_id,user_id');
// // // // // //       if (rating != null) {
// // // // // //         await ratePack(packId: packId, userId: userId, rating: rating);
// // // // // //       }
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> reportPack({
// // // // // //     required String packId,
// // // // // //     required String reporterId,
// // // // // //     required String reason,
// // // // // //     String? details,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'reportPack',
// // // // // //     operation: () async {
// // // // // //       await _supabase.from('pack_reports').upsert({
// // // // // //         'pack_id': packId,
// // // // // //         'reporter_id': reporterId,
// // // // // //         'reason': reason,
// // // // // //         'details': details,
// // // // // //       }, onConflict: 'pack_id,reporter_id');
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Creator operations ─────────────────────────────────────────────────────

// // // // // //   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
// // // // // //       guardedCall(
// // // // // //         operationName: 'savePackReactions',
// // // // // //         operation: () async {
// // // // // //           await _api.post(
// // // // // //             '/v1/packs/$packId/reactions',
// // // // // //             data: {
// // // // // //               'reactions': imageUrls
// // // // // //                   .asMap()
// // // // // //                   .entries
// // // // // //                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
// // // // // //                   .toList(),
// // // // // //             },
// // // // // //           );
// // // // // //         },
// // // // // //       );

// // // // // //   Future<List<String>> getPackReactions(String packId) => guardedCall(
// // // // // //     operationName: 'getPackReactions',
// // // // // //     operation: () async {
// // // // // //       try {
// // // // // //         // Try API first (bypasses RLS — works for all pack statuses)
// // // // // //         final response = await _api.get('/v1/packs/$packId/reactions');
// // // // // //         final data = response.data as Map<String, dynamic>?;
// // // // // //         final reactions = data?['data']?['reactions'] as List?;
// // // // // //         if (reactions != null) {
// // // // // //           return reactions.map((r) => r['image_url'] as String).toList();
// // // // // //         }
// // // // // //       } catch (_) {
// // // // // //         // Fallback to direct Supabase if API fails
// // // // // //       }
// // // // // //       // Fallback: direct Supabase (works if RLS allows it)
// // // // // //       final rows = await _supabase
// // // // // //           .from('pack_reactions')
// // // // // //           .select('image_url')
// // // // // //           .eq('pack_id', packId)
// // // // // //           .order('sort_order');
// // // // // //       return (rows as List).map((r) => r['image_url'] as String).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
// // // // // //     operationName: 'getMyCreatedPacks',
// // // // // //     operation: () async {
// // // // // //       final rows = await _supabase
// // // // // //           .from('packs')
// // // // // //           .select()
// // // // // //           .eq('creator_id', creatorId)
// // // // // //           .isFilter('deleted_at', null)
// // // // // //           .order('created_at', ascending: false);
// // // // // //       return rows.map(_rowToEntity).toList();
// // // // // //     },
// // // // // //   );

// // // // // //   /// Create a pack draft (via Node.js for service_role insert).
// // // // // //   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
// // // // // //       guardedCall(
// // // // // //         operationName: 'createPackDraft',
// // // // // //         operation: () async {
// // // // // //           final resp = await _api.post<Map<String, dynamic>>(
// // // // // //             '/v1/packs/create',
// // // // // //             data: {
// // // // // //               'title': draft.titleJson,
// // // // // //               'description': {'en': draft.descriptionEn},
// // // // // //               'game_type': draft.gameType,
// // // // // //               'language': draft.language,
// // // // // //               'price_mru': draft.priceMru,
// // // // // //               'category_id': draft.categoryId,
// // // // // //               'has_spicy': draft.allowSpicy,
// // // // // //               'min_players': draft.minPlayers,
// // // // // //               'tags': draft.tags,
// // // // // //               'cover_image_url': draft.coverImageUrl,
// // // // // //             },
// // // // // //           );
// // // // // //           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
// // // // // //           return _rowToEntity(row);
// // // // // //         },
// // // // // //       );

// // // // // //   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
// // // // // //       guardedCall(
// // // // // //         operationName: 'updatePackDraft',
// // // // // //         operation: () async {
// // // // // //           final resp = await _api.patch<Map<String, dynamic>>(
// // // // // //             '/v1/packs/$packId',
// // // // // //             data: {
// // // // // //               'title': draft.titleJson,
// // // // // //               'description': {'en': draft.descriptionEn},
// // // // // //               'price_mru': draft.priceMru,
// // // // // //               'category_id': draft.categoryId,
// // // // // //               'has_spicy': draft.allowSpicy,
// // // // // //               'min_players': draft.minPlayers,
// // // // // //               'tags': draft.tags,
// // // // // //               'cover_image_url': draft.coverImageUrl,
// // // // // //             },
// // // // // //           );
// // // // // //           return _rowToEntity(
// // // // // //             resp.data!['data']['pack'] as Map<String, dynamic>,
// // // // // //           );
// // // // // //         },
// // // // // //       );

// // // // // //   Future<PackEntity> submitForReview(String packId) => guardedCall(
// // // // // //     operationName: 'submitForReview',
// // // // // //     operation: () async {
// // // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // // //         '/v1/packs/$packId/submit',
// // // // // //       );
// // // // // //       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
// // // // // //     operationName: 'addCards',
// // // // // //     operation: () async {
// // // // // //       // Delete existing cards then re-insert (replace all)
// // // // // //       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

// // // // // //       if (cards.isEmpty) return;

// // // // // //       final rows = cards
// // // // // //           .asMap()
// // // // // //           .entries
// // // // // //           .map(
// // // // // //             (e) => {
// // // // // //               'pack_id': packId,
// // // // // //               'content': e.value.contentJson,
// // // // // //               'card_type': e.value.type.name,
// // // // // //               'difficulty': e.value.difficulty.name,
// // // // // //               'sort_order': e.key,
// // // // // //               'is_active': true,
// // // // // //             },
// // // // // //           )
// // // // // //           .toList();

// // // // // //       await _supabase.from('pack_cards').insert(rows);
// // // // // //     },
// // // // // //   );

// // // // // //   Future<void> deleteCard(String packId, String cardId) => guardedCall(
// // // // // //     operationName: 'deleteCard',
// // // // // //     operation: () async {
// // // // // //       await _supabase
// // // // // //           .from('pack_cards')
// // // // // //           .delete()
// // // // // //           .eq('id', cardId)
// // // // // //           .eq('pack_id', packId);
// // // // // //     },
// // // // // //   );

// // // // // //   /// For each pack, returns only the languages that EVERY active card
// // // // // //   /// actually has non-empty content for — not just the languages the
// // // // // //   /// pack metadata (title/available_languages) claims to support.
// // // // // //   ///
// // // // // //   /// Used to filter the room's pack picker so a selected language never
// // // // // //   /// silently falls back to English mid-game because a card was missed
// // // // // //   /// when the creator filled in translations.
// // // // // //   Future<Map<String, Set<String>>> getCardLanguageCoverage(
// // // // // //     List<String> packIds,
// // // // // //   ) => guardedCall(
// // // // // //     operationName: 'getCardLanguageCoverage',
// // // // // //     operation: () async {
// // // // // //       if (packIds.isEmpty) return <String, Set<String>>{};

// // // // // //       final rows = await _supabase
// // // // // //           .from('pack_cards')
// // // // // //           .select('pack_id, content')
// // // // // //           .inFilter('pack_id', packIds)
// // // // // //           .eq('is_active', true);

// // // // // //       // pack_id → intersection of language keys present (non-empty) on
// // // // // //       // every card seen so far for that pack.
// // // // // //       final coverage = <String, Set<String>>{};
// // // // // //       final seenAnyCard = <String>{};

// // // // // //       for (final r in rows) {
// // // // // //         final packId = r['pack_id'] as String;
// // // // // //         final content = r['content'] as Map<String, dynamic>? ?? {};
// // // // // //         final cardLangs = content.entries
// // // // // //             .where((e) => (e.value as String?)?.trim().isNotEmpty ?? false)
// // // // // //             .map((e) => e.key)
// // // // // //             .toSet();

// // // // // //         if (seenAnyCard.add(packId)) {
// // // // // //           coverage[packId] = cardLangs;
// // // // // //         } else {
// // // // // //           coverage[packId] = coverage[packId]!.intersection(cardLangs);
// // // // // //         }
// // // // // //       }

// // // // // //       return coverage;
// // // // // //     },
// // // // // //   );

// // // // // //   /// Request a presigned upload URL from Node.js for Wasabi.
// // // // // //   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
// // // // // //     required String contentType,
// // // // // //     required String fileType, // 'cover' or 'card_image'
// // // // // //     required int fileSizeBytes,
// // // // // //   }) => guardedCall(
// // // // // //     operationName: 'getUploadUrl',
// // // // // //     operation: () async {
// // // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // // //         '/v1/storage/upload-url',
// // // // // //         data: {
// // // // // //           'file_type': fileType,
// // // // // //           'content_type': contentType,
// // // // // //           'file_size_bytes': fileSizeBytes,
// // // // // //         },
// // // // // //       );
// // // // // //       final data = resp.data!['data'] as Map<String, dynamic>;
// // // // // //       return (
// // // // // //         uploadUrl: data['upload_url'] as String,
// // // // // //         publicUrl: data['public_url'] as String,
// // // // // //       );
// // // // // //     },
// // // // // //   );

// // // // // //   // ── Mappers ────────────────────────────────────────────────────────────────

// // // // // //   PackEntity _rowToEntity(Map<String, dynamic> r) {
// // // // // //     // Creator profile (joined)
// // // // // //     final creator = r['profiles'] as Map<String, dynamic>?;
// // // // // //     // Tags (joined)
// // // // // //     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
// // // // // //     final tags = tagRows.map((t) => t['tag'] as String).toList();

// // // // // //     return PackEntity(
// // // // // //       id: r['id'] as String,
// // // // // //       creatorId: r['creator_id'] as String,
// // // // // //       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // // //       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
// // // // // //       coverImageUrl: r['cover_image_url'] as String?,
// // // // // //       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
// // // // // //       gameType: r['game_type'] as String? ?? 'truth_or_dare',
// // // // // //       language: r['language'] as String? ?? 'en',
// // // // // //       isMultilang: r['is_multilang'] as bool? ?? false,
// // // // // //       availableLanguages: _parseAvailableLanguages(r),
// // // // // //       priceMru: r['price_mru'] as int? ?? 0,
// // // // // //       cardCount: r['card_count'] as int? ?? 0,
// // // // // //       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
// // // // // //       totalRatings: r['total_ratings'] as int? ?? 0,
// // // // // //       totalPurchases: r['total_purchases'] as int? ?? 0,
// // // // // //       totalPlays: r['total_plays'] as int? ?? 0,
// // // // // //       downloadUrl: r['download_url'] as String?,
// // // // // //       version: r['version'] as int? ?? 1,
// // // // // //       hasSpicy: r['has_spicy'] as bool? ?? false,
// // // // // //       isFeatured: r['is_featured'] as bool? ?? false,
// // // // // //       isPromoted: r['is_promoted'] as bool? ?? false,
// // // // // //       categoryId: r['category_id'] as String?,
// // // // // //       tags: tags,
// // // // // //       publishedAt: r['published_at'] != null
// // // // // //           ? DateTime.tryParse(r['published_at'] as String)
// // // // // //           : null,
// // // // // //       createdAt: r['created_at'] != null
// // // // // //           ? DateTime.tryParse(r['created_at'] as String)
// // // // // //           : null,
// // // // // //       updatedAt: r['updated_at'] != null
// // // // // //           ? DateTime.tryParse(r['updated_at'] as String)
// // // // // //           : null,
// // // // // //       creatorName:
// // // // // //           creator?['display_name'] as String? ??
// // // // // //           creator?['username'] as String?,
// // // // // //       creatorAvatarUrl: creator?['avatar_url'] as String?,
// // // // // //       isVerifiedCreator: creator?['verification_status'] == 'verified',
// // // // // //     );
// // // // // //   }

// // // // // //   /// Parse available_languages from DB row.
// // // // // //   /// Falls back to computing from language/is_multilang if column not present.
// // // // // //   List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
// // // // // //     final raw = r['available_languages'];
// // // // // //     if (raw is List && raw.isNotEmpty) {
// // // // // //       return raw.map((e) => e.toString()).toList();
// // // // // //     }
// // // // // //     // Fallback: derive from language field
// // // // // //     final lang = r['language'] as String? ?? 'en';
// // // // // //     final multilang = r['is_multilang'] as bool? ?? false;
// // // // // //     if (multilang || lang == 'multi') return ['en', 'ar', 'fr'];
// // // // // //     return [lang];
// // // // // //   }

// // // // // //   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
// // // // // //     id: r['id'] as String,
// // // // // //     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // // //     slug: r['slug'] as String,
// // // // // //     icon: r['icon'] as String? ?? '📦',
// // // // // //     sortOrder: r['sort_order'] as int? ?? 0,
// // // // // //   );

// // // // // //   PackReview _rowToReview(Map<String, dynamic> r) {
// // // // // //     final author = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // // //     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
// // // // // //     return PackReview(
// // // // // //       id: r['id'] as String,
// // // // // //       packId: r['pack_id'] as String,
// // // // // //       userId: r['user_id'] as String,
// // // // // //       content: r['content'] as String,
// // // // // //       rating: ratingRow?['rating'] as int?,
// // // // // //       authorName: author['display_name'] as String?,
// // // // // //       authorAvatarUrl: author['avatar_url'] as String?,
// // // // // //       createdAt: DateTime.parse(r['created_at'] as String),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // // import 'package:uuid/uuid.dart';

// // // // // import '../../../core/data/base_repository.dart';
// // // // // import '../../../core/errors/failures.dart';
// // // // // import '../../../core/network/api_client.dart';
// // // // // import '../domain/pack_entity.dart';

// // // // // export '../domain/pack_entity.dart'; // Barrel re-export for convenience

// // // // // const _uuid = Uuid();

// // // // // /// All marketplace and pack data operations.
// // // // // ///
// // // // // /// Read  → Supabase direct (RLS-protected anon key)
// // // // // /// Write → Node.js API (service_role business rules)
// // // // // class PackRepository extends BaseRepository {
// // // // //   PackRepository._();
// // // // //   static final PackRepository _instance = PackRepository._();
// // // // //   static PackRepository get instance => _instance;

// // // // //   final _supabase = Supabase.instance.client;
// // // // //   final _api = ApiClient.instance;

// // // // //   // ── Browse ─────────────────────────────────────────────────────────────────

// // // // //   Future<List<PackEntity>> browsePacks({
// // // // //     String? query,
// // // // //     String? gameType,
// // // // //     String? categoryId,
// // // // //     bool freeOnly = false,
// // // // //     String? language,
// // // // //     String sortBy = 'avg_rating',
// // // // //     int page = 0,
// // // // //     int perPage = 20,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'browsePacks',
// // // // //     operation: () async {
// // // // //       var q = _supabase
// // // // //           .from('packs')
// // // // //           .select('''
// // // // //                 id, creator_id, title, description, cover_image_url,
// // // // //                 status, game_type, language, is_multilang, price_mru,
// // // // //                 card_count, avg_rating, total_ratings, total_purchases,
// // // // //                 total_plays, version, has_spicy, is_featured, is_promoted,
// // // // //                 category_id, download_url, published_at, created_at,
// // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // //               ''')
// // // // //           .eq('status', 'approved')
// // // // //           .isFilter('deleted_at', null);

// // // // //       if (gameType != null) q = q.eq('game_type', gameType);
// // // // //       if (categoryId != null) q = q.eq('category_id', categoryId);
// // // // //       if (freeOnly) q = q.eq('price_mru', 0);
// // // // //       if (language != null && language != 'multi') {
// // // // //         q = q.or('language.eq.$language,is_multilang.eq.true');
// // // // //       }

// // // // //       final rows = await q
// // // // //           .order(sortBy, ascending: false)
// // // // //           .range(page * perPage, (page + 1) * perPage - 1);

// // // // //       return rows.map(_rowToEntity).toList();
// // // // //     },
// // // // //   );

// // // // //   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
// // // // //     operationName: 'getFeaturedPacks',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('packs')
// // // // //           .select('''
// // // // //                 id, creator_id, title, description, cover_image_url,
// // // // //                 status, game_type, language, price_mru, card_count,
// // // // //                 avg_rating, total_ratings, total_purchases, total_plays,
// // // // //                 version, has_spicy, is_featured, is_promoted,
// // // // //                 category_id, download_url,
// // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // // //               ''')
// // // // //           .eq('status', 'approved')
// // // // //           .eq('is_featured', true)
// // // // //           .isFilter('deleted_at', null)
// // // // //           .order('avg_rating', ascending: false)
// // // // //           .limit(10);
// // // // //       return rows.map(_rowToEntity).toList();
// // // // //     },
// // // // //   );

// // // // //   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
// // // // //     operationName: 'getPromotedPacks',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('promoted_packs')
// // // // //           .select('packs!pack_id(*), position')
// // // // //           .lte('starts_at', DateTime.now().toIso8601String())
// // // // //           .gte('ends_at', DateTime.now().toIso8601String())
// // // // //           .order('position');

// // // // //       return rows
// // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // //           .toList();
// // // // //     },
// // // // //   );

// // // // //   Future<List<PackCategory>> getCategories() => guardedCall(
// // // // //     operationName: 'getCategories',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('pack_categories')
// // // // //           .select()
// // // // //           .eq('is_active', true)
// // // // //           .order('sort_order');
// // // // //       return rows.map(_rowToCategory).toList();
// // // // //     },
// // // // //   );

// // // // //   // ── Detail ─────────────────────────────────────────────────────────────────

// // // // //   Future<PackEntity> getPackDetail(String packId) => guardedCall(
// // // // //     operationName: 'getPackDetail',
// // // // //     operation: () async {
// // // // //       final row = await _supabase
// // // // //           .from('packs')
// // // // //           .select('''
// // // // //                 *,
// // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
// // // // //                 pack_tags(tag)
// // // // //               ''')
// // // // //           .eq('id', packId)
// // // // //           .single();
// // // // //       return _rowToEntity(row);
// // // // //     },
// // // // //   );

// // // // //   Future<List<PackReview>> getPackReviews(
// // // // //     String packId, {
// // // // //     int limit = 20,
// // // // //     int page = 0,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'getPackReviews',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('pack_reviews')
// // // // //           .select('''
// // // // //                 id, pack_id, user_id, content, created_at,
// // // // //                 profiles!user_id(display_name, avatar_url),
// // // // //                 pack_ratings!rating_id(rating)
// // // // //               ''')
// // // // //           .eq('pack_id', packId)
// // // // //           .eq('is_visible', true)
// // // // //           .order('created_at', ascending: false)
// // // // //           .range(page * limit, (page + 1) * limit - 1);

// // // // //       return rows.map(_rowToReview).toList();
// // // // //     },
// // // // //   );

// // // // //   Future<PackRating?> getMyRating(String packId, String userId) =>
// // // // //       softCall<PackRating?>(
// // // // //         operationName: 'getMyRating',
// // // // //         operation: () async {
// // // // //           final row = await _supabase
// // // // //               .from('pack_ratings')
// // // // //               .select()
// // // // //               .eq('pack_id', packId)
// // // // //               .eq('user_id', userId)
// // // // //               .maybeSingle();
// // // // //           if (row == null) return null;
// // // // //           return PackRating(
// // // // //             packId: row['pack_id'] as String,
// // // // //             userId: row['user_id'] as String,
// // // // //             rating: row['rating'] as int,
// // // // //           );
// // // // //         },
// // // // //       );

// // // // //   // ── Purchases ──────────────────────────────────────────────────────────────

// // // // //   /// Quick existence check — are there any free (price_mru = 0) approved
// // // // //   /// packs in the marketplace at all? Used to gate room creation: a user
// // // // //   /// with zero purchased packs can still create a room if free packs are
// // // // //   /// available for them to pick up.
// // // // //   Future<bool> hasFreePacksAvailable() => guardedCall(
// // // // //     operationName: 'hasFreePacksAvailable',
// // // // //     operation: () async {
// // // // //       final row = await _supabase
// // // // //           .from('packs')
// // // // //           .select('id')
// // // // //           .eq('price_mru', 0)
// // // // //           .eq('status', 'approved')
// // // // //           .isFilter('deleted_at', null)
// // // // //           .limit(1)
// // // // //           .maybeSingle();
// // // // //       return row != null;
// // // // //     },
// // // // //   );

// // // // //   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
// // // // //     operationName: 'getMyPurchasedPacks',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('pack_purchases')
// // // // //           .select('pack_id, purchased_at, expires_at, packs(*)')
// // // // //           .eq('buyer_id', userId)
// // // // //           .eq('status', 'completed')
// // // // //           // Include rows where expires_at is null (permanent) OR in the future
// // // // //           .or(
// // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // //           )
// // // // //           .order('purchased_at', ascending: false);

// // // // //       return rows
// // // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // // //           .toList();
// // // // //     },
// // // // //   );

// // // // //   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
// // // // //     operationName: 'getPurchaseRecords',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('pack_purchases')
// // // // //           .select('pack_id, purchased_at, expires_at, price_paid_mru')
// // // // //           .eq('buyer_id', userId)
// // // // //           .eq('status', 'completed')
// // // // //           .or(
// // // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // // //           );

// // // // //       return rows
// // // // //           .map(
// // // // //             (r) => PackPurchase(
// // // // //               packId: r['pack_id'] as String,
// // // // //               purchasedAt: DateTime.parse(r['purchased_at'] as String),
// // // // //               expiresAt: DateTime.parse(r['expires_at'] as String),
// // // // //               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// // // // //             ),
// // // // //           )
// // // // //           .toList();
// // // // //     },
// // // // //   );

// // // // //   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
// // // // //     operationName: 'hasPurchased',
// // // // //     operation: () async {
// // // // //       final row = await _supabase
// // // // //           .from('pack_purchases')
// // // // //           .select('id')
// // // // //           .eq('pack_id', packId)
// // // // //           .eq('buyer_id', userId)
// // // // //           .eq('status', 'completed')
// // // // //           .gt('expires_at', DateTime.now().toIso8601String())
// // // // //           .maybeSingle();
// // // // //       return row != null;
// // // // //     },
// // // // //   );

// // // // //   /// Purchase a pack via Node.js API (uses service_role to bypass RLS).
// // // // //   /// RLS policy "pack_purchases: no client insert" blocks direct Supabase writes.
// // // // //   Future<void> purchasePack(String packId) => guardedCall(
// // // // //     operationName: 'purchasePack',
// // // // //     operation: () async {
// // // // //       final response = await _api.post(
// // // // //         '/v1/packs/purchase',
// // // // //         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
// // // // //       );
// // // // //       final data = response.data as Map<String, dynamic>?;
// // // // //       final error = data?['error'] as String?;
// // // // //       if (error != null) throw Exception(error);
// // // // //     },
// // // // //   );

// // // // //   // ── Ratings & Reviews ──────────────────────────────────────────────────────

// // // // //   Future<void> ratePack({
// // // // //     required String packId,
// // // // //     required String userId,
// // // // //     required int rating,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'ratePack',
// // // // //     operation: () async {
// // // // //       await _supabase.from('pack_ratings').upsert({
// // // // //         'user_id': userId,
// // // // //         'pack_id': packId,
// // // // //         'rating': rating,
// // // // //       }, onConflict: 'pack_id,user_id');
// // // // //     },
// // // // //   );

// // // // //   Future<void> submitReview({
// // // // //     required String packId,
// // // // //     required String userId,
// // // // //     required String content,
// // // // //     int? rating,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'submitReview',
// // // // //     operation: () async {
// // // // //       await _supabase.from('pack_reviews').upsert({
// // // // //         'id': _uuid.v4(),
// // // // //         'pack_id': packId,
// // // // //         'user_id': userId,
// // // // //         'content': content,
// // // // //       }, onConflict: 'pack_id,user_id');
// // // // //       if (rating != null) {
// // // // //         await ratePack(packId: packId, userId: userId, rating: rating);
// // // // //       }
// // // // //     },
// // // // //   );

// // // // //   Future<void> reportPack({
// // // // //     required String packId,
// // // // //     required String reporterId,
// // // // //     required String reason,
// // // // //     String? details,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'reportPack',
// // // // //     operation: () async {
// // // // //       await _supabase.from('pack_reports').upsert({
// // // // //         'pack_id': packId,
// // // // //         'reporter_id': reporterId,
// // // // //         'reason': reason,
// // // // //         'details': details,
// // // // //       }, onConflict: 'pack_id,reporter_id');
// // // // //     },
// // // // //   );

// // // // //   // ── Creator operations ─────────────────────────────────────────────────────

// // // // //   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
// // // // //       guardedCall(
// // // // //         operationName: 'savePackReactions',
// // // // //         operation: () async {
// // // // //           await _api.post(
// // // // //             '/v1/packs/$packId/reactions',
// // // // //             data: {
// // // // //               'reactions': imageUrls
// // // // //                   .asMap()
// // // // //                   .entries
// // // // //                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
// // // // //                   .toList(),
// // // // //             },
// // // // //           );
// // // // //         },
// // // // //       );

// // // // //   Future<List<String>> getPackReactions(String packId) => guardedCall(
// // // // //     operationName: 'getPackReactions',
// // // // //     operation: () async {
// // // // //       try {
// // // // //         // Try API first (bypasses RLS — works for all pack statuses)
// // // // //         final response = await _api.get('/v1/packs/$packId/reactions');
// // // // //         final data = response.data as Map<String, dynamic>?;
// // // // //         final reactions = data?['data']?['reactions'] as List?;
// // // // //         if (reactions != null) {
// // // // //           return reactions.map((r) => r['image_url'] as String).toList();
// // // // //         }
// // // // //       } catch (_) {
// // // // //         // Fallback to direct Supabase if API fails
// // // // //       }
// // // // //       // Fallback: direct Supabase (works if RLS allows it)
// // // // //       final rows = await _supabase
// // // // //           .from('pack_reactions')
// // // // //           .select('image_url')
// // // // //           .eq('pack_id', packId)
// // // // //           .order('sort_order');
// // // // //       return (rows as List).map((r) => r['image_url'] as String).toList();
// // // // //     },
// // // // //   );

// // // // //   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
// // // // //     operationName: 'getMyCreatedPacks',
// // // // //     operation: () async {
// // // // //       final rows = await _supabase
// // // // //           .from('packs')
// // // // //           .select()
// // // // //           .eq('creator_id', creatorId)
// // // // //           .isFilter('deleted_at', null)
// // // // //           .order('created_at', ascending: false);
// // // // //       return rows.map(_rowToEntity).toList();
// // // // //     },
// // // // //   );

// // // // //   /// Create a pack draft (via Node.js for service_role insert).
// // // // //   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
// // // // //       guardedCall(
// // // // //         operationName: 'createPackDraft',
// // // // //         operation: () async {
// // // // //           final resp = await _api.post<Map<String, dynamic>>(
// // // // //             '/v1/packs/create',
// // // // //             data: {
// // // // //               'title': draft.titleJson,
// // // // //               'description': {'en': draft.descriptionEn},
// // // // //               'game_type': draft.gameType,
// // // // //               'language': draft.language,
// // // // //               'price_mru': draft.priceMru,
// // // // //               'category_id': draft.categoryId,
// // // // //               'has_spicy': draft.allowSpicy,
// // // // //               'min_players': draft.minPlayers,
// // // // //               'tags': draft.tags,
// // // // //               'cover_image_url': draft.coverImageUrl,
// // // // //             },
// // // // //           );
// // // // //           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
// // // // //           return _rowToEntity(row);
// // // // //         },
// // // // //       );

// // // // //   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
// // // // //       guardedCall(
// // // // //         operationName: 'updatePackDraft',
// // // // //         operation: () async {
// // // // //           final resp = await _api.patch<Map<String, dynamic>>(
// // // // //             '/v1/packs/$packId',
// // // // //             data: {
// // // // //               'title': draft.titleJson,
// // // // //               'description': {'en': draft.descriptionEn},
// // // // //               'price_mru': draft.priceMru,
// // // // //               'category_id': draft.categoryId,
// // // // //               'has_spicy': draft.allowSpicy,
// // // // //               'min_players': draft.minPlayers,
// // // // //               'tags': draft.tags,
// // // // //               'cover_image_url': draft.coverImageUrl,
// // // // //             },
// // // // //           );
// // // // //           return _rowToEntity(
// // // // //             resp.data!['data']['pack'] as Map<String, dynamic>,
// // // // //           );
// // // // //         },
// // // // //       );

// // // // //   Future<PackEntity> submitForReview(String packId) => guardedCall(
// // // // //     operationName: 'submitForReview',
// // // // //     operation: () async {
// // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // //         '/v1/packs/$packId/submit',
// // // // //       );
// // // // //       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
// // // // //     },
// // // // //   );

// // // // //   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
// // // // //     operationName: 'addCards',
// // // // //     operation: () async {
// // // // //       // Delete existing cards then re-insert (replace all)
// // // // //       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

// // // // //       if (cards.isEmpty) return;

// // // // //       final rows = cards
// // // // //           .asMap()
// // // // //           .entries
// // // // //           .map(
// // // // //             (e) => {
// // // // //               'pack_id': packId,
// // // // //               'content': e.value.contentJson,
// // // // //               'card_type': e.value.type.name,
// // // // //               'difficulty': e.value.difficulty.name,
// // // // //               'sort_order': e.key,
// // // // //               'is_active': true,
// // // // //             },
// // // // //           )
// // // // //           .toList();

// // // // //       await _supabase.from('pack_cards').insert(rows);
// // // // //     },
// // // // //   );

// // // // //   Future<void> deleteCard(String packId, String cardId) => guardedCall(
// // // // //     operationName: 'deleteCard',
// // // // //     operation: () async {
// // // // //       await _supabase
// // // // //           .from('pack_cards')
// // // // //           .delete()
// // // // //           .eq('id', cardId)
// // // // //           .eq('pack_id', packId);
// // // // //     },
// // // // //   );

// // // // //   /// For each pack, returns only the languages that EVERY active card
// // // // //   /// actually has non-empty content for — not just the languages the
// // // // //   /// pack metadata (title/available_languages) claims to support.
// // // // //   ///
// // // // //   /// Used to filter the room's pack picker so a selected language never
// // // // //   /// silently falls back to English mid-game because a card was missed
// // // // //   /// when the creator filled in translations.
// // // // //   Future<Map<String, Set<String>>> getCardLanguageCoverage(
// // // // //     List<String> packIds,
// // // // //   ) => guardedCall(
// // // // //     operationName: 'getCardLanguageCoverage',
// // // // //     operation: () async {
// // // // //       if (packIds.isEmpty) return <String, Set<String>>{};

// // // // //       final rows = await _supabase
// // // // //           .from('pack_cards')
// // // // //           .select('pack_id, content')
// // // // //           .inFilter('pack_id', packIds)
// // // // //           .eq('is_active', true);

// // // // //       // pack_id → intersection of language keys present (non-empty) on
// // // // //       // every card seen so far for that pack.
// // // // //       final coverage = <String, Set<String>>{};
// // // // //       final seenAnyCard = <String>{};

// // // // //       for (final r in rows) {
// // // // //         final packId = r['pack_id'] as String;
// // // // //         final content = r['content'] as Map<String, dynamic>? ?? {};
// // // // //         final cardLangs = content.entries
// // // // //             .where((e) => (e.value as String?)?.trim().isNotEmpty ?? false)
// // // // //             .map((e) => e.key)
// // // // //             .toSet();

// // // // //         if (seenAnyCard.add(packId)) {
// // // // //           coverage[packId] = cardLangs;
// // // // //         } else {
// // // // //           coverage[packId] = coverage[packId]!.intersection(cardLangs);
// // // // //         }
// // // // //       }

// // // // //       return coverage;
// // // // //     },
// // // // //   );

// // // // //   /// Request a presigned upload URL from Node.js for Wasabi.
// // // // //   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
// // // // //     required String contentType,
// // // // //     required String fileType, // 'cover' or 'card_image'
// // // // //     required int fileSizeBytes,
// // // // //   }) => guardedCall(
// // // // //     operationName: 'getUploadUrl',
// // // // //     operation: () async {
// // // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // // //         '/v1/storage/upload-url',
// // // // //         data: {
// // // // //           'file_type': fileType,
// // // // //           'content_type': contentType,
// // // // //           'file_size_bytes': fileSizeBytes,
// // // // //         },
// // // // //       );
// // // // //       final data = resp.data!['data'] as Map<String, dynamic>;
// // // // //       return (
// // // // //         uploadUrl: data['upload_url'] as String,
// // // // //         publicUrl: data['public_url'] as String,
// // // // //       );
// // // // //     },
// // // // //   );

// // // // //   // ── Mappers ────────────────────────────────────────────────────────────────

// // // // //   PackEntity _rowToEntity(Map<String, dynamic> r) {
// // // // //     // Creator profile (joined)
// // // // //     final creator = r['profiles'] as Map<String, dynamic>?;
// // // // //     // Tags (joined)
// // // // //     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
// // // // //     final tags = tagRows.map((t) => t['tag'] as String).toList();

// // // // //     return PackEntity(
// // // // //       id: r['id'] as String,
// // // // //       creatorId: r['creator_id'] as String,
// // // // //       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // //       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
// // // // //       coverImageUrl: r['cover_image_url'] as String?,
// // // // //       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
// // // // //       gameType: r['game_type'] as String? ?? 'truth_or_dare',
// // // // //       language: r['language'] as String? ?? 'en',
// // // // //       isMultilang: r['is_multilang'] as bool? ?? false,
// // // // //       availableLanguages: _parseAvailableLanguages(r),
// // // // //       priceMru: r['price_mru'] as int? ?? 0,
// // // // //       cardCount: r['card_count'] as int? ?? 0,
// // // // //       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
// // // // //       totalRatings: r['total_ratings'] as int? ?? 0,
// // // // //       totalPurchases: r['total_purchases'] as int? ?? 0,
// // // // //       totalPlays: r['total_plays'] as int? ?? 0,
// // // // //       downloadUrl: r['download_url'] as String?,
// // // // //       version: r['version'] as int? ?? 1,
// // // // //       hasSpicy: r['has_spicy'] as bool? ?? false,
// // // // //       isFeatured: r['is_featured'] as bool? ?? false,
// // // // //       isPromoted: r['is_promoted'] as bool? ?? false,
// // // // //       categoryId: r['category_id'] as String?,
// // // // //       tags: tags,
// // // // //       publishedAt: r['published_at'] != null
// // // // //           ? DateTime.tryParse(r['published_at'] as String)
// // // // //           : null,
// // // // //       createdAt: r['created_at'] != null
// // // // //           ? DateTime.tryParse(r['created_at'] as String)
// // // // //           : null,
// // // // //       updatedAt: r['updated_at'] != null
// // // // //           ? DateTime.tryParse(r['updated_at'] as String)
// // // // //           : null,
// // // // //       creatorName:
// // // // //           creator?['display_name'] as String? ??
// // // // //           creator?['username'] as String?,
// // // // //       creatorAvatarUrl: creator?['avatar_url'] as String?,
// // // // //       isVerifiedCreator: creator?['verification_status'] == 'verified',
// // // // //     );
// // // // //   }

// // // // //   /// Parse available_languages from DB row.
// // // // //   /// Falls back to computing from language/is_multilang if column not present.
// // // // //   List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
// // // // //     final raw = r['available_languages'];
// // // // //     if (raw is List && raw.isNotEmpty) {
// // // // //       return raw.map((e) => e.toString()).toList();
// // // // //     }
// // // // //     // Fallback: derive from language field
// // // // //     final lang = r['language'] as String? ?? 'en';
// // // // //     final multilang = r['is_multilang'] as bool? ?? false;
// // // // //     if (multilang || lang == 'multi') return ['en', 'ar', 'fr'];
// // // // //     return [lang];
// // // // //   }

// // // // //   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
// // // // //     id: r['id'] as String,
// // // // //     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
// // // // //     slug: r['slug'] as String,
// // // // //     icon: r['icon'] as String? ?? '📦',
// // // // //     sortOrder: r['sort_order'] as int? ?? 0,
// // // // //   );

// // // // //   PackReview _rowToReview(Map<String, dynamic> r) {
// // // // //     final author = r['profiles'] as Map<String, dynamic>? ?? {};
// // // // //     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
// // // // //     return PackReview(
// // // // //       id: r['id'] as String,
// // // // //       packId: r['pack_id'] as String,
// // // // //       userId: r['user_id'] as String,
// // // // //       content: r['content'] as String,
// // // // //       rating: ratingRow?['rating'] as int?,
// // // // //       authorName: author['display_name'] as String?,
// // // // //       authorAvatarUrl: author['avatar_url'] as String?,
// // // // //       createdAt: DateTime.parse(r['created_at'] as String),
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // // import 'package:uuid/uuid.dart';

// // // // import '../../../core/data/base_repository.dart';
// // // // import '../../../core/errors/failures.dart';
// // // // import '../../../core/network/api_client.dart';
// // // // import '../domain/pack_entity.dart';

// // // // export '../domain/pack_entity.dart'; // Barrel re-export for convenience

// // // // const _uuid = Uuid();

// // // // /// A selectable pack content language, sourced from the pack_languages
// // // // /// table instead of a hardcoded list — admins can add new ones without an
// // // // /// app update.
// // // // class PackLanguage {
// // // //   const PackLanguage({
// // // //     required this.code,
// // // //     required this.name,
// // // //     required this.nativeName,
// // // //     this.isRtl = false,
// // // //   });
// // // //   final String code; // e.g. 'en'
// // // //   final String name; // e.g. 'English'
// // // //   final String nativeName; // e.g. 'English' or 'العربية'
// // // //   final bool isRtl;
// // // // }

// // // // /// All marketplace and pack data operations.
// // // // ///
// // // // /// Read  → Supabase direct (RLS-protected anon key)
// // // // /// Write → Node.js API (service_role business rules)
// // // // class PackRepository extends BaseRepository {
// // // //   PackRepository._();
// // // //   static final PackRepository _instance = PackRepository._();
// // // //   static PackRepository get instance => _instance;

// // // //   final _supabase = Supabase.instance.client;
// // // //   final _api = ApiClient.instance;

// // // //   // ── Browse ─────────────────────────────────────────────────────────────────

// // // //   Future<List<PackEntity>> browsePacks({
// // // //     String? query,
// // // //     String? gameType,
// // // //     String? categoryId,
// // // //     bool freeOnly = false,
// // // //     String? language,
// // // //     String sortBy = 'avg_rating',
// // // //     int page = 0,
// // // //     int perPage = 20,
// // // //   }) => guardedCall(
// // // //     operationName: 'browsePacks',
// // // //     operation: () async {
// // // //       var q = _supabase
// // // //           .from('packs')
// // // //           .select('''
// // // //                 id, creator_id, title, description, cover_image_url,
// // // //                 status, game_type, language, is_multilang, price_mru,
// // // //                 card_count, avg_rating, total_ratings, total_purchases,
// // // //                 total_plays, version, has_spicy, is_featured, is_promoted,
// // // //                 category_id, download_url, published_at, created_at,
// // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // //               ''')
// // // //           .eq('status', 'approved')
// // // //           .isFilter('deleted_at', null);

// // // //       if (gameType != null) q = q.eq('game_type', gameType);
// // // //       if (categoryId != null) q = q.eq('category_id', categoryId);
// // // //       if (freeOnly) q = q.eq('price_mru', 0);
// // // //       if (language != null && language != 'multi') {
// // // //         q = q.or('language.eq.$language,is_multilang.eq.true');
// // // //       }

// // // //       final rows = await q
// // // //           .order(sortBy, ascending: false)
// // // //           .range(page * perPage, (page + 1) * perPage - 1);

// // // //       return rows.map(_rowToEntity).toList();
// // // //     },
// // // //   );

// // // //   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
// // // //     operationName: 'getFeaturedPacks',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('packs')
// // // //           .select('''
// // // //                 id, creator_id, title, description, cover_image_url,
// // // //                 status, game_type, language, price_mru, card_count,
// // // //                 avg_rating, total_ratings, total_purchases, total_plays,
// // // //                 version, has_spicy, is_featured, is_promoted,
// // // //                 category_id, download_url,
// // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // // //               ''')
// // // //           .eq('status', 'approved')
// // // //           .eq('is_featured', true)
// // // //           .isFilter('deleted_at', null)
// // // //           .order('avg_rating', ascending: false)
// // // //           .limit(10);
// // // //       return rows.map(_rowToEntity).toList();
// // // //     },
// // // //   );

// // // //   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
// // // //     operationName: 'getPromotedPacks',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('promoted_packs')
// // // //           .select('packs!pack_id(*), position')
// // // //           .lte('starts_at', DateTime.now().toIso8601String())
// // // //           .gte('ends_at', DateTime.now().toIso8601String())
// // // //           .order('position');

// // // //       return rows
// // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // //           .toList();
// // // //     },
// // // //   );

// // // //   Future<List<PackCategory>> getCategories() => guardedCall(
// // // //     operationName: 'getCategories',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('pack_categories')
// // // //           .select()
// // // //           .eq('is_active', true)
// // // //           .order('sort_order');
// // // //       return rows.map(_rowToCategory).toList();
// // // //     },
// // // //   );

// // // //   // ── Detail ─────────────────────────────────────────────────────────────────

// // // //   Future<PackEntity> getPackDetail(String packId) => guardedCall(
// // // //     operationName: 'getPackDetail',
// // // //     operation: () async {
// // // //       final row = await _supabase
// // // //           .from('packs')
// // // //           .select('''
// // // //                 *,
// // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
// // // //                 pack_tags(tag)
// // // //               ''')
// // // //           .eq('id', packId)
// // // //           .single();
// // // //       return _rowToEntity(row);
// // // //     },
// // // //   );

// // // //   Future<List<PackReview>> getPackReviews(
// // // //     String packId, {
// // // //     int limit = 20,
// // // //     int page = 0,
// // // //   }) => guardedCall(
// // // //     operationName: 'getPackReviews',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('pack_reviews')
// // // //           .select('''
// // // //                 id, pack_id, user_id, content, created_at,
// // // //                 profiles!user_id(display_name, avatar_url),
// // // //                 pack_ratings!rating_id(rating)
// // // //               ''')
// // // //           .eq('pack_id', packId)
// // // //           .eq('is_visible', true)
// // // //           .order('created_at', ascending: false)
// // // //           .range(page * limit, (page + 1) * limit - 1);

// // // //       return rows.map(_rowToReview).toList();
// // // //     },
// // // //   );

// // // //   Future<PackRating?> getMyRating(String packId, String userId) =>
// // // //       softCall<PackRating?>(
// // // //         operationName: 'getMyRating',
// // // //         operation: () async {
// // // //           final row = await _supabase
// // // //               .from('pack_ratings')
// // // //               .select()
// // // //               .eq('pack_id', packId)
// // // //               .eq('user_id', userId)
// // // //               .maybeSingle();
// // // //           if (row == null) return null;
// // // //           return PackRating(
// // // //             packId: row['pack_id'] as String,
// // // //             userId: row['user_id'] as String,
// // // //             rating: row['rating'] as int,
// // // //           );
// // // //         },
// // // //       );

// // // //   // ── Languages ─────────────────────────────────────────────────────────────

// // // //   /// Available pack languages, admin-configurable via the pack_languages
// // // //   /// table — add a new language there and it shows up here automatically,
// // // //   /// no app update needed. Excludes the 'multi' flag row (not a real
// // // //   /// selectable language).
// // // //   Future<List<PackLanguage>> getAvailableLanguages() => guardedCall(
// // // //     operationName: 'getAvailableLanguages',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('pack_languages')
// // // //           .select('code, name, native_name, is_rtl')
// // // //           .eq('is_active', true)
// // // //           .order('sort_order');
// // // //       return rows
// // // //           .map(
// // // //             (r) => PackLanguage(
// // // //               code: r['code'] as String,
// // // //               name: r['name'] as String,
// // // //               nativeName: r['native_name'] as String,
// // // //               isRtl: r['is_rtl'] as bool? ?? false,
// // // //             ),
// // // //           )
// // // //           .toList();
// // // //     },
// // // //   );

// // // //   // ── Purchases ──────────────────────────────────────────────────────────────

// // // //   /// Quick existence check — are there any free (price_mru = 0) approved
// // // //   /// packs in the marketplace at all? Used to gate room creation: a user
// // // //   /// with zero purchased packs can still create a room if free packs are
// // // //   /// available for them to pick up.
// // // //   Future<bool> hasFreePacksAvailable() => guardedCall(
// // // //     operationName: 'hasFreePacksAvailable',
// // // //     operation: () async {
// // // //       final row = await _supabase
// // // //           .from('packs')
// // // //           .select('id')
// // // //           .eq('price_mru', 0)
// // // //           .eq('status', 'approved')
// // // //           .isFilter('deleted_at', null)
// // // //           .limit(1)
// // // //           .maybeSingle();
// // // //       return row != null;
// // // //     },
// // // //   );

// // // //   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
// // // //     operationName: 'getMyPurchasedPacks',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('pack_purchases')
// // // //           .select('pack_id, purchased_at, expires_at, packs(*)')
// // // //           .eq('buyer_id', userId)
// // // //           .eq('status', 'completed')
// // // //           // Include rows where expires_at is null (permanent) OR in the future
// // // //           .or(
// // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // //           )
// // // //           .order('purchased_at', ascending: false);

// // // //       return rows
// // // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // // //           .toList();
// // // //     },
// // // //   );

// // // //   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
// // // //     operationName: 'getPurchaseRecords',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('pack_purchases')
// // // //           .select('pack_id, purchased_at, expires_at, price_paid_mru')
// // // //           .eq('buyer_id', userId)
// // // //           .eq('status', 'completed')
// // // //           .or(
// // // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // // //           );

// // // //       return rows
// // // //           .map(
// // // //             (r) => PackPurchase(
// // // //               packId: r['pack_id'] as String,
// // // //               purchasedAt: DateTime.parse(r['purchased_at'] as String),
// // // //               expiresAt: DateTime.parse(r['expires_at'] as String),
// // // //               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// // // //             ),
// // // //           )
// // // //           .toList();
// // // //     },
// // // //   );

// // // //   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
// // // //     operationName: 'hasPurchased',
// // // //     operation: () async {
// // // //       final row = await _supabase
// // // //           .from('pack_purchases')
// // // //           .select('id')
// // // //           .eq('pack_id', packId)
// // // //           .eq('buyer_id', userId)
// // // //           .eq('status', 'completed')
// // // //           .gt('expires_at', DateTime.now().toIso8601String())
// // // //           .maybeSingle();
// // // //       return row != null;
// // // //     },
// // // //   );

// // // //   /// Purchase a pack via Node.js API (uses service_role to bypass RLS).
// // // //   /// RLS policy "pack_purchases: no client insert" blocks direct Supabase writes.
// // // //   Future<void> purchasePack(String packId) => guardedCall(
// // // //     operationName: 'purchasePack',
// // // //     operation: () async {
// // // //       final response = await _api.post(
// // // //         '/v1/packs/purchase',
// // // //         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
// // // //       );
// // // //       final data = response.data as Map<String, dynamic>?;
// // // //       final error = data?['error'] as String?;
// // // //       if (error != null) throw Exception(error);
// // // //     },
// // // //   );

// // // //   // ── Ratings & Reviews ──────────────────────────────────────────────────────

// // // //   Future<void> ratePack({
// // // //     required String packId,
// // // //     required String userId,
// // // //     required int rating,
// // // //   }) => guardedCall(
// // // //     operationName: 'ratePack',
// // // //     operation: () async {
// // // //       await _supabase.from('pack_ratings').upsert({
// // // //         'user_id': userId,
// // // //         'pack_id': packId,
// // // //         'rating': rating,
// // // //       }, onConflict: 'pack_id,user_id');
// // // //     },
// // // //   );

// // // //   Future<void> submitReview({
// // // //     required String packId,
// // // //     required String userId,
// // // //     required String content,
// // // //     int? rating,
// // // //   }) => guardedCall(
// // // //     operationName: 'submitReview',
// // // //     operation: () async {
// // // //       await _supabase.from('pack_reviews').upsert({
// // // //         'id': _uuid.v4(),
// // // //         'pack_id': packId,
// // // //         'user_id': userId,
// // // //         'content': content,
// // // //       }, onConflict: 'pack_id,user_id');
// // // //       if (rating != null) {
// // // //         await ratePack(packId: packId, userId: userId, rating: rating);
// // // //       }
// // // //     },
// // // //   );

// // // //   Future<void> reportPack({
// // // //     required String packId,
// // // //     required String reporterId,
// // // //     required String reason,
// // // //     String? details,
// // // //   }) => guardedCall(
// // // //     operationName: 'reportPack',
// // // //     operation: () async {
// // // //       await _supabase.from('pack_reports').upsert({
// // // //         'pack_id': packId,
// // // //         'reporter_id': reporterId,
// // // //         'reason': reason,
// // // //         'details': details,
// // // //       }, onConflict: 'pack_id,reporter_id');
// // // //     },
// // // //   );

// // // //   // ── Creator operations ─────────────────────────────────────────────────────

// // // //   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
// // // //       guardedCall(
// // // //         operationName: 'savePackReactions',
// // // //         operation: () async {
// // // //           await _api.post(
// // // //             '/v1/packs/$packId/reactions',
// // // //             data: {
// // // //               'reactions': imageUrls
// // // //                   .asMap()
// // // //                   .entries
// // // //                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
// // // //                   .toList(),
// // // //             },
// // // //           );
// // // //         },
// // // //       );

// // // //   Future<List<String>> getPackReactions(String packId) => guardedCall(
// // // //     operationName: 'getPackReactions',
// // // //     operation: () async {
// // // //       try {
// // // //         // Try API first (bypasses RLS — works for all pack statuses)
// // // //         final response = await _api.get('/v1/packs/$packId/reactions');
// // // //         final data = response.data as Map<String, dynamic>?;
// // // //         final reactions = data?['data']?['reactions'] as List?;
// // // //         if (reactions != null) {
// // // //           return reactions.map((r) => r['image_url'] as String).toList();
// // // //         }
// // // //       } catch (_) {
// // // //         // Fallback to direct Supabase if API fails
// // // //       }
// // // //       // Fallback: direct Supabase (works if RLS allows it)
// // // //       final rows = await _supabase
// // // //           .from('pack_reactions')
// // // //           .select('image_url')
// // // //           .eq('pack_id', packId)
// // // //           .order('sort_order');
// // // //       return (rows as List).map((r) => r['image_url'] as String).toList();
// // // //     },
// // // //   );

// // // //   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
// // // //     operationName: 'getMyCreatedPacks',
// // // //     operation: () async {
// // // //       final rows = await _supabase
// // // //           .from('packs')
// // // //           .select()
// // // //           .eq('creator_id', creatorId)
// // // //           .isFilter('deleted_at', null)
// // // //           .order('created_at', ascending: false);
// // // //       return rows.map(_rowToEntity).toList();
// // // //     },
// // // //   );

// // // //   /// Create a pack draft (via Node.js for service_role insert).
// // // //   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
// // // //       guardedCall(
// // // //         operationName: 'createPackDraft',
// // // //         operation: () async {
// // // //           final resp = await _api.post<Map<String, dynamic>>(
// // // //             '/v1/packs/create',
// // // //             data: {
// // // //               'title': draft.titleJson,
// // // //               'description': {'en': draft.descriptionEn},
// // // //               'game_type': draft.gameType,
// // // //               'language': draft.language,
// // // //               'price_mru': draft.priceMru,
// // // //               'category_id': draft.categoryId,
// // // //               'has_spicy': draft.allowSpicy,
// // // //               'min_players': draft.minPlayers,
// // // //               'tags': draft.tags,
// // // //               'cover_image_url': draft.coverImageUrl,
// // // //             },
// // // //           );
// // // //           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
// // // //           return _rowToEntity(row);
// // // //         },
// // // //       );

// // // //   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
// // // //       guardedCall(
// // // //         operationName: 'updatePackDraft',
// // // //         operation: () async {
// // // //           final resp = await _api.patch<Map<String, dynamic>>(
// // // //             '/v1/packs/$packId',
// // // //             data: {
// // // //               'title': draft.titleJson,
// // // //               'description': {'en': draft.descriptionEn},
// // // //               'price_mru': draft.priceMru,
// // // //               'category_id': draft.categoryId,
// // // //               'has_spicy': draft.allowSpicy,
// // // //               'min_players': draft.minPlayers,
// // // //               'tags': draft.tags,
// // // //               'cover_image_url': draft.coverImageUrl,
// // // //             },
// // // //           );
// // // //           return _rowToEntity(
// // // //             resp.data!['data']['pack'] as Map<String, dynamic>,
// // // //           );
// // // //         },
// // // //       );

// // // //   Future<PackEntity> submitForReview(String packId) => guardedCall(
// // // //     operationName: 'submitForReview',
// // // //     operation: () async {
// // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // //         '/v1/packs/$packId/submit',
// // // //       );
// // // //       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
// // // //     },
// // // //   );

// // // //   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
// // // //     operationName: 'addCards',
// // // //     operation: () async {
// // // //       // Delete existing cards then re-insert (replace all)
// // // //       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

// // // //       if (cards.isEmpty) return;

// // // //       final rows = cards
// // // //           .asMap()
// // // //           .entries
// // // //           .map(
// // // //             (e) => {
// // // //               'pack_id': packId,
// // // //               'content': e.value.contentJson,
// // // //               'card_type': e.value.type.name,
// // // //               'difficulty': e.value.difficulty.name,
// // // //               'sort_order': e.key,
// // // //               'is_active': true,
// // // //             },
// // // //           )
// // // //           .toList();

// // // //       await _supabase.from('pack_cards').insert(rows);
// // // //     },
// // // //   );

// // // //   Future<void> deleteCard(String packId, String cardId) => guardedCall(
// // // //     operationName: 'deleteCard',
// // // //     operation: () async {
// // // //       await _supabase
// // // //           .from('pack_cards')
// // // //           .delete()
// // // //           .eq('id', cardId)
// // // //           .eq('pack_id', packId);
// // // //     },
// // // //   );

// // // //   /// For each pack, returns only the languages that EVERY active card
// // // //   /// actually has non-empty content for — not just the languages the
// // // //   /// pack metadata (title/available_languages) claims to support.
// // // //   ///
// // // //   /// Used to filter the room's pack picker so a selected language never
// // // //   /// silently falls back to English mid-game because a card was missed
// // // //   /// when the creator filled in translations.
// // // //   Future<Map<String, Set<String>>> getCardLanguageCoverage(
// // // //     List<String> packIds,
// // // //   ) => guardedCall(
// // // //     operationName: 'getCardLanguageCoverage',
// // // //     operation: () async {
// // // //       if (packIds.isEmpty) return <String, Set<String>>{};

// // // //       final rows = await _supabase
// // // //           .from('pack_cards')
// // // //           .select('pack_id, content')
// // // //           .inFilter('pack_id', packIds)
// // // //           .eq('is_active', true);

// // // //       // pack_id → intersection of language keys present (non-empty) on
// // // //       // every card seen so far for that pack.
// // // //       final coverage = <String, Set<String>>{};
// // // //       final seenAnyCard = <String>{};

// // // //       for (final r in rows) {
// // // //         final packId = r['pack_id'] as String;
// // // //         final content = r['content'] as Map<String, dynamic>? ?? {};
// // // //         final cardLangs = content.entries
// // // //             .where((e) => (e.value as String?)?.trim().isNotEmpty ?? false)
// // // //             .map((e) => e.key)
// // // //             .toSet();

// // // //         if (seenAnyCard.add(packId)) {
// // // //           coverage[packId] = cardLangs;
// // // //         } else {
// // // //           coverage[packId] = coverage[packId]!.intersection(cardLangs);
// // // //         }
// // // //       }

// // // //       return coverage;
// // // //     },
// // // //   );

// // // //   /// Request a presigned upload URL from Node.js for Wasabi.
// // // //   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
// // // //     required String contentType,
// // // //     required String fileType, // 'cover' or 'card_image'
// // // //     required int fileSizeBytes,
// // // //   }) => guardedCall(
// // // //     operationName: 'getUploadUrl',
// // // //     operation: () async {
// // // //       final resp = await _api.post<Map<String, dynamic>>(
// // // //         '/v1/storage/upload-url',
// // // //         data: {
// // // //           'file_type': fileType,
// // // //           'content_type': contentType,
// // // //           'file_size_bytes': fileSizeBytes,
// // // //         },
// // // //       );
// // // //       final data = resp.data!['data'] as Map<String, dynamic>;
// // // //       return (
// // // //         uploadUrl: data['upload_url'] as String,
// // // //         publicUrl: data['public_url'] as String,
// // // //       );
// // // //     },
// // // //   );

// // // //   // ── Mappers ────────────────────────────────────────────────────────────────

// // // //   PackEntity _rowToEntity(Map<String, dynamic> r) {
// // // //     // Creator profile (joined)
// // // //     final creator = r['profiles'] as Map<String, dynamic>?;
// // // //     // Tags (joined)
// // // //     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
// // // //     final tags = tagRows.map((t) => t['tag'] as String).toList();

// // // //     return PackEntity(
// // // //       id: r['id'] as String,
// // // //       creatorId: r['creator_id'] as String,
// // // //       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
// // // //       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
// // // //       coverImageUrl: r['cover_image_url'] as String?,
// // // //       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
// // // //       gameType: r['game_type'] as String? ?? 'truth_or_dare',
// // // //       language: r['language'] as String? ?? 'en',
// // // //       isMultilang: r['is_multilang'] as bool? ?? false,
// // // //       availableLanguages: _parseAvailableLanguages(r),
// // // //       priceMru: r['price_mru'] as int? ?? 0,
// // // //       cardCount: r['card_count'] as int? ?? 0,
// // // //       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
// // // //       totalRatings: r['total_ratings'] as int? ?? 0,
// // // //       totalPurchases: r['total_purchases'] as int? ?? 0,
// // // //       totalPlays: r['total_plays'] as int? ?? 0,
// // // //       downloadUrl: r['download_url'] as String?,
// // // //       version: r['version'] as int? ?? 1,
// // // //       hasSpicy: r['has_spicy'] as bool? ?? false,
// // // //       isFeatured: r['is_featured'] as bool? ?? false,
// // // //       isPromoted: r['is_promoted'] as bool? ?? false,
// // // //       categoryId: r['category_id'] as String?,
// // // //       tags: tags,
// // // //       publishedAt: r['published_at'] != null
// // // //           ? DateTime.tryParse(r['published_at'] as String)
// // // //           : null,
// // // //       createdAt: r['created_at'] != null
// // // //           ? DateTime.tryParse(r['created_at'] as String)
// // // //           : null,
// // // //       updatedAt: r['updated_at'] != null
// // // //           ? DateTime.tryParse(r['updated_at'] as String)
// // // //           : null,
// // // //       creatorName:
// // // //           creator?['display_name'] as String? ??
// // // //           creator?['username'] as String?,
// // // //       creatorAvatarUrl: creator?['avatar_url'] as String?,
// // // //       isVerifiedCreator: creator?['verification_status'] == 'verified',
// // // //     );
// // // //   }

// // // //   /// Parse available_languages from DB row.
// // // //   /// Falls back to computing from language/is_multilang if column not present.
// // // //   List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
// // // //     final raw = r['available_languages'];
// // // //     if (raw is List && raw.isNotEmpty) {
// // // //       return raw.map((e) => e.toString()).toList();
// // // //     }
// // // //     // Fallback: derive from language field
// // // //     final lang = r['language'] as String? ?? 'en';
// // // //     final multilang = r['is_multilang'] as bool? ?? false;
// // // //     if (multilang || lang == 'multi') return ['en', 'ar', 'fr'];
// // // //     return [lang];
// // // //   }

// // // //   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
// // // //     id: r['id'] as String,
// // // //     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
// // // //     slug: r['slug'] as String,
// // // //     icon: r['icon'] as String? ?? '📦',
// // // //     sortOrder: r['sort_order'] as int? ?? 0,
// // // //   );

// // // //   PackReview _rowToReview(Map<String, dynamic> r) {
// // // //     final author = r['profiles'] as Map<String, dynamic>? ?? {};
// // // //     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
// // // //     return PackReview(
// // // //       id: r['id'] as String,
// // // //       packId: r['pack_id'] as String,
// // // //       userId: r['user_id'] as String,
// // // //       content: r['content'] as String,
// // // //       rating: ratingRow?['rating'] as int?,
// // // //       authorName: author['display_name'] as String?,
// // // //       authorAvatarUrl: author['avatar_url'] as String?,
// // // //       createdAt: DateTime.parse(r['created_at'] as String),
// // // //     );
// // // //   }
// // // // }

// // // import 'package:supabase_flutter/supabase_flutter.dart';
// // // import 'package:uuid/uuid.dart';

// // // import '../../../core/data/base_repository.dart';
// // // import '../../../core/errors/failures.dart';
// // // import '../../../core/network/api_client.dart';
// // // import '../domain/pack_entity.dart';

// // // export '../domain/pack_entity.dart';

// // // const _uuid = Uuid();

// // // class PackRepository extends BaseRepository {
// // //   PackRepository._();
// // //   static final PackRepository _instance = PackRepository._();
// // //   static PackRepository get instance => _instance;

// // //   final _supabase = Supabase.instance.client;
// // //   final _api = ApiClient.instance;

// // //   Future<List<PackEntity>> browsePacks({
// // //     String? query,
// // //     String? gameType,
// // //     String? categoryId,
// // //     bool freeOnly = false,
// // //     String? language,
// // //     String sortBy = 'avg_rating',
// // //     int page = 0,
// // //     int perPage = 20,
// // //   }) => guardedCall(
// // //     operationName: 'browsePacks',
// // //     operation: () async {
// // //       var q = _supabase
// // //           .from('packs')
// // //           .select('''
// // //                 id, creator_id, title, description, cover_image_url,
// // //                 status, game_type, language, is_multilang, price_mru,
// // //                 card_count, avg_rating, total_ratings, total_purchases,
// // //                 total_plays, version, has_spicy, is_featured, is_promoted,
// // //                 category_id, download_url, published_at, created_at,
// // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // //               ''')
// // //           .eq('status', 'approved')
// // //           .isFilter('deleted_at', null);

// // //       if (gameType != null) q = q.eq('game_type', gameType);
// // //       if (categoryId != null) q = q.eq('category_id', categoryId);
// // //       if (freeOnly) q = q.eq('price_mru', 0);
// // //       if (language != null && language != 'multi') {
// // //         q = q.or('language.eq.$language,is_multilang.eq.true');
// // //       }

// // //       final rows = await q
// // //           .order(sortBy, ascending: false)
// // //           .range(page * perPage, (page + 1) * perPage - 1);

// // //       return rows.map(_rowToEntity).toList();
// // //     },
// // //   );

// // //   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
// // //     operationName: 'getFeaturedPacks',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('packs')
// // //           .select('''
// // //                 id, creator_id, title, description, cover_image_url,
// // //                 status, game_type, language, price_mru, card_count,
// // //                 avg_rating, total_ratings, total_purchases, total_plays,
// // //                 version, has_spicy, is_featured, is_promoted,
// // //                 category_id, download_url,
// // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // //               ''')
// // //           .eq('status', 'approved')
// // //           .eq('is_featured', true)
// // //           .isFilter('deleted_at', null)
// // //           .order('avg_rating', ascending: false)
// // //           .limit(10);
// // //       return rows.map(_rowToEntity).toList();
// // //     },
// // //   );

// // //   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
// // //     operationName: 'getPromotedPacks',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('promoted_packs')
// // //           .select('packs!pack_id(*), position')
// // //           .lte('starts_at', DateTime.now().toIso8601String())
// // //           .gte('ends_at', DateTime.now().toIso8601String())
// // //           .order('position');

// // //       return rows
// // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // //           .toList();
// // //     },
// // //   );

// // //   Future<List<PackCategory>> getCategories() => guardedCall(
// // //     operationName: 'getCategories',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('pack_categories')
// // //           .select()
// // //           .eq('is_active', true)
// // //           .order('sort_order');
// // //       return rows.map(_rowToCategory).toList();
// // //     },
// // //   );

// // //   Future<PackEntity> getPackDetail(String packId) => guardedCall(
// // //     operationName: 'getPackDetail',
// // //     operation: () async {
// // //       final row = await _supabase
// // //           .from('packs')
// // //           .select('''
// // //                 *,
// // //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
// // //                 pack_tags(tag)
// // //               ''')
// // //           .eq('id', packId)
// // //           .single();
// // //       return _rowToEntity(row);
// // //     },
// // //   );

// // //   Future<List<PackReview>> getPackReviews(
// // //     String packId, {
// // //     int limit = 20,
// // //     int page = 0,
// // //   }) => guardedCall(
// // //     operationName: 'getPackReviews',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('pack_reviews')
// // //           .select('''
// // //                 id, pack_id, user_id, content, created_at,
// // //                 profiles!user_id(display_name, avatar_url),
// // //                 pack_ratings!rating_id(rating)
// // //               ''')
// // //           .eq('pack_id', packId)
// // //           .eq('is_visible', true)
// // //           .order('created_at', ascending: false)
// // //           .range(page * limit, (page + 1) * limit - 1);

// // //       return rows.map(_rowToReview).toList();
// // //     },
// // //   );

// // //   Future<PackRating?> getMyRating(String packId, String userId) =>
// // //       softCall<PackRating?>(
// // //         operationName: 'getMyRating',
// // //         operation: () async {
// // //           final row = await _supabase
// // //               .from('pack_ratings')
// // //               .select()
// // //               .eq('pack_id', packId)
// // //               .eq('user_id', userId)
// // //               .maybeSingle();
// // //           if (row == null) return null;
// // //           return PackRating(
// // //             packId: row['pack_id'] as String,
// // //             userId: row['user_id'] as String,
// // //             rating: row['rating'] as int,
// // //           );
// // //         },
// // //       );

// // //   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
// // //     operationName: 'getMyPurchasedPacks',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('pack_purchases')
// // //           .select('pack_id, purchased_at, expires_at, packs(*)')
// // //           .eq('buyer_id', userId)
// // //           .eq('status', 'completed')
// // //           .or(
// // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // //           )
// // //           .order('purchased_at', ascending: false);

// // //       return rows
// // //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// // //           .toList();
// // //     },
// // //   );

// // //   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
// // //     operationName: 'getPurchaseRecords',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('pack_purchases')
// // //           .select('pack_id, purchased_at, expires_at, price_paid_mru')
// // //           .eq('buyer_id', userId)
// // //           .eq('status', 'completed')
// // //           .or(
// // //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// // //           );

// // //       return rows
// // //           .map(
// // //             (r) => PackPurchase(
// // //               packId: r['pack_id'] as String,
// // //               purchasedAt: DateTime.parse(r['purchased_at'] as String),
// // //               expiresAt: DateTime.parse(r['expires_at'] as String),
// // //               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// // //             ),
// // //           )
// // //           .toList();
// // //     },
// // //   );

// // //   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
// // //     operationName: 'hasPurchased',
// // //     operation: () async {
// // //       final row = await _supabase
// // //           .from('pack_purchases')
// // //           .select('id')
// // //           .eq('pack_id', packId)
// // //           .eq('buyer_id', userId)
// // //           .eq('status', 'completed')
// // //           .gt('expires_at', DateTime.now().toIso8601String())
// // //           .maybeSingle();
// // //       return row != null;
// // //     },
// // //   );

// // //   Future<void> purchasePack(String packId) => guardedCall(
// // //     operationName: 'purchasePack',
// // //     operation: () async {
// // //       final response = await _api.post(
// // //         '/v1/packs/purchase',
// // //         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
// // //       );
// // //       final data = response.data as Map<String, dynamic>?;
// // //       final error = data?['error'] as String?;
// // //       if (error != null) throw Exception(error);
// // //     },
// // //   );

// // //   Future<void> ratePack({
// // //     required String packId,
// // //     required String userId,
// // //     required int rating,
// // //   }) => guardedCall(
// // //     operationName: 'ratePack',
// // //     operation: () async {
// // //       await _supabase.from('pack_ratings').upsert({
// // //         'user_id': userId,
// // //         'pack_id': packId,
// // //         'rating': rating,
// // //       }, onConflict: 'pack_id,user_id');
// // //     },
// // //   );

// // //   Future<void> submitReview({
// // //     required String packId,
// // //     required String userId,
// // //     required String content,
// // //     int? rating,
// // //   }) => guardedCall(
// // //     operationName: 'submitReview',
// // //     operation: () async {
// // //       await _supabase.from('pack_reviews').upsert({
// // //         'pack_id': packId,
// // //         'user_id': userId,
// // //         'content': content,
// // //         'updated_at': DateTime.now().toIso8601String(),
// // //       }, onConflict: 'pack_id,user_id');
// // //       if (rating != null) {
// // //         await ratePack(packId: packId, userId: userId, rating: rating);
// // //       }
// // //     },
// // //   );

// // //   Future<void> reportPack({
// // //     required String packId,
// // //     required String reporterId,
// // //     required String reason,
// // //     String? details,
// // //   }) => guardedCall(
// // //     operationName: 'reportPack',
// // //     operation: () async {
// // //       await _supabase.from('pack_reports').upsert({
// // //         'pack_id': packId,
// // //         'reporter_id': reporterId,
// // //         'reason': reason,
// // //         'details': details,
// // //       }, onConflict: 'pack_id,reporter_id');
// // //     },
// // //   );

// // //   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
// // //       guardedCall(
// // //         operationName: 'savePackReactions',
// // //         operation: () async {
// // //           await _api.post(
// // //             '/v1/packs/$packId/reactions',
// // //             data: {
// // //               'reactions': imageUrls
// // //                   .asMap()
// // //                   .entries
// // //                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
// // //                   .toList(),
// // //             },
// // //           );
// // //         },
// // //       );

// // //   Future<List<String>> getPackReactions(String packId) => guardedCall(
// // //     operationName: 'getPackReactions',
// // //     operation: () async {
// // //       try {
// // //         final response = await _api.get('/v1/packs/$packId/reactions');
// // //         final data = response.data as Map<String, dynamic>?;
// // //         final reactions = data?['data']?['reactions'] as List?;
// // //         if (reactions != null) {
// // //           return reactions.map((r) => r['image_url'] as String).toList();
// // //         }
// // //       } catch (_) {}
// // //       final rows = await _supabase
// // //           .from('pack_reactions')
// // //           .select('image_url')
// // //           .eq('pack_id', packId)
// // //           .order('sort_order');
// // //       return (rows as List).map((r) => r['image_url'] as String).toList();
// // //     },
// // //   );

// // //   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
// // //     operationName: 'getMyCreatedPacks',
// // //     operation: () async {
// // //       final rows = await _supabase
// // //           .from('packs')
// // //           .select()
// // //           .eq('creator_id', creatorId)
// // //           .isFilter('deleted_at', null)
// // //           .order('created_at', ascending: false);
// // //       return rows.map(_rowToEntity).toList();
// // //     },
// // //   );

// // //   Future<List<PackEntity>> getMostPlayedPacksForUser(String userId) =>
// // //       guardedCall(
// // //         operationName: 'getMostPlayedPacksForUser',
// // //         operation: () async {
// // //           final memberRows = await _supabase
// // //               .from('room_members')
// // //               .select('room_id')
// // //               .eq('user_id', userId);
// // //           final roomIds = memberRows
// // //               .map((r) => r['room_id'] as String)
// // //               .toList();
// // //           if (roomIds.isEmpty) return const [];

// // //           final playRows = await _supabase
// // //               .from('room_played_packs')
// // //               .select('pack_id')
// // //               .inFilter('room_id', roomIds);

// // //           if (playRows.isEmpty) return const [];

// // //           final counts = <String, int>{};
// // //           for (final r in playRows) {
// // //             final id = r['pack_id'] as String;
// // //             counts[id] = (counts[id] ?? 0) + 1;
// // //           }

// // //           final sorted = counts.entries.toList()
// // //             ..sort((a, b) => b.value.compareTo(a.value));
// // //           final topIds = sorted.take(5).map((e) => e.key).toList();

// // //           final packRows = await _supabase
// // //               .from('packs')
// // //               .select('''
// // //             id, creator_id, title, description, cover_image_url,
// // //             status, game_type, language, price_mru, card_count,
// // //             avg_rating, total_ratings, total_purchases, total_plays,
// // //             version, has_spicy, is_featured,
// // //             profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// // //           ''')
// // //               .inFilter('id', topIds)
// // //               .isFilter('deleted_at', null);

// // //           final entityMap = {
// // //             for (final r in packRows) (r['id'] as String): _rowToEntity(r),
// // //           };
// // //           return topIds
// // //               .where((id) => entityMap.containsKey(id))
// // //               .map((id) => entityMap[id]!)
// // //               .toList();
// // //         },
// // //       );

// // //   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
// // //       guardedCall(
// // //         operationName: 'createPackDraft',
// // //         operation: () async {
// // //           final resp = await _api.post<Map<String, dynamic>>(
// // //             '/v1/packs/create',
// // //             data: {
// // //               'title': draft.titleJson,
// // //               'description': {'en': draft.descriptionEn},
// // //               'game_type': draft.gameType,
// // //               'language': draft.language,
// // //               'price_mru': draft.priceMru,
// // //               'category_id': draft.categoryId,
// // //               'has_spicy': draft.allowSpicy,
// // //               'min_players': draft.minPlayers,
// // //               'tags': draft.tags,
// // //               'cover_image_url': draft.coverImageUrl,
// // //             },
// // //           );
// // //           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
// // //           return _rowToEntity(row);
// // //         },
// // //       );

// // //   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
// // //       guardedCall(
// // //         operationName: 'updatePackDraft',
// // //         operation: () async {
// // //           final resp = await _api.patch<Map<String, dynamic>>(
// // //             '/v1/packs/$packId',
// // //             data: {
// // //               'title': draft.titleJson,
// // //               'description': {'en': draft.descriptionEn},
// // //               'price_mru': draft.priceMru,
// // //               'category_id': draft.categoryId,
// // //               'has_spicy': draft.allowSpicy,
// // //               'min_players': draft.minPlayers,
// // //               'tags': draft.tags,
// // //               'cover_image_url': draft.coverImageUrl,
// // //             },
// // //           );
// // //           return _rowToEntity(
// // //             resp.data!['data']['pack'] as Map<String, dynamic>,
// // //           );
// // //         },
// // //       );

// // //   Future<PackEntity> submitForReview(String packId) => guardedCall(
// // //     operationName: 'submitForReview',
// // //     operation: () async {
// // //       final resp = await _api.post<Map<String, dynamic>>(
// // //         '/v1/packs/$packId/submit',
// // //       );
// // //       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
// // //     },
// // //   );

// // //   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
// // //     operationName: 'addCards',
// // //     operation: () async {
// // //       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

// // //       if (cards.isEmpty) return;

// // //       final rows = cards
// // //           .asMap()
// // //           .entries
// // //           .map(
// // //             (e) => {
// // //               'pack_id': packId,
// // //               'content': e.value.contentJson,
// // //               'card_type': e.value.type.name,
// // //               'difficulty': e.value.difficulty.name,
// // //               'sort_order': e.key,
// // //               'is_active': true,
// // //             },
// // //           )
// // //           .toList();

// // //       await _supabase.from('pack_cards').insert(rows);
// // //     },
// // //   );

// // //   Future<void> deleteCard(String packId, String cardId) => guardedCall(
// // //     operationName: 'deleteCard',
// // //     operation: () async {
// // //       await _supabase
// // //           .from('pack_cards')
// // //           .delete()
// // //           .eq('id', cardId)
// // //           .eq('pack_id', packId);
// // //     },
// // //   );

// // //   Future<Map<String, Set<String>>> getCardLanguageCoverage(
// // //     List<String> packIds,
// // //   ) => guardedCall(
// // //     operationName: 'getCardLanguageCoverage',
// // //     operation: () async {
// // //       if (packIds.isEmpty) return <String, Set<String>>{};

// // //       final rows = await _supabase
// // //           .from('pack_cards')
// // //           .select('pack_id, content')
// // //           .inFilter('pack_id', packIds)
// // //           .eq('is_active', true);

// // //       final coverage = <String, Set<String>>{};
// // //       final seenAnyCard = <String>{};

// // //       for (final r in rows) {
// // //         final packId = r['pack_id'] as String;
// // //         final content = r['content'] as Map<String, dynamic>? ?? {};
// // //         final cardLangs = content.entries
// // //             .where((e) => (e.value as String?)?.trim().isNotEmpty ?? false)
// // //             .map((e) => e.key)
// // //             .toSet();

// // //         if (seenAnyCard.add(packId)) {
// // //           coverage[packId] = cardLangs;
// // //         } else {
// // //           coverage[packId] = coverage[packId]!.intersection(cardLangs);
// // //         }
// // //       }

// // //       return coverage;
// // //     },
// // //   );

// // //   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
// // //     required String contentType,
// // //     required String fileType,
// // //     required int fileSizeBytes,
// // //   }) => guardedCall(
// // //     operationName: 'getUploadUrl',
// // //     operation: () async {
// // //       final resp = await _api.post<Map<String, dynamic>>(
// // //         '/v1/storage/upload-url',
// // //         data: {
// // //           'file_type': fileType,
// // //           'content_type': contentType,
// // //           'file_size_bytes': fileSizeBytes,
// // //         },
// // //       );
// // //       final data = resp.data!['data'] as Map<String, dynamic>;
// // //       return (
// // //         uploadUrl: data['upload_url'] as String,
// // //         publicUrl: data['public_url'] as String,
// // //       );
// // //     },
// // //   );

// // //   PackEntity _rowToEntity(Map<String, dynamic> r) {
// // //     final creator = r['profiles'] as Map<String, dynamic>?;
// // //     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
// // //     final tags = tagRows.map((t) => t['tag'] as String).toList();

// // //     return PackEntity(
// // //       id: r['id'] as String,
// // //       creatorId: r['creator_id'] as String,
// // //       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
// // //       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
// // //       coverImageUrl: r['cover_image_url'] as String?,
// // //       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
// // //       gameType: r['game_type'] as String? ?? 'truth_or_dare',
// // //       language: r['language'] as String? ?? 'en',
// // //       isMultilang: r['is_multilang'] as bool? ?? false,
// // //       availableLanguages: _parseAvailableLanguages(r),
// // //       priceMru: r['price_mru'] as int? ?? 0,
// // //       cardCount: r['card_count'] as int? ?? 0,
// // //       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
// // //       totalRatings: r['total_ratings'] as int? ?? 0,
// // //       totalPurchases: r['total_purchases'] as int? ?? 0,
// // //       totalPlays: r['total_plays'] as int? ?? 0,
// // //       downloadUrl: r['download_url'] as String?,
// // //       version: r['version'] as int? ?? 1,
// // //       hasSpicy: r['has_spicy'] as bool? ?? false,
// // //       isFeatured: r['is_featured'] as bool? ?? false,
// // //       isPromoted: r['is_promoted'] as bool? ?? false,
// // //       categoryId: r['category_id'] as String?,
// // //       tags: tags,
// // //       publishedAt: r['published_at'] != null
// // //           ? DateTime.tryParse(r['published_at'] as String)
// // //           : null,
// // //       createdAt: r['created_at'] != null
// // //           ? DateTime.tryParse(r['created_at'] as String)
// // //           : null,
// // //       updatedAt: r['updated_at'] != null
// // //           ? DateTime.tryParse(r['updated_at'] as String)
// // //           : null,
// // //       creatorName:
// // //           creator?['display_name'] as String? ??
// // //           creator?['username'] as String?,
// // //       creatorAvatarUrl: creator?['avatar_url'] as String?,
// // //       isVerifiedCreator: creator?['verification_status'] == 'verified',
// // //     );
// // //   }

// // //   List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
// // //     final raw = r['available_languages'];
// // //     if (raw is List && raw.isNotEmpty) {
// // //       return raw.map((e) => e.toString()).toList();
// // //     }
// // //     final lang = r['language'] as String? ?? 'en';
// // //     final multilang = r['is_multilang'] as bool? ?? false;
// // //     if (multilang || lang == 'multi') return ['en', 'ar', 'fr'];
// // //     return [lang];
// // //   }

// // //   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
// // //     id: r['id'] as String,
// // //     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
// // //     slug: r['slug'] as String,
// // //     icon: r['icon'] as String? ?? '📦',
// // //     sortOrder: r['sort_order'] as int? ?? 0,
// // //   );

// // //   PackReview _rowToReview(Map<String, dynamic> r) {
// // //     final author = r['profiles'] as Map<String, dynamic>? ?? {};
// // //     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
// // //     return PackReview(
// // //       id: r['id'] as String,
// // //       packId: r['pack_id'] as String,
// // //       userId: r['user_id'] as String,
// // //       content: r['content'] as String,
// // //       rating: ratingRow?['rating'] as int?,
// // //       authorName: author['display_name'] as String?,
// // //       authorAvatarUrl: author['avatar_url'] as String?,
// // //       createdAt: DateTime.parse(r['created_at'] as String),
// // //     );
// // //   }
// // // }

// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'package:uuid/uuid.dart';

// // import '../../../core/data/base_repository.dart';
// // import '../../../core/errors/failures.dart';
// // import '../../../core/network/api_client.dart';
// // import '../domain/pack_entity.dart';

// // export '../domain/pack_entity.dart';

// // const _uuid = Uuid();

// // class PackRepository extends BaseRepository {
// //   PackRepository._();
// //   static final PackRepository _instance = PackRepository._();
// //   static PackRepository get instance => _instance;

// //   final _supabase = Supabase.instance.client;
// //   final _api = ApiClient.instance;

// //   Future<List<PackEntity>> browsePacks({
// //     String? query,
// //     String? gameType,
// //     String? categoryId,
// //     bool freeOnly = false,
// //     String? language,
// //     String sortBy = 'avg_rating',
// //     int page = 0,
// //     int perPage = 20,
// //   }) => guardedCall(
// //     operationName: 'browsePacks',
// //     operation: () async {
// //       var q = _supabase
// //           .from('packs')
// //           .select('''
// //                 id, creator_id, title, description, cover_image_url,
// //                 status, game_type, language, is_multilang, price_mru,
// //                 card_count, avg_rating, total_ratings, total_purchases,
// //                 total_plays, version, has_spicy, is_featured, is_promoted,
// //                 category_id, download_url, published_at, created_at,
// //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// //               ''')
// //           .eq('status', 'approved')
// //           .isFilter('deleted_at', null);

// //       if (gameType != null) q = q.eq('game_type', gameType);
// //       if (categoryId != null) q = q.eq('category_id', categoryId);
// //       if (freeOnly) q = q.eq('price_mru', 0);
// //       if (language != null && language != 'multi') {
// //         q = q.or('language.eq.$language,is_multilang.eq.true');
// //       }

// //       final rows = await q
// //           .order(sortBy, ascending: false)
// //           .range(page * perPage, (page + 1) * perPage - 1);

// //       return rows.map(_rowToEntity).toList();
// //     },
// //   );

// //   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
// //     operationName: 'getFeaturedPacks',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('packs')
// //           .select('''
// //                 id, creator_id, title, description, cover_image_url,
// //                 status, game_type, language, price_mru, card_count,
// //                 avg_rating, total_ratings, total_purchases, total_plays,
// //                 version, has_spicy, is_featured, is_promoted,
// //                 category_id, download_url,
// //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// //               ''')
// //           .eq('status', 'approved')
// //           .eq('is_featured', true)
// //           .isFilter('deleted_at', null)
// //           .order('avg_rating', ascending: false)
// //           .limit(10);
// //       return rows.map(_rowToEntity).toList();
// //     },
// //   );

// //   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
// //     operationName: 'getPromotedPacks',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('promoted_packs')
// //           .select('packs!pack_id(*), position')
// //           .lte('starts_at', DateTime.now().toIso8601String())
// //           .gte('ends_at', DateTime.now().toIso8601String())
// //           .order('position');

// //       return rows
// //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// //           .toList();
// //     },
// //   );

// //   Future<List<PackCategory>> getCategories() => guardedCall(
// //     operationName: 'getCategories',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('pack_categories')
// //           .select()
// //           .eq('is_active', true)
// //           .order('sort_order');
// //       return rows.map(_rowToCategory).toList();
// //     },
// //   );

// //   Future<PackEntity> getPackDetail(String packId) => guardedCall(
// //     operationName: 'getPackDetail',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('packs')
// //           .select('''
// //                 *,
// //                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
// //                 pack_tags(tag)
// //               ''')
// //           .eq('id', packId)
// //           .single();
// //       return _rowToEntity(row);
// //     },
// //   );

// //   Future<List<PackReview>> getPackReviews(
// //     String packId, {
// //     int limit = 20,
// //     int page = 0,
// //   }) => guardedCall(
// //     operationName: 'getPackReviews',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('pack_reviews')
// //           .select('''
// //                 id, pack_id, user_id, content, created_at,
// //                 profiles!user_id(display_name, avatar_url),
// //                 pack_ratings!rating_id(rating)
// //               ''')
// //           .eq('pack_id', packId)
// //           .eq('is_visible', true)
// //           .order('created_at', ascending: false)
// //           .range(page * limit, (page + 1) * limit - 1);

// //       return rows.map(_rowToReview).toList();
// //     },
// //   );

// //   Future<PackRating?> getMyRating(String packId, String userId) =>
// //       softCall<PackRating?>(
// //         operationName: 'getMyRating',
// //         operation: () async {
// //           final row = await _supabase
// //               .from('pack_ratings')
// //               .select()
// //               .eq('pack_id', packId)
// //               .eq('user_id', userId)
// //               .maybeSingle();
// //           if (row == null) return null;
// //           return PackRating(
// //             packId: row['pack_id'] as String,
// //             userId: row['user_id'] as String,
// //             rating: row['rating'] as int,
// //           );
// //         },
// //       );

// //   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
// //     operationName: 'getMyPurchasedPacks',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('pack_purchases')
// //           .select('pack_id, purchased_at, expires_at, packs(*)')
// //           .eq('buyer_id', userId)
// //           .eq('status', 'completed')
// //           .or(
// //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// //           )
// //           .order('purchased_at', ascending: false);

// //       return rows
// //           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
// //           .toList();
// //     },
// //   );

// //   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
// //     operationName: 'getPurchaseRecords',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('pack_purchases')
// //           .select('pack_id, purchased_at, expires_at, price_paid_mru')
// //           .eq('buyer_id', userId)
// //           .eq('status', 'completed')
// //           .or(
// //             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
// //           );

// //       return rows
// //           .map(
// //             (r) => PackPurchase(
// //               packId: r['pack_id'] as String,
// //               purchasedAt: DateTime.parse(r['purchased_at'] as String),
// //               expiresAt: DateTime.parse(r['expires_at'] as String),
// //               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
// //             ),
// //           )
// //           .toList();
// //     },
// //   );

// //   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
// //     operationName: 'hasPurchased',
// //     operation: () async {
// //       final row = await _supabase
// //           .from('pack_purchases')
// //           .select('id')
// //           .eq('pack_id', packId)
// //           .eq('buyer_id', userId)
// //           .eq('status', 'completed')
// //           .gt('expires_at', DateTime.now().toIso8601String())
// //           .maybeSingle();
// //       return row != null;
// //     },
// //   );

// //   Future<void> purchasePack(String packId) => guardedCall(
// //     operationName: 'purchasePack',
// //     operation: () async {
// //       final response = await _api.post(
// //         '/v1/packs/purchase',
// //         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
// //       );
// //       final data = response.data as Map<String, dynamic>?;
// //       final error = data?['error'] as String?;
// //       if (error != null) throw Exception(error);
// //     },
// //   );

// //   Future<void> ratePack({
// //     required String packId,
// //     required String userId,
// //     required int rating,
// //   }) => guardedCall(
// //     operationName: 'ratePack',
// //     operation: () async {
// //       await _supabase.from('pack_ratings').upsert({
// //         'user_id': userId,
// //         'pack_id': packId,
// //         'rating': rating,
// //       }, onConflict: 'pack_id,user_id');
// //     },
// //   );

// //   Future<void> submitReview({
// //     required String packId,
// //     required String userId,
// //     required String content,
// //     int? rating,
// //   }) => guardedCall(
// //     operationName: 'submitReview',
// //     operation: () async {
// //       await _supabase.from('pack_reviews').upsert({
// //         'pack_id': packId,
// //         'user_id': userId,
// //         'content': content,
// //         'updated_at': DateTime.now().toIso8601String(),
// //       }, onConflict: 'pack_id,user_id');
// //       if (rating != null) {
// //         await ratePack(packId: packId, userId: userId, rating: rating);
// //       }
// //     },
// //   );

// //   Future<void> reportPack({
// //     required String packId,
// //     required String reporterId,
// //     required String reason,
// //     String? details,
// //   }) => guardedCall(
// //     operationName: 'reportPack',
// //     operation: () async {
// //       await _supabase.from('pack_reports').upsert({
// //         'pack_id': packId,
// //         'reporter_id': reporterId,
// //         'reason': reason,
// //         'details': details,
// //       }, onConflict: 'pack_id,reporter_id');
// //     },
// //   );

// //   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
// //       guardedCall(
// //         operationName: 'savePackReactions',
// //         operation: () async {
// //           await _api.post(
// //             '/v1/packs/$packId/reactions',
// //             data: {
// //               'reactions': imageUrls
// //                   .asMap()
// //                   .entries
// //                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
// //                   .toList(),
// //             },
// //           );
// //         },
// //       );

// //   Future<List<String>> getPackReactions(String packId) => guardedCall(
// //     operationName: 'getPackReactions',
// //     operation: () async {
// //       try {
// //         final response = await _api.get('/v1/packs/$packId/reactions');
// //         final data = response.data as Map<String, dynamic>?;
// //         final reactions = data?['data']?['reactions'] as List?;
// //         if (reactions != null) {
// //           return reactions.map((r) => r['image_url'] as String).toList();
// //         }
// //       } catch (_) {}
// //       final rows = await _supabase
// //           .from('pack_reactions')
// //           .select('image_url')
// //           .eq('pack_id', packId)
// //           .order('sort_order');
// //       return (rows as List).map((r) => r['image_url'] as String).toList();
// //     },
// //   );

// //   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
// //     operationName: 'getMyCreatedPacks',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('packs')
// //           .select()
// //           .eq('creator_id', creatorId)
// //           .isFilter('deleted_at', null)
// //           .order('created_at', ascending: false);
// //       return rows.map(_rowToEntity).toList();
// //     },
// //   );

// //   Future<List<PackEntity>> getMostPlayedPacksForUser(String userId) =>
// //       guardedCall(
// //         operationName: 'getMostPlayedPacksForUser',
// //         operation: () async {
// //           final memberRows = await _supabase
// //               .from('room_members')
// //               .select('room_id')
// //               .eq('user_id', userId);
// //           final roomIds = memberRows
// //               .map((r) => r['room_id'] as String)
// //               .toList();
// //           if (roomIds.isEmpty) return const [];

// //           final playRows = await _supabase
// //               .from('room_played_packs')
// //               .select('pack_id')
// //               .inFilter('room_id', roomIds);

// //           if (playRows.isEmpty) return const [];

// //           final counts = <String, int>{};
// //           for (final r in playRows) {
// //             final id = r['pack_id'] as String;
// //             counts[id] = (counts[id] ?? 0) + 1;
// //           }

// //           final sorted = counts.entries.toList()
// //             ..sort((a, b) => b.value.compareTo(a.value));
// //           final topIds = sorted.take(5).map((e) => e.key).toList();

// //           final packRows = await _supabase
// //               .from('packs')
// //               .select('''
// //             id, creator_id, title, description, cover_image_url,
// //             status, game_type, language, price_mru, card_count,
// //             avg_rating, total_ratings, total_purchases, total_plays,
// //             version, has_spicy, is_featured,
// //             profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
// //           ''')
// //               .inFilter('id', topIds)
// //               .isFilter('deleted_at', null);

// //           final entityMap = {
// //             for (final r in packRows) (r['id'] as String): _rowToEntity(r),
// //           };
// //           return topIds
// //               .where((id) => entityMap.containsKey(id))
// //               .map((id) => entityMap[id]!)
// //               .toList();
// //         },
// //       );

// //   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
// //       guardedCall(
// //         operationName: 'createPackDraft',
// //         operation: () async {
// //           final resp = await _api.post<Map<String, dynamic>>(
// //             '/v1/packs/create',
// //             data: {
// //               'title': draft.titleJson,
// //               'description': {'en': draft.descriptionEn},
// //               'game_type': draft.gameType,
// //               'language': draft.language,
// //               'price_mru': draft.priceMru,
// //               'category_id': draft.categoryId,
// //               'has_spicy': draft.allowSpicy,
// //               'min_players': draft.minPlayers,
// //               'tags': draft.tags,
// //               'cover_image_url': draft.coverImageUrl,
// //             },
// //           );
// //           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
// //           return _rowToEntity(row);
// //         },
// //       );

// //   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
// //       guardedCall(
// //         operationName: 'updatePackDraft',
// //         operation: () async {
// //           final resp = await _api.patch<Map<String, dynamic>>(
// //             '/v1/packs/$packId',
// //             data: {
// //               'title': draft.titleJson,
// //               'description': {'en': draft.descriptionEn},
// //               'price_mru': draft.priceMru,
// //               'category_id': draft.categoryId,
// //               'has_spicy': draft.allowSpicy,
// //               'min_players': draft.minPlayers,
// //               'tags': draft.tags,
// //               'cover_image_url': draft.coverImageUrl,
// //             },
// //           );
// //           return _rowToEntity(
// //             resp.data!['data']['pack'] as Map<String, dynamic>,
// //           );
// //         },
// //       );

// //   Future<PackEntity> submitForReview(String packId) => guardedCall(
// //     operationName: 'submitForReview',
// //     operation: () async {
// //       final resp = await _api.post<Map<String, dynamic>>(
// //         '/v1/packs/$packId/submit',
// //       );
// //       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
// //     },
// //   );

// //   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
// //     operationName: 'addCards',
// //     operation: () async {
// //       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

// //       if (cards.isEmpty) return;

// //       final rows = cards
// //           .asMap()
// //           .entries
// //           .map(
// //             (e) => {
// //               'pack_id': packId,
// //               'content': e.value.contentJson,
// //               'card_type': e.value.type.name,
// //               'difficulty': e.value.difficulty.name,
// //               'sort_order': e.key,
// //               'is_active': true,
// //             },
// //           )
// //           .toList();

// //       await _supabase.from('pack_cards').insert(rows);
// //     },
// //   );

// //   Future<void> deleteCard(String packId, String cardId) => guardedCall(
// //     operationName: 'deleteCard',
// //     operation: () async {
// //       await _supabase
// //           .from('pack_cards')
// //           .delete()
// //           .eq('id', cardId)
// //           .eq('pack_id', packId);
// //     },
// //   );

// //   Future<Map<String, Set<String>>> getCardLanguageCoverage(
// //     List<String> packIds,
// //   ) => guardedCall(
// //     operationName: 'getCardLanguageCoverage',
// //     operation: () async {
// //       if (packIds.isEmpty) return <String, Set<String>>{};

// //       final rows = await _supabase
// //           .from('pack_cards')
// //           .select('pack_id, content')
// //           .inFilter('pack_id', packIds)
// //           .eq('is_active', true);

// //       final coverage = <String, Set<String>>{};
// //       final seenAnyCard = <String>{};

// //       for (final r in rows) {
// //         final packId = r['pack_id'] as String;
// //         final content = r['content'] as Map<String, dynamic>? ?? {};
// //         final cardLangs = content.entries
// //             .where((e) => (e.value as String?)?.trim().isNotEmpty ?? false)
// //             .map((e) => e.key)
// //             .toSet();

// //         if (seenAnyCard.add(packId)) {
// //           coverage[packId] = cardLangs;
// //         } else {
// //           coverage[packId] = coverage[packId]!.intersection(cardLangs);
// //         }
// //       }

// //       return coverage;
// //     },
// //   );

// //   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
// //     required String contentType,
// //     required String fileType,
// //     required int fileSizeBytes,
// //   }) => guardedCall(
// //     operationName: 'getUploadUrl',
// //     operation: () async {
// //       final resp = await _api.post<Map<String, dynamic>>(
// //         '/v1/storage/upload-url',
// //         data: {
// //           'file_type': fileType,
// //           'content_type': contentType,
// //           'file_size_bytes': fileSizeBytes,
// //         },
// //       );
// //       final data = resp.data!['data'] as Map<String, dynamic>;
// //       return (
// //         uploadUrl: data['upload_url'] as String,
// //         publicUrl: data['public_url'] as String,
// //       );
// //     },
// //   );

// //   PackEntity _rowToEntity(Map<String, dynamic> r) {
// //     final creator = r['profiles'] as Map<String, dynamic>?;
// //     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
// //     final tags = tagRows.map((t) => t['tag'] as String).toList();

// //     return PackEntity(
// //       id: r['id'] as String,
// //       creatorId: r['creator_id'] as String,
// //       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
// //       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
// //       coverImageUrl: r['cover_image_url'] as String?,
// //       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
// //       gameType: r['game_type'] as String? ?? 'truth_or_dare',
// //       language: r['language'] as String? ?? 'en',
// //       isMultilang: r['is_multilang'] as bool? ?? false,
// //       availableLanguages: _parseAvailableLanguages(r),
// //       priceMru: r['price_mru'] as int? ?? 0,
// //       cardCount: r['card_count'] as int? ?? 0,
// //       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
// //       totalRatings: r['total_ratings'] as int? ?? 0,
// //       totalPurchases: r['total_purchases'] as int? ?? 0,
// //       totalPlays: r['total_plays'] as int? ?? 0,
// //       downloadUrl: r['download_url'] as String?,
// //       version: r['version'] as int? ?? 1,
// //       hasSpicy: r['has_spicy'] as bool? ?? false,
// //       isFeatured: r['is_featured'] as bool? ?? false,
// //       isPromoted: r['is_promoted'] as bool? ?? false,
// //       categoryId: r['category_id'] as String?,
// //       tags: tags,
// //       publishedAt: r['published_at'] != null
// //           ? DateTime.tryParse(r['published_at'] as String)
// //           : null,
// //       createdAt: r['created_at'] != null
// //           ? DateTime.tryParse(r['created_at'] as String)
// //           : null,
// //       updatedAt: r['updated_at'] != null
// //           ? DateTime.tryParse(r['updated_at'] as String)
// //           : null,
// //       creatorName:
// //           creator?['display_name'] as String? ??
// //           creator?['username'] as String?,
// //       creatorAvatarUrl: creator?['avatar_url'] as String?,
// //       isVerifiedCreator: creator?['verification_status'] == 'verified',
// //     );
// //   }

// //   List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
// //     final raw = r['available_languages'];
// //     if (raw is List && raw.isNotEmpty) {
// //       return raw.map((e) => e.toString()).toList();
// //     }
// //     final lang = r['language'] as String? ?? 'en';
// //     final multilang = r['is_multilang'] as bool? ?? false;
// //     if (multilang || lang == 'multi') return ['en', 'ar', 'fr'];
// //     return [lang];
// //   }

// //   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
// //     id: r['id'] as String,
// //     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
// //     slug: r['slug'] as String,
// //     icon: r['icon'] as String? ?? '📦',
// //     sortOrder: r['sort_order'] as int? ?? 0,
// //   );

// //   PackReview _rowToReview(Map<String, dynamic> r) {
// //     final author = r['profiles'] as Map<String, dynamic>? ?? {};
// //     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
// //     return PackReview(
// //       id: r['id'] as String,
// //       packId: r['pack_id'] as String,
// //       userId: r['user_id'] as String,
// //       content: r['content'] as String,
// //       rating: ratingRow?['rating'] as int?,
// //       authorName: author['display_name'] as String?,
// //       authorAvatarUrl: author['avatar_url'] as String?,
// //       createdAt: DateTime.parse(r['created_at'] as String),
// //     );
// //   }

// //   Future<bool> hasFreePacksAvailable() => guardedCall(
// //     operationName: 'hasFreePacksAvailable',
// //     operation: () async {
// //       final rows = await _supabase
// //           .from('packs')
// //           .select('id')
// //           .eq('status', 'approved')
// //           .eq('price_mru', 0)
// //           .isFilter('deleted_at', null)
// //           .limit(1);
// //       return rows.isNotEmpty;
// //     },
// //   );
// // }

// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:uuid/uuid.dart';

// import '../../../core/data/base_repository.dart';
// import '../../../core/errors/failures.dart';
// import '../../../core/network/api_client.dart';
// import '../domain/pack_entity.dart';

// export '../domain/pack_entity.dart';

// const _uuid = Uuid();

// class PackRepository extends BaseRepository {
//   PackRepository._();
//   static final PackRepository _instance = PackRepository._();
//   static PackRepository get instance => _instance;

//   final _supabase = Supabase.instance.client;
//   final _api = ApiClient.instance;

//   Future<List<PackEntity>> browsePacks({
//     String? query,
//     String? gameType,
//     String? categoryId,
//     bool freeOnly = false,
//     String? language,
//     String sortBy = 'avg_rating',
//     int page = 0,
//     int perPage = 20,
//   }) => guardedCall(
//     operationName: 'browsePacks',
//     operation: () async {
//       var q = _supabase
//           .from('packs')
//           .select('''
//                 id, creator_id, title, description, cover_image_url,
//                 status, game_type, language, is_multilang, price_mru,
//                 card_count, avg_rating, total_ratings, total_purchases,
//                 total_plays, version, has_spicy, is_featured, is_promoted,
//                 category_id, download_url, published_at, created_at,
//                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
//               ''')
//           .eq('status', 'approved')
//           .isFilter('deleted_at', null);

//       if (gameType != null) q = q.eq('game_type', gameType);
//       if (categoryId != null) q = q.eq('category_id', categoryId);
//       if (freeOnly) q = q.eq('price_mru', 0);
//       if (language != null && language != 'multi') {
//         q = q.or('language.eq.$language,is_multilang.eq.true');
//       }

//       final rows = await q
//           .order(sortBy, ascending: false)
//           .range(page * perPage, (page + 1) * perPage - 1);

//       return rows.map(_rowToEntity).toList();
//     },
//   );

//   Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
//     operationName: 'getFeaturedPacks',
//     operation: () async {
//       final rows = await _supabase
//           .from('packs')
//           .select('''
//                 id, creator_id, title, description, cover_image_url,
//                 status, game_type, language, price_mru, card_count,
//                 avg_rating, total_ratings, total_purchases, total_plays,
//                 version, has_spicy, is_featured, is_promoted,
//                 category_id, download_url,
//                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
//               ''')
//           .eq('status', 'approved')
//           .eq('is_featured', true)
//           .isFilter('deleted_at', null)
//           .order('avg_rating', ascending: false)
//           .limit(10);
//       return rows.map(_rowToEntity).toList();
//     },
//   );

//   Future<List<PackEntity>> getPromotedPacks() => guardedCall(
//     operationName: 'getPromotedPacks',
//     operation: () async {
//       final rows = await _supabase
//           .from('promoted_packs')
//           .select('packs!pack_id(*), position')
//           .lte('starts_at', DateTime.now().toIso8601String())
//           .gte('ends_at', DateTime.now().toIso8601String())
//           .order('position');

//       return rows
//           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
//           .toList();
//     },
//   );

//   Future<List<PackCategory>> getCategories() => guardedCall(
//     operationName: 'getCategories',
//     operation: () async {
//       final rows = await _supabase
//           .from('pack_categories')
//           .select()
//           .eq('is_active', true)
//           .order('sort_order');
//       return rows.map(_rowToCategory).toList();
//     },
//   );

//   Future<PackEntity> getPackDetail(String packId) => guardedCall(
//     operationName: 'getPackDetail',
//     operation: () async {
//       final row = await _supabase
//           .from('packs')
//           .select('''
//                 *,
//                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
//                 pack_tags(tag)
//               ''')
//           .eq('id', packId)
//           .single();
//       return _rowToEntity(row);
//     },
//   );

//   Future<List<PackReview>> getPackReviews(
//     String packId, {
//     int limit = 20,
//     int page = 0,
//   }) => guardedCall(
//     operationName: 'getPackReviews',
//     operation: () async {
//       final rows = await _supabase
//           .from('pack_reviews')
//           .select('''
//                 id, pack_id, user_id, content, created_at,
//                 profiles!user_id(display_name, avatar_url),
//                 pack_ratings!rating_id(rating)
//               ''')
//           .eq('pack_id', packId)
//           .eq('is_visible', true)
//           .order('created_at', ascending: false)
//           .range(page * limit, (page + 1) * limit - 1);

//       return rows.map(_rowToReview).toList();
//     },
//   );

//   Future<PackRating?> getMyRating(String packId, String userId) =>
//       softCall<PackRating?>(
//         operationName: 'getMyRating',
//         operation: () async {
//           final row = await _supabase
//               .from('pack_ratings')
//               .select()
//               .eq('pack_id', packId)
//               .eq('user_id', userId)
//               .maybeSingle();
//           if (row == null) return null;
//           return PackRating(
//             packId: row['pack_id'] as String,
//             userId: row['user_id'] as String,
//             rating: row['rating'] as int,
//           );
//         },
//       );

//   Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
//     operationName: 'getMyPurchasedPacks',
//     operation: () async {
//       final rows = await _supabase
//           .from('pack_purchases')
//           .select('pack_id, purchased_at, expires_at, packs(*)')
//           .eq('buyer_id', userId)
//           .eq('status', 'completed')
//           .or(
//             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
//           )
//           .order('purchased_at', ascending: false);

//       return rows
//           .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
//           .toList();
//     },
//   );

//   Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
//     operationName: 'getPurchaseRecords',
//     operation: () async {
//       final rows = await _supabase
//           .from('pack_purchases')
//           .select('pack_id, purchased_at, expires_at, price_paid_mru')
//           .eq('buyer_id', userId)
//           .eq('status', 'completed')
//           .or(
//             'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
//           );

//       return rows
//           .map(
//             (r) => PackPurchase(
//               packId: r['pack_id'] as String,
//               purchasedAt: DateTime.parse(r['purchased_at'] as String),
//               expiresAt: DateTime.parse(r['expires_at'] as String),
//               pricePaidMru: r['price_paid_mru'] as int? ?? 0,
//             ),
//           )
//           .toList();
//     },
//   );

//   Future<bool> hasPurchased(String packId, String userId) => guardedCall(
//     operationName: 'hasPurchased',
//     operation: () async {
//       final row = await _supabase
//           .from('pack_purchases')
//           .select('id')
//           .eq('pack_id', packId)
//           .eq('buyer_id', userId)
//           .eq('status', 'completed')
//           .gt('expires_at', DateTime.now().toIso8601String())
//           .maybeSingle();
//       return row != null;
//     },
//   );

//   Future<void> purchasePack(String packId) => guardedCall(
//     operationName: 'purchasePack',
//     operation: () async {
//       final response = await _api.post(
//         '/v1/packs/purchase',
//         data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
//       );
//       final data = response.data as Map<String, dynamic>?;
//       final error = data?['error'] as String?;
//       if (error != null) throw Exception(error);
//     },
//   );

//   Future<void> ratePack({
//     required String packId,
//     required String userId,
//     required int rating,
//   }) => guardedCall(
//     operationName: 'ratePack',
//     operation: () async {
//       await _supabase.from('pack_ratings').upsert({
//         'user_id': userId,
//         'pack_id': packId,
//         'rating': rating,
//       }, onConflict: 'pack_id,user_id');
//     },
//   );

//   Future<void> submitReview({
//     required String packId,
//     required String userId,
//     required String content,
//     int? rating,
//   }) => guardedCall(
//     operationName: 'submitReview',
//     operation: () async {
//       await _supabase.from('pack_reviews').upsert({
//         'id': _uuid.v4(),
//         'pack_id': packId,
//         'user_id': userId,
//         'content': content,
//       }, onConflict: 'pack_id,user_id');
//       if (rating != null) {
//         await ratePack(packId: packId, userId: userId, rating: rating);
//       }
//     },
//   );

//   Future<void> reportPack({
//     required String packId,
//     required String reporterId,
//     required String reason,
//     String? details,
//   }) => guardedCall(
//     operationName: 'reportPack',
//     operation: () async {
//       await _supabase.from('pack_reports').upsert({
//         'pack_id': packId,
//         'reporter_id': reporterId,
//         'reason': reason,
//         'details': details,
//       }, onConflict: 'pack_id,reporter_id');
//     },
//   );

//   Future<void> savePackReactions(String packId, List<String> imageUrls) =>
//       guardedCall(
//         operationName: 'savePackReactions',
//         operation: () async {
//           await _api.post(
//             '/v1/packs/$packId/reactions',
//             data: {
//               'reactions': imageUrls
//                   .asMap()
//                   .entries
//                   .map((e) => {'image_url': e.value, 'sort_order': e.key})
//                   .toList(),
//             },
//           );
//         },
//       );

//   Future<List<String>> getPackReactions(String packId) => guardedCall(
//     operationName: 'getPackReactions',
//     operation: () async {
//       try {
//         final response = await _api.get('/v1/packs/$packId/reactions');
//         final data = response.data as Map<String, dynamic>?;
//         final reactions = data?['data']?['reactions'] as List?;
//         if (reactions != null) {
//           return reactions.map((r) => r['image_url'] as String).toList();
//         }
//       } catch (_) {}
//       final rows = await _supabase
//           .from('pack_reactions')
//           .select('image_url')
//           .eq('pack_id', packId)
//           .order('sort_order');
//       return (rows as List).map((r) => r['image_url'] as String).toList();
//     },
//   );

//   Future<bool> hasFreePacksAvailable() => guardedCall(
//     operationName: 'hasFreePacksAvailable',
//     operation: () async {
//       final rows = await _supabase
//           .from('packs')
//           .select('id')
//           .eq('status', 'approved')
//           .eq('price_mru', 0)
//           .isFilter('deleted_at', null)
//           .limit(1);
//       return rows.isNotEmpty;
//     },
//   );

//   Future<List<PackEntity>> getMostPlayedPacksForUser(String userId) =>
//       guardedCall(
//         operationName: 'getMostPlayedPacksForUser',
//         operation: () async {
//           final memberRows = await _supabase
//               .from('room_members')
//               .select('room_id')
//               .eq('user_id', userId);
//           final roomIds = memberRows
//               .map((r) => r['room_id'] as String)
//               .toSet()
//               .toList();
//           if (roomIds.isEmpty) return <PackEntity>[];

//           final playedRows = await _supabase
//               .from('room_played_packs')
//               .select('pack_id')
//               .inFilter('room_id', roomIds);

//           final counts = <String, int>{};
//           for (final r in playedRows) {
//             final id = r['pack_id'] as String;
//             counts[id] = (counts[id] ?? 0) + 1;
//           }
//           if (counts.isEmpty) return <PackEntity>[];

//           final topIds = counts.entries.toList()
//             ..sort((a, b) => b.value.compareTo(a.value));
//           final ids = topIds.take(10).map((e) => e.key).toList();

//           final packRows = await _supabase
//               .from('packs')
//               .select('''
//                 id, creator_id, title, description, cover_image_url,
//                 status, game_type, language, is_multilang, price_mru,
//                 card_count, avg_rating, total_ratings, total_purchases,
//                 total_plays, version, has_spicy, is_featured, is_promoted,
//                 category_id, download_url, published_at, created_at,
//                 profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
//               ''')
//               .inFilter('id', ids)
//               .isFilter('deleted_at', null);

//           final packsById = {
//             for (final row in packRows) row['id'] as String: _rowToEntity(row),
//           };
//           return ids
//               .where(packsById.containsKey)
//               .map((id) => packsById[id]!)
//               .toList();
//         },
//       );

//   Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
//     operationName: 'getMyCreatedPacks',
//     operation: () async {
//       final rows = await _supabase
//           .from('packs')
//           .select()
//           .eq('creator_id', creatorId)
//           .isFilter('deleted_at', null)
//           .order('created_at', ascending: false);
//       return rows.map(_rowToEntity).toList();
//     },
//   );

//   Future<List<PackEntity>> getPublicPacksByCreator(String creatorId) =>
//       guardedCall(
//         operationName: 'getPublicPacksByCreator',
//         operation: () async {
//           final rows = await _supabase
//               .from('packs')
//               .select('''
//             id, creator_id, title, description, cover_image_url,
//             status, game_type, language, is_multilang, price_mru,
//             card_count, avg_rating, total_ratings, total_purchases,
//             total_plays, version, has_spicy, is_featured, is_promoted,
//             category_id, download_url, published_at, created_at,
//             profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
//           ''')
//               .eq('creator_id', creatorId)
//               .eq('status', 'approved')
//               .isFilter('deleted_at', null)
//               .order('total_plays', ascending: false);
//           return rows.map(_rowToEntity).toList();
//         },
//       );

//   Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
//       guardedCall(
//         operationName: 'createPackDraft',
//         operation: () async {
//           final resp = await _api.post<Map<String, dynamic>>(
//             '/v1/packs/create',
//             data: {
//               'title': draft.titleJson,
//               'description': {'en': draft.descriptionEn},
//               'game_type': draft.gameType,
//               'language': draft.language,
//               'price_mru': draft.priceMru,
//               'category_id': draft.categoryId,
//               'has_spicy': draft.allowSpicy,
//               'min_players': draft.minPlayers,
//               'tags': draft.tags,
//               'cover_image_url': draft.coverImageUrl,
//             },
//           );
//           final row = resp.data!['data']['pack'] as Map<String, dynamic>;
//           return _rowToEntity(row);
//         },
//       );

//   Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
//       guardedCall(
//         operationName: 'updatePackDraft',
//         operation: () async {
//           final resp = await _api.patch<Map<String, dynamic>>(
//             '/v1/packs/$packId',
//             data: {
//               'title': draft.titleJson,
//               'description': {'en': draft.descriptionEn},
//               'price_mru': draft.priceMru,
//               'category_id': draft.categoryId,
//               'has_spicy': draft.allowSpicy,
//               'min_players': draft.minPlayers,
//               'tags': draft.tags,
//               'cover_image_url': draft.coverImageUrl,
//             },
//           );
//           return _rowToEntity(
//             resp.data!['data']['pack'] as Map<String, dynamic>,
//           );
//         },
//       );

//   Future<PackEntity> submitForReview(String packId) => guardedCall(
//     operationName: 'submitForReview',
//     operation: () async {
//       final resp = await _api.post<Map<String, dynamic>>(
//         '/v1/packs/$packId/submit',
//       );
//       return _rowToEntity(resp.data!['data']['pack'] as Map<String, dynamic>);
//     },
//   );

//   Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
//     operationName: 'addCards',
//     operation: () async {
//       await _supabase.from('pack_cards').delete().eq('pack_id', packId);

//       if (cards.isEmpty) return;

//       final rows = cards
//           .asMap()
//           .entries
//           .map(
//             (e) => {
//               'pack_id': packId,
//               'content': e.value.contentJson,
//               'card_type': e.value.type.name,
//               'difficulty': e.value.difficulty.name,
//               'sort_order': e.key,
//               'is_active': true,
//             },
//           )
//           .toList();

//       await _supabase.from('pack_cards').insert(rows);
//     },
//   );

//   Future<void> deleteCard(String packId, String cardId) => guardedCall(
//     operationName: 'deleteCard',
//     operation: () async {
//       await _supabase
//           .from('pack_cards')
//           .delete()
//           .eq('id', cardId)
//           .eq('pack_id', packId);
//     },
//   );

//   Future<Map<String, Set<String>>> getCardLanguageCoverage(
//     List<String> packIds,
//   ) => guardedCall(
//     operationName: 'getCardLanguageCoverage',
//     operation: () async {
//       if (packIds.isEmpty) return <String, Set<String>>{};

//       final rows = await _supabase
//           .from('pack_cards')
//           .select('pack_id, content')
//           .inFilter('pack_id', packIds)
//           .eq('is_active', true);

//       final coverage = <String, Set<String>>{};
//       final seenAnyCard = <String>{};

//       for (final r in rows) {
//         final packId = r['pack_id'] as String;
//         final content = r['content'] as Map<String, dynamic>? ?? {};
//         final cardLangs = content.entries
//             .where((e) => (e.value as String?)?.trim().isNotEmpty ?? false)
//             .map((e) => e.key)
//             .toSet();

//         if (seenAnyCard.add(packId)) {
//           coverage[packId] = cardLangs;
//         } else {
//           coverage[packId] = coverage[packId]!.intersection(cardLangs);
//         }
//       }

//       return coverage;
//     },
//   );

//   Future<({String uploadUrl, String publicUrl})> getUploadUrl({
//     required String contentType,
//     required String fileType,
//     required int fileSizeBytes,
//   }) => guardedCall(
//     operationName: 'getUploadUrl',
//     operation: () async {
//       final resp = await _api.post<Map<String, dynamic>>(
//         '/v1/storage/upload-url',
//         data: {
//           'file_type': fileType,
//           'content_type': contentType,
//           'file_size_bytes': fileSizeBytes,
//         },
//       );
//       final data = resp.data!['data'] as Map<String, dynamic>;
//       return (
//         uploadUrl: data['upload_url'] as String,
//         publicUrl: data['public_url'] as String,
//       );
//     },
//   );

//   PackEntity _rowToEntity(Map<String, dynamic> r) {
//     final creator = r['profiles'] as Map<String, dynamic>?;
//     final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
//     final tags = tagRows.map((t) => t['tag'] as String).toList();

//     return PackEntity(
//       id: r['id'] as String,
//       creatorId: r['creator_id'] as String,
//       titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
//       descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
//       coverImageUrl: r['cover_image_url'] as String?,
//       status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
//       gameType: r['game_type'] as String? ?? 'truth_or_dare',
//       language: r['language'] as String? ?? 'en',
//       isMultilang: r['is_multilang'] as bool? ?? false,
//       availableLanguages: _parseAvailableLanguages(r),
//       priceMru: r['price_mru'] as int? ?? 0,
//       cardCount: r['card_count'] as int? ?? 0,
//       avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
//       totalRatings: r['total_ratings'] as int? ?? 0,
//       totalPurchases: r['total_purchases'] as int? ?? 0,
//       totalPlays: r['total_plays'] as int? ?? 0,
//       downloadUrl: r['download_url'] as String?,
//       version: r['version'] as int? ?? 1,
//       hasSpicy: r['has_spicy'] as bool? ?? false,
//       isFeatured: r['is_featured'] as bool? ?? false,
//       isPromoted: r['is_promoted'] as bool? ?? false,
//       categoryId: r['category_id'] as String?,
//       tags: tags,
//       publishedAt: r['published_at'] != null
//           ? DateTime.tryParse(r['published_at'] as String)
//           : null,
//       createdAt: r['created_at'] != null
//           ? DateTime.tryParse(r['created_at'] as String)
//           : null,
//       updatedAt: r['updated_at'] != null
//           ? DateTime.tryParse(r['updated_at'] as String)
//           : null,
//       creatorName:
//           creator?['display_name'] as String? ??
//           creator?['username'] as String?,
//       creatorAvatarUrl: creator?['avatar_url'] as String?,
//       isVerifiedCreator: creator?['verification_status'] == 'verified',
//     );
//   }

//   List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
//     final raw = r['available_languages'];
//     if (raw is List && raw.isNotEmpty) {
//       return raw.map((e) => e.toString()).toList();
//     }
//     final lang = r['language'] as String? ?? 'en';
//     final multilang = r['is_multilang'] as bool? ?? false;
//     if (multilang || lang == 'multi') return ['en', 'ar', 'fr'];
//     return [lang];
//   }

//   PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
//     id: r['id'] as String,
//     nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
//     slug: r['slug'] as String,
//     icon: r['icon'] as String? ?? '📦',
//     sortOrder: r['sort_order'] as int? ?? 0,
//   );

//   PackReview _rowToReview(Map<String, dynamic> r) {
//     final author = r['profiles'] as Map<String, dynamic>? ?? {};
//     final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
//     return PackReview(
//       id: r['id'] as String,
//       packId: r['pack_id'] as String,
//       userId: r['user_id'] as String,
//       content: r['content'] as String,
//       rating: ratingRow?['rating'] as int?,
//       authorName: author['display_name'] as String?,
//       authorAvatarUrl: author['avatar_url'] as String?,
//       createdAt: DateTime.parse(r['created_at'] as String),
//     );
//   }
// }

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../domain/pack_entity.dart';
import '../domain/pack_situation_tags.dart';

export '../domain/pack_entity.dart';

const _uuid = Uuid();

/// A selectable pack content language, sourced from the pack_languages
/// table instead of a hardcoded list — admins can add new ones without an
/// app update.
class PackLanguage {
  const PackLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isRtl = false,
  });
  final String code; // e.g. 'en'
  final String name; // e.g. 'English'
  final String nativeName; // e.g. 'English' or 'العربية'
  final bool isRtl;
}

/// Server-authoritative promotion state for one pack — see
/// PackRepository.getPackPromotionStatus.
class PackPromotionStatus {
  const PackPromotionStatus({required this.active, this.endsAt});

  factory PackPromotionStatus.fromMap(Map<String, dynamic> map) {
    return PackPromotionStatus(
      active: map['active'] as bool? ?? false,
      endsAt: map['ends_at'] != null
          ? DateTime.parse(map['ends_at'] as String)
          : null,
    );
  }

  final bool active;
  final DateTime? endsAt;
}

class PackRepository extends BaseRepository {
  PackRepository._();
  static final PackRepository _instance = PackRepository._();
  static PackRepository get instance => _instance;

  final _supabase = Supabase.instance.client;
  final _api = ApiClient.instance;

  /// Available pack languages, admin-configurable via the pack_languages
  /// table — add a new language there and it shows up here automatically,
  /// no app update needed.
  Future<List<PackLanguage>> getAvailableLanguages() => guardedCall(
    operationName: 'getAvailableLanguages',
    operation: () async {
      final rows = await _supabase
          .from('pack_languages')
          .select('code, name, native_name, is_rtl')
          .eq('is_active', true)
          .order('sort_order');
      return rows
          .map(
            (r) => PackLanguage(
              code: r['code'] as String,
              name: r['name'] as String,
              nativeName: r['native_name'] as String,
              isRtl: r['is_rtl'] as bool? ?? false,
            ),
          )
          .toList();
    },
  );

  /// Item 7 — curated ToD pack-discovery "situation" filter vocabulary,
  /// admin-configurable via the pack_situation_filters table (same
  /// active/sort_order/public-read shape as pack_categories/pack_languages).
  /// A slug added there shows up here automatically; a disabled/removed one
  /// disappears automatically — no app update needed. Still just labels for
  /// the SAME pack_tags.tag string vocabulary packs already carry; no
  /// separate taxonomy.
  Future<List<PackSituationTag>> getSituationFilters() => guardedCall(
    operationName: 'getSituationFilters',
    operation: () async {
      final rows = await _supabase
          .from('pack_situation_filters')
          .select('slug, icon, name_json')
          .eq('is_active', true)
          .order('sort_order');
      return rows
          .map(
            (r) => PackSituationTag(
              r['slug'] as String,
              r['icon'] as String? ?? '🏷️',
              (r['name_json'] as Map?)?.cast<String, dynamic>() ?? const {},
            ),
          )
          .toList();
    },
  );

  Future<List<PackEntity>> browsePacks({
    String? query,
    String? gameType,
    String? categoryId,
    bool freeOnly = false,
    String? language,
    String sortBy = 'avg_rating',
    int page = 0,
    int perPage = 20,
  }) => guardedCall(
    operationName: 'browsePacks',
    operation: () async {
      var q = _supabase
          .from('packs')
          .select('''
                id, creator_id, title, description, cover_image_url,
                status, game_type, language, is_multilang, price_mru,
                card_count, avg_rating, total_ratings, total_purchases,
                total_plays, version, has_spicy, is_featured, is_promoted,
                min_age, max_age, gender_restriction, suggested_punishments,
                min_players, max_players, category_id, download_url, published_at, created_at,
                profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
              ''')
          .eq('status', 'approved')
          .isFilter('deleted_at', null);

      if (gameType != null) q = q.eq('game_type', gameType);
      if (categoryId != null) q = q.eq('category_id', categoryId);
      if (freeOnly) q = q.eq('price_mru', 0);
      if (language != null && language != 'multi') {
        q = q.or('language.eq.$language,is_multilang.eq.true');
      }

      final rows = await q
          .order(sortBy, ascending: false)
          .range(page * perPage, (page + 1) * perPage - 1);

      return rows.map(_rowToEntity).toList();
    },
  );

  /// Real pack search — by pack name (any of the 3 title languages),
  /// creator username/display name, or category, via the search_packs()
  /// RPC (matches against the GIN full-text indexes that already existed
  /// on packs.title and profiles.username/display_name — idx_packs_search
  /// / idx_profiles_search — but were never actually queried from
  /// anywhere until now). The RPC only resolves matching IDs, in
  /// relevance order; fetching the actual rows reuses the exact same
  /// .select() (with the creator profile embed) and _rowToEntity as
  /// browsePacks above, so a search result is shaped identically to
  /// every other pack list in the app — no separate parsing path.
  Future<List<PackEntity>> searchPacks({
    required String query,
    String? gameType,
    String? categoryId,
    bool freeOnly = false,
    String? language,
    int page = 0,
    int perPage = 20,
  }) => guardedCall(
    operationName: 'searchPacks',
    operation: () async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return <PackEntity>[];

      final idRows = await _supabase.rpc(
        'search_packs',
        params: {
          'p_query': trimmed,
          if (gameType != null) 'p_game_type': gameType,
          if (categoryId != null) 'p_category_id': categoryId,
          'p_free_only': freeOnly,
          if (language != null) 'p_language': language,
          'p_page': page,
          'p_per_page': perPage,
        },
      );
      final orderedIds = (idRows as List)
          .map((r) => (r as Map<String, dynamic>)['id'] as String)
          .toList();
      if (orderedIds.isEmpty) return <PackEntity>[];

      final rows = await _supabase
          .from('packs')
          .select('''
                id, creator_id, title, description, cover_image_url,
                status, game_type, language, is_multilang, price_mru,
                card_count, avg_rating, total_ratings, total_purchases,
                total_plays, version, has_spicy, is_featured, is_promoted,
                min_age, max_age, gender_restriction, suggested_punishments,
                min_players, max_players, category_id, download_url, published_at, created_at,
                profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
              ''')
          .inFilter('id', orderedIds);

      // .inFilter doesn't preserve the RPC's relevance order, so
      // re-sort the fetched rows back into it.
      final byId = {
        for (final row in rows) row['id'] as String: _rowToEntity(row),
      };
      return orderedIds.where(byId.containsKey).map((id) => byId[id]!).toList();
    },
  );

  Future<List<PackEntity>> getFeaturedPacks() => guardedCall(
    operationName: 'getFeaturedPacks',
    operation: () async {
      final rows = await _supabase
          .from('packs')
          .select('''
                id, creator_id, title, description, cover_image_url,
                status, game_type, language, price_mru, card_count,
                avg_rating, total_ratings, total_purchases, total_plays,
                version, has_spicy, is_featured, is_promoted,
                min_age, max_age, gender_restriction, suggested_punishments,
                min_players, max_players, category_id, download_url,
                profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
              ''')
          .eq('status', 'approved')
          .eq('is_featured', true)
          .isFilter('deleted_at', null)
          .order('avg_rating', ascending: false)
          .limit(10);
      return rows.map(_rowToEntity).toList();
    },
  );

  Future<List<PackEntity>> getPromotedPacks() => guardedCall(
    operationName: 'getPromotedPacks',
    operation: () async {
      final rows = await _supabase
          .from('promoted_packs')
          .select('packs!pack_id(*), position')
          .lte('starts_at', DateTime.now().toIso8601String())
          .gte('ends_at', DateTime.now().toIso8601String())
          .order('position');

      return rows
          .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
          .toList();
    },
  );

  Future<List<PackCategory>> getCategories() => guardedCall(
    operationName: 'getCategories',
    operation: () async {
      final rows = await _supabase
          .from('pack_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return rows.map(_rowToCategory).toList();
    },
  );

  /// Browses the centralized sticker library (task item 3) for a pack
  /// creator to pick from when building a meme card, instead of always
  /// uploading a new image. Server/RLS already restricts this to active
  /// rows (sticker_library: public read active) — the .eq here is
  /// redundant with that policy but keeps the query shape self-documenting
  /// and matches getCategories'/getSituationFilters' style.
  Future<List<StickerEntity>> getStickerLibrary({String? category}) =>
      guardedCall(
        operationName: 'getStickerLibrary',
        operation: () async {
          var q = _supabase
              .from('sticker_library')
              .select()
              .eq('is_active', true);
          if (category != null) q = q.eq('category', category);
          final rows = await q.order('sort_order');
          return (rows as List)
              .map(
                (r) => StickerEntity(
                  id: r['id'] as String,
                  name: r['name'] as String? ?? '',
                  publicUrl: r['public_url'] as String,
                  category: r['category'] as String?,
                  sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
                ),
              )
              .toList();
        },
      );

  /// Submits a new category name for admin review — independent of any
  /// specific pack (no pack_id column), so it can be created before the
  /// pack draft itself has been saved. Call [linkPendingCategorySuggestion]
  /// once a pack id exists to actually attach it.
  Future<String> suggestCategory(String name) => guardedCall(
    operationName: 'suggestCategory',
    operation: () async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const AuthFailure(message: 'Not logged in.');
      final row = await _supabase
          .from('pack_category_suggestions')
          .insert({'suggested_name': name, 'suggested_by': userId})
          .select('id')
          .single();
      return row['id'] as String;
    },
  );

  /// Direct client write (not the Node API) — packs' own RLS already lets
  /// the creator update their own draft/rejected pack rows, so this one
  /// field doesn't need a server-side route of its own. Clears category_id
  /// since the two are mutually exclusive until the suggestion is decided.
  Future<void> linkPendingCategorySuggestion(
    String packId,
    String suggestionId,
  ) => guardedCall(
    operationName: 'linkPendingCategorySuggestion',
    operation: () async {
      await _supabase
          .from('packs')
          .update({
            'category_id': null,
            'pending_category_suggestion_id': suggestionId,
          })
          .eq('id', packId);
    },
  );

  Future<Map<String, dynamic>?> getCategorySuggestion(String id) => guardedCall(
    operationName: 'getCategorySuggestion',
    operation: () async {
      return await _supabase
          .from('pack_category_suggestions')
          .select('suggested_name, status, rejection_reason')
          .eq('id', id)
          .maybeSingle();
    },
  );

  Future<PackEntity> getPackDetail(String packId) => guardedCall(
    operationName: 'getPackDetail',
    operation: () async {
      final row = await _supabase
          .from('packs')
          .select('''
                *,
                profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account),
                pack_tags(tag)
              ''')
          .eq('id', packId)
          .single();
      return _rowToEntity(row);
    },
  );

  Future<List<PackReview>> getPackReviews(
    String packId, {
    int limit = 20,
    int page = 0,
  }) => guardedCall(
    operationName: 'getPackReviews',
    operation: () async {
      final rows = await _supabase
          .from('pack_reviews')
          .select('''
                id, pack_id, user_id, content, created_at,
                profiles!user_id(display_name, avatar_url),
                pack_ratings!rating_id(rating)
              ''')
          .eq('pack_id', packId)
          .eq('is_visible', true)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return rows.map(_rowToReview).toList();
    },
  );

  Future<PackRating?> getMyRating(String packId, String userId) =>
      softCall<PackRating?>(
        operationName: 'getMyRating',
        operation: () async {
          final row = await _supabase
              .from('pack_ratings')
              .select()
              .eq('pack_id', packId)
              .eq('user_id', userId)
              .maybeSingle();
          if (row == null) return null;
          return PackRating(
            packId: row['pack_id'] as String,
            userId: row['user_id'] as String,
            rating: row['rating'] as int,
          );
        },
      );

  Future<List<PackEntity>> getMyPurchasedPacks(String userId) => guardedCall(
    operationName: 'getMyPurchasedPacks',
    operation: () async {
      final rows = await _supabase
          .from('pack_purchases')
          .select('pack_id, purchased_at, expires_at, packs(*)')
          .eq('buyer_id', userId)
          .eq('status', 'completed')
          .or(
            'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
          )
          .order('purchased_at', ascending: false);

      return rows
          .map((r) => _rowToEntity(r['packs'] as Map<String, dynamic>))
          .toList();
    },
  );

  Future<List<PackPurchase>> getMyPurchaseRecords(String userId) => guardedCall(
    operationName: 'getPurchaseRecords',
    operation: () async {
      final rows = await _supabase
          .from('pack_purchases')
          .select('pack_id, purchased_at, expires_at, price_paid_mru')
          .eq('buyer_id', userId)
          .eq('status', 'completed')
          .or(
            'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
          );

      return rows
          .map(
            (r) => PackPurchase(
              packId: r['pack_id'] as String,
              purchasedAt: DateTime.parse(r['purchased_at'] as String),
              expiresAt: r['expires_at'] != null
                  ? DateTime.parse(r['expires_at'] as String)
                  : null,
              pricePaidMru: r['price_paid_mru'] as int? ?? 0,
            ),
          )
          .toList();
    },
  );

  Future<bool> hasPurchased(String packId, String userId) => guardedCall(
    operationName: 'hasPurchased',
    operation: () async {
      final row = await _supabase
          .from('pack_purchases')
          .select('id')
          .eq('pack_id', packId)
          .eq('buyer_id', userId)
          .eq('status', 'completed')
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();
      return row != null;
    },
  );

  Future<void> purchasePack(String packId) => guardedCall(
    operationName: 'purchasePack',
    operation: () async {
      final response = await _api.post(
        '/v1/packs/purchase',
        data: {'pack_id': packId, 'idempotency_key': _uuid.v4()},
      );
      final data = response.data as Map<String, dynamic>?;
      final error = data?['error'] as String?;
      if (error != null) throw Exception(error);
    },
  );

  /// Requests a printed physical copy of a pack the caller already owns.
  /// Price is entirely app-controlled — never set by the pack creator —
  /// and the debit + row insert happen atomically server-side. Total
  /// charge is the configured unit price times [quantity].
  Future<String> requestPhysicalPack({
    required String packId,
    required String recipientName,
    required String phoneNumber,
    required String city,
    required String zone,
    int quantity = 1,
    String? notes,
  }) => guardedCall(
    operationName: 'requestPhysicalPack',
    operation: () async {
      try {
        final result = await _supabase.rpc(
          'request_physical_pack',
          params: {
            'p_pack_id': packId,
            'p_recipient_name': recipientName,
            'p_phone_number': phoneNumber,
            'p_city': city,
            'p_zone': zone,
            'p_quantity': quantity,
            'p_notes': notes,
          },
        );
        return result as String;
      } on PostgrestException catch (e) {
        if (e.message.contains('pack_not_owned')) {
          throw const ForbiddenFailure(
            message:
                'You need to own this pack before requesting a printed copy.',
          );
        }
        if (e.message.contains('already_requested')) {
          throw const ConflictFailure(
            message: 'You already have a pending request for this pack.',
          );
        }
        if (e.message.contains('invalid_quantity')) {
          throw const ValidationFailure(
            message: 'Quantity must be at least 1.',
          );
        }
        if (e.message.contains('insufficient') ||
            e.message.contains('Insufficient balance')) {
          throw const PaymentFailure(
            message: 'Insufficient wallet balance for the physical copy fee.',
          );
        }
        // Task section 3: physical_pack_requests_enabled is now actually
        // reachable from Super Admin Settings (previously real server-side
        // enforcement with no admin UI to trigger it) — without this, a
        // disabled admin toggle surfaced as a raw PostgrestException
        // string via the generic catch-all below instead of a clean
        // message, exactly like every other business-rule error this
        // function already maps.
        if (e.message.contains('physical_pack_requests_disabled')) {
          throw const ForbiddenFailure(
            message: 'Physical pack requests are currently unavailable.',
          );
        }
        rethrow;
      }
    },
  );

  /// Promotes a pack the caller owns for [duration] ('24h' or '7d').
  /// Verified-creator status, pack-published status, and wallet balance
  /// are all re-checked atomically server-side — the client only mirrors
  /// those checks to fail fast/show a nicer message.
  Future<void> promotePack({
    required String packId,
    required String duration,
  }) => guardedCall(
    operationName: 'promotePack',
    operation: () async {
      try {
        await _supabase.rpc(
          'promote_pack',
          params: {'p_pack_id': packId, 'p_duration': duration},
        );
      } on PostgrestException catch (e) {
        if (e.message.contains('not_pack_owner')) {
          throw const ForbiddenFailure(
            message: 'You can only promote packs you created.',
          );
        }
        if (e.message.contains('pack_not_published')) {
          throw const ValidationFailure(
            message: 'Only reviewed and published packs can be promoted.',
          );
        }
        if (e.message.contains('creator_not_verified')) {
          throw const ForbiddenFailure(
            message: 'Only verified creators can promote packs.',
          );
        }
        if (e.message.contains('promotion_slots_full')) {
          throw const ConflictFailure(
            message:
                'All promotion slots are taken right now — try again later.',
          );
        }
        if (e.message.contains('already_promoted')) {
          throw const ConflictFailure(
            message: 'This pack already has an active promotion.',
            code: 'already_promoted',
          );
        }
        if (e.message.contains('insufficient') ||
            e.message.contains('Insufficient balance')) {
          throw const PaymentFailure(
            message: 'Insufficient wallet balance to promote this pack.',
          );
        }
        rethrow;
      }
    },
  );

  /// Server-authoritative "is this pack currently promoted" check (mirrors
  /// promote_pack()'s own active-promotion guard — see
  /// get_pack_promotion_status RPC) so the UI can hide the Promote action
  /// and show an "active until ..." state instead of relying on a client
  /// side guess. Returns null `endsAt` when there is no active promotion.
  Future<PackPromotionStatus> getPackPromotionStatus(String packId) =>
      guardedCall(
        operationName: 'getPackPromotionStatus',
        operation: () async {
          final result = await _supabase.rpc(
            'get_pack_promotion_status',
            params: {'p_pack_id': packId},
          );
          final map = Map<String, dynamic>.from(result as Map);
          return PackPromotionStatus.fromMap(map);
        },
      );

  Future<List<Map<String, dynamic>>> getMyPhysicalPackRequests() => guardedCall(
    operationName: 'getMyPhysicalPackRequests',
    operation: () async {
      final rows = await _supabase
          .from('physical_pack_requests')
          .select('*, packs(title, cover_image_url)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    },
  );

  // Upsert against (pack_id, user_id) — one rating per user per pack.
  // pack_ratings_pack_id_user_id_key (see supabase/migrations/20260810090000_
  // fix_pack_rating_write_path.sql) is the arbiter this ON CONFLICT needs;
  // without it this throws on every call (42P10 — no matching unique
  // constraint), which is why no rating was ever actually being saved.
  // trg_pack_rating_refresh then recomputes packs.avg_rating/total_ratings
  // from every row in this table — no separate cache-update call needed
  // here.
  Future<void> ratePack({
    required String packId,
    required String userId,
    required int rating,
  }) => guardedCall(
    operationName: 'ratePack',
    operation: () async {
      await _supabase.from('pack_ratings').upsert({
        'user_id': userId,
        'pack_id': packId,
        'rating': rating,
      }, onConflict: 'pack_id,user_id');
    },
  );

  /// Removes the caller's own rating for a pack. trg_pack_rating_refresh
  /// recomputes packs.avg_rating/total_ratings on DELETE too, so this is
  /// enough on its own to correctly bring the count down (to 0 if it was
  /// their last rating) — no separate cache update needed.
  Future<void> unratePack({required String packId, required String userId}) =>
      guardedCall(
        operationName: 'unratePack',
        operation: () async {
          await _supabase
              .from('pack_ratings')
              .delete()
              .eq('pack_id', packId)
              .eq('user_id', userId);
        },
      );

  Future<void> submitReview({
    required String packId,
    required String userId,
    required String content,
    int? rating,
  }) => guardedCall(
    operationName: 'submitReview',
    operation: () async {
      // Rating first (if provided) so the review row can link to it via
      // rating_id — getPackReviews()'s pack_ratings!rating_id(rating) embed
      // depends on that link to show the star rating next to a written
      // review; it was never set before, so that embed always came back
      // null even when the reviewer also rated the pack.
      String? ratingId;
      if (rating != null) {
        final ratingRow = await _supabase
            .from('pack_ratings')
            .upsert({
              'user_id': userId,
              'pack_id': packId,
              'rating': rating,
            }, onConflict: 'pack_id,user_id')
            .select('id')
            .single();
        ratingId = ratingRow['id'] as String;
      }
      // 'id' is intentionally omitted here (unlike the old version, which
      // sent a fresh random uuid on every call) — on an update via the
      // pack_id,user_id upsert conflict, including 'id' in the payload
      // would try to overwrite the existing row's primary key with that
      // new random value on every resubmission. Omitting it lets Postgres'
      // own gen_random_uuid() default apply on true inserts and leaves it
      // untouched on updates, exactly like ratePack()'s payload above.
      await _supabase.from('pack_reviews').upsert({
        'pack_id': packId,
        'user_id': userId,
        'content': content,
        if (ratingId != null) 'rating_id': ratingId,
      }, onConflict: 'pack_id,user_id');
    },
  );

  /// Writes to the generic `reports` table (target_type='pack'), NOT the
  /// legacy `pack_reports` table — `pack_reports` is an orphaned, earlier
  /// pack-specific report system that the admin report queue
  /// (jma3a-api's reportsService.js / jma3a_admin's reports_repository.dart)
  /// never reads from, so a pack report written there silently never
  /// reached admin review. `reports` already supports target_type='pack'
  /// (see its target_type CHECK constraint) and already has the
  /// equivalent one-report-per-reporter-per-target restriction via its own
  /// UNIQUE (reporter_id, target_type, target_id) constraint, so this is a
  /// pure redirect — no new backend concept, per the existing "don't build
  /// a duplicate system" convention. `pack_reports` itself is left in
  /// place (data preserved, not dropped) in case anything else still
  /// depends on it; nothing found to during this fix.
  Future<void> reportPack({
    required String packId,
    required String reporterId,
    required String reason,
    String? details,
  }) => guardedCall(
    operationName: 'reportPack',
    operation: () async {
      try {
        await _supabase.from('reports').insert({
          'target_type': 'pack',
          'target_id': packId,
          'reporter_id': reporterId,
          'reason': reason,
          'details': details,
        });
      } on PostgrestException catch (e) {
        // uq_report is DEFERRABLE (Postgres doesn't allow ON CONFLICT
        // against a deferrable constraint as the arbiter — verified live,
        // an upsert() here fails at the SQL level), so a second report
        // from the same reporter for the same pack surfaces as a plain
        // 23505 unique-violation instead of an upsert-style update. That's
        // the correct outcome for "duplicate/report restrictions behave
        // correctly": at most one open report per (reporter, pack) either
        // way — treated as a silent success here rather than an error,
        // since from the reporter's point of view they've already
        // reported this pack.
        if (e.code != '23505') rethrow;
      }
    },
  );

  Future<void> savePackReactions(String packId, List<String> imageUrls) =>
      guardedCall(
        operationName: 'savePackReactions',
        operation: () async {
          await _api.post(
            '/v1/packs/$packId/reactions',
            data: {
              'reactions': imageUrls
                  .asMap()
                  .entries
                  .map((e) => {'image_url': e.value, 'sort_order': e.key})
                  .toList(),
            },
          );
        },
      );

  Future<List<String>> getPackReactions(String packId) => guardedCall(
    operationName: 'getPackReactions',
    operation: () async {
      try {
        final response = await _api.get('/v1/packs/$packId/reactions');
        final data = response.data as Map<String, dynamic>?;
        final reactions = data?['data']?['reactions'] as List?;
        if (reactions != null) {
          return reactions.map((r) => r['image_url'] as String).toList();
        }
      } catch (_) {}
      final rows = await _supabase
          .from('pack_reactions')
          .select('image_url')
          .eq('pack_id', packId)
          .order('sort_order');
      return (rows as List).map((r) => r['image_url'] as String).toList();
    },
  );

  /// Correction pass — the pack-level sticker pool an admin selects when
  /// authoring an official Meme pack (jma3a_admin's create_official_pack_
  /// screen.dart _StickersStep -> the `pack_stickers` table added by that
  /// same pass). Genuinely separate from [getPackReactions]'s
  /// `pack_reactions` (a verified creator's own custom-uploaded images) —
  /// MemeGameScreen prefers pack_reactions when present and falls back to
  /// this pool, so an admin-authored pack (which never has pack_reactions)
  /// still gets its own stickers instead of dropping all the way to the
  /// hardcoded kAppStickers preset.
  ///
  /// Sticker architecture correction pass — pack_stickers rows now come
  /// from TWO sources: a `sticker_library` embed (globally admin-curated,
  /// selectable across any pack) or a `pack_owned_stickers` embed (an
  /// asset uploaded specifically for this one pack — never inserted into
  /// the global library). Gameplay only needs the resolved image URL, so
  /// both are flattened into one combined pool here rather than exposed
  /// as two separate lists — the distinction only matters to the admin
  /// editor, not to a player picking a reaction sticker.
  ///
  /// Returns RAW (unsigned) URLs for both sources — same contract as pack
  /// cover/card image fields elsewhere in this class; callers sign via
  /// ImageUrlSigner (POST /v1/storage/sign-urls signs ANY URL under our
  /// own Wasabi bucket via wasabi.isOwnedUrl, not a hardcoded per-table
  /// field list, so packs/stickers/... pack-owned uploads sign correctly
  /// through the exact same call as sticker_library.public_url) rather
  /// than this repository re-implementing that signing itself.
  /// pack_stickers' own RLS (approved pack, or the pack's own creator)
  /// already gates this read — no dedicated API endpoint needed.
  Future<List<String>> getPackStickers(String packId) => guardedCall(
    operationName: 'getPackStickers',
    operation: () async {
      final rows = await _supabase
          .from('pack_stickers')
          .select('sticker_library(public_url), pack_owned_stickers(public_url)')
          .eq('pack_id', packId);
      return (rows as List)
          .map((r) =>
              (r['sticker_library'] as Map?)?['public_url'] as String? ??
              (r['pack_owned_stickers'] as Map?)?['public_url'] as String?)
          .whereType<String>()
          .toList();
    },
  );

  Future<bool> hasFreePacksAvailable() => guardedCall(
    operationName: 'hasFreePacksAvailable',
    operation: () async {
      final rows = await _supabase
          .from('packs')
          .select('id')
          .eq('status', 'approved')
          .eq('price_mru', 0)
          .isFilter('deleted_at', null)
          .limit(1);
      return rows.isNotEmpty;
    },
  );

  Future<List<PackEntity>> getMostPlayedPacksForUser(String userId) =>
      guardedCall(
        operationName: 'getMostPlayedPacksForUser',
        operation: () async {
          final memberRows = await _supabase
              .from('room_members')
              .select('room_id')
              .eq('user_id', userId);
          final roomIds = memberRows
              .map((r) => r['room_id'] as String)
              .toSet()
              .toList();
          if (roomIds.isEmpty) return <PackEntity>[];

          final playedRows = await _supabase
              .from('room_played_packs')
              .select('pack_id')
              .inFilter('room_id', roomIds);

          final counts = <String, int>{};
          for (final r in playedRows) {
            final id = r['pack_id'] as String;
            counts[id] = (counts[id] ?? 0) + 1;
          }
          if (counts.isEmpty) return <PackEntity>[];

          final topIds = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final ids = topIds.take(10).map((e) => e.key).toList();

          final packRows = await _supabase
              .from('packs')
              .select('''
                id, creator_id, title, description, cover_image_url,
                status, game_type, language, is_multilang, price_mru,
                card_count, avg_rating, total_ratings, total_purchases,
                total_plays, version, has_spicy, is_featured, is_promoted,
                min_age, max_age, gender_restriction, suggested_punishments,
                min_players, max_players, category_id, download_url, published_at, created_at,
                profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
              ''')
              .inFilter('id', ids)
              .isFilter('deleted_at', null);

          final packsById = {
            for (final row in packRows) row['id'] as String: _rowToEntity(row),
          };
          return ids
              .where(packsById.containsKey)
              .map((id) => packsById[id]!)
              .toList();
        },
      );

  Future<List<PackEntity>> getMyCreatedPacks(String creatorId) => guardedCall(
    operationName: 'getMyCreatedPacks',
    operation: () async {
      final rows = await _supabase
          .from('packs')
          .select()
          .eq('creator_id', creatorId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return rows.map(_rowToEntity).toList();
    },
  );

  Future<List<PackEntity>> getPublicPacksByCreator(String creatorId) =>
      guardedCall(
        operationName: 'getPublicPacksByCreator',
        operation: () async {
          final rows = await _supabase
              .from('packs')
              .select('''
            id, creator_id, title, description, cover_image_url,
            status, game_type, language, is_multilang, price_mru,
            card_count, avg_rating, total_ratings, total_purchases,
            total_plays, version, has_spicy, is_featured, is_promoted,
            category_id, download_url, published_at, created_at,
            profiles!creator_id(username, display_name, avatar_url, verification_status, is_official_account)
          ''')
              .eq('creator_id', creatorId)
              .eq('status', 'approved')
              .isFilter('deleted_at', null)
              .order('total_plays', ascending: false);
          return rows.map(_rowToEntity).toList();
        },
      );

  Future<PackEntity> createPackDraft(PackDraft draft, String creatorId) =>
      guardedCall(
        operationName: 'createPackDraft',
        operation: () async {
          final resp = await _api.post<Map<String, dynamic>>(
            '/v1/packs/create',
            data: {
              'title': draft.titleJson,
              'description': draft.descriptionJson,
              'game_type': draft.gameType,
              'language': draft.language,
              'price_mru': draft.priceMru,
              'category_id': draft.categoryId,
              'has_spicy': draft.allowSpicy,
              'min_players': draft.minPlayers,
              'max_players': draft.maxPlayers,
              'tags': draft.tags,
              'cover_image_url': draft.coverImageUrl,
              'min_age': draft.minAge,
              'max_age': draft.maxAge,
              'gender_restriction': draft.genderRestriction,
              'suggested_punishments': draft.suggestedPunishments,
            },
          );
          final row = resp.data!['data']['pack'] as Map<String, dynamic>;
          return _rowToEntity(row);
        },
      );

  Future<PackEntity> updatePackDraft(String packId, PackDraft draft) =>
      guardedCall(
        operationName: 'updatePackDraft',
        operation: () async {
          final resp = await _api.patch<Map<String, dynamic>>(
            '/v1/packs/$packId',
            data: {
              'title': draft.titleJson,
              'description': draft.descriptionJson,
              // Persist language + game type so an edited draft keeps the
              // creator's real choices (Part 9 editability); the language is
              // additionally recoverable from the title keys on reload.
              'language': draft.language,
              'game_type': draft.gameType,
              'price_mru': draft.priceMru,
              'category_id': draft.categoryId,
              'has_spicy': draft.allowSpicy,
              'min_players': draft.minPlayers,
              'max_players': draft.maxPlayers,
              'tags': draft.tags,
              'cover_image_url': draft.coverImageUrl,
              'min_age': draft.minAge,
              'max_age': draft.maxAge,
              'gender_restriction': draft.genderRestriction,
              'suggested_punishments': draft.suggestedPunishments,
            },
          );
          return _rowToEntity(
            resp.data!['data']['pack'] as Map<String, dynamic>,
          );
        },
      );

  /// Enforces the 1-free-submission-every-15-days rule (a pure rolling
  /// gap since the creator's last row in pack_submissions — NOT a
  /// calendar-month counter; "2 per month" is the natural cadence of a
  /// 15-day interval, not a second, independently-resettable limit) and
  /// the database-configured paid-exception fee entirely server-side
  /// (SECURITY DEFINER RPC `submit_pack_for_review`) — the quota/fee
  /// logic lives in exactly one place (Postgres), not split across this
  /// client and the Node API's `/v1/packs/:id/submit` route. Also
  /// verifies the caller is a verified creator (reuses the exact same
  /// creator_verifications check promote_pack() already enforces — not a
  /// second definition). Pass [payFee] true only after the caller has
  /// already shown the user the fee amount and gotten confirmation;
  /// calling with it false first is how the fee amount itself is
  /// discovered (a `fee_required` PaymentFailure is thrown).
  Future<Map<String, dynamic>> submitForReview(
    String packId, {
    bool payFee = false,
  }) => guardedCall(
    operationName: 'submitForReview',
    operation: () async {
      try {
        final result = await _supabase.rpc(
          'submit_pack_for_review',
          params: {'p_pack_id': packId, 'p_pay_fee': payFee},
        );
        return Map<String, dynamic>.from(result as Map);
      } on PostgrestException catch (e) {
        if (e.message.contains('fee_required')) {
          throw const PaymentFailure(
            message: 'Your next free submission is not available yet.',
            code: 'fee_required',
          );
        }
        if (e.message.contains('creator_not_verified')) {
          throw const ForbiddenFailure(
            message: 'Only verified creators can submit packs for review.',
            code: 'creator_not_verified',
          );
        }
        if (e.message.contains('pack_not_editable')) {
          throw const ValidationFailure(
            message: 'This pack cannot be submitted in its current state.',
          );
        }
        if (e.message.contains('pack_not_found')) {
          throw const NotFoundFailure(message: 'Pack not found.');
        }
        // Server-authoritative content gates (mirror PackDraft.validationIssues
        // — a client that bypassed the wizard is rejected here too).
        if (e.message.contains('price_below_minimum')) {
          throw ValidationFailure(
            message:
                'Set a price of at least ${AppConstants.minPaidPackPriceMru} MRU.',
          );
        }
        if (e.message.contains('not_enough_cards')) {
          throw const ValidationFailure(message: 'Add at least 20 cards.');
        }
        if (e.message.contains('truth_dare_unbalanced')) {
          throw const ValidationFailure(
            message:
                'Truth or Dare packs need an equal number of Truth and Dare cards.',
          );
        }
        if (e.message.contains('title_required')) {
          throw const ValidationFailure(
            message: 'Add a name for the pack before submitting.',
          );
        }
        if (e.message.contains('spicy_content_disabled')) {
          throw const ForbiddenFailure(
            message: 'Spicy content is not available right now.',
            code: 'spicy_content_disabled',
          );
        }
        rethrow;
      }
    },
  );

  /// The ONE authoritative pack-creation preflight round trip
  /// (get_pack_creation_status RPC) — replaces the old client-side
  /// wouldPackSubmissionNeedFee pre-check, which queried pack_submissions
  /// directly and duplicated the free/gap arithmetic here. This is still
  /// UX-only (submitForReview above independently re-verifies every
  /// condition server-side regardless of what this returns), but it's now
  /// a single source of truth instead of Flutter performing its own
  /// independent calculation.
  Future<PackCreationStatus> getPackCreationStatus() => guardedCall(
    operationName: 'getPackCreationStatus',
    operation: () async {
      final result = await _supabase.rpc('get_pack_creation_status');
      return PackCreationStatus.fromMap(Map<String, dynamic>.from(result as Map));
    },
  );

  /// Server-authoritative draft deletion (SECURITY DEFINER RPC
  /// `delete_pack_draft`) — ownership and status ('draft' only) are
  /// re-verified in Postgres, not just gated by hiding the button in the
  /// UI for a non-owner/non-draft pack. Freeing the draft slot is a side
  /// effect of the same row this soft-deletes (see
  /// idx_packs_one_draft_per_creator's `deleted_at IS NULL` predicate) —
  /// no separate "slot" bookkeeping to update here.
  Future<void> deletePackDraft(String packId) => guardedCall(
    operationName: 'deletePackDraft',
    operation: () async {
      try {
        await _supabase.rpc(
          'delete_pack_draft',
          params: {'p_pack_id': packId},
        );
      } on PostgrestException catch (e) {
        if (e.message.contains('pack_not_found')) {
          throw const NotFoundFailure(message: 'Pack not found.');
        }
        if (e.message.contains('pack_not_draft')) {
          throw const ValidationFailure(
            message: 'Only a draft pack can be deleted this way.',
          );
        }
        rethrow;
      }
    },
  );

  Future<void> addCards(String packId, List<CardDraft> cards) => guardedCall(
    operationName: 'addCards',
    operation: () async {
      await _supabase.from('pack_cards').delete().eq('pack_id', packId);

      if (cards.isEmpty) return;

      final rows = cards
          .asMap()
          .entries
          .map(
            (e) => {
              'pack_id': packId,
              'content': e.value.contentJson,
              'card_type': e.value.type.name,
              'difficulty': e.value.difficulty.name,
              'sort_order': e.key,
              'is_active': true,
              'image_url': e.value.imageUrl,
              'sticker_id': e.value.stickerId,
            },
          )
          .toList();

      await _supabase.from('pack_cards').insert(rows);
    },
  );

  Future<void> deleteCard(String packId, String cardId) => guardedCall(
    operationName: 'deleteCard',
    operation: () async {
      await _supabase
          .from('pack_cards')
          .delete()
          .eq('id', cardId)
          .eq('pack_id', packId);
    },
  );

  Future<Map<String, Set<String>>> getCardLanguageCoverage(
    List<String> packIds,
  ) => guardedCall(
    operationName: 'getCardLanguageCoverage',
    operation: () async {
      if (packIds.isEmpty) return <String, Set<String>>{};

      final rows = await _supabase
          .from('pack_cards')
          .select('pack_id, content')
          .inFilter('pack_id', packIds)
          .eq('is_active', true);

      final coverage = <String, Set<String>>{};
      final seenAnyCard = <String>{};

      for (final r in rows) {
        final packId = r['pack_id'] as String;
        final content = r['content'] as Map<String, dynamic>? ?? {};
        final cardLangs = content.entries
            .where((e) => (e.value as String?)?.trim().isNotEmpty ?? false)
            .map((e) => e.key)
            .toSet();

        if (seenAnyCard.add(packId)) {
          coverage[packId] = cardLangs;
        } else {
          coverage[packId] = coverage[packId]!.intersection(cardLangs);
        }
      }

      return coverage;
    },
  );

  Future<({String uploadUrl, String publicUrl})> getUploadUrl({
    required String contentType,
    required String fileType,
    required int fileSizeBytes,
  }) => guardedCall(
    operationName: 'getUploadUrl',
    operation: () async {
      final resp = await _api.post<Map<String, dynamic>>(
        '/v1/storage/upload-url',
        data: {
          'file_type': fileType,
          'content_type': contentType,
          'file_size_bytes': fileSizeBytes,
        },
      );
      final data = resp.data!['data'] as Map<String, dynamic>;
      return (
        uploadUrl: data['upload_url'] as String,
        publicUrl: data['public_url'] as String,
      );
    },
  );

  /// Batch-resolves viewable URLs for stored pack/card/sticker image
  /// references. The Wasabi bucket rejects unauthenticated GETs (kept
  /// private, not made public) — packs.cover_image_url / pack_cards.
  /// image_url / sticker_library.public_url are permanent object
  /// references, not directly-viewable URLs, so anything read straight off
  /// a `packs`/`pack_cards` row needs to go through this before it can be
  /// handed to an image widget. An external URL (e.g. a stock-photo cover)
  /// is returned unchanged by the server, not mis-signed. See
  /// ImageUrlSigner, which wraps this with client-side caching.
  Future<Map<String, String>> signImageUrls(List<String> urls) => guardedCall(
    operationName: 'signImageUrls',
    operation: () async {
      if (urls.isEmpty) return <String, String>{};
      final resp = await _api.post<Map<String, dynamic>>(
        '/v1/storage/sign-urls',
        data: {'urls': urls},
      );
      final data = resp.data!['data'] as Map<String, dynamic>;
      final signed = data['urls'] as Map<String, dynamic>;
      return signed.map((k, v) => MapEntry(k, v as String));
    },
  );

  PackEntity _rowToEntity(Map<String, dynamic> r) {
    final creator = r['profiles'] as Map<String, dynamic>?;
    final tagRows = r['pack_tags'] as List<dynamic>? ?? [];
    final tags = tagRows.map((t) => t['tag'] as String).toList();

    return PackEntity(
      id: r['id'] as String,
      creatorId: r['creator_id'] as String,
      titleJson: (r['title'] as Map?)?.cast<String, dynamic>() ?? {},
      descriptionJson: (r['description'] as Map?)?.cast<String, dynamic>(),
      coverImageUrl: r['cover_image_url'] as String?,
      status: PackStatus.fromString(r['status'] as String? ?? 'approved'),
      gameType: r['game_type'] as String? ?? 'truth_or_dare',
      language: r['language'] as String? ?? 'en',
      isMultilang: r['is_multilang'] as bool? ?? false,
      availableLanguages: _parseAvailableLanguages(r),
      priceMru: r['price_mru'] as int? ?? 0,
      cardCount: r['card_count'] as int? ?? 0,
      avgRating: (r['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: r['total_ratings'] as int? ?? 0,
      totalPurchases: r['total_purchases'] as int? ?? 0,
      totalPlays: r['total_plays'] as int? ?? 0,
      downloadUrl: r['download_url'] as String?,
      version: r['version'] as int? ?? 1,
      hasSpicy: r['has_spicy'] as bool? ?? false,
      isFeatured: r['is_featured'] as bool? ?? false,
      isPromoted: r['is_promoted'] as bool? ?? false,
      categoryId: r['category_id'] as String?,
      tags: tags,
      publishedAt: r['published_at'] != null
          ? DateTime.tryParse(r['published_at'] as String)
          : null,
      createdAt: r['created_at'] != null
          ? DateTime.tryParse(r['created_at'] as String)
          : null,
      updatedAt: r['updated_at'] != null
          ? DateTime.tryParse(r['updated_at'] as String)
          : null,
      creatorName:
          creator?['display_name'] as String? ??
          creator?['username'] as String?,
      creatorAvatarUrl: creator?['avatar_url'] as String?,
      isVerifiedCreator: creator?['verification_status'] == 'verified',
      isOfficialCreator: creator?['is_official_account'] as bool? ?? false,
      rejectionReason: r['rejection_reason'] as String?,
      minAge: r['min_age'] as int?,
      maxAge: r['max_age'] as int?,
      genderRestriction: r['gender_restriction'] as String? ?? 'everyone',
      minPlayers: r['min_players'] as int? ?? 2,
      maxPlayers: r['max_players'] as int?,
      suggestedPunishments:
          (r['suggested_punishments'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      platformManaged: r['platform_managed'] as bool? ?? false,
    );
  }

  List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
    final raw = r['available_languages'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).toList();
    }
    // Authoritative source: the languages the creator actually filled title
    // content in. Deriving from the title JSON keys means a French-only pack
    // restores as ['fr'] and an ar+fr pack as ['ar','fr'] — never the old
    // hardcoded ['en','ar','fr'], which wrongly re-injected English into the
    // language selector when re-opening any multi-language draft (Part 5).
    final title = r['title'];
    if (title is Map && title.isNotEmpty) {
      return title.keys.map((e) => e.toString()).toList();
    }
    final lang = r['language'] as String? ?? 'en';
    return lang == 'multi' ? const <String>[] : [lang];
  }

  PackCategory _rowToCategory(Map<String, dynamic> r) => PackCategory(
    id: r['id'] as String,
    nameJson: (r['name_json'] as Map?)?.cast<String, dynamic>() ?? {},
    slug: r['slug'] as String,
    icon: r['icon'] as String? ?? '📦',
    sortOrder: r['sort_order'] as int? ?? 0,
  );

  PackReview _rowToReview(Map<String, dynamic> r) {
    final author = r['profiles'] as Map<String, dynamic>? ?? {};
    final ratingRow = r['pack_ratings'] as Map<String, dynamic>?;
    return PackReview(
      id: r['id'] as String,
      packId: r['pack_id'] as String,
      userId: r['user_id'] as String,
      content: r['content'] as String,
      rating: ratingRow?['rating'] as int?,
      authorName: author['display_name'] as String?,
      authorAvatarUrl: author['avatar_url'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  }
}
