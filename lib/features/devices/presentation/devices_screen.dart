import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/enums.dart';
import '../../../domain/device_query.dart';
import '../../../domain/device_status_engine.dart';
import '../../../domain/device_view.dart';
import '../application/devices_controller.dart';
import 'widgets/device_card.dart';

final deviceQueryProvider = NotifierProvider<DeviceQueryController, DeviceQuery>(DeviceQueryController.new);

class DeviceQueryController extends Notifier<DeviceQuery> {
  @override
  DeviceQuery build() => const DeviceQuery();

  void set(DeviceQuery q) => state = q;
}

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  late final _search = TextEditingController(text: ref.read(deviceQueryProvider).text);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _sortSheet(DeviceQuery q) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Align(alignment: Alignment.centerLeft, child: Text('Sort by')),
            ),
            RadioGroup<DeviceSort>(
              groupValue: q.sort,
              onChanged: (v) {
                if (v != null) ref.read(deviceQueryProvider.notifier).set(q.copyWith(sort: v));
                Navigator.pop(ctx);
              },
              child: Column(
                children: [
                  for (final s in DeviceSort.values) RadioListTile<DeviceSort>(value: s, title: Text(s.label)),
                ],
              ),
            ),
            AppSpacing.gapMd,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(deviceQueryProvider);
    final views = ref.watch(deviceViewsProvider);
    final setQ = ref.read(deviceQueryProvider.notifier).set;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            tooltip: 'Sort',
            onPressed: () => _sortSheet(q),
            icon: const Icon(AppIcons.sort),
          ),
          IconButton(
            tooltip: 'Add tracker',
            onPressed: () => context.push(Routes.addDevice),
            icon: const Icon(AppIcons.add),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: SearchField(
                fieldKey: const Key('device-search'),
                controller: _search,
                hint: 'Search name, ID, plate, driver...',
                onChanged: (t) => setQ(q.copyWith(text: t)),
              ),
            ),
            ChipFilterBar<StatusFilter>(
              values: StatusFilter.values,
              selected: q.status,
              label: (s) => s.label,
              onSelected: (s) => setQ(q.copyWith(status: s)),
              counts: views.hasValue
                  ? {
                      for (final f in StatusFilter.values)
                        f: views.requireValue
                            .where((v) => DeviceStatusEngine.matchesFilter(v.status, f))
                            .length,
                    }
                  : null,
            ),
            AppSpacing.gapSm,
            ChipFilterBar<AssetFilter>(
              values: AssetFilter.values,
              selected: q.asset,
              label: (s) => s.label,
              onSelected: (s) => setQ(q.copyWith(asset: s)),
            ),
            AppSpacing.gapSm,
            Expanded(
              child: AsyncView<List<DeviceView>>(
                value: views,
                onRetry: () => ref.invalidate(devicesProvider),
                loading: const SkeletonList(message: 'Loading devices...'),
                data: (all) => _DeviceList(all: all, query: q, onClear: () {
                  _search.clear();
                  setQ(DeviceQuery(sort: q.sort));
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-device',
        onPressed: () => context.push(Routes.addDevice),
        icon: const Icon(AppIcons.add),
        label: const Text('Add tracker'),
      ),
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.all, required this.query, required this.onClear});

  final List<DeviceView> all;
  final DeviceQuery query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return EmptyView(
        icon: AppIcons.devices,
        title: 'No devices found.',
        message: 'Add your first tracker to start tracking.',
        actionLabel: 'Add Tracker',
        onAction: () => context.push(Routes.addDevice),
      );
    }
    final list = query.apply(all);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyView(
              icon: AppIcons.search,
              title: 'No matching devices',
              message: 'Try a different search or clear the filters.',
            ),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.bottomSafe),
      itemCount: list.length + 1,
      separatorBuilder: (_, _) => AppSpacing.gapMd,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Text(
            '${list.length} of ${all.length} devices · sorted by ${query.sort.label.toLowerCase()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          );
        }
        final v = list[i - 1];
        return DeviceCard(key: ValueKey(v.id), view: v);
      },
    );
  }
}
