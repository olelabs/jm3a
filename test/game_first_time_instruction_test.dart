// Regression coverage for "first-time game instruction banner, shown once
// per game type per device" (Truth or Dare / Never Have I Ever / Meme).
//
// This already exists end-to-end, reusing the app's existing tutorial
// architecture: each game screen wraps its main content in ScreenTutorial
// (lib/shared/widgets/tutorial/screen_tutorial.dart) with a dedicated
// TutorialIds.{tod,nhie,meme}Intro id (lib/core/services/
// app_tutorial_service.dart) and a single showcase step whose title/body
// explain that game's objective — see tutTodTitle/tutTodBody,
// tutNhieTitle/tutNhieBody, tutMemeTitle/tutMemeBody in the l10n .arb
// files (EN/AR/FR all present). AppTutorialService persists completion via
// the existing LocalStorageService (SharedPreferences) — no backend/DB
// state — under a single string-list key, independent per tutorial id.
//
// What's verified here (the part that's genuinely unit-testable without a
// full game screen + Supabase harness): each of the three game intro ids
// is independently tracked — completing one does not affect the others,
// completion persists across "sessions" (re-reading LocalStorageService),
// and shouldShow correctly reflects the once-per-device contract.
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/di/service_locator.dart';
import 'package:jma3a/core/services/app_tutorial_service.dart';
import 'package:jma3a/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.initialize();
  });

  group('10: first-time game instruction state, once per game type', () {
    test('all three game intro ids are registered and start out not '
        'completed on a fresh device', () {
      for (final id in [
        TutorialIds.todIntro,
        TutorialIds.nhieIntro,
        TutorialIds.memeIntro,
      ]) {
        expect(sl.tutorialService.isCompleted(id), isFalse);
        expect(sl.tutorialService.shouldShow(id), isTrue);
      }
    });

    test('completing Truth or Dare\'s intro does not show it again, but '
        'leaves NHIE\'s and Meme\'s untouched', () async {
      await sl.tutorialService.markCompleted(TutorialIds.todIntro);

      expect(sl.tutorialService.isCompleted(TutorialIds.todIntro), isTrue);
      expect(sl.tutorialService.shouldShow(TutorialIds.todIntro), isFalse);

      expect(sl.tutorialService.isCompleted(TutorialIds.nhieIntro), isFalse);
      expect(sl.tutorialService.shouldShow(TutorialIds.nhieIntro), isTrue);
      expect(sl.tutorialService.isCompleted(TutorialIds.memeIntro), isFalse);
      expect(sl.tutorialService.shouldShow(TutorialIds.memeIntro), isTrue);
    });

    test('completing all three independently persists all three, each '
        'once', () async {
      await sl.tutorialService.markCompleted(TutorialIds.todIntro);
      await sl.tutorialService.markCompleted(TutorialIds.nhieIntro);
      await sl.tutorialService.markCompleted(TutorialIds.memeIntro);

      for (final id in [
        TutorialIds.todIntro,
        TutorialIds.nhieIntro,
        TutorialIds.memeIntro,
      ]) {
        expect(sl.tutorialService.shouldShow(id), isFalse);
      }

      // Persistence survives re-reading the same underlying store (the
      // same guarantee a real app restart relies on — this service reads
      // straight from LocalStorageService each call, never an in-memory
      // cache of completion).
      expect(
        LocalStorageService.instance.getStringList('tutorials_completed_v1'),
        containsAll([
          TutorialIds.todIntro,
          TutorialIds.nhieIntro,
          TutorialIds.memeIntro,
        ]),
      );
    });

    test('marking the same game intro completed twice is idempotent', () async {
      await sl.tutorialService.markCompleted(TutorialIds.memeIntro);
      await sl.tutorialService.markCompleted(TutorialIds.memeIntro);
      final stored = LocalStorageService.instance.getStringList(
        'tutorials_completed_v1',
      );
      expect(stored?.where((e) => e == TutorialIds.memeIntro).length, 1);
    });

    test('resetTutorial re-enables just that one game\'s intro', () async {
      await sl.tutorialService.markCompleted(TutorialIds.todIntro);
      await sl.tutorialService.markCompleted(TutorialIds.nhieIntro);

      await sl.tutorialService.resetTutorial(TutorialIds.todIntro);

      expect(sl.tutorialService.shouldShow(TutorialIds.todIntro), isTrue);
      expect(sl.tutorialService.shouldShow(TutorialIds.nhieIntro), isFalse);
    });
  });
}
