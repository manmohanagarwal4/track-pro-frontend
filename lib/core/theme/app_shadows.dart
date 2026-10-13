import 'package:flutter/material.dart';

/// Elevation, derived from the ground: a hairline edge plus ambient darkness
/// on dark, soft ink-tinted shadows on light.
abstract final class AppShadows {
  static List<BoxShadow> card(Brightness b) => const [];

  /// Hairline ring used by glass controls over the map (`--shadow-sm`).
  static List<BoxShadow> hairline(Brightness b) => [
        BoxShadow(
          color: b == Brightness.dark ? const Color(0xFF3F424D) : const Color(0xFFD6D9E8),
          spreadRadius: 1,
        ),
      ];

  /// `--shadow-md`: sheets and floating panels.
  static List<BoxShadow> floating(Brightness b) => b == Brightness.dark
      ? const [
          BoxShadow(color: Color(0xFF595D6C), spreadRadius: 1),
          BoxShadow(color: Color(0x8C000000), blurRadius: 18, offset: Offset(0, 6)),
        ]
      : const [
          BoxShadow(color: Color(0xFFCFD3E5), spreadRadius: 1),
          BoxShadow(color: Color(0x1A1E203C), blurRadius: 18, offset: Offset(0, 6)),
        ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 30,
        ),
      ];
}
