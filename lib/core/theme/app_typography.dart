import 'package:flutter/material.dart';

/// Type scale. Colors are applied by the theme, never here.
abstract final class AppTypography {
  static const _tight = -0.3;

  static const textTheme = TextTheme(
    displaySmall: TextStyle(
        fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: _tight),
    headlineMedium: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: _tight),
    headlineSmall: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: _tight),
    titleLarge: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: _tight),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4),
  );

  /// Large numeric readouts (speed, counts).
  static const metric = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const metricSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const tabular = [FontFeature.tabularFigures()];
}
