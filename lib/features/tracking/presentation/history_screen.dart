import 'dart:async';

import 'package:clock/clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/device_location.dart';
import '../../../data/models/trip.dart';
import '../../devices/application/devices_controller.dart';
import '../../map/presentation/widgets/device_marker.dart';
import '../../map/presentation/widgets/map_layers.dart';
import '../../map/presentation/widgets/tracker_map.dart';
import '../../settings/application/settings_controller.dart';
import '../../trips/application/trips_providers.dart';
import '../../trips/presentation/widgets/trip_widgets.dart';

/// Height of the map block above the playback panel.
const double _mapHeight = 420;

/// How far the panel overlaps the map.
const double _overlap = 22;

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateRangePreset _preset = DateRangePreset.today;
  DateTimeRange? _custom;
  late RangeQuery _query = _buildQuery();

  RangeQuery _buildQuery() {
    final r = resolveRange(_preset, _custom, clock.now());
    return (deviceId: widget.deviceId, start: r.start, end: r.end);
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(deviceViewProvider(widget.deviceId));
    final history = ref.watch(historyProvider(_query));
    final header = _MapHeader(
      title: '${view?.name ?? 'Device'} · History',
      selector: DateRangeSelector(
        preset: _preset,
        custom: _custom,
        onChanged: (p, c) => setState(() {
          _preset = p;
          _custom = c;
          _query = _buildQuery();
        }),
      ),
    );
    final data = history.value;
    if (data != null && !data.isEmpty && !history.hasError) {
      return Scaffold(
        body: _HistoryBody(key: ValueKey(_query), history: data, header: header),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 110),
              child: AsyncView<LocationHistory>(
                value: history,
                onRetry: () => ref.invalidate(historyProvider(_query)),
                loadingMessage: 'Loading route history...',
                data: (h) => EmptyView(
                  icon: AppIcons.route,
                  title: 'No movement in this period',
                  message: view != null && !view.type.isVehicle && view.status.isResting
                      ? 'This tracker stayed in one place.'
                      : 'Try a different date range.',
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, top: 0, child: header),
        ],
      ),
    );
  }
}

/// Glass back button, title and day chips floating over the map.
class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.title, required this.selector});

  final String title;
  final Widget selector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final glassChips = theme.copyWith(
      chipTheme: theme.chipTheme.copyWith(
        backgroundColor: tones.glass,
        selectedColor: tones.glass,
        secondarySelectedColor: tones.glass,
        side: WidgetStateBorderSide.resolveWith(
          (states) =>
              BorderSide(color: states.contains(WidgetState.selected) ? theme.colorScheme.primary : tones.divider),
        ),
        labelStyle: theme.chipTheme.labelStyle?.copyWith(fontSize: 12),
        secondaryLabelStyle: theme.chipTheme.secondaryLabelStyle?.copyWith(fontSize: 12),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                if (canPop) ...[
                  MapGlass(
                    child: SizedBox.square(
                      dimension: 44,
                      child: BackButton(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  AppSpacing.gapSm,
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Theme(data: glassChips, child: selector),
        ],
      ),
    );
  }
}

class _HistoryBody extends ConsumerStatefulWidget {
  const _HistoryBody({super.key, required this.history, required this.header});

  final LocationHistory history;
  final Widget header;

  @override
  ConsumerState<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends ConsumerState<_HistoryBody> {
  final _controller = MapController();
  double _index = 0;
  Timer? _timer;
  int _speed = 8;

  List<TrackPoint> get _pts => widget.history.points;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() => _timer = null);
      return;
    }
    if (_index >= _pts.length - 1) _index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) return;
      setState(() {
        _index = (_index + _speed / 4).clamp(0, _pts.length - 1).toDouble();
        if (_index >= _pts.length - 1) {
          t.cancel();
          _timer = null;
        }
      });
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final ground = context.tones.groundBase;
    final top = MediaQuery.paddingOf(context).top;
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final points = [for (final p in _pts) p.position];
    final current = _pts[_index.round()];
    final stats = widget.history.stats;
    final view = ref.watch(deviceViewProvider(widget.history.deviceId));
    final meta = theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500);
    return LayoutBuilder(
      builder: (context, c) {
        final mapHeight = _mapHeight.clamp(0.0, c.maxHeight * 0.55);
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: mapHeight,
              child: TrackerMap(
                controller: _controller,
                showUserLocation: false,
                initialFit: CameraFit.coordinates(
                  coordinates: points,
                  padding: EdgeInsets.fromLTRB(36, top + 120, 36, _overlap + 28),
                ),
                layersBelowDevices: [
                  RouteLayers(points: points),
                  if (view != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: current.position,
                          width: DeviceMarkerIcon.size,
                          height: DeviceMarkerIcon.size,
                          child: DeviceMarkerIcon(view: view, heading: 0),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: top + 120,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ground, ground.withAlpha(0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(left: 0, right: 0, top: 0, child: widget.header),
            Positioned(
              left: 0,
              right: 0,
              top: mapHeight - _overlap,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: AppRadius.sheet),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    40 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    ResponsiveCenter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton.outlined(
                                key: const Key('history-play'),
                                onPressed: _togglePlay,
                                style: IconButton.styleFrom(
                                  fixedSize: const Size(44, 44),
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(color: theme.colorScheme.primary),
                                ),
                                icon: Icon(_timer == null ? AppIcons.play : AppIcons.pause, size: 18),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _index,
                                  max: (_pts.length - 1).toDouble(),
                                  onChanged: (v) => setState(() => _index = v),
                                ),
                              ),
                              Text(
                                Fmt.time(current.timestamp),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  fontFeatures: AppTypography.tabular,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 56),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${Fmt.dateTime(current.timestamp)} · ${Fmt.speed(current.speedKmh, unit)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: meta?.copyWith(fontFeatures: AppTypography.tabular),
                                  ),
                                ),
                                PopupMenuButton<int>(
                                  tooltip: 'Playback speed',
                                  initialValue: _speed,
                                  onSelected: (v) => setState(() => _speed = v),
                                  itemBuilder: (_) => [
                                    for (final s in [4, 8, 16, 32]) PopupMenuItem(value: s, child: Text('${s}x')),
                                  ],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      '${_speed}x',
                                      style: theme.textTheme.labelLarge?.copyWith(color: tones.accent300),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapLg,
                          _StatGrid(items: tripStatTiles(stats, ref)),
                          AppSpacing.gapLg,
                          _EndpointRow(
                            label: 'Start',
                            time: _pts.first.timestamp,
                            trailing: Fmt.dayLabel(_pts.first.timestamp),
                          ),
                          _EndpointRow(
                            label: 'End',
                            time: _pts.last.timestamp,
                            trailing: Fmt.distance(stats.distanceKm, unit, decimals: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Plain value-over-label stats, as in the design's playback panel.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<StatTile> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 560 ? 6 : 3;
        final w = (c.maxWidth - (cols - 1) * 6) / cols;
        return Wrap(
          spacing: 6,
          runSpacing: AppSpacing.md,
          children: [
            for (final i in items)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: tones.neutral500),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// time | label | meta row with a divider on top.
class _EndpointRow extends StatelessWidget {
  const _EndpointRow({required this.label, required this.time, required this.trailing});

  final String label;
  final DateTime time;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final base = theme.textTheme.bodyMedium?.copyWith(fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tones.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              Fmt.time(time),
              style: base?.copyWith(color: tones.neutral500, fontFeatures: AppTypography.tabular),
            ),
          ),
          AppSpacing.gapMd,
          Expanded(child: Text(label, style: base)),
          Text(trailing, style: base?.copyWith(color: tones.neutral400)),
        ],
      ),
    );
  }
}
