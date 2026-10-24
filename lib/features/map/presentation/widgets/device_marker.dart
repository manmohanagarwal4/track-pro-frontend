import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../domain/device_view.dart';

/// Custom map pin: ground-filled disc ringed in the status color with the
/// asset glyph, heading arrow when moving, name tag + outer ring when
/// selected, pulse in emergency.
class DeviceMarkerIcon extends StatelessWidget {
  const DeviceMarkerIcon({
    super.key,
    required this.view,
    required this.heading,
    this.selected = false,
    this.pulse,
  });

  final DeviceView view;
  final double heading;
  final bool selected;

  /// 0..1 animation phase for the emergency pulse.
  final double? pulse;

  static const double size = 76;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final color = tones.tone(StatusStyle.of(view.status));
    final ground = context.tones.groundBase;
    final halo = MapPalette.of(context).land;
    final disc = selected ? 36.0 : 30.0;
    final moving = view.status.isMoving;
    final emergency = view.status.isEmergency;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (emergency && pulse != null)
            Container(
              width: disc + 34 * pulse!,
              height: disc + 34 * pulse!,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tones.crit.withValues(alpha: 0.3 * (1 - pulse!)),
              ),
            ),
          if (selected || emergency)
            Container(
              width: disc + 14,
              height: disc + 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
              ),
            ),
          if (moving)
            Transform.rotate(
              angle: heading * math.pi / 180,
              child: SizedBox(
                width: disc + 18,
                height: disc + 18,
                child: CustomPaint(painter: _HeadingPainter(color, halo)),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              color: ground,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              boxShadow: [BoxShadow(color: halo, spreadRadius: 1.5)],
            ),
            child: Icon(AppIcons.asset(view.iconType), size: disc * 0.48, color: color),
          ),
          if (selected)
            Positioned(
              top: size / 2 + disc / 2 + 6,
              child: _NameTag(name: view.name),
            ),
        ],
      ),
    );
  }
}

class _NameTag extends StatelessWidget {
  const _NameTag({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _HeadingPainter extends CustomPainter {
  _HeadingPainter(this.color, this.halo);

  final Color color;
  final Color halo;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final path = Path()
      ..moveTo(c.dx, 0)
      ..lineTo(c.dx - 6, 9)
      ..lineTo(c.dx + 6, 9)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = halo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HeadingPainter old) => old.color != color || old.halo != halo;
}

/// Cluster bubble with device count.
class ClusterMarkerIcon extends StatelessWidget {
  const ClusterMarkerIcon({super.key, required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.tones.tone(color);
    final d = count < 10 ? 40.0 : count < 50 ? 48.0 : 56.0;
    return Center(
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.14)),
        alignment: Alignment.center,
        child: Container(
          width: d - 12,
          height: d - 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(color: c, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing accent dot for the user's (simulated) location.
class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.16)),
        alignment: Alignment.center,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.tones.groundBase,
            border: Border.all(color: accent, width: 3),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: context.tones.accent300),
          ),
        ),
      ),
    );
  }
}
