import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/services/app_theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Reusable 3D flip presentation for a Jma3a game card (Truth or Dare,
/// NHIE, Meme). Fully NATIVE Flutter — gradients, borders, glow shadows
/// and a small deterministic decorative-particle painter — no image
/// asset of any kind. Only lays the game's title (back) and content
/// (front) inside that native shell.
///
/// Fully controlled by the caller's own game state — no global state:
///
/// * [revealed] is the manual-reveal edge: false→true starts the flip
///   (Truth or Dare's "player tapped Truth/Dare" case). Leave it `false`
///   forever for an auto-revealing game (NHIE/Meme) and use
///   [autoRevealDelay] instead.
/// * [contentId] identifies WHICH content is currently on the card (e.g.
///   a card/turn id). Changing it resets the card to back-visible and,
///   if [autoRevealDelay] is set, schedules a fresh disposal/stale-safe
///   auto-reveal for the new id — a timer scheduled for a previous id is
///   a guaranteed no-op (see [_generation]), so a rapid round change can
///   never reveal stale content.
/// * [onRevealed] fires exactly once per reveal, the instant the flip
///   lands on the front — games that need a further transition once the
///   front is visible (Meme's minimize) hook this, not the animation
///   internals.
class GameFlipCard extends StatefulWidget {
  const GameFlipCard({
    super.key,
    required this.title,
    required this.frontChild,
    this.revealed = false,
    this.contentId,
    this.autoRevealDelay,
    this.onRevealed,
    this.flipDuration = const Duration(milliseconds: 600),
    // Item 2 (card-size regression pass) — raised from 340. 340 was
    // narrow enough to be the BINDING constraint (not the parent's real
    // available width/height) on most phones, which is what made the
    // card visibly smaller than its previous presentation even though
    // the actual overflow-safe min(maxWidth, constraints.maxWidth,
    // constraints.maxHeight * ratio) logic below was otherwise correct.
    // 520 is a generous ceiling that only ever binds on genuinely
    // tablet-width screens — every phone-width caller still gets sized
    // by its parent's real constraints, exactly as intended by "sensible
    // cap so it doesn't become absurdly large on tablets" above.
    this.maxWidth = 520,
    this.scale = 1.0,
    this.frontContentBuilder,
    this.aspectRatioOverride,
  });

  /// Localized game title (e.g. `l10n.gameNameTruthOrDare`), rendered
  /// centered inside the back face's native title plate. Never place
  /// this text anywhere else — it's the one and only title surface.
  final String title;

  /// The game's own already-selected content, centered in the front
  /// face's safe content zone once revealed. Rendered exactly as given
  /// — this widget never sources/selects content itself.
  final Widget frontChild;

  /// Optional escape hatch for front content that needs to size itself
  /// against the REAL bounded safe-content box (width AND height),
  /// instead of [frontChild]'s default handling — which wraps the child
  /// in `FittedBox(scaleDown)` around a fixed-width `SizedBox`. That
  /// default is correct for short/fixed content (Truth or Dare/NHIE's
  /// prompts): it never scales anything that already fits. But for
  /// content whose length varies a lot (Meme's caption), a wrapped block
  /// that's taller than the safe zone gets shrunk UNIFORMLY on both axes
  /// by scaleDown — narrowing the rendered width along with the font
  /// even though only the height was ever the actual constraint, which
  /// reads as the text being "squeezed into a narrow column". When set,
  /// this builder replaces [frontChild] on the front face and receives
  /// the safe zone's true bounded [BoxConstraints], so it can pick its
  /// own font size against the full available width instead. Leave null
  /// (the default) to keep the existing [frontChild] behavior exactly as
  /// before — every other caller of this widget is unaffected.
  final Widget Function(BuildContext context, BoxConstraints safeConstraints)?
  frontContentBuilder;

  final bool revealed;
  final Object? contentId;
  final Duration? autoRevealDelay;
  final VoidCallback? onRevealed;
  final Duration flipDuration;

  /// Sensible cap so the card doesn't become absurdly large on tablets;
  /// actual rendered width is `min(maxWidth, available width)`.
  final double maxWidth;

  /// External uniform scale — e.g. Meme's minimize-after-reveal
  /// transition. This widget only renders at whatever scale it's given;
  /// it never decides to shrink itself.
  final double scale;

  /// Portrait ratio in the spirit of the original design reference —
  /// chosen for the native design, not copied from any image's pixel
  /// dimensions. The default for every caller that doesn't set
  /// [aspectRatioOverride] (Truth or Dare, NHIE) — unaffected by it.
  static const double aspectRatio = 0.68;

  /// Per-instance override of [aspectRatio] — e.g. Meme's wide/horizontal
  /// card (long captions need width, not the portrait shape ToD/NHIE's
  /// short prompts suit). Null (the default) keeps every existing caller
  /// on the static [aspectRatio] exactly as before.
  final double? aspectRatioOverride;

  /// Key on the actual sized card box (see build()) — the outer shell
  /// fills whatever bounded space its parent gives it (so this widget
  /// composes correctly inside a Positioned.fill/Expanded/Column), so
  /// this is what tests should measure for the card's true rendered
  /// size, not GameFlipCard's own bounds.
  @visibleForTesting
  static const Key cardBoxKey = ValueKey('gameFlipCardBox');

  @override
  State<GameFlipCard> createState() => _GameFlipCardState();
}

class _GameFlipCardState extends State<GameFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.flipDuration,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  /// Bumped every time [GameFlipCard.contentId] changes — a pending
  /// auto-reveal [Timer] captures the generation it was scheduled under
  /// and checks it's still current before touching the controller, so a
  /// stale timer from a previous round can never reveal the wrong card.
  int _generation = 0;
  Timer? _autoRevealTimer;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
    if (widget.revealed) {
      _controller.value = 1;
    } else {
      _scheduleAutoRevealIfNeeded();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onRevealed?.call();
  }

  @override
  void didUpdateWidget(covariant GameFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final contentChanged = widget.contentId != oldWidget.contentId;
    if (contentChanged) {
      _generation++;
      _autoRevealTimer?.cancel();
    }

    // A genuine reveal edge (false→true) ALWAYS animates, even if
    // contentId also changed in this same update — Truth or Dare's
    // choosingType→readingCard swap (via GameFlipCard's shared
    // GlobalKey, see TodCardScreen) changes both `revealed` and
    // `contentId` simultaneously in one didUpdateWidget call, and that
    // is exactly the transition that must play the flip, not snap.
    // Checking this BEFORE contentChanged is what makes that so — the
    // reverse order would silently jump straight to the front instead
    // of animating.
    if (widget.revealed && !oldWidget.revealed) {
      _controller.forward();
      return;
    }

    if (contentChanged) {
      // New, not-yet-revealed content (NHIE/Meme's per-round reset) —
      // snap back to the back face and, if configured, schedule a fresh
      // auto-reveal for this new content/generation.
      _controller.value = widget.revealed ? 1 : 0;
      if (!widget.revealed) _scheduleAutoRevealIfNeeded();
      return;
    }

    if (!widget.revealed && oldWidget.revealed) {
      // Explicit reset/replay from the parent.
      _controller.value = 0;
      _scheduleAutoRevealIfNeeded();
    }
  }

  void _scheduleAutoRevealIfNeeded() {
    final delay = widget.autoRevealDelay;
    if (delay == null) return;
    final scheduledGeneration = _generation;
    _autoRevealTimer = Timer(delay, () {
      if (!mounted) return;
      if (scheduledGeneration != _generation) return; // superseded
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _autoRevealTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = widget.aspectRatioOverride ?? GameFlipCard.aspectRatio;
        final widthByAvailableWidth = math.min(
          widget.maxWidth,
          constraints.maxWidth,
        );
        // Bound by the available HEIGHT too, not just width — the card's
        // height was previously derived purely from width * aspect ratio,
        // with no awareness of how much vertical space the parent
        // actually has (e.g. ToD's pre-selection screen shares its
        // Expanded region with a banner, prompt text, and the Truth/Dare
        // buttons; a tall portrait card sized only from width could
        // demand more height than that region has, which the SizedBox
        // below doesn't clip — the actual overflow). Only ever shrinks
        // relative to the width-only calculation, and only when the
        // parent's height is genuinely bounded (never divides by/against
        // an unbounded maxHeight).
        final width = constraints.maxHeight.isFinite
            ? math.min(widthByAvailableWidth, constraints.maxHeight * ratio)
            : widthByAvailableWidth;
        final height = width / ratio;
        return Center(
          child: Transform.scale(
            scale: widget.scale,
            child: SizedBox(
              key: GameFlipCard.cardBoxKey,
              width: width,
              height: height,
              child: AnimatedBuilder(
                animation: _t,
                builder: (context, _) {
                  final angle = _t.value * math.pi;
                  final isBack = angle <= math.pi / 2;
                  // The front's OWN local rotation returns to exactly 0
                  // at angle == pi (full reveal), so it renders flat and
                  // unmirrored — see this widget's class doc for why
                  // subtracting pi here (rather than showing the same
                  // `angle` on both faces) is what prevents the front
                  // from ever appearing backwards during the second half
                  // of the flip.
                  final localAngle = isBack ? angle : angle - math.pi;
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(localAngle);
                  return Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: isBack
                        ? _CardBack(
                            title: widget.title,
                            width: width,
                            height: height,
                          )
                        : _CardFront(
                            frontChild: widget.frontChild,
                            width: width,
                            height: height,
                            frontContentBuilder: widget.frontContentBuilder,
                          ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Native card shell — shared gradient/border/glow/decoration frame both
// faces render inside. No image of any kind.
// ─────────────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.width,
    required this.height,
    required this.decorations,
    required this.child,
    List<Color>? gradientColors,
    Color? borderGlowColor,
  }) : _gradientColors = gradientColors ?? _defaultGradientColors,
       _borderGlowColor = borderGlowColor ?? AppColors.neonPink;

  final double width;
  final double height;
  final List<_Decoration> decorations;
  final Widget child;

  // Items 5-8 — front-card-only Game Card Color override (see
  // GameCardColorData). [_CardBack]'s own call site never passes these,
  // so the back face always renders this exact default regardless of
  // what the user picks for the front — that's the explicit requirement,
  // not an oversight.
  final List<Color> _gradientColors;
  final Color _borderGlowColor;

  static const List<Color> _defaultGradientColors = [
    Color(0xFF4C2E8C),
    Color(0xFF2A1854),
    Color(0xFF130A29),
  ];

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        // Deep radial glow, brightest toward the upper-left, fading to a
        // near-black base — the "dark gradient background + subtle
        // radial glow" in one gradient. Colors are either the default
        // purple (back face, or front with no override applied) or the
        // user's selected Game Card Color (front face only).
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.7),
          radius: 1.3,
          colors: _gradientColors,
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: _borderGlowColor.withValues(alpha: 0.55),
          width: 1.4,
        ),
        boxShadow: [
          ...AppShadows.glow(_gradientColors.first),
          // Soft highlight on the upper edge, echoing the inspiration
          // artwork's accent border — tinted to match the selected color
          // instead of a fixed pink that would clash with every hue.
          BoxShadow(
            color: _borderGlowColor.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _DecorationsPainter(decorations)),
            // Subtle inner top highlight — a lacquered-surface cue
            // without a second drawn "card" behind the content.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.logoHeight = 26, this.fontSize = 17});

  /// Item 7 — both default to the width-proportional values _CardFront
  /// now actually passes (roughly double the OLD hardcoded
  /// compact-corner-mark size of 18/13) so the front face's Jma3a
  /// branding reads as clearly intentional, not tiny decorative text,
  /// while staying responsive on small phones since the caller derives
  /// these from the card's own rendered width rather than a fixed px
  /// value. Defaults kept only as a sane fallback if ever constructed
  /// without explicit sizing.
  final double logoHeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/backgrounds/jma3a_logo_white.png',
          height: logoHeight,
          errorBuilder: (_, _, _) =>
              Icon(Icons.groups_rounded, color: Colors.white, size: logoHeight),
        ),
        SizedBox(width: logoHeight * 0.3),
        Text(
          context.l10n.appName,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

/// The back face's hero mark — the SAME real Jma3a logo asset as
/// [_BrandMark] (never a fabricated one), just rendered large and
/// centered instead of small-and-corner, per the back face's "big logo,
/// title beneath it" composition. Falls back to a large native wordmark
/// (not an image) only if the asset genuinely fails to load — mirrors
/// _BrandMark's own errorBuilder fallback so the two never disagree.
class _BackHeroLogo extends StatelessWidget {
  const _BackHeroLogo({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/backgrounds/jma3a_logo_white.png',
      height: height,
      errorBuilder: (_, _, _) => Text(
        context.l10n.appName,
        style: TextStyle(
          color: Colors.white,
          fontSize: height * 0.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: AppColors.neonPink.withValues(alpha: 0.6),
              blurRadius: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// The back face's native title plate: a soft translucent panel with a
/// thin neon divider and a glow behind the text — the direct
/// replacement for the old brush-stroke image plate.
class _TitlePlate extends StatelessWidget {
  const _TitlePlate({required this.title, required this.maxWidth});
  final String title;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final safeWidth = maxWidth * 0.84;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.22),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 2.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.neonPink.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: safeWidth,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                style:
                    AppTextStyles.gameCardTitle(
                      color: Colors.white,
                      fontFamily: AppTextStyles.familyForLocale(locale),
                    ).copyWith(
                      shadows: [
                        Shadow(
                          color: AppColors.neonPink.withValues(alpha: 0.55),
                          blurRadius: 18,
                        ),
                        const Shadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.title,
    required this.width,
    required this.height,
  });
  final String title;
  final double width;
  final double height;

  static const List<_Decoration> _decorations = [
    _Decoration(_Shape.star, 0.18, 0.10, 14, AppColors.neonPink, 0.55),
    _Decoration(_Shape.dot, 0.82, 0.08, 8, AppColors.brandPurpleLight, 0.5),
    _Decoration(_Shape.sparkle, 0.70, 0.16, 12, Colors.white, 0.4),
    _Decoration(_Shape.ring, 0.12, 0.22, 16, AppColors.brandPurpleLight, 0.35),
    _Decoration(_Shape.triangle, 0.85, 0.26, 10, AppColors.neonPink, 0.4),
    _Decoration(_Shape.dot, 0.25, 0.78, 7, Colors.white, 0.4),
    _Decoration(_Shape.star, 0.80, 0.82, 12, AppColors.brandPurpleLight, 0.5),
    _Decoration(_Shape.sparkle, 0.15, 0.88, 10, AppColors.neonPink, 0.45),
    _Decoration(_Shape.ring, 0.55, 0.93, 12, Colors.white, 0.3),
    _Decoration(_Shape.dot, 0.90, 0.90, 6, AppColors.brandPurpleLight, 0.4),
  ];

  @override
  Widget build(BuildContext context) {
    return _CardShell(
          width: width,
          height: height,
          decorations: _decorations,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.09,
              vertical: height * 0.07,
            ),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Large, prominent JMA3A mark — the back face's hero
                // element (substantially bigger than the title plate
                // below it), reusing the app's own real logo asset (see
                // _BrandMark's identical asset reference) rather than a
                // fabricated wordmark.
                _BackHeroLogo(height: height * 0.20),
                SizedBox(height: height * 0.035),
                _TitlePlate(title: title, maxWidth: width),
                const Spacer(flex: 4),
              ],
            ),
          ),
        )
        // A one-shot "just dealt" pop — never repeats, so it never
        // fights tester.pumpAndSettle() or a real device's battery.
        .animate()
        .fadeIn(duration: 220.ms)
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          duration: 320.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.frontChild,
    required this.width,
    required this.height,
    this.frontContentBuilder,
  });
  final Widget frontChild;
  final double width;
  final double height;
  final Widget Function(BuildContext context, BoxConstraints safeConstraints)?
  frontContentBuilder;

  static const double _horizontalMargin = 0.10;

  static const List<_Decoration> _decorations = [
    _Decoration(_Shape.star, 0.88, 0.07, 12, AppColors.neonPink, 0.5),
    _Decoration(_Shape.dot, 0.10, 0.14, 7, Colors.white, 0.35),
    _Decoration(
      _Shape.sparkle,
      0.80,
      0.18,
      10,
      AppColors.brandPurpleLight,
      0.4,
    ),
    _Decoration(_Shape.ring, 0.14, 0.85, 14, AppColors.neonPink, 0.35),
    _Decoration(_Shape.triangle, 0.85, 0.88, 10, Colors.white, 0.35),
    _Decoration(_Shape.dot, 0.55, 0.92, 6, AppColors.brandPurpleLight, 0.4),
    _Decoration(_Shape.star, 0.30, 0.90, 9, AppColors.neonPink, 0.35),
    _Decoration(_Shape.sparkle, 0.92, 0.55, 8, Colors.white, 0.3),
  ];

  @override
  Widget build(BuildContext context) {
    final safeWidth = width * (1 - _horizontalMargin * 2);
    // Items 5/6/8 — the front face is the ONLY one that ever reads the
    // user's selected Game Card Color; the back face (_CardBack) never
    // passes gradientColors/borderGlowColor to its own _CardShell call,
    // so it always keeps the existing default regardless of this setting.
    // context.watch (not read) so every game screen using GameFlipCard
    // re-colors live the instant the user changes this in Themes —
    // AppThemeService is already a root-level ChangeNotifierProvider (see
    // app.dart), the same one theme_picker_screen.dart itself watches.
    final gameCardColor = context.watch<AppThemeService>().currentGameCardColor;
    return _CardShell(
          width: width,
          height: height,
          decorations: _decorations,
          gradientColors: gameCardColor.gradientColors,
          borderGlowColor: gameCardColor.borderGlowColor,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * _horizontalMargin,
              vertical: height * 0.06,
            ),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  // Item 7 — noticeably bigger, responsive (scales with
                  // the card's own rendered width, so it stays
                  // proportional on small phones too) instead of the old
                  // fixed-tiny `compact: true` sizing.
                  child: _BrandMark(
                    logoHeight: width * 0.13,
                    fontSize: width * 0.072,
                  ),
                ),
                Expanded(
                  child: frontContentBuilder != null
                      ? LayoutBuilder(
                          builder: (context, constraints) => Center(
                            child: frontContentBuilder!(context, constraints),
                          ),
                        )
                      : Center(
                          // The inner SizedBox lets the content wrap
                          // normally at its natural font size within the
                          // safe width first; FittedBox(scaleDown) then
                          // only shrinks the WHOLE already-wrapped block
                          // uniformly, and only if it's still too tall for
                          // the safe zone — i.e. short/medium content is
                          // never scaled at all, and long content wraps
                          // before it ever shrinks. Never scales up, never
                          // overflows.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: safeWidth,
                              child: frontChild,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 220.ms)
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          duration: 320.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Deterministic decorative particles — a fixed const list per face (never
// randomized/re-rolled on rebuild), painted once via a single lightweight
// CustomPainter. Subtle by design: low opacity, ~8-10 shapes per face.
// ─────────────────────────────────────────────────────────────────────────

enum _Shape { dot, star, ring, triangle, sparkle }

class _Decoration {
  const _Decoration(
    this.shape,
    this.dx,
    this.dy,
    this.size,
    this.color,
    this.opacity,
  );

  /// Fractional position within the card (0..1 of width/height).
  final double dx;
  final double dy;
  final double size;
  final Color color;
  final double opacity;
  final _Shape shape;
}

class _DecorationsPainter extends CustomPainter {
  const _DecorationsPainter(this.decorations);
  final List<_Decoration> decorations;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in decorations) {
      final center = Offset(d.dx * size.width, d.dy * size.height);
      final color = d.color.withValues(alpha: d.opacity);
      switch (d.shape) {
        case _Shape.dot:
          canvas.drawCircle(center, d.size / 2, Paint()..color = color);
        case _Shape.ring:
          canvas.drawCircle(
            center,
            d.size / 2,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        case _Shape.star:
          canvas.drawPath(_starPath(center, d.size), Paint()..color = color);
        case _Shape.triangle:
          canvas.drawPath(
            _trianglePath(center, d.size),
            Paint()..color = color,
          );
        case _Shape.sparkle:
          _drawSparkle(canvas, center, d.size, color);
      }
    }
  }

  Path _starPath(Offset c, double size) {
    final path = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? size / 2 : size / 4;
      final a = (i * math.pi / points) - math.pi / 2;
      final px = c.dx + r * math.cos(a);
      final py = c.dy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  Path _trianglePath(Offset c, double size) {
    final h = size * 0.86;
    return Path()
      ..moveTo(c.dx, c.dy - h / 2)
      ..lineTo(c.dx + size / 2, c.dy + h / 2)
      ..lineTo(c.dx - size / 2, c.dy + h / 2)
      ..close();
  }

  void _drawSparkle(Canvas canvas, Offset c, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(c.dx - size / 2, c.dy),
      Offset(c.dx + size / 2, c.dy),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx, c.dy - size / 2),
      Offset(c.dx, c.dy + size / 2),
      paint,
    );
    canvas.drawCircle(c, size / 6, Paint()..color = color);
  }

  // The decoration list is a compile-time const — it never changes for
  // the lifetime of this painter, so it never needs to repaint itself.
  @override
  bool shouldRepaint(covariant _DecorationsPainter oldDelegate) => false;
}
