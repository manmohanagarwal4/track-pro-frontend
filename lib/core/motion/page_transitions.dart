import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import 'ambient_backdrop.dart';

/// Page routes rise and sharpen into place while the page underneath sinks
/// back and dims, giving every push a sense of depth. Each page gets its own
/// [AmbientBackdrop].
class DepthPageTransitionsBuilder extends PageTransitionsBuilder {
  const DepthPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 480);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: AppCurves.emphasized, reverseCurve: Curves.easeInCubic);
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    final under = CurvedAnimation(parent: secondaryAnimation, curve: AppCurves.emphasized);
    return AnimatedBuilder(
      animation: under,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(enter),
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(enter),
            child: AmbientBackdrop(child: child),
          ),
        ),
      ),
      builder: (_, page) => Transform.scale(
        scale: 1 - 0.05 * under.value,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.35 * under.value), BlendMode.srcATop),
          child: page,
        ),
      ),
    );
  }
}

/// iOS keeps its native slide and edge-swipe-back, on top of the backdrop.
class BackdropCupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const BackdropCupertinoPageTransitionsBuilder();

  static const _cupertino = CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _cupertino.buildTransitions(route, context, animation, secondaryAnimation, AmbientBackdrop(child: child));
}

/// Tab switches inside the shell: a quick fade-through with a slight zoom.
/// Tabs are transparent and share the shell's backdrop.
CustomTransitionPage<void> fadeThroughPage(Widget child, GoRouterState state) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 360),
  reverseTransitionDuration: const Duration(milliseconds: 200),
  transitionsBuilder: (_, animation, secondaryAnimation, child) {
    final t = CurvedAnimation(parent: animation, curve: AppCurves.enter);
    // Both tabs are see-through, so the outgoing one fades out first
    // (driven by the incoming tab's animation) before this one fades in.
    return FadeTransition(
      opacity: ReverseAnimation(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0, 0.25, curve: Curves.easeIn),
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.25, 1, curve: Curves.easeOut),
        ),
        child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(t), child: child),
      ),
    );
  },
);
