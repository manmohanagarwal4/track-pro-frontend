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
                color: StatusStyle.geofence(g.type).withValues(alpha: g.id == highlightId ? 0.22 : 0.12),
                borderColor: StatusStyle.geofence(g.type).withValues(alpha: 0.85),
                borderStrokeWidth: g.id == highlightId ? 2.5 : 1.5,
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

class _FenceLabel extends StatelessWidget {
  const _FenceLabel({required this.fence});

  final Geofence fence;

  @override
  Widget build(BuildContext context) {
    final color = StatusStyle.geofence(fence.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.geofenceType(fence.type), size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              fence.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: color),
            ),
          ),
        ],
      ),
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
              borderColor: Colors.white.withValues(alpha: 0.8),
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

class _EndpointPin extends StatelessWidget {
  const _EndpointPin({required this.start});

  final bool start;

  @override
  Widget build(BuildContext context) {
    final color = start ? AppColors.moving : AppColors.emergency;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
      ),
      child: Icon(start ? AppIcons.play : AppIcons.flag, size: 12, color: Colors.white),
    );
  }
}
