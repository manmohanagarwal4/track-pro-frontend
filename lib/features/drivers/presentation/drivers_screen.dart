import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/driver.dart';
import '../../../data/models/enums.dart';
import '../../../domain/device_view.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../application/drivers_controller.dart';
import 'assign_vehicle_sheet.dart';
import 'driver_editor_sheet.dart';

/// Driver status derived from the assigned vehicle's live status.
DriverStatus driverStatus(Driver d, List<DeviceView> views) {
  if (d.assetId == null) return DriverStatus.offDuty;
  final v = views.where((v) => v.asset?.id == d.assetId).firstOrNull;
  return v != null && v.status.isMoving ? DriverStatus.driving : DriverStatus.onDuty;
}

Color driverStatusColor(DriverStatus s) => switch (s) {
      DriverStatus.driving => AppColors.moving,
      DriverStatus.onDuty => AppColors.stationary,
      DriverStatus.offDuty => AppColors.offline,
    };

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  String _text = '';
  DriverStatus? _status;

  Future<void> _addDriver(BuildContext context) async {
    final driver = await showDriverEditor(context);
    if (driver == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${driver.name} added'),
      action: SnackBarAction(label: 'Assign vehicle', onPressed: () => showAssignVehicleSheet(context, driver)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driversProvider);
    final views = ref.watch(allDeviceViewsProvider).value ?? const <DeviceView>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-driver'),
        onPressed: () => _addDriver(context),
        icon: const Icon(AppIcons.add),
        label: const Text('Add driver'),
      ),
      body: AsyncView<List<Driver>>(
        value: drivers,
        onRetry: () => ref.invalidate(driversProvider),
        loading: const SkeletonList(message: 'Loading drivers...'),
        data: (all) {
          final q = _text.trim().toLowerCase();
          final list = all.where((d) {
            final st = driverStatus(d, views);
            if (_status != null && st != _status) return false;
            if (q.isEmpty) return true;
            final vehicle = views.where((v) => v.asset?.id == d.assetId).firstOrNull?.name ?? '';
            return d.name.toLowerCase().contains(q) || vehicle.toLowerCase().contains(q) || d.phone.contains(q);
          }).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return ResponsiveCenter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: SearchField(hint: 'Search driver or vehicle', onChanged: (t) => setState(() => _text = t)),
                ),
                ChipFilterBar<DriverStatus?>(
                  values: const [null, ...DriverStatus.values],
                  selected: _status,
                  label: (s) => s?.label ?? 'All',
                  onSelected: (s) => setState(() => _status = s),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: all.isEmpty
                      ? EmptyView(
                          icon: AppIcons.users,
                          title: 'No drivers yet',
                          message: 'Add your drivers to assign them to vehicles.',
                          actionLabel: 'Add driver',
                          onAction: () => _addDriver(context),
                        )
                      : list.isEmpty
                      ? const EmptyView(icon: AppIcons.users, title: 'No drivers found', message: 'Try a different search.')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => AppSpacing.gapMd,
                          itemBuilder: (_, i) => DriverCard(driver: list[i], views: views),
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

class DriverCard extends ConsumerWidget {
  const DriverCard({super.key, required this.driver, required this.views});

  final Driver driver;
  final List<DeviceView> views;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = driverStatus(driver, views);
    final color = driverStatusColor(status);
    final vehicle = views.where((v) => v.asset?.id == driver.assetId).firstOrNull;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return AppCard(
      onTap: () => context.push(Routes.driver(driver.id)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(driver.initials, style: theme.textTheme.labelLarge?.copyWith(color: color)),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(driver.name, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Pill(label: status.label, color: color),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Vehicle: ${vehicle?.name ?? 'Unassigned'} · Trips: ${driver.tripsCount}',
                  style: muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(driver.phone, style: muted),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'view') context.push(Routes.driver(driver.id));
              if (v == 'assign') await showAssignVehicleSheet(context, driver);
              if (v == 'unassign') await ref.read(driversProvider.notifier).unassign(driver.id);
              if (v == 'edit' && context.mounted) await showDriverEditor(context, driver: driver);
              if (v == 'delete' && context.mounted) {
                await confirmDeleteDriver(context, ref, driver, vehicleName: vehicle?.name);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('View')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'assign', child: Text(driver.assetId == null ? 'Assign Vehicle' : 'Change Vehicle')),
              if (driver.assetId != null) const PopupMenuItem(value: 'unassign', child: Text('Unassign')),
              PopupMenuItem(
                key: Key('driver-delete-${driver.id}'),
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
