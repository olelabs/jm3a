import 'package:flutter/widgets.dart';

import '../data/pack_repository.dart';

/// Curated "situation" vocabulary for pack discovery (lobby filtering) and
/// pack creation (creator-assigned types), sourced from the DB-admin-
/// configurable pack_situation_filters table (item 7) — see
/// PackRepository.getSituationFilters. Still backed by the EXISTING
/// pack_tags table/pack_repository tags plumbing (already fully wired
/// end-to-end: create/update send `tags`, browse/search already select
/// `pack_tags(tag)` into PackEntity.tags); this is just per-slug display
/// metadata (emoji + per-language label) layered on top of that same slug
/// string vocabulary, not a second taxonomy. pack_tags itself still
/// accepts any `^[a-z0-9_-]{1,30}$` slug — a tag can exist on a pack
/// without being one of these curated/filterable entries.
class PackSituationTag {
  const PackSituationTag(this.slug, this.emoji, this.nameJson);

  /// Matches a pack_tags.tag value exactly.
  final String slug;
  final String emoji;

  /// Per-language display name, e.g. {'en': 'Relationship', 'ar': '...'}.
  final Map<String, dynamic> nameJson;

  String label(BuildContext context) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final value = nameJson[lang] ?? nameJson['en'];
    return value is String && value.isNotEmpty ? value : slug;
  }
}

/// Look up a tag's display label by slug against an already-loaded filter
/// list — used to render a pack's EXISTING tags (which may include ones
/// outside the curated/active set) without crashing; falls back to the raw
/// slug for anything not currently a recognized filter.
String packSituationTagLabel(
  BuildContext context,
  String slug,
  List<PackSituationTag> tags,
) {
  for (final t in tags) {
    if (t.slug == slug) return t.label(context);
  }
  return slug;
}

/// How many of [selectedTags] this pack carries — the sole ranking signal.
/// 0 when nothing is selected or nothing overlaps.
extension PackSituationMatch on PackEntity {
  int situationMatchCount(Set<String> selectedTags) {
    if (selectedTags.isEmpty || tags.isEmpty) return 0;
    var n = 0;
    for (final t in tags) {
      if (selectedTags.contains(t)) n++;
    }
    return n;
  }
}

/// Deterministic ranking (item 7): packs with MORE overlapping tags with
/// [selectedTags] sort first (full/exact match > partial match > no
/// match); ties preserve each pack's original relative order (a stable
/// sort keyed on the original index, never random) so browsing stays
/// predictable. Returns [packs] completely unchanged, in the same order,
/// when [selectedTags] is empty — existing behavior for anyone who
/// doesn't use the filter.
List<PackEntity> rankPacksBySituation(
  List<PackEntity> packs,
  Set<String> selectedTags,
) {
  if (selectedTags.isEmpty) return packs;
  final indexed = packs.asMap().entries.toList();
  indexed.sort((a, b) {
    final scoreA = a.value.situationMatchCount(selectedTags);
    final scoreB = b.value.situationMatchCount(selectedTags);
    if (scoreA != scoreB) return scoreB.compareTo(scoreA);
    return a.key.compareTo(b.key);
  });
  return indexed.map((e) => e.value).toList();
}
