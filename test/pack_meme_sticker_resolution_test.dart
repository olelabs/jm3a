// Meme sticker upload follow-up — pure coverage for
// resolveCardStickerFields (create_pack_screen.dart), the function that
// decides whether a new meme prompt card's sticker comes from
// CardDraft.stickerId (a sticker_library pick) or CardDraft.imageUrl (a
// freshly uploaded sticker, which has no sticker_library row — that
// table has no client-insert RLS policy, confirmed against
// dbf/schema.sql). Mutually exclusive, matching CardDraft.stickerId's own
// doc comment.
//
// _StickerPickerSheet/_MultiLangCardInput are private classes in
// create_pack_screen.dart and can't be constructed directly from a test
// in a different library, and the full CreatePackScreen wizard needs a
// live Supabase-backed PackRepository/PackProvider to advance past the
// first network-backed step — matching this project's established
// testing boundary, so this file tests the one genuinely pure decision
// the sticker picker flow makes. See pack_create_wizard_regression_test
// for the widget-level coverage that IS reachable (jumping straight to
// the Cards step via existingPackId/existingPack, which needs no network
// call to build).
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/packs/presentation/screens/create_pack_screen.dart';

void main() {
  group('resolveCardStickerFields', () {
    test('a library pick (stickerId set) uses stickerId, not imageUrl', () {
      final result = resolveCardStickerFields(
        selectedStickerId: 'lib-sticker-1',
        selectedStickerUrl: 'https://cdn.example/lib-sticker-1.png',
      );
      expect(result.stickerId, 'lib-sticker-1');
      expect(result.imageUrl, isNull);
    });

    test(
      'an uploaded sticker (url only, no library id) uses imageUrl, not '
      'stickerId',
      () {
        final result = resolveCardStickerFields(
          selectedStickerId: null,
          selectedStickerUrl: 'https://cdn.example/uploaded123.jpg',
        );
        expect(result.stickerId, isNull);
        expect(result.imageUrl, 'https://cdn.example/uploaded123.jpg');
      },
    );

    test('no sticker selected at all -> both fields null', () {
      final result = resolveCardStickerFields(
        selectedStickerId: null,
        selectedStickerUrl: null,
      );
      expect(result.stickerId, isNull);
      expect(result.imageUrl, isNull);
    });
  });
}
