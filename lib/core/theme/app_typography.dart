import 'package:flutter/material.dart';

/// Type scale, set in Barlow: heavy, tightly tracked display headings over a
/// light, airy body. Colors are applied by the theme, never here.
abstract final class AppTypography {
  static const family = 'Barlow';
  static const _tight = -0.6;

  static const textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: _tight, height: 1.05),
    headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: _tight, height: 1.1),
    headlineSmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: _tight, height: 1.15),
    titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
    labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
  );

  /// Large numeric readouts (speed, counts).
  static const metric = TextStyle(
    fontFamily: family,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const metricSmall = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Uppercase, tracked section label ("RECENT EVENTS").
  static const overline = TextStyle(fontFamily: family, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4);

  static const tabular = [FontFeature.tabularFigures()];
}
