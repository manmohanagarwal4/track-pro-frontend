import 'dart:async';
import 'package:clock/clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text('${view?.name ?? 'Device'} · History')),
      body: Column(
        children: [
          DateRangeSelector(
            preset: _preset,
            custom: _custom,
            onChanged: (p, c) => setState(() {
              _preset = p;
              _custom = c;
              _query = _buildQuery();
            }),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: AsyncView<LocationHistory>(
              value: history,
              onRetry: () => ref.invalidate(historyProvider(_query)),
              loadingMessage: 'Loading route history...',
              data: (h) => h.isEmpty
                  ? EmptyView(
                      icon: AppIcons.route,
                      title: 'No movement in this period',
                      message: view != null && !view.type.isVehicle && view.status.isResting
                          ? 'This tracker stayed in one place.'
                          : 'Try a different date range.',
                    )
                  : _HistoryBody(key: ValueKey(_query), history: h),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBody extends ConsumerStatefulWidget {
  const _HistoryBody({super.key, required this.history});

  final LocationHistory history;

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
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final points = [for (final p in _pts) p.position];
    final current = _pts[_index.round()];
    final stats = widget.history.stats;
    final view = ref.watch(deviceViewProvider(widget.history.deviceId));
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        ResponsiveCenter(
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.lgAll,
                  child: SizedBox(
                    height: 320,
                    child: TrackerMap(
                      controller: _controller,
                      showUserLocation: false,
                      initialFit: CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(36)),
                      layersBelowDevices: [
                        RouteLayers(points: points),
                        if (view != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: current.position,
                              width: DeviceMarkerIcon.size,
                              height: DeviceMarkerIcon.size,
                              child: DeviceMarkerIcon(view: view, heading: 0),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapMd,
                AppCard(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            key: const Key('history-play'),
                            onPressed: _togglePlay,
                            icon: Icon(_timer == null ? AppIcons.play : AppIcons.pause, size: 18),
                          ),
                          Expanded(
                            child: Slider(
                              value: _index,
                              max: (_pts.length - 1).toDouble(),
                              onChanged: (v) => setState(() => _index = v),
                            ),
                          ),
                          PopupMenuButton<int>(
                            tooltip: 'Playback speed',
                            initialValue: _speed,
                            onSelected: (v) => setState(() => _speed = v),
                            itemBuilder: (_) => [
                              for (final s in [4, 8, 16, 32]) PopupMenuItem(value: s, child: Text('${s}x')),
                            ],
                            child: Text('${_speed}x', style: theme.textTheme.labelLarge),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: Row(
                          children: [
                            Text(Fmt.dateTime(current.timestamp), style: theme.textTheme.bodySmall),
                            const Spacer(),
                            Text(Fmt.speed(current.speedKmh, unit), style: theme.textTheme.labelLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapMd,
                AppCard(
                  child: Row(
                    children: [
                      Expanded(child: _Endpoint(label: 'Start', time: _pts.first.timestamp, start: true)),
                      Expanded(child: _Endpoint(label: 'End', time: _pts.last.timestamp, start: false)),
                    ],
                  ),
                ),
                AppSpacing.gapMd,
                StatsGrid(items: tripStatTiles(stats, ref)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.label, required this.time, required this.start});

  final String label;
  final DateTime time;
  final bool start;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(start ? AppIcons.play : AppIcons.flag, size: 16, color: theme.colorScheme.primary),
        AppSpacing.gapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(Fmt.dayLabel(time), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
              Text(Fmt.time(time), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}
