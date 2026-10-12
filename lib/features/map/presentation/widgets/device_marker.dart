import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../domain/device_view.dart';

/// Custom map pin: asset icon in a status-colored disc, heading arrow when
/// moving, name tag when selected, red pulse in emergency.
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
    final color = StatusStyle.of(view.status);
    final disc = selected ? 40.0 : 32.0;
    final moving = view.status.isMoving;
    final emergency = view.status.isEmergency;
    final surface = Theme.of(context).colorScheme.surface;

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
                color: AppColors.emergency.withValues(alpha: 0.35 * (1 - pulse!)),
              ),
            ),
          if (selected)
            Container(
              width: disc + 16,
              height: disc + 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.18)),
            ),
          if (moving)
            Transform.rotate(
              angle: heading * math.pi / 180,
              child: SizedBox(
                width: disc + 18,
                height: disc + 18,
                child: CustomPaint(painter: _HeadingPainter(color)),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: surface, width: 2.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(AppIcons.asset(view.iconType), size: disc * 0.5, color: Colors.white),
          ),
          if (selected)
            Positioned(
              top: size / 2 + disc / 2 + 4,
              child: _NameTag(name: view.name, color: color),
            ),
        ],
      ),
    );
  }
}

class _NameTag extends StatelessWidget {
  const _NameTag({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _HeadingPainter extends CustomPainter {
  _HeadingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final path = Path()
      ..moveTo(c.dx, 0)
      ..lineTo(c.dx - 6, 9)
      ..lineTo(c.dx + 6, 9)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HeadingPainter old) => old.color != color;
}

/// Cluster bubble with device count.
class ClusterMarkerIcon extends StatelessWidget {
  const ClusterMarkerIcon({super.key, required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final d = count < 10 ? 40.0 : count < 50 ? 48.0 : 56.0;
    return Center(
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.22),
        ),
        alignment: Alignment.center,
        child: Container(
          width: d - 10,
          height: d - 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

/// Pulsing blue dot for the user's (simulated) location.
class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.stationary.withValues(alpha: 0.18),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.stationary,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
            ),
          ),
        ),
      );
}
