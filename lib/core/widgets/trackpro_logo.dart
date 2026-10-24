import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// TrackPro mark: an accent-outlined rounded square holding a pin with
/// signal arcs.
class TrackProMark extends StatelessWidget {
  const TrackProMark({super.key, this.size = 48, this.rounded = true, this.outline, this.glyph});

  final double size;
  final bool rounded;

  /// Overrides for use on a colored ground; default to the theme accent.
  final Color? outline;
  final Color? glyph;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: TrackProMarkPainter(
            rounded: rounded,
            outline: outline ?? Theme.of(context).colorScheme.primary,
            glyph: glyph ?? AppTones.of(context).accent300,
          ),
        ),
      );
}

class TrackProMarkPainter extends CustomPainter {
  const TrackProMarkPainter({
    this.rounded = true,
    this.outline = AppColors.crimsonLight,
    this.glyph = AppColors.roseLight,
  });

  final bool rounded;
  final Color outline;
  final Color glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final stroke = math.max(1.5, s * 0.03);
    final box = rect.deflate(stroke / 2);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = outline;
    if (rounded) {
      canvas.drawRRect(RRect.fromRectAndRadius(box, Radius.circular(s * 0.29)), border);
    } else {
      canvas.drawRect(box, border);
    }

    // Pin: a teardrop whose sides are tangent to the head circle.
    final cx = s * 0.42;
    final cy = s * 0.47;
    final r = s * 0.175;
    final tipY = cy + r * 2.05;
    final alpha = math.asin(r / (tipY - cy)); // tangent angle
    final pin = Path()
      ..moveTo(cx, tipY)
      ..lineTo(cx - r * math.cos(alpha), cy + r * math.sin(alpha))
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi - alpha, math.pi + 2 * alpha, false)
      ..close();
    // Punch the pin's eye out on its own layer so the ground shows through.
    canvas.saveLayer(rect, Paint());
    canvas.drawPath(pin, Paint()..color = glyph);
    canvas.drawCircle(Offset(cx, cy), r * 0.42, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // Signal arcs
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.05;
    final origin = Offset(cx, cy);
    for (final k in [1.7, 2.3]) {
      canvas.drawArc(Rect.fromCircle(center: origin, radius: r * k), -math.pi * 0.40, math.pi * 0.32, false,
          arc..color = glyph.withValues(alpha: k < 2 ? 0.95 : 0.6));
    }
  }

  @override
  bool shouldRepaint(TrackProMarkPainter old) =>
      old.rounded != rounded || old.outline != outline || old.glyph != glyph;
}

class TrackProLogo extends StatelessWidget {
  const TrackProLogo({super.key, this.size = 36, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TrackProMark(size: size),
        if (showWordmark) ...[
          SizedBox(width: size * 0.3),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Track'),
              TextSpan(text: 'Pro', style: TextStyle(color: theme.colorScheme.primary)),
            ]),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: size * 0.62,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
