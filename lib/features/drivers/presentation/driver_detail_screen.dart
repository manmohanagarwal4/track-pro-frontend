import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/device_view.dart';
import '../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../../trips/presentation/widgets/trip_widgets.dart';
import '../application/drivers_controller.dart';
import 'assign_vehicle_sheet.dart';
import 'driver_editor_sheet.dart';
import 'drivers_screen.dart';

class DriverDetailScreen extends ConsumerWidget {
  const DriverDetailScreen({super.key, required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = context.tones;
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
        actions: [
          IconButton(
            tooltip: 'Edit driver',
            onPressed: () => showDriverEditor(context, driver: driver),
            icon: const Icon(AppIcons.edit, size: 20),
          ),
          IconButton(
            key: const Key('driver-detail-delete'),
            tooltip: 'Delete driver',
            onPressed: () async {
              final router = GoRouter.of(context);
              final deleted = await confirmDeleteDriver(context, ref, driver, vehicleName: vehicle?.name);
              if (deleted) router.pop();
            },
            icon: Icon(AppIcons.delete, size: 20, color: tones.crit),
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
                  AppSpacing.gapXs,
                  Row(
                    children: [
                      DriverInitials(driver.initials, size: 52),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            Text(driver.phone,
                                style: TextStyle(fontSize: 12, color: tones.neutral500)),
                          ],
                        ),
                      ),
                      Pill(label: status.label, color: color),
                    ],
                  ),
                  AppSpacing.gapLg,
                  StatsGrid(
                    items: [
                      StatTile('Trips', '${driver.tripsCount}', AppIcons.trips),
                      StatTile('Rating', '${driver.rating.toStringAsFixed(1)} ★', AppIcons.star),
                      StatTile('Since', '${driver.joinedAt.year}', AppIcons.calendar),
                    ],
                  ),
                  AppSpacing.gapMd,
                  GroupedTile(
                    inset: 14,
                    children: [
                      FactRow(icon: AppIcons.phone, label: 'Phone', value: driver.phone),
                      FactRow(icon: AppIcons.driver, label: 'Licence', value: driver.licenseNo),
                      FactRow(icon: AppIcons.calendar, label: 'Joined', value: Fmt.date(driver.joinedAt)),
                    ],
                  ),
                  const SectionHeader('Assigned vehicle', padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm)),
                  if (vehicle != null)
                    DeviceCard(view: vehicle, dense: true)
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
                      child: Text('No vehicle assigned', style: TextStyle(fontSize: 13, color: tones.neutral500)),
                    ),
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
                        AppSpacing.gapSm,
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
                    AppSpacing.gapSm,
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
