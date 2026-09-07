import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_ext.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Key in LocalStorageService (a thin SharedPreferences wrapper already
/// initialized during app startup — see ServiceLocator.initialize()) that
/// gates whether this screen is shown again. Reused directly rather than
/// introducing a new storage service, per this feature's "reuse existing
/// architecture" requirement.
const String kHasSeenIntroKey = 'has_seen_intro';

class _IntroPageData {
  const _IntroPageData({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
  });
  final String emoji;
  final String title;
  final String body;
  final List<Color> gradient;
}

/// First-launch introduction — five pages explaining the app's core value
/// props before the user reaches auth/home. Shown once (gated by
/// [kHasSeenIntroKey] in AppRouter's redirect logic) and replayable from
/// Settings. Deliberately independent of AuthProvider/auth state — this is
/// a product tour, not part of the existing profile-completion
/// "onboarding" flow (OnboardingScreen/RouteNames.onboarding), which is a
/// different, already-existing thing this screen does not duplicate or
/// touch.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Root cause of stale-screen content during rapid navigation: neither
  // _next() nor _finish() guarded against re-entrancy. PageController.
  // nextPage()'s returned Future only completes once ITS OWN animation
  // settles, but _next() was fire-and-forget — a second rapid tap (or
  // Skip fired mid-transition) called nextPage()/_finish() again while
  // the first animation was still in flight, so the two competed and
  // PageController's animation controller could be redirected mid-flight
  // (dropping or reordering the intermediate onPageChanged calls that
  // update _page). Since the surrounding chrome (background gradient,
  // progress dots, the Skip/Next label swapping to "Get started") reads
  // ONLY _page, a dropped/reordered onPageChanged left that chrome
  // reporting an earlier page than the one the PageView had actually
  // settled on — the visible symptom of "the previous screen's details
  // are still showing" the bug report describes. This flag makes both
  // handlers ignore further taps until the in-flight transition's own
  // Future genuinely resolves, so at most one transition — and one
  // onPageChanged — is ever in flight at a time.
  bool _isTransitioning = false;

  static const _pageCount = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    await LocalStorageService.instance.setBool(kHasSeenIntroKey, true);
    if (!mounted) return;
    // Same "force redirect re-evaluation" idiom SplashScreen uses — lets
    // AppRouter's existing redirect logic decide where to actually land
    // (auth, home, or profile-onboarding) instead of this screen having
    // its own opinion about auth state.
    context.go(RouteNames.splash);
  }

  Future<void> _next() async {
    if (_isTransitioning) return;
    if (_page == _pageCount - 1) {
      await _finish();
      return;
    }
    _isTransitioning = true;
    try {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } finally {
      // The transition that was in flight when this fires is, by
      // definition, still the current one — nothing else could have
      // started a second one while _isTransitioning was true — so it's
      // always correct to clear the guard here regardless of mount
      // state (no setState involved, just unblocking future taps).
      _isTransitioning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      _IntroPageData(
        emoji: '🎉',
        title: l10n.introPage1Title,
        body: l10n.introPage1Body,
        gradient: const [AppColors.brandBlueDark, AppColors.brandBlueMid],
      ),
      _IntroPageData(
        emoji: '🎴',
        title: l10n.introPage2Title,
        body: l10n.introPage2Body,
        gradient: const [AppColors.brandPurpleDark, AppColors.brandPurpleMid],
      ),
      _IntroPageData(
        emoji: '🚪',
        title: l10n.introPage3Title,
        body: l10n.introPage3Body,
        gradient: const [AppColors.brandOrangeDark, AppColors.brandOrangeMid],
      ),
      _IntroPageData(
        emoji: '✦',
        title: l10n.introPage4Title,
        body: l10n.introPage4Body,
        gradient: const [AppColors.brandPurpleMid, AppColors.brandBlueMid],
      ),
      _IntroPageData(
        emoji: '🚀',
        title: l10n.introPage5Title,
        body: l10n.introPage5Body,
        gradient: const [AppColors.brandBlueDark, AppColors.brandOrangeDark],
      ),
    ];
    final current = pages[_page];
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: current.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: isLast
                      ? const SizedBox(height: 40)
                      : TextButton(
                          onPressed: _finish,
                          child: Text(
                            l10n.introSkip,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageCount,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final p = pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                                p.emoji,
                                style: const TextStyle(fontSize: 88),
                              )
                              .animate(key: ValueKey('emoji_$i'))
                              .fadeIn(duration: 420.ms)
                              .scale(
                                begin: const Offset(0.6, 0.6),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 32),
                          Text(
                                p.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                              .animate(key: ValueKey('title_$i'))
                              .fadeIn(delay: 100.ms, duration: 380.ms)
                              .slideY(
                                begin: 0.15,
                                end: 0,
                                delay: 100.ms,
                                duration: 380.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 16),
                          Text(
                                p.body,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              )
                              .animate(key: ValueKey('body_$i'))
                              .fadeIn(delay: 180.ms, duration: 380.ms)
                              .slideY(
                                begin: 0.15,
                                end: 0,
                                delay: 180.ms,
                                duration: 380.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pageCount,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: current.gradient.first,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLast ? l10n.introGetStarted : l10n.introNext,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
