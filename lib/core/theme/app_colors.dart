import 'package:flutter/material.dart';

/// TrackPro palette — the "Nocturne" system: a cool indigo-grey ground with a
/// soft blurple accent, and quiet ok / warn / crit tones for state.
///
/// The static colors here are theme-neutral mid tones, safe on both grounds.
/// For per-theme values (tonal ramps, tag backgrounds, glass) use
/// [AppTones.of] / `context.tones`.
abstract final class AppColors {
  // Brand (accent). `iris` sits between the dark (#9184D9) and light
  // (#6A5DB3) accents so it reads on either ground.
  static const iris = Color(0xFF7C6FCB);
  static const irisLight = Color(0xFF9184D9);
  static const irisDeep = Color(0xFF5D5294);
  static const signal = Color(0xFFA7A1DB);
  static const signalLight = Color(0xFFD2CEFD);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9184D9), Color(0xFF6A5DB3)],
  );

  // Status
  static const moving = Color(0xFF2CAB70);
  static const stationary = Color(0xFF8E83D6);
  static const offline = Color(0xFF9397AB);
  static const warning = Color(0xFFDE9C31);
  static const emergency = Color(0xFFE54C4A);
  static const idle = Color(0xFF3BAECE);

  // Light neutrals
  static const lightBackground = Color(0xFFECEEF6);
  static const lightSurface = Color(0xFFF8F9FD);
  static const lightSurfaceHigh = Color(0xFFE1E4F1);
  static const lightOutline = Color(0x2122242E); // text @ 13%
  static const lightText = Color(0xFF22242E);
  static const lightTextMuted = Color(0xFF6F7385);

  // Dark neutrals
  static const darkBackground = Color(0xFF161826);
  static const darkSurface = Color(0xFF232532);
  static const darkSurfaceHigh = Color(0xFF3F424D);
  static const darkOutline = Color(0x29E9E9ED); // text @ 16%
  static const darkText = Color(0xFFE9E9ED);
  static const darkTextMuted = Color(0xFF9397AB);

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
  });

  final Color ok, warn, crit;
  final Color okBg, warnBg, critBg;
  final Color okInk, warnInk, critInk;

  /// Translucent ground for controls floating over the map.
  final Color glass;
  final Color divider;

  final Color neutral300, neutral400, neutral500, neutral600, neutral700, neutral800, neutral900;
  final Color accent100, accent200, accent300, accent700, accent800, accent900;

  static const dark = AppTones(
    ok: Color(0xFF5ECA91),
    warn: Color(0xFFF0BA59),
    crit: Color(0xFFF3625F),
    okBg: Color(0xFF183525),
    warnBg: Color(0xFF403012),
    critBg: Color(0xFF481B1A),
    okInk: Color(0xFFB4E9C9),
    warnInk: Color(0xFFFEDCA5),
    critInk: Color(0xFFFFCCC8),
    glass: Color(0xDB161826),
    divider: AppColors.darkOutline,
    neutral300: Color(0xFFCFD3E5),
    neutral400: Color(0xFFB2B6CA),
    neutral500: Color(0xFF9397AB),
    neutral600: Color(0xFF75798C),
    neutral700: Color(0xFF595D6C),
    neutral800: Color(0xFF3F424D),
    neutral900: Color(0xFF292B31),
    accent100: Color(0xFFF5F4FF),
    accent200: Color(0xFFE7E5FE),
    accent300: Color(0xFFD2CEFD),
    accent700: Color(0xFF5D5294),
    accent800: Color(0xFF423A6A),
    accent900: Color(0xFF2B2741),
  );

  static const light = AppTones(
    ok: Color(0xFF008853),
    warn: Color(0xFFBB7400),
    crit: Color(0xFFCC3336),
    okBg: Color(0xFFCAEFD8),
    warnBg: Color(0xFFFAE6BB),
    critBg: Color(0xFFFFDAD6),
    okInk: Color(0xFF00502F),
    warnInk: Color(0xFF6F4100),
    critInk: Color(0xFF892122),
    glass: Color(0xE0F8F9FD),
    divider: AppColors.lightOutline,
    neutral300: Color(0xFF595D6C),
    neutral400: Color(0xFF666A7C),
    neutral500: Color(0xFF6F7385),
    neutral600: Color(0xFF9397AB),
    neutral700: Color(0xFFCFD3E5),
    neutral800: Color(0xFFE1E4F1),
    neutral900: Color(0xFFF3F5FE),
    accent100: Color(0xFF2B2741),
    accent200: Color(0xFF423A6A),
    accent300: Color(0xFF5D5294),
    accent700: Color(0xFFD2CEFD),
    accent800: Color(0xFFE4E1FC),
    accent900: Color(0xFFF5F4FF),
  );

  static AppTones of(BuildContext context) =>
      Theme.of(context).extension<AppTones>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// Tag background / ink pair for a palette color, matching the design's
  /// `--ok-bg` / `--ok-ink` tonal tags. Null for colors outside the palette.
  ({Color bg, Color ink})? knownTag(Color c) {
    if (c == AppColors.moving) return (bg: okBg, ink: okInk);
    if (c == AppColors.warning) return (bg: warnBg, ink: warnInk);
    if (c == AppColors.emergency) return (bg: critBg, ink: critInk);
    if (c == AppColors.offline) return (bg: neutral800, ink: neutral300);
    if (c == AppColors.iris || c == AppColors.irisLight || c == AppColors.stationary || c == AppColors.signal) {
      return (bg: accent800, ink: accent100);
    }
    return null;
  }

  /// Like [knownTag], falling back to a translucent tint of [c].
  ({Color bg, Color ink}) tag(Color c) => knownTag(c) ?? (bg: c.withValues(alpha: 0.14), ink: c);

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

  @override
  AppTones lerp(AppTones? other, double t) => t < 0.5 || other == null ? this : other;
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
    land: Color(0xFFE2E5EE),
    urban: Color(0xFFDADEEA),
    urbanBorder: Color(0xFFD0D4E2),
    water: Color(0xFFC8D2EA),
    highway: Color(0xFFFBFBFE),
    highwayCasing: Color(0xFFD0D4E2),
    road: Color(0xFFF2F3F8),
    label: Color(0xFF75798C),
    labelHalo: Color(0xFFE2E5EE),
    park: Color(0xFFD3E2D5),
  );

  static const dark = MapPalette(
    land: Color(0xFF1A1C2A),
    urban: Color(0xFF1E2030),
    urbanBorder: Color(0xFF242738),
    water: Color(0xFF141C32),
    highway: Color(0xFF30344A),
    highwayCasing: Color(0xFF1A1C2A),
    road: Color(0xFF222536),
    label: Color(0xFF6D7184),
    labelHalo: Color(0xFF1A1C2A),
    park: Color(0xFF1B2521),
  );

  static MapPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
