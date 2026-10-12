import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/asset.dart';
import '../../devices/application/devices_controller.dart';
import '../application/assets_controller.dart';
import 'asset_editor_sheet.dart';

/// Result of [showAssetPicker]: an asset id, or [unassign].
class AssetPick {
  const AssetPick.asset(this.assetId) : unassign = false;
  const AssetPick.unassign()
      : assetId = null,
        unassign = true;

  final String? assetId;
  final bool unassign;
}

Future<AssetPick?> showAssetPicker(BuildContext context, {required String deviceId, String? currentAssetId}) {
  return showModalBottomSheet<AssetPick>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AssetPickerSheet(deviceId: deviceId, currentAssetId: currentAssetId),
  );
}

class _AssetPickerSheet extends ConsumerWidget {
  const _AssetPickerSheet({required this.deviceId, this.currentAssetId});

  final String deviceId;
  final String? currentAssetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final assets = ref.watch(assetsProvider);
    final devices = ref.watch(devicesProvider).value ?? const {};
    final trackerByAsset = {
      for (final d in devices.values)
        if (d.assetId != null) d.assetId!: d.id,
    };
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: Row(
              children: [
                Expanded(child: Text('Assign asset', style: theme.textTheme.titleLarge)),
                TextButton.icon(
                  onPressed: () async {
                    final created = await showAssetEditor(context);
                    if (created != null && context.mounted) {
                      Navigator.pop(context, AssetPick.asset(created.id));
                    }
                  },
                  icon: const Icon(AppIcons.add, size: 18),
                  label: const Text('New asset'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Text(
              'A tracker is linked to one asset at a time. Moving it detaches it from its previous asset.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: AsyncView<List<Asset>>(
              value: assets,
              onRetry: () => ref.invalidate(assetsProvider),
              data: (list) {
                final sorted = [...list]
                  ..sort((a, b) {
                    final fa = trackerByAsset.containsKey(a.id) ? 1 : 0;
                    final fb = trackerByAsset.containsKey(b.id) ? 1 : 0;
                    return fa != fb ? fa - fb : a.name.compareTo(b.name);
                  });
                return ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    if (currentAssetId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          onTap: () => Navigator.pop(context, const AssetPick.unassign()),
                          child: Row(
                            children: [
                              IconBadge(icon: AppIcons.close, color: theme.colorScheme.error),
                              AppSpacing.gapMd,
                              Text('Unassign current asset',
                                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      ),
                    for (final a in sorted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          padding: AppSpacing.cardCompact,
                          onTap: a.id == currentAssetId ? null : () => Navigator.pop(context, AssetPick.asset(a.id)),
                          border: a.id == currentAssetId ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
                          child: Row(
                            children: [
                              IconBadge(icon: AppIcons.asset(a.type), color: theme.colorScheme.primary),
                              AppSpacing.gapMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.name, style: theme.textTheme.titleSmall),
                                    Text(
                                      [a.type.label, ?a.registration].join(' · '),
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                a.id == currentAssetId
                                    ? 'Current'
                                    : trackerByAsset[a.id] == null
                                        ? 'No tracker'
                                        : trackerByAsset[a.id]!,
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
