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
// // // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
// // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
// // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
// // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
// // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
// // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // // //                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
// // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// // //                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
// // //             profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// //                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
// //                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
// //             profiles!creator_id(username, display_name, avatar_url, verification_status)
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
//                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
//                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
//                 profiles!creator_id(username, display_name, avatar_url, verification_status),
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
//                 profiles!creator_id(username, display_name, avatar_url, verification_status)
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
//             profiles!creator_id(username, display_name, avatar_url, verification_status)
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

import '../../../core/data/base_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../domain/pack_entity.dart';

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
                min_players, category_id, download_url, published_at, created_at,
                profiles!creator_id(username, display_name, avatar_url, verification_status)
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
                min_players, category_id, download_url,
                profiles!creator_id(username, display_name, avatar_url, verification_status)
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

  Future<Map<String, dynamic>?> getCategorySuggestion(String id) =>
      guardedCall(
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
                profiles!creator_id(username, display_name, avatar_url, verification_status),
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
            message: 'You need to own this pack before requesting a printed copy.',
          );
        }
        if (e.message.contains('already_requested')) {
          throw const ConflictFailure(
            message: 'You already have a pending request for this pack.',
          );
        }
        if (e.message.contains('invalid_quantity')) {
          throw const ValidationFailure(message: 'Quantity must be at least 1.');
        }
        if (e.message.contains('insufficient') ||
            e.message.contains('Insufficient balance')) {
          throw const PaymentFailure(
            message: 'Insufficient wallet balance for the physical copy fee.',
          );
        }
        rethrow;
      }
    },
  );

  /// The current price for a physical pack copy, admin-configurable via
  /// app_settings — never hardcoded client-side.
  Future<int> getPhysicalPackPrice() => guardedCall(
    operationName: 'getPhysicalPackPrice',
    operation: () async {
      final row = await _supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'physical_pack_price_mru')
          .maybeSingle();
      final raw = row?['value'];
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    },
  );

  /// The current extra-submission fee charged once a creator is past the
  /// free 2/month or 15-day-gap limit, admin-configurable via app_settings
  /// — never hardcoded client-side. submit_pack_for_review always
  /// re-verifies and charges the live value server-side regardless of what
  /// this returns; this is only used to show the fee amount before asking
  /// for confirmation.
  Future<int> getPackExtraCreationFee() => guardedCall(
    operationName: 'getPackExtraCreationFee',
    operation: () async {
      final row = await _supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'pack_extra_creation_price_mru')
          .maybeSingle();
      final raw = row?['value'];
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    },
  );

  Future<List<Map<String, dynamic>>> getMyPhysicalPackRequests() =>
      guardedCall(
        operationName: 'getMyPhysicalPackRequests',
        operation: () async {
          final rows = await _supabase
              .from('physical_pack_requests')
              .select('*, packs(title, cover_image_url)')
              .order('created_at', ascending: false);
          return List<Map<String, dynamic>>.from(rows);
        },
      );

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

  Future<void> submitReview({
    required String packId,
    required String userId,
    required String content,
    int? rating,
  }) => guardedCall(
    operationName: 'submitReview',
    operation: () async {
      await _supabase.from('pack_reviews').upsert({
        'id': _uuid.v4(),
        'pack_id': packId,
        'user_id': userId,
        'content': content,
      }, onConflict: 'pack_id,user_id');
      if (rating != null) {
        await ratePack(packId: packId, userId: userId, rating: rating);
      }
    },
  );

  Future<void> reportPack({
    required String packId,
    required String reporterId,
    required String reason,
    String? details,
  }) => guardedCall(
    operationName: 'reportPack',
    operation: () async {
      await _supabase.from('pack_reports').upsert({
        'pack_id': packId,
        'reporter_id': reporterId,
        'reason': reason,
        'details': details,
      }, onConflict: 'pack_id,reporter_id');
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
                min_players, category_id, download_url, published_at, created_at,
                profiles!creator_id(username, display_name, avatar_url, verification_status)
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
            profiles!creator_id(username, display_name, avatar_url, verification_status)
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
              'price_mru': draft.priceMru,
              'category_id': draft.categoryId,
              'has_spicy': draft.allowSpicy,
              'min_players': draft.minPlayers,
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

  /// Enforces the 2-per-calendar-month / 15-day-gap submission limits and
  /// the 300 MRU paid-exception fee entirely server-side (SECURITY DEFINER
  /// RPC `submit_pack_for_review`) — the quota/fee logic lives in exactly
  /// one place (Postgres), not split across this client and the Node API's
  /// `/v1/packs/:id/submit` route. Pass [payFee] true only after the caller
  /// has already shown the user the fee amount and gotten confirmation;
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
            message: 'This pack is past your free monthly submission limit.',
            code: 'fee_required',
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
        rethrow;
      }
    },
  );

  /// Non-authoritative pre-check used only to decide whether to show a
  /// "this will cost 300 MRU" confirmation before calling [submitForReview]
  /// — the RPC always re-verifies the same rule server-side regardless of
  /// what this returns, so this never needs to be exactly right.
  Future<bool> wouldPackSubmissionNeedFee() => guardedCall(
    operationName: 'wouldPackSubmissionNeedFee',
    operation: () async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      final monthStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      );
      final rows = await _supabase
          .from('pack_submissions')
          .select('submitted_at')
          .eq('creator_id', userId)
          .order('submitted_at', ascending: false);
      final list = (rows as List).cast<Map<String, dynamic>>();
      final monthCount = list
          .where(
            (r) => DateTime.parse(
              r['submitted_at'] as String,
            ).isAfter(monthStart),
          )
          .length;
      if (monthCount >= 2) return true;
      if (list.isEmpty) return false;
      final last = DateTime.parse(list.first['submitted_at'] as String);
      return DateTime.now().difference(last) < const Duration(days: 15);
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
      rejectionReason: r['rejection_reason'] as String?,
      minAge: r['min_age'] as int?,
      maxAge: r['max_age'] as int?,
      genderRestriction: r['gender_restriction'] as String? ?? 'everyone',
      minPlayers: r['min_players'] as int? ?? 2,
      suggestedPunishments:
          (r['suggested_punishments'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  List<String> _parseAvailableLanguages(Map<String, dynamic> r) {
    final raw = r['available_languages'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).toList();
    }
    final lang = r['language'] as String? ?? 'en';
    final multilang = r['is_multilang'] as bool? ?? false;
    if (multilang || lang == 'multi') return ['en', 'ar', 'fr'];
    return [lang];
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
