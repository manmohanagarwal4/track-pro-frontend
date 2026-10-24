import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../data/models/geofence.dart';

/// Geofence circles with name labels.
class GeofenceLayers extends StatelessWidget {
  const GeofenceLayers({super.key, required this.geofences, this.highlightId, this.showLabels = true});

  final List<Geofence> geofences;
  final String? highlightId;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom;
    final tones = context.tones;
    final fences = geofences.where((g) => g.active || g.id == highlightId).toList();
    return Stack(
      children: [
        CircleLayer(
          circles: [
            for (final g in fences)
              CircleMarker(
                point: g.center,
                radius: g.radiusM,
                useRadiusInMeter: true,
                color: tones.tone(StatusStyle.geofence(g.type)).withValues(alpha: g.id == highlightId ? 0.16 : 0.08),
                borderColor: tones.tone(StatusStyle.geofence(g.type)),
                borderStrokeWidth: g.id == highlightId ? 2 : 1.5,
              ),
          ],
        ),
        if (showLabels && zoom >= 11)
          MarkerLayer(
            markers: [
              for (final g in fences)
                Marker(
                  point: g.center,
                  width: 150,
                  height: 26,
                  child: Center(child: _FenceLabel(fence: g)),
                ),
            ],
          ),
      ],
    );
  }
}

/// Status-colored label with a map-ground halo, like the design's zone names.
class _FenceLabel extends StatelessWidget {
  const _FenceLabel({required this.fence});

  final Geofence fence;

  @override
  Widget build(BuildContext context) {
    final color = context.tones.tone(StatusStyle.geofence(fence.type));
    final halo = MapPalette.of(context).labelHalo;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w500,
        );
    final label = fence.name.toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.geofenceType(fence.type), size: 11, color: color, shadows: [Shadow(color: halo, blurRadius: 3)]),
        const SizedBox(width: 4),
        Flexible(
          child: Stack(
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..strokeJoin = StrokeJoin.round
                    ..color = halo,
                ),
              ),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style?.copyWith(color: color)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A route polyline with start / end pins.
class RouteLayers extends StatelessWidget {
  const RouteLayers({
    super.key,
    required this.points,
    this.color,
    this.showEndpoints = true,
    this.dashed = false,
    this.width = 4.5,
  });

  final List<LatLng> points;
  final Color? color;
  final bool showEndpoints;
  final bool dashed;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              strokeWidth: width,
              color: c,
              borderStrokeWidth: 2,
              borderColor: MapPalette.of(context).land.withValues(alpha: 0.85),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
              pattern: dashed ? StrokePattern.dashed(segments: const [8, 6]) : const StrokePattern.solid(),
            ),
          ],
        ),
        if (showEndpoints)
          MarkerLayer(
            markers: [
              Marker(point: points.first, width: 28, height: 28, child: const _EndpointPin(start: true)),
              Marker(point: points.last, width: 28, height: 28, child: const _EndpointPin(start: false)),
            ],
          ),
      ],
    );
  }
}

/// Start: ground disc ringed in text color. End: accent square with halo.
class _EndpointPin extends StatelessWidget {
  const _EndpointPin({required this.start});

  final bool start;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (start) {
      final ink = theme.colorScheme.onSurface;
      return Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: context.tones.groundBase,
            shape: BoxShape.circle,
            border: Border.all(color: ink, width: 2.5),
            boxShadow: [BoxShadow(color: MapPalette.of(context).land, spreadRadius: 1.5)],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
        ),
      );
    }
    final accent = theme.colorScheme.primary;
    return Container(
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}
