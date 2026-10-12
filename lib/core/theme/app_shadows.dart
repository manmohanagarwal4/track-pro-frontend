import 'package:flutter/material.dart';

abstract final class AppShadows {
  static List<BoxShadow> card(Brightness b) => b == Brightness.dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ];

  static List<BoxShadow> floating(Brightness b) => [
        BoxShadow(
          color: b == Brightness.dark
              ? const Color(0x66000000)
              : const Color(0x1F0F172A),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ];
}
