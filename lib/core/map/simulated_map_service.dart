import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/mock/geo/ncr_geo.dart';
import '../theme/app_colors.dart';
import 'map_service.dart';

/// Offline base map of Delhi NCR rendered entirely from local vector data.
/// No tiles, API keys or network access are needed.
class SimulatedMapService implements MapService {
  const SimulatedMapService();

  @override
  String get name => 'TrackPro Simulated Map';

  @override
  bool get requiresNetwork => false;

  @override
  double get minZoom => 8.5;

  @override
  double get maxZoom => 18;

  @override
  LatLng get defaultCenter => NcrGeo.defaultCenter;

  @override
  double get defaultZoom => NcrGeo.defaultZoom;

  @override
  Color backgroundColor(BuildContext context) => MapPalette.of(context).land;

  @override
  List<Widget> buildBaseLayers(BuildContext context, {required bool showLabels}) {
    final p = MapPalette.of(context);
    return [
      PolygonLayer(
        simplificationTolerance: 0,
        polygons: [
          for (final a in NcrGeo.areas)
            Polygon(
              points: a.points,
              color: a.isPark ? p.park : p.urban,
              borderColor: a.isPark ? p.park : p.urbanBorder,
              borderStrokeWidth: 1,
            ),
        ],
      ),
      PolylineLayer(
        simplificationTolerance: 0,
        polylines: [
          Polyline(
              points: NcrGeo.yamuna, color: p.water, strokeWidth: 320, useStrokeWidthInMeter: true),
          Polyline(
              points: NcrGeo.hindon, color: p.water, strokeWidth: 120, useStrokeWidthInMeter: true),
        ],
      ),
      _RoadsLayer(palette: p),
      if (showLabels) _LabelsLayer(palette: p),
    ];
  }
}

class _RoadsLayer extends StatelessWidget {
  const _RoadsLayer({required this.palette});

  final MapPalette palette;

  static final _geometry = [
    for (final r in NcrGeo.roads)
      (r.roadClass, [for (final id in r.nodes) NcrGeo.placeById[id]!.point]),
  ];

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom;
    final scale = ((zoom - 9) * 0.9 + 1.6).clamp(1.2, 9.0);
    final lines = <Polyline>[];
    for (final (cls, pts) in _geometry) {
      final w = cls == RoadClass.highway ? scale * 1.4 : scale;
      lines.add(Polyline(
        points: pts,
        strokeWidth: w,
        color: cls == RoadClass.highway ? palette.highway : palette.road,
        borderStrokeWidth: cls == RoadClass.highway ? 1.2 : 0.8,
        borderColor: palette.highwayCasing,
      ));
    }
    return PolylineLayer(polylines: lines, simplificationTolerance: 0);
  }
}

class _LabelsLayer extends StatelessWidget {
  const _LabelsLayer({required this.palette});

  final MapPalette palette;

  @override
  Widget build(BuildContext context) {
    final zoom = MapCamera.of(context).zoom;
    final halo = [
      Shadow(color: palette.labelHalo, blurRadius: 3),
      Shadow(color: palette.labelHalo, blurRadius: 6),
    ];
    final markers = <Marker>[
      if (zoom < 13.5)
        for (final c in NcrGeo.cityLabels)
          if (c.primary || zoom >= 10.5)
            Marker(
              point: c.point,
              width: 160,
              height: 22,
              child: Center(
                child: Text(
                  c.name,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: zoom < 10 ? 10 : 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: palette.label.withValues(alpha: 0.75),
                    shadows: halo,
                  ),
                ),
              ),
            ),
      if (zoom >= 11.3)
        for (final pl in NcrGeo.places)
          if (pl.major || zoom >= 12.3)
            Marker(
              point: pl.point,
              width: 140,
              height: 32,
              alignment: Alignment.topCenter,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    pl.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: palette.label,
                      shadows: halo,
                    ),
                  ),
                ),
              ),
            ),
    ];
    return MarkerLayer(markers: markers, rotate: true);
  }
}
