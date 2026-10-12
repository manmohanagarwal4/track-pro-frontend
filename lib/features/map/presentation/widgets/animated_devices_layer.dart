import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/status_style.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../domain/device_view.dart';
import 'device_marker.dart';

class _Track {
  _Track(this.from, this.heading) : to = from, headingFrom = heading, headingTo = heading;

  LatLng from;
  LatLng to;
  double headingFrom;
  double headingTo;
  double heading;
  Duration start = Duration.zero;
  Duration duration = Duration.zero;

  LatLng positionAt(Duration t) {
    if (duration == Duration.zero) return to;
    final p = ((t - start).inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
    return GeoUtils.lerp(from, to, p);
  }

  double headingAt(Duration t) {
    if (duration == Duration.zero) return headingTo;
    final p = ((t - start).inMicroseconds / (duration.inMicroseconds * 0.35)).clamp(0.0, 1.0);
    return GeoUtils.lerpHeading(headingFrom, headingTo, p);
  }

  bool done(Duration t) => t - start >= duration;
}

/// Marker layer that glides devices between reported fixes instead of
/// teleporting, and clusters nearby devices at low zoom.
///
/// Must be placed inside a [FlutterMap] (it reads [MapCamera]).
class AnimatedDevicesLayer extends StatefulWidget {
  const AnimatedDevicesLayer({
    super.key,
    required this.devices,
    this.selectedId,
    this.onTap,
    this.clustering = true,
    this.onSelectedPosition,
    this.mapController,
  });

  final List<DeviceView> devices;
  final String? selectedId;
  final ValueChanged<String>? onTap;
  final bool clustering;

  /// Called every frame with the selected device's animated position
  /// (used for "follow" mode).
  final ValueChanged<LatLng>? onSelectedPosition;
  final MapController? mapController;

  @override
  State<AnimatedDevicesLayer> createState() => _AnimatedDevicesLayerState();
}

class _AnimatedDevicesLayerState extends State<AnimatedDevicesLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Map<String, _Track> _tracks = {};
  Duration _elapsed = Duration.zero;
  bool _hasEmergency = false;

  static const _maxGlide = Duration(milliseconds: 4800);
  static const _minGlide = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _sync(initial: true);
  }

  @override
  void didUpdateWidget(AnimatedDevicesLayer old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync({bool initial = false}) {
    final seen = <String>{};
    _hasEmergency = false;
    for (final v in widget.devices) {
      final pos = v.position;
      if (pos == null) continue;
      seen.add(v.id);
      if (v.status.isEmergency) _hasEmergency = true;
      final t = _tracks[v.id];
      if (t == null || initial) {
        _tracks[v.id] = _Track(pos, v.heading);
        continue;
      }
      if (t.to == pos) continue;
      final current = t.positionAt(_elapsed);
      final jump = GeoUtils.distanceMeters(current, pos);
      t
        ..from = jump > 20000 ? pos : current
        ..to = pos
        ..headingFrom = t.headingAt(_elapsed)
        ..headingTo = v.heading
        ..start = _elapsed;
      var glide = v.device.updateInterval;
      if (glide > _maxGlide) glide = _maxGlide;
      if (glide < _minGlide) glide = _minGlide;
      t.duration = glide;
    }
    _tracks.removeWhere((id, _) => !seen.contains(id));
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    final animating = _hasEmergency || _tracks.values.any((t) => !t.done(elapsed));
    final sel = widget.selectedId;
    if (sel != null && widget.onSelectedPosition != null) {
      final t = _tracks[sel];
      if (t != null) widget.onSelectedPosition!(t.positionAt(elapsed));
    }
    if (mounted) setState(() {});
    if (!animating) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final pulse = (_elapsed.inMilliseconds % 1400) / 1400;
    final items = <({DeviceView view, LatLng pos, double heading})>[];
    for (final v in widget.devices) {
      final t = _tracks[v.id];
      if (t == null) continue;
      items.add((view: v, pos: t.positionAt(_elapsed), heading: t.headingAt(_elapsed)));
    }

    final markers = <Marker>[];
    Marker deviceMarker(({DeviceView view, LatLng pos, double heading}) i) => Marker(
          key: ValueKey('dev-${i.view.id}'),
          point: i.pos,
          width: DeviceMarkerIcon.size,
          height: DeviceMarkerIcon.size,
          child: GestureDetector(
            onTap: () => widget.onTap?.call(i.view.id),
            child: DeviceMarkerIcon(
              view: i.view,
              heading: i.heading,
              selected: i.view.id == widget.selectedId,
              pulse: i.view.status.isEmergency ? pulse : null,
            ),
          ),
        );

    if (!widget.clustering || camera.zoom >= 13.5 || items.length < 8) {
      // Selected device drawn last so it is on top.
      items.sort((a, b) => (a.view.id == widget.selectedId ? 1 : 0) - (b.view.id == widget.selectedId ? 1 : 0));
      markers.addAll(items.map(deviceMarker));
      return MarkerLayer(markers: markers);
    }

    // Grid clustering in screen space.
    const cell = 64.0;
    final buckets = <(int, int), List<({DeviceView view, LatLng pos, double heading})>>{};
    ({DeviceView view, LatLng pos, double heading})? selected;
    for (final i in items) {
      if (i.view.id == widget.selectedId || i.view.status.isEmergency) {
        if (i.view.id == widget.selectedId) {
          selected = i;
        } else {
          markers.add(deviceMarker(i));
        }
        continue;
      }
      final p = camera.projectAtZoom(i.pos);
      buckets.putIfAbsent(((p.dx / cell).floor(), (p.dy / cell).floor()), () => []).add(i);
    }
    for (final group in buckets.values) {
      if (group.length == 1) {
        markers.add(deviceMarker(group.first));
        continue;
      }
      var lat = 0.0, lng = 0.0;
      final counts = <Color, int>{};
      for (final g in group) {
        lat += g.pos.latitude;
        lng += g.pos.longitude;
        final c = StatusStyle.of(g.view.status);
        counts[c] = (counts[c] ?? 0) + 1;
      }
      final color = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      final center = LatLng(lat / group.length, lng / group.length);
      final points = [for (final g in group) g.pos];
      markers.add(Marker(
        point: center,
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _zoomInto(points, camera),
          child: ClusterMarkerIcon(count: group.length, color: color),
        ),
      ));
    }
    if (selected != null) markers.add(deviceMarker(selected));
    return MarkerLayer(markers: markers);
  }

  void _zoomInto(List<LatLng> points, MapCamera camera) {
    final controller = widget.mapController;
    if (controller == null) return;
    final bounds = LatLngBounds.fromPoints(points);
    final spread = GeoUtils.distanceMeters(bounds.southWest, bounds.northEast);
    if (spread < 50) {
      controller.move(bounds.center, math.min(camera.zoom + 3, 17));
    } else {
      controller.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
        maxZoom: 16,
      ));
    }
  }
}
