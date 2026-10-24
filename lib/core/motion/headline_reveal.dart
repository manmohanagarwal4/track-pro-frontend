import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_spacing.dart';

/// Cinematic entrance for a headline: the text rises out of a mask, wipes in
/// left to right and pulls into focus.
///
/// Wraps any child (usually a single [Text]) so the text stays one widget for
/// semantics and tests.
class HeadlineReveal extends StatefulWidget {
  const HeadlineReveal({super.key, required this.child, this.delay = Duration.zero, this.duration = AppDurations.hero});

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<HeadlineReveal> createState() => _HeadlineRevealState();
}

class _HeadlineRevealState extends State<HeadlineReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + widget.duration);
  late final double _start = widget.delay.inMicroseconds / (widget.delay + widget.duration).inMicroseconds;
  late final _rise = CurvedAnimation(
    parent: _c,
    curve: Interval(_start, 1, curve: AppCurves.enter),
  );
  late final _wipe = CurvedAnimation(
    parent: _c,
    curve: Interval(_start, 1, curve: Curves.easeInOutCubic),
  );

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _rise.dispose();
    _wipe.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final rise = _rise.value;
        final wipe = _wipe.value;
        final blur = (1 - rise) * 6;
        // A soft-edged alpha band sweeping left to right. Past the end of the
        // wipe the whole gradient is opaque.
        final edge = -0.25 + wipe * 1.5;
        return ClipRect(
          child: FractionalTranslation(
            translation: Offset(0, (1 - rise) * 0.7),
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => LinearGradient(
                colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
                stops: [0, edge.clamp(0.0, 1.0), (edge + 0.25).clamp(0.0, 1.0)],
              ).createShader(r),
              child: ImageFiltered(
                enabled: blur > 0.05,
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Text filled with an accent gradient that a highlight sweeps across every
/// few seconds, like light catching a glossy surface.
class ShimmerText extends StatefulWidget {
  const ShimmerText(this.text, {super.key, this.style, required this.colors, this.period = const Duration(seconds: 3)});

  final String text;
  final TextStyle? style;
  final List<Color> colors;
  final Duration period;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        // The highlight crosses during the first 40% of each period, then rests.
        final p = (_c.value / 0.4).clamp(0.0, 1.0);
        final x = -0.5 + p * 2;
        const w = 0.22;
        final a = widget.colors.first, b = widget.colors.last;
        // A constant a→b base with a white band at x. Off either end the band
        // stops collapse onto 0 or 1, leaving just the base gradient.
        double s(double v) => v.clamp(0.0, 1.0);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [a, Color.lerp(a, b, s(x - w))!, Colors.white, Color.lerp(a, b, s(x + w))!, b],
            stops: [0, s(x - w), s(x), s(x + w), 1],
          ).createShader(r),
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}
