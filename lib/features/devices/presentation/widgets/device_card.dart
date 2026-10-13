import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/status_style.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_widgets.dart';
import '../../../../data/models/enums.dart';
import '../../../../domain/device_view.dart';
import '../../../settings/application/settings_controller.dart';

/// Device row used across Dashboard, Devices and Fleet.
///
/// Standalone it renders as its own surface tile; with [inList] it renders as
/// a bare row (bottom divider unless [divider] is false) meant to sit inside
/// a [DeviceListGroup].
class DeviceCard extends ConsumerWidget {
  const DeviceCard({
    super.key,
    required this.view,
    this.onTap,
    this.dense = false,
    this.inList = false,
    this.divider = true,
  });

  final DeviceView view;
  final VoidCallback? onTap;
  final bool dense;
  final bool inList;
  final bool divider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final unit = ref.watch(settingsProvider.select((s) => s.unit));
    final muted = theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500);
    final s = view.status;
    final subtitle = <String>[
      if (s.isMoving) Fmt.speed(view.speedKmh, unit) else StatusStyle.label(s),
      if (view.registration != null) view.registration!,
      if (view.driver != null) view.driver!.name,
      if (view.registration == null && view.driver == null && view.position != null)
        ref.read(placeResolverProvider).shortName(view.position!),
    ].join(' · ');
    final battery = view.battery;

    final row = Row(
      children: [
        DeviceAvatar(view, size: 40),
        AppSpacing.gapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(view.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
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
                Text(
                  battery == null ? '--' : '$battery%',
                  style: muted?.copyWith(
                    color: tones.tone(StatusStyle.battery(battery)),
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
                if (view.device.location != null && s.isOnline) ...[
                  const SizedBox(width: 8),
                  SignalBars(view.device.location!.telemetry.signal),
                ],
              ],
            ),
            const SizedBox(height: 4),
            TimeAgoText(view.lastUpdate, style: muted?.copyWith(fontSize: 11), short: true),
          ],
        ),
      ],
    );

    final tap = onTap ?? () => context.push(Routes.device(view.id));
    if (inList) {
      return InkWell(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: divider ? BoxDecoration(border: Border(bottom: BorderSide(color: tones.divider))) : null,
          child: row,
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 10 : 12),
      onTap: tap,
      child: row,
    );
  }
}

/// One surface tile holding [DeviceCard] rows separated by dividers.
class DeviceListGroup extends StatelessWidget {
  const DeviceListGroup({super.key, required this.views, this.onTap});

  final List<DeviceView> views;
  final void Function(DeviceView view)? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < views.length; i++)
            DeviceCard(
              key: ValueKey(views[i].id),
              view: views[i],
              inList: true,
              divider: i < views.length - 1,
              onTap: onTap == null ? null : () => onTap!(views[i]),
            ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling filter chips: pill outline (accent when selected),
/// optional status dot, count in a muted tone.
class ChipFilterBar<T> extends StatelessWidget {
  const ChipFilterBar({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.counts,
    this.dot,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final Map<T, int>? counts;

  /// Optional status-dot color per value (null = no dot).
  final Color? Function(T)? dot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.colorScheme.onSurface);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final v = values[i];
          final count = counts?[v];
          final isSelected = v == selected;
          final dotColor = dot?.call(v);
          return Center(
            child: ChoiceChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              backgroundColor: AppColors.transparent,
              selectedColor: AppColors.transparent,
              side: BorderSide(color: isSelected ? theme.colorScheme.primary : tones.divider),
              labelStyle: labelStyle,
              avatar: dotColor == null
                  ? null
                  : Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: tones.tone(dotColor), shape: BoxShape.circle),
                    ),
              label: count == null
                  ? Text(label(v))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label(v)),
                        const SizedBox(width: 6),
                        Text('$count', style: labelStyle?.copyWith(color: tones.neutral500)),
                      ],
                    ),
              selected: isSelected,
              onSelected: (_) => onSelected(v),
            ),
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
        prefixIcon: Icon(AppIcons.search, size: 20, color: context.tones.neutral500),
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
