import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/base_repository.dart';

/// Item 1 (official content: separate posts from ads) — the two content
/// kinds `official_posts.type` distinguishes. Matches the Postgres enum
/// `official_content_type_enum` (see migration_2026_official_content_
/// type.sql) exactly — `post` renders in the official profile's "Jma3a
/// Feed" section, `ad` in its "Advertisements" section, and a row must
/// never appear in both.
enum OfficialContentType { post, ad }

OfficialContentType _contentTypeFromString(String? raw) => switch (raw) {
  'ad' => OfficialContentType.ad,
  _ => OfficialContentType.post,
};

/// Phase 1 (professional brand profile) — the content model for the
/// official Jma3a account's own profile, covering both its "Jma3a Feed"
/// (posts) and "Advertisements" (ads) sections — see UserProfileScreen's
/// `p.isOfficial` branch. Deliberately NOT a general feed/post system for
/// every user — see migration_2026_official_posts.sql's own header
/// comment for why this is scoped to official accounts only, and why
/// there's no client-facing create/edit UI (content is seeded via
/// direct DB/service-role access only, matching "no CMS yet").
class OfficialContentItem {
  const OfficialContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final OfficialContentType type;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime createdAt;

  static OfficialContentItem fromMap(Map<String, dynamic> m) =>
      OfficialContentItem(
        id: m['id'] as String,
        type: _contentTypeFromString(m['type'] as String?),
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        imageUrl: m['image_url'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

/// Read-only repository for `public.official_posts` — same singleton
/// pattern as every other repository in this app (RoomRepository,
/// FriendsRepository, PackRepository). Kept separate from
/// FriendsRepository (already an enormous, unrelated-domain file) and
/// PackRepository (a post is not a pack) — this is its own small table
/// family, matching the scope decision to build only the foundation
/// needed to DISPLAY official content, not a full content-management
/// surface. [getPosts]/[getAdvertisements] both read the SAME table,
/// filtered by `type` at the query level (never a client-side filter
/// over one unfiltered fetch) — one table cleanly represents both
/// content kinds, no duplicate table/model needed.
class OfficialContentRepository extends BaseRepository {
  OfficialContentRepository._();
  static final OfficialContentRepository _instance =
      OfficialContentRepository._();
  static OfficialContentRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  Future<List<OfficialContentItem>> _getByType(String type) => guardedCall(
    operationName: 'getOfficialContent($type)',
    operation: () async {
      final rows = await _supabase
          .from('official_posts')
          .select()
          .eq('type', type)
          .order('created_at', ascending: false);
      return (rows as List)
          .map(
            (r) => OfficialContentItem.fromMap(
              Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList();
    },
  );

  /// The official profile's "Jma3a Feed" section — type = 'post' only.
  Future<List<OfficialContentItem>> getPosts() => _getByType('post');

  /// The official profile's "Advertisements" section — type = 'ad' only.
  Future<List<OfficialContentItem>> getAdvertisements() => _getByType('ad');
}
