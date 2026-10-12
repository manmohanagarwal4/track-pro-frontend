import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_widgets.dart';
import '../../../../data/models/enums.dart';
import '../../../../domain/device_view.dart';
import '../../../settings/application/settings_controller.dart';

/// Device row used across Dashboard, Devices and Fleet.
class DeviceCard extends ConsumerWidget {
  const DeviceCard({super.key, required this.view, this.onTap, this.dense = false});

  final DeviceView view;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final s = view.status;
    final subtitle = <String>[
      if (s.isMoving) Fmt.speed(view.speedKmh, unit) else s.primary.label,
      if (view.registration != null) view.registration!,
      if (view.driver != null) view.driver!.name,
      if (view.registration == null && view.driver == null && view.position != null)
        ref.read(placeResolverProvider).shortName(view.position!),
    ].join(' · ');

    return AppCard(
      padding: dense ? AppSpacing.cardCompact : AppSpacing.card,
      onTap: onTap ?? () => context.push(Routes.device(view.id)),
      child: Row(
        children: [
          DeviceAvatar(view, size: dense ? 40 : 46),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(view.name,
                          style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Flexible(child: StatusBadge(s, compact: true)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (view.device.location != null && s.isOnline) ...[
                    SignalBars(view.device.location!.telemetry.signal),
                    const SizedBox(width: 8),
                  ],
                  BatteryIndicator(view.battery),
                ],
              ),
              const SizedBox(height: 6),
              TimeAgoText(view.lastUpdate, style: muted, short: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling choice chips.
class ChipFilterBar<T> extends StatelessWidget {
  const ChipFilterBar({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.counts,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final Map<T, int>? counts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final v = values[i];
          final count = counts?[v];
          return ChoiceChip(
            label: Text(count == null ? label(v) : '${label(v)}  $count'),
            selected: v == selected,
            onSelected: (_) => onSelected(v),
          );
        },
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.onChanged, this.hint = 'Search', this.controller, this.fieldKey});

  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(AppIcons.search, size: 20),
        suffixIcon: controller == null
            ? null
            : ListenableBuilder(
                listenable: controller!,
                builder: (_, _) => controller!.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(AppIcons.close, size: 18),
                        onPressed: () {
                          controller!.clear();
                          onChanged('');
                        },
                      ),
              ),
      ),
    );
  }
}

String assetFilterLabel(AssetFilter f) => f.label;
