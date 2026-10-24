import 'package:flutter/material.dart';

/// TrackPro palette — the "Crimson Night" system: a midnight-navy ground lit
/// by a maroon glow, plum-to-navy glass surfaces, and a crimson accent that
/// glows. State colors follow the red / blue / green / yellow swatch set.
///
/// The static colors here are theme-neutral mid tones, safe on both grounds.
/// For per-theme values (tonal ramps, tag backgrounds, glass) use
/// [AppTones.of] / `context.tones`.
abstract final class AppColors {
  // Brand (accent). `crimson` sits between the dark (#FF5A64) and light
  // (#C81E33) accents so it reads on either ground.
  static const crimson = Color(0xFFE03A45);
  static const crimsonLight = Color(0xFFFF5A64);
  static const crimsonDeep = Color(0xFFB81D30);
  static const rose = Color(0xFFE68AA0);
  static const roseLight = Color(0xFFFFC2CF);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5A64), Color(0xFFC81E33)],
  );

  // Status
  static const moving = Color(0xFF3CCF6E);
  static const stationary = Color(0xFF8B7CF6);
  static const offline = Color(0xFF8A8DA6);
  static const warning = Color(0xFFE5C337);
  static const emergency = Color(0xFFFF4060);
  static const idle = Color(0xFF2F9BEA);

  // Light neutrals
  static const lightBackground = Color(0xFFF6F1F4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFEDE6EC);
  static const lightOutline = Color(0x1F14162E); // text @ 12%
  static const lightText = Color(0xFF14162E);
  static const lightTextMuted = Color(0xFF62657E);

  // Dark neutrals
  static const darkBackground = Color(0xFF0E1027);
  static const darkSurface = Color(0xFF1A1C38);
  static const darkSurfaceHigh = Color(0xFF2A2C4A);
  static const darkOutline = Color(0x1FFFFFFF); // white @ 12%
  static const darkText = Color(0xFFF5F5FA);
  static const darkTextMuted = Color(0xFFA3A6C2);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);
}

/// Per-theme tokens that Material's [ColorScheme] has no slot for.
///
/// The neutral and accent ramps flip between themes so that, e.g.,
/// `neutral800` is always "a quiet tile on the surface" and `accent300`
/// is always "an accent-tinted icon".
@immutable
class AppTones extends ThemeExtension<AppTones> {
  const AppTones({
    required this.ok,
    required this.warn,
    required this.crit,
    required this.okBg,
    required this.warnBg,
    required this.critBg,
    required this.okInk,
    required this.warnInk,
    required this.critInk,
    required this.glass,
    required this.divider,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
    required this.accent100,
    required this.accent200,
    required this.accent300,
    required this.accent700,
    required this.accent800,
    required this.accent900,
    required this.glassTop,
    required this.glassBottom,
    required this.glassBorder,
    required this.glassHighlight,
    required this.groundBase,
    required this.groundGlow,
    required this.groundEmber,
    required this.shadow,
  });

  final Color ok, warn, crit;
  final Color okBg, warnBg, critBg;
  final Color okInk, warnInk, critInk;

  /// Translucent ground for controls floating over the map.
  final Color glass;
  final Color divider;

  final Color neutral300, neutral400, neutral500, neutral600, neutral700, neutral800, neutral900;
  final Color accent100, accent200, accent300, accent700, accent800, accent900;

  /// Glass card fill: plum-tinted at the top-left, fading to navy.
  final Color glassTop, glassBottom;

  /// Glass card rim and the specular sheen along its top edge.
  final Color glassBorder, glassHighlight;

  /// Ambient backdrop: base ground, the maroon glow at top-left and the
  /// faint crimson ember at bottom-right.
  final Color groundBase, groundGlow, groundEmber;

  /// Ambient drop shadow under raised surfaces.
  final Color shadow;

  LinearGradient get glassGradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [glassTop, glassBottom]);

  static const dark = AppTones(
    ok: Color(0xFF4ADE80),
    warn: Color(0xFFF2CF4A),
    crit: Color(0xFFFF5A6E),
    okBg: Color(0xFF143524),
    warnBg: Color(0xFF3A3212),
    critBg: Color(0xFF4A1622),
    okInk: Color(0xFFB6F2CB),
    warnInk: Color(0xFFFCEBA8),
    critInk: Color(0xFFFFC9D0),
    glass: Color(0xB31A1C38),
    divider: AppColors.darkOutline,
    neutral300: Color(0xFFD3D5E8),
    neutral400: Color(0xFFB4B7D0),
    neutral500: Color(0xFF9497B3),
    neutral600: Color(0xFF73769A),
    neutral700: Color(0xFF54577A),
    neutral800: Color(0xFF2E3052),
    neutral900: Color(0xFF15172F),
    accent100: Color(0xFFFFF1F2),
    accent200: Color(0xFFFFD6DA),
    accent300: Color(0xFFFF9AA4),
    accent700: Color(0xFFA61E2E),
    accent800: Color(0xFF5C1A26),
    accent900: Color(0xFF33121E),
    glassTop: Color(0xD9693349),
    glassBottom: Color(0xE6151836),
    glassBorder: Color(0x1FFFFFFF),
    glassHighlight: Color(0x1AFFFFFF),
    groundBase: AppColors.darkBackground,
    groundGlow: Color(0xFF5A1B2B),
    groundEmber: Color(0x40E03A45),
    shadow: Color(0x8C05060F),
  );

  static const light = AppTones(
    ok: Color(0xFF138A4A),
    warn: Color(0xFFA87F00),
    crit: Color(0xFFD21F3C),
    okBg: Color(0xFFD3F5E0),
    warnBg: Color(0xFFFBEFC2),
    critBg: Color(0xFFFFDDE2),
    okInk: Color(0xFF0B5530),
    warnInk: Color(0xFF654C00),
    critInk: Color(0xFF8A1225),
    glass: Color(0xCCFFFFFF),
    divider: AppColors.lightOutline,
    neutral300: Color(0xFF4F5270),
    neutral400: Color(0xFF5E6180),
    neutral500: Color(0xFF6B6E8A),
    neutral600: Color(0xFF9A9CB4),
    neutral700: Color(0xFFD5D2DE),
    neutral800: Color(0xFFECE6EC),
    neutral900: Color(0xFFF8F4F7),
    accent100: Color(0xFF4A0E18),
    accent200: Color(0xFF7A1726),
    accent300: Color(0xFFB81D30),
    accent700: Color(0xFFFFC2C9),
    accent800: Color(0xFFFFE1E4),
    accent900: Color(0xFFFFF2F3),
    glassTop: Color(0xF2FFFFFF),
    glassBottom: Color(0xCCFFF3F5),
    glassBorder: Color(0x1FB81D30),
    glassHighlight: Color(0xB3FFFFFF),
    groundBase: AppColors.lightBackground,
    groundGlow: Color(0xFFFFD3DA),
    groundEmber: Color(0x33C9C4FF),
    shadow: Color(0x2414162E),
  );

  static AppTones of(BuildContext context) =>
      Theme.of(context).extension<AppTones>() ?? (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// Tag background / ink pair for a palette color, matching the design's
  /// `--ok-bg` / `--ok-ink` tonal tags. Null for colors outside the palette.
  ({Color bg, Color ink})? knownTag(Color c) {
    if (c == AppColors.moving) return (bg: okBg, ink: okInk);
    if (c == AppColors.warning) return (bg: warnBg, ink: warnInk);
    if (c == AppColors.emergency) return (bg: critBg, ink: critInk);
    if (c == AppColors.offline) return (bg: neutral800, ink: neutral300);
    if (c == AppColors.crimson || c == AppColors.crimsonLight || c == AppColors.rose) {
      return (bg: accent800, ink: accent100);
    }
    return null;
  }

  /// Like [knownTag], falling back to a translucent tint of [c].
  ({Color bg, Color ink}) tag(Color c) => knownTag(c) ?? (bg: c.withValues(alpha: 0.16), ink: c);

  /// The theme-tuned variant of a static status color (brighter on dark,
  /// deeper on light).
  Color tone(Color status) {
    if (status == AppColors.moving) return ok;
    if (status == AppColors.warning) return warn;
    if (status == AppColors.emergency) return crit;
    return status;
  }

  @override
  AppTones copyWith() => this;

  /// Blends every token so a light / dark switch morphs instead of snapping.
  @override
  AppTones lerp(AppTones? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTones(
      ok: l(ok, other.ok),
      warn: l(warn, other.warn),
      crit: l(crit, other.crit),
      okBg: l(okBg, other.okBg),
      warnBg: l(warnBg, other.warnBg),
      critBg: l(critBg, other.critBg),
      okInk: l(okInk, other.okInk),
      warnInk: l(warnInk, other.warnInk),
      critInk: l(critInk, other.critInk),
      glass: l(glass, other.glass),
      divider: l(divider, other.divider),
      neutral300: l(neutral300, other.neutral300),
      neutral400: l(neutral400, other.neutral400),
      neutral500: l(neutral500, other.neutral500),
      neutral600: l(neutral600, other.neutral600),
      neutral700: l(neutral700, other.neutral700),
      neutral800: l(neutral800, other.neutral800),
      neutral900: l(neutral900, other.neutral900),
      accent100: l(accent100, other.accent100),
      accent200: l(accent200, other.accent200),
      accent300: l(accent300, other.accent300),
      accent700: l(accent700, other.accent700),
      accent800: l(accent800, other.accent800),
      accent900: l(accent900, other.accent900),
      glassTop: l(glassTop, other.glassTop),
      glassBottom: l(glassBottom, other.glassBottom),
      glassBorder: l(glassBorder, other.glassBorder),
      glassHighlight: l(glassHighlight, other.glassHighlight),
      groundBase: l(groundBase, other.groundBase),
      groundGlow: l(groundGlow, other.groundGlow),
      groundEmber: l(groundEmber, other.groundEmber),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppTonesContext on BuildContext {
  AppTones get tones => AppTones.of(this);
}

/// Colors for the locally rendered (simulated) map, per brightness.
class MapPalette {
  const MapPalette({
    required this.land,
    required this.urban,
    required this.urbanBorder,
    required this.water,
    required this.highway,
    required this.highwayCasing,
    required this.road,
    required this.label,
    required this.labelHalo,
    required this.park,
  });

  final Color land;
  final Color urban;
  final Color urbanBorder;
  final Color water;
  final Color highway;
  final Color highwayCasing;
  final Color road;
  final Color label;
  final Color labelHalo;
  final Color park;

  static const light = MapPalette(
    land: Color(0xFFF1ECF0),
    urban: Color(0xFFEAE3E9),
    urbanBorder: Color(0xFFDFD6DE),
    water: Color(0xFFCFD6EE),
    highway: Color(0xFFFFFFFF),
    highwayCasing: Color(0xFFE6C9CF),
    road: Color(0xFFF9F6F8),
    label: Color(0xFF6B6E8A),
    labelHalo: Color(0xFFF1ECF0),
    park: Color(0xFFD7E8DA),
  );

  static const dark = MapPalette(
    land: Color(0xFF12142E),
    urban: Color(0xFF171936),
    urbanBorder: Color(0xFF1F2142),
    water: Color(0xFF0B1030),
    highway: Color(0xFF3A2440),
    highwayCasing: Color(0xFF12142E),
    road: Color(0xFF1E2040),
    label: Color(0xFF7C7FA0),
    labelHalo: Color(0xFF12142E),
    park: Color(0xFF13241F),
  );

  static MapPalette of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;
}
