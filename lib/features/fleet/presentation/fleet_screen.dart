import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/enums.dart';
import '../../../domain/device_query.dart';
import '../../../domain/device_view.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../../map/presentation/widgets/tracker_map.dart';

class FleetScreen extends ConsumerStatefulWidget {
  const FleetScreen({super.key});

  @override
  ConsumerState<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends ConsumerState<FleetScreen> {
  static const pageSize = 15;

  final _search = TextEditingController();
  final _map = MapController();
  DeviceQuery _query = const DeviceQuery(sort: DeviceSort.status);
  int _visible = pageSize;
  bool _showMap = false;

  @override
  void dispose() {
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  void _setQuery(DeviceQuery q) => setState(() {
        _query = q;
        _visible = pageSize;
      });

  @override
  Widget build(BuildContext context) {
    final views = ref.watch(deviceViewsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet'),
        actions: [
          IconButton(
            tooltip: 'Drivers',
            onPressed: () => context.push(Routes.drivers),
            icon: const Icon(AppIcons.driver),
          ),
          IconButton(
            tooltip: _showMap ? 'List view' : 'Map view',
            onPressed: () => setState(() => _showMap = !_showMap),
            icon: Icon(_showMap ? AppIcons.devices : AppIcons.map),
          ),
        ],
      ),
      body: AsyncView<List<DeviceView>>(
        value: views,
        onRetry: () => ref.invalidate(devicesProvider),
        loading: const SkeletonList(message: 'Loading fleet...'),
        data: (all) {
          final vehicles = all.where((v) => v.type.isVehicle || v.type == AssetType.equipment).toList();
          final counts = DashboardCounts.of(vehicles);
          final list = _query.apply(vehicles);
          return ResponsiveCenter(
            maxWidth: 1000,
            child: Column(
              children: [
                Padding(
                  padding: AppSpacing.screen,
                  child: _Overview(counts: counts, onFilter: (f) => _setQuery(_query.copyWith(status: f))),
                ),
                AppSpacing.gapMd,
                Padding(
                  padding: AppSpacing.screen,
                  child: SearchField(
                    fieldKey: const Key('fleet-search'),
                    controller: _search,
                    hint: 'Search vehicle, plate or driver',
                    onChanged: (t) => _setQuery(_query.copyWith(text: t)),
                  ),
                ),
                AppSpacing.gapSm,
                ChipFilterBar<StatusFilter>(
                  values: StatusFilter.values,
                  selected: _query.status,
                  label: (s) => s.label,
                  onSelected: (s) => _setQuery(_query.copyWith(status: s)),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: _showMap
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                          child: ClipRRect(
                            borderRadius: AppRadius.lgAll,
                            child: TrackerMap(
                              controller: _map,
                              devices: list,
                              clustering: true,
                              onDeviceTap: (id) => context.push(Routes.device(id)),
                            ),
                          ),
                        )
                      : _PagedList(
                          list: list,
                          visible: _visible,
                          onLoadMore: () => setState(() => _visible += pageSize),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.counts, required this.onFilter});

  final DashboardCounts counts;
  final ValueChanged<StatusFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('Moving', counts.moving, AppColors.moving, StatusFilter.moving),
      ('Idle', counts.idle, AppColors.idle, StatusFilter.idle),
      ('Stopped', counts.stopped, AppColors.stationary, StatusFilter.idle),
      ('Offline', counts.offline, AppColors.offline, StatusFilter.offline),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('Fleet Overview',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
              ),
              Text('${counts.total}', style: AppTypography.metric),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Vehicles', style: theme.textTheme.bodySmall),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              for (final i in items)
                Expanded(
                  child: InkWell(
                    borderRadius: AppRadius.mdAll,
                    onTap: () => onFilter(i.$4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Column(
                        children: [
                          Text('${i.$2}', style: AppTypography.metricSmall.copyWith(color: i.$3)),
                          Text(i.$1, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PagedList extends StatelessWidget {
  const _PagedList({required this.list, required this.visible, required this.onLoadMore});

  final List<DeviceView> list;
  final int visible;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const EmptyView(icon: AppIcons.fleet, title: 'No vehicles match', message: 'Try clearing the search or filters.');
    }
    final shown = list.length < visible ? list.length : visible;
    final hasMore = shown < list.length;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (hasMore && n.metrics.extentAfter < 300) onLoadMore();
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.bottomSafe),
        itemCount: shown + 1,
        separatorBuilder: (_, _) => AppSpacing.gapMd,
        itemBuilder: (context, i) {
          if (i == shown) {
            return Center(
              child: hasMore
                  ? TextButton(onPressed: onLoadMore, child: Text('Load more (${list.length - shown} remaining)'))
                  : Text('Showing all ${list.length} vehicles', style: Theme.of(context).textTheme.bodySmall),
            );
          }
          final v = list[i];
          return DeviceCard(key: ValueKey(v.id), view: v);
        },
      ),
    );
  }
}
