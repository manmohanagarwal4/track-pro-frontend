import 'package:flutter/material.dart';

/// TrackPro brand palette and semantic colors.
///
/// Brand: "Iris" violet primary with a "Signal" teal accent.
/// Status colors are reserved for device state and are never used decoratively.
abstract final class AppColors {
  // Brand
  static const iris = Color(0xFF5A4BFF);
  static const irisLight = Color(0xFF8C82FF);
  static const irisDeep = Color(0xFF3B2FD1);
  static const signal = Color(0xFF14B8A6);
  static const signalLight = Color(0xFF5EEAD4);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [iris, Color(0xFF3D8BFF), signal],
    stops: [0, 0.55, 1],
  );

  // Status
  static const moving = Color(0xFF16A34A);
  static const stationary = Color(0xFF2F7BF6);
  static const offline = Color(0xFF94A3B8);
  static const warning = Color(0xFFF59E0B);
  static const emergency = Color(0xFFEF4444);
  static const idle = Color(0xFF0EA5E9);

  // Light neutrals
  static const lightBackground = Color(0xFFF5F6FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFEEF0F6);
  static const lightOutline = Color(0xFFE2E5EE);
  static const lightText = Color(0xFF0F172A);
  static const lightTextMuted = Color(0xFF64748B);

  // Dark neutrals
  static const darkBackground = Color(0xFF0A0E17);
  static const darkSurface = Color(0xFF121826);
  static const darkSurfaceHigh = Color(0xFF1B2335);
  static const darkOutline = Color(0xFF263049);
  static const darkText = Color(0xFFF1F5F9);
  static const darkTextMuted = Color(0xFF94A3B8);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);
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
    land: Color(0xFFF1EFEA),
    urban: Color(0xFFE6E3DC),
    urbanBorder: Color(0xFFD9D4CA),
    water: Color(0xFFAFD3F0),
    highway: Color(0xFFFFFFFF),
    highwayCasing: Color(0xFFD4CFC4),
    road: Color(0xFFFBFAF7),
    label: Color(0xFF4B5563),
    labelHalo: Color(0xFFF1EFEA),
    park: Color(0xFFD5EBCF),
  );

  static const dark = MapPalette(
    land: Color(0xFF111827),
    urban: Color(0xFF172033),
    urbanBorder: Color(0xFF1F2A40),
    water: Color(0xFF0E2A47),
    highway: Color(0xFF34405A),
    highwayCasing: Color(0xFF1A2236),
    road: Color(0xFF2A3449),
    label: Color(0xFF9CA3AF),
    labelHalo: Color(0xFF111827),
    park: Color(0xFF14261F),
  );

  static MapPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
