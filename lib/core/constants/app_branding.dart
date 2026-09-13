/// Centralized MOUJ TECH app-ownership branding configuration.
///
/// Jma3a is developed/owned by MOUJ TECH — this is the ONE place that
/// fact is encoded (asset path + display name). No screen should ever
/// hardcode its own logo path or "Developed by MOUJ TECH" copy; use
/// [MoujTechBrand] (shared/widgets/mouj_tech_brand.dart), which reads
/// from here.
///
/// This is deliberately distinct from the Jma3a app's OWN logo/wordmark
/// (see `assets/images/backgrounds/jma3a_logo_white.png`, used by
/// [GameFlipCard]'s `_BrandMark`, etc. — the splash screen switched to
/// the full-color `jma3a_logo.png` instead, item 7 of the splash-logo
/// pass) — MOUJ TECH is the owning company, not the app's own product
/// mark.
abstract final class AppBranding {
  /// Owning company name — shown wherever the app must disclose who
  /// develops/operates it.
  static const String ownerName = 'MOUJ TECH';

  /// The real MOUJ TECH logo, as provided (a full brand card: wave mark +
  /// "MOUJ TECH" wordmark + tagline, on a black canvas — NOT just the
  /// icon by itself). [MoujTechBrand] crops this down to the icon mark at
  /// render time (see its own doc comment) rather than this file
  /// referencing a second, separately-cropped asset — there is still only
  /// ONE real logo file, this is the ONE place its path is named, and
  /// nothing else in the app references a logo file path directly.
  ///
  /// If this file is ever missing/fails to load, [MoujTechBrand]'s
  /// `Image.asset` falls back to a text-only "Developed by MOUJ TECH"
  /// mark via its `errorBuilder` — never a fabricated placeholder logo.
  static const String logoAssetPath = 'assets/images/branding/mouj.jpeg';
}
