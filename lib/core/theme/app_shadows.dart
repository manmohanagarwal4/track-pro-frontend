import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Depth: soft ambient shadows that sink glass surfaces into the ground, and
/// colored glows that make accents look lit from within.
abstract final class AppShadows {
  /// Resting glass card: a deep, soft drop shadow.
  static List<BoxShadow> card(Brightness b) => b == Brightness.dark
      ? const [BoxShadow(color: Color(0x6605060F), blurRadius: 28, offset: Offset(0, 14), spreadRadius: -6)]
      : const [BoxShadow(color: Color(0x1A14162E), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -6)];

  /// Pressed / hovered glass card: the shadow tightens and an accent glow
  /// blooms around the rim.
  static List<BoxShadow> cardActive(Brightness b, Color accent) => [
    BoxShadow(color: accent.withValues(alpha: b == Brightness.dark ? 0.32 : 0.18), blurRadius: 26, spreadRadius: -4),
    ...card(b),
  ];

  /// Hairline ring used by glass controls over the map (`--shadow-sm`).
  static List<BoxShadow> hairline(Brightness b) => [
    BoxShadow(color: b == Brightness.dark ? AppColors.darkOutline : const Color(0x1FB81D30), spreadRadius: 1),
    BoxShadow(
      color: b == Brightness.dark ? const Color(0x5905060F) : const Color(0x1414162E),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  /// `--shadow-md`: sheets and floating panels.
  static List<BoxShadow> floating(Brightness b) => b == Brightness.dark
      ? const [
          BoxShadow(color: AppColors.darkOutline, spreadRadius: 1),
          BoxShadow(color: Color(0x9905060F), blurRadius: 32, offset: Offset(0, 14)),
        ]
      : const [
          BoxShadow(color: Color(0x1FB81D30), spreadRadius: 1),
          BoxShadow(color: Color(0x2414162E), blurRadius: 28, offset: Offset(0, 12)),
        ];

  /// Neon bloom under an accent element (buttons, active nav, badges).
  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.55 * strength),
      blurRadius: 18 * strength,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.25 * strength),
      blurRadius: 40 * strength,
      spreadRadius: 2,
    ),
  ];
}
