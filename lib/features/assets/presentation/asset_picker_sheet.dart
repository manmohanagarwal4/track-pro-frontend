import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/asset.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../devices/application/devices_controller.dart';
import '../application/assets_controller.dart';
import 'asset_editor_sheet.dart';
import 'assets_screen.dart';

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
    final tones = context.tones;
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.sm, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Assign asset',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.4)),
                ),
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
              decoration: BoxDecoration(color: tones.accent900, borderRadius: AppRadius.mdAll),
              child: Row(
                children: [
                  Icon(AppIcons.info, size: 18, color: tones.accent300),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'A tracker is linked to one asset at a time. Moving it detaches it from its previous asset.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
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
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.xl),
                  children: [
                    GroupedTile(
                      color: AppColors.transparent,
                      inset: AppSpacing.sm,
                      children: [
                        if (currentAssetId != null)
                          InkWell(
                            onTap: () => Navigator.pop(context, const AssetPick.unassign()),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(color: tones.critBg, borderRadius: BorderRadius.circular(12)),
                                    child: Icon(AppIcons.close, size: 20, color: tones.critInk),
                                  ),
                                  AppSpacing.gapMd,
                                  Text('Unassign current asset',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: tones.crit)),
                                ],
                              ),
                            ),
                          ),
                        for (final a in sorted)
                          InkWell(
                            onTap: a.id == currentAssetId ? null : () => Navigator.pop(context, AssetPick.asset(a.id)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 11),
                              child: Row(
                                children: [
                                  AssetTypeIcon(a.type),
                                  AppSpacing.gapMd,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                        Text(
                                          [a.type.label, ?a.registration].join(' · '),
                                          style: TextStyle(fontSize: 12, color: tones.neutral500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppSpacing.gapSm,
                                  if (a.id == currentAssetId)
                                    const Pill(label: 'Current', color: AppColors.crimson)
                                  else
                                    Text(
                                      trackerByAsset[a.id] ?? 'No tracker',
                                      style: TextStyle(fontSize: 11, color: tones.neutral500),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
