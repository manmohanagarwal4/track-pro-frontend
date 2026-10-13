import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  static const screen = EdgeInsets.symmetric(horizontal: lg);
  static const screenAll = EdgeInsets.all(lg);
  static const card = EdgeInsets.all(lg);
  static const cardCompact = EdgeInsets.all(md);
  static const listItem = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const chip = EdgeInsets.symmetric(horizontal: md, vertical: sm);

  static const gapXs = SizedBox(width: xs, height: xs);
  static const gapSm = SizedBox(width: sm, height: sm);
  static const gapMd = SizedBox(width: md, height: md);
  static const gapLg = SizedBox(width: lg, height: lg);
  static const gapXl = SizedBox(width: xl, height: xl);
  static const gapXxl = SizedBox(width: xxl, height: xxl);

  /// Max width for content columns on tablets / web.
  static const double maxContentWidth = 760;

  /// Bottom padding for scrollables so content clears the bottom nav / FABs.
  static const double bottomSafe = 96;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 8;
  static const double lg = 14;
  static const double xl = 22;
  static const double pill = 999;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const xlAll = BorderRadius.all(Radius.circular(xl));
  static const pillAll = BorderRadius.all(Radius.circular(pill));
  static const sheet = BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

abstract final class Breakpoints {
  static const double tablet = 720;
  static const double desktop = 1080;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}
