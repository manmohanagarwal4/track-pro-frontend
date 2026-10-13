import 'package:flutter/material.dart';
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
import '../../../domain/device_status_engine.dart';
import '../../../domain/device_view.dart';
import '../../auth/application/session_controller.dart';
import '../application/devices_controller.dart';
import 'widgets/device_card.dart';

final deviceQueryProvider = NotifierProvider<DeviceQueryController, DeviceQuery>(DeviceQueryController.new);

class DeviceQueryController extends Notifier<DeviceQuery> {
  @override
  DeviceQuery build() => const DeviceQuery();

  void set(DeviceQuery q) => state = q;
}

Color? _statusDot(StatusFilter f) => switch (f) {
      StatusFilter.all => null,
      StatusFilter.online || StatusFilter.moving => AppColors.moving,
      StatusFilter.offline => AppColors.offline,
      StatusFilter.idle => AppColors.idle,
      StatusFilter.alert => AppColors.emergency,
    };

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
            const SectionHeader('Sort by', padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm)),
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
    final theme = Theme.of(context);
    final q = ref.watch(deviceQueryProvider);
    final views = ref.watch(deviceViewsProvider);
    final setQ = ref.read(deviceQueryProvider.notifier).set;
    final business = ref.watch(accountTypeProvider) == AccountType.business;
    final counts = views.hasValue
        ? {
            for (final f in StatusFilter.values)
              f: views.requireValue.where((v) => DeviceStatusEngine.matchesFilter(v.status, f)).length,
          }
        : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Devices', style: theme.textTheme.headlineMedium),
                    ),
                    IconButton(
                      tooltip: 'Sort',
                      onPressed: () => _sortSheet(q),
                      icon: Icon(AppIcons.sort, color: context.tones.neutral400),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Add tracker',
                      child: FilledButton.icon(
                        onPressed: () => context.push(Routes.addDevice),
                        icon: const Icon(AppIcons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: SearchField(
                  fieldKey: const Key('device-search'),
                  controller: _search,
                  hint: 'Search name, ID, plate, driver...',
                  onChanged: (t) => setQ(q.copyWith(text: t)),
                ),
              ),
              if (business && counts != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: _KpiRow(counts: counts),
                ),
              ChipFilterBar<StatusFilter>(
                values: StatusFilter.values,
                selected: q.status,
                label: (s) => s.label,
                dot: _statusDot,
                onSelected: (s) => setQ(q.copyWith(status: s)),
                counts: counts,
              ),
              const SizedBox(height: 6),
              ChipFilterBar<AssetFilter>(
                values: AssetFilter.values,
                selected: q.asset,
                label: (s) => s.label,
                onSelected: (s) => setQ(q.copyWith(asset: s)),
              ),
              const SizedBox(height: 6),
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
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.counts});

  final Map<StatusFilter, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    const shown = [StatusFilter.moving, StatusFilter.idle, StatusFilter.offline, StatusFilter.alert];
    return Row(
      children: [
        for (final f in shown) ...[
          if (f != shown.first) const SizedBox(width: 6),
          Expanded(
            child: AppCard(
              radius: AppRadius.mdAll,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${counts[f] ?? 0}',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 19, fontFeatures: AppTypography.tabular)),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: tones.tone(_statusDot(f)!), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          f.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w400, color: tones.neutral500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.all, required this.query, required this.onClear});

  final List<DeviceView> all;
  final DeviceQuery query;
  final VoidCallback onClear;

  /// Consecutive runs of devices sharing a group label (keeps sort order).
  List<(String, List<DeviceView>)> _groups(List<DeviceView> list) {
    final out = <(String, List<DeviceView>)>[];
    for (final v in list) {
      final key = query.sort == DeviceSort.status ? v.status.primary.label : 'Sorted by ${query.sort.label.toLowerCase()}';
      if (out.isNotEmpty && out.last.$1 == key) {
        out.last.$2.add(v);
      } else {
        out.add((key, [v]));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
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
    final groups = _groups(list);
    final meta = theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.bottomSafe),
      children: [
        for (final (name, items) in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(name.toUpperCase(), style: AppTypography.overline.copyWith(color: tones.neutral500)),
                ),
                Text('${items.length}', style: meta),
              ],
            ),
          ),
          DeviceListGroup(views: items),
          AppSpacing.gapMd,
        ],
        Text(
          '${list.length} of ${all.length} devices · sorted by ${query.sort.label.toLowerCase()}',
          textAlign: TextAlign.center,
          style: meta,
        ),
      ],
    );
  }
}
