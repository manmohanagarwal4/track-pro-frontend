import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/device_view.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../application/drivers_controller.dart';
import 'assign_vehicle_sheet.dart';
import 'driver_editor_sheet.dart';
import 'drivers_screen.dart';

class DriverDetailScreen extends ConsumerWidget {
  const DriverDetailScreen({super.key, required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final drivers = ref.watch(driversProvider);
    final views = ref.watch(allDeviceViewsProvider).value ?? const <DeviceView>[];
    final driver = drivers.value?.where((d) => d.id == driverId).firstOrNull;
    if (driver == null) {
      return Scaffold(
        appBar: AppBar(),
        body: drivers.isLoading
            ? const LoadingView()
            : drivers.hasError
                ? ErrorView(message: 'Unable to load drivers.', onRetry: () => ref.invalidate(driversProvider))
                : const EmptyView(icon: AppIcons.users, title: 'Driver not found', message: ''),
      );
    }
    final status = driverStatus(driver, views);
    final color = driverStatusColor(status);
    final vehicle = views.where((v) => v.asset?.id == driver.assetId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
        actions: [
          IconButton(
            tooltip: 'Edit driver',
            onPressed: () => showDriverEditor(context, driver: driver),
            icon: const Icon(AppIcons.edit),
          ),
          IconButton(
            key: const Key('driver-detail-delete'),
            tooltip: 'Delete driver',
            onPressed: () async {
              final router = GoRouter.of(context);
              final deleted = await confirmDeleteDriver(context, ref, driver, vehicleName: vehicle?.name);
              if (deleted) router.pop();
            },
            icon: Icon(AppIcons.delete, color: theme.colorScheme.error),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          ResponsiveCenter(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(driver.initials, style: theme.textTheme.headlineSmall?.copyWith(color: color)),
                        ),
                        AppSpacing.gapMd,
                        Text(driver.name, style: theme.textTheme.titleLarge),
                        AppSpacing.gapXs,
                        Pill(label: status.label, color: color),
                        AppSpacing.gapLg,
                        Row(
                          children: [
                            Expanded(child: _Stat(label: 'Trips', value: '${driver.tripsCount}')),
                            Expanded(child: _Stat(label: 'Rating', value: '${driver.rating.toStringAsFixed(1)} ★')),
                            Expanded(child: _Stat(label: 'Since', value: '${driver.joinedAt.year}')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(leading: const Icon(AppIcons.phone), title: const Text('Phone'), subtitle: Text(driver.phone)),
                        ListTile(
                            leading: const Icon(AppIcons.driver), title: const Text('Licence'), subtitle: Text(driver.licenseNo)),
                        ListTile(
                            leading: const Icon(AppIcons.calendar),
                            title: const Text('Joined'),
                            subtitle: Text(Fmt.date(driver.joinedAt))),
                      ],
                    ),
                  ),
                  const SectionHeader('Assigned vehicle', padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm)),
                  if (vehicle != null) DeviceCard(view: vehicle) else const AppCard(child: Text('No vehicle assigned')),
                  AppSpacing.gapMd,
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('driver-assign'),
                          onPressed: () => showAssignVehicleSheet(context, driver),
                          icon: const Icon(AppIcons.fleet, size: 18),
                          label: Text(vehicle == null ? 'Assign Vehicle' : 'Change Vehicle'),
                        ),
                      ),
                      if (vehicle != null) ...[
                        AppSpacing.gapMd,
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ref.read(driversProvider.notifier).unassign(driver.id),
                            child: const Text('Unassign'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (vehicle != null) ...[
                    AppSpacing.gapMd,
                    OutlinedButton.icon(
                      onPressed: () => context.push(Routes.deviceTrips(vehicle.id)),
                      icon: const Icon(AppIcons.trips, size: 18),
                      label: const Text('Trip history'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
