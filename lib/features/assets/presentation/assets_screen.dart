import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/asset.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/tracker_device.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../../drivers/application/drivers_controller.dart';
import '../application/assets_controller.dart';
import 'asset_editor_sheet.dart';

/// Assets (the things tracked) are managed separately from trackers (devices).
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  String _text = '';
  AssetFilter _filter = AssetFilter.all;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final assets = ref.watch(assetsProvider);
    final devices = ref.watch(devicesProvider).value ?? const <String, TrackerDevice>{};
    final trackerByAsset = {
      for (final d in devices.values)
        if (d.assetId != null) d.assetId!: d,
    };
    final unassignedTrackers = devices.values.where((d) => d.assetId == null).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Assets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAssetEditor(context),
        icon: const Icon(AppIcons.add),
        label: const Text('New asset'),
      ),
      body: AsyncView<List<Asset>>(
        value: assets,
        onRetry: () => ref.invalidate(assetsProvider),
        loading: const SkeletonList(message: 'Loading assets...'),
        data: (all) {
          final q = _text.trim().toLowerCase();
          final list = all
              .where((a) =>
                  (_filter == AssetFilter.all || a.type.filterGroup == _filter) &&
                  (q.isEmpty || a.name.toLowerCase().contains(q) || (a.registration ?? '').toLowerCase().contains(q)))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return ResponsiveCenter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: SearchField(hint: 'Search assets or plates', onChanged: (t) => setState(() => _text = t)),
                ),
                DotFilterBar<AssetFilter>(
                  values: AssetFilter.values,
                  selected: _filter,
                  label: (f) => f.label,
                  count: (f) => f == AssetFilter.all ? all.length : all.where((a) => a.type.filterGroup == f).length,
                  onSelected: (f) => setState(() => _filter = f),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.bottomSafe),
                    children: [
                      if (unassignedTrackers.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
                          decoration: BoxDecoration(color: tones.warnBg, borderRadius: AppRadius.mdAll),
                          child: Row(
                            children: [
                              Icon(AppIcons.tracker, size: 18, color: tones.warn),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${unassignedTrackers.length} tracker${unassignedTrackers.length == 1 ? ' is' : 's are'} '
                                  'not assigned to an asset: ${unassignedTrackers.map((d) => d.id).join(', ')}',
                                  style: TextStyle(fontSize: 13, color: tones.warnInk),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push(Routes.device(unassignedTrackers.first.id)),
                                style: TextButton.styleFrom(foregroundColor: tones.warnInk),
                                child: const Text('Assign'),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapSm,
                      ],
                      SizedBox(
                        height: 32,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${list.length} assets', style: TextStyle(fontSize: 12, color: tones.neutral500)),
                        ),
                      ),
                      if (list.isEmpty)
                        const EmptyView(icon: AppIcons.assets, title: 'No assets', message: 'Create an asset to attach a tracker to it.')
                      else
                        GroupedTile(
                          children: [
                            for (final a in list) _AssetCard(asset: a, tracker: trackerByAsset[a.id]),
                          ],
                        ),
                    ],
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

/// Quiet rounded tile with the asset-type icon.
class AssetTypeIcon extends StatelessWidget {
  const AssetTypeIcon(this.type, {super.key, this.size = 40});

  final AssetType type;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: context.tones.neutral800, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(AppIcons.asset(type), size: size * 0.5, color: Theme.of(context).colorScheme.onSurface),
      );
}

class _AssetCard extends ConsumerWidget {
  const _AssetCard({required this.asset, this.tracker});

  final Asset asset;
  final TrackerDevice? tracker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;
    return InkWell(
      onTap: tracker == null ? () => showAssetEditor(context, asset: asset) : () => context.push(Routes.device(tracker!.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 11, 0, 11),
        child: Row(
          children: [
            AssetTypeIcon(asset.type),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  Text([asset.type.label, ?asset.registration].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tones.neutral500)),
                  const SizedBox(height: 5),
                  tracker == null
                      ? const Pill(label: 'No tracker', color: AppColors.offline)
                      : Pill(label: 'Device: ${tracker!.id}', color: AppColors.moving, icon: AppIcons.tracker),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(AppIcons.more, size: 18, color: tones.neutral400),
              onSelected: (v) async {
                switch (v) {
                  case 'edit':
                    await showAssetEditor(context, asset: asset);
                  case 'unassign':
                    await ref.read(devicesProvider.notifier).assignAsset(tracker!.id, null);
                  case 'delete':
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete ${asset.name}?'),
                        content: Text(tracker == null
                            ? 'This asset will be removed.'
                            : 'Tracker ${tracker!.id} will become unassigned but keep reporting.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: ctx.tones.crit),
                              foregroundColor: ctx.tones.critInk,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(assetsProvider.notifier).delete(asset.id);
                      ref.read(devicesProvider.notifier).detachAssetLocal(asset.id);
                      ref.read(driversProvider.notifier).detachAssetLocal(asset.id);
                    }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (tracker != null) const PopupMenuItem(value: 'unassign', child: Text('Unassign tracker')),
                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: tones.crit))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
