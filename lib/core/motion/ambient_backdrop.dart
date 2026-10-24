import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_colors.dart';

/// The app's ground: midnight navy lit by a maroon glow at the top-left and a
/// faint crimson ember at the bottom-right, both drifting slowly so the
/// screen never feels static.
///
/// Opaque, so it can sit under every page route. Only the top route ticks:
/// routes covered by an opaque route are offstage and their tickers muted.
class AmbientBackdrop extends StatefulWidget {
  const AmbientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<AmbientBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 22));

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
    final tones = context.tones;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GroundPainter(t: _c, base: tones.groundBase, glow: tones.groundGlow, ember: tones.groundEmber),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GroundPainter extends CustomPainter {
  _GroundPainter({required this.t, required this.base, required this.glow, required this.ember}) : super(repaint: t);

  final Animation<double> t;
  final Color base, glow, ember;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);
    final a = t.value * 2 * math.pi;
    final longest = size.longestSide;

    void orb(Offset center, double radius, Color color) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Maroon glow wanders around the top-left corner.
    orb(
      Offset(size.width * (0.08 + 0.10 * math.sin(a)), size.height * (0.02 + 0.06 * math.cos(a))),
      longest * 0.7,
      glow.withValues(alpha: glow.a * 0.75),
    );
    // Ember drifts along the bottom-right, out of phase.
    orb(
      Offset(size.width * (0.95 - 0.12 * math.cos(a)), size.height * (0.92 - 0.05 * math.sin(a))),
      longest * 0.6,
      ember,
    );
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.base != base || old.glow != glow || old.ember != ember;
}
