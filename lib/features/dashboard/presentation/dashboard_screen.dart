import 'package:clock/clock.dart';
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
import '../../../data/models/enums.dart';
import '../../../domain/device_query.dart';
import '../../../domain/device_view.dart';
import '../../alerts/application/alerts_controller.dart';
import '../../auth/application/session_controller.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/devices_screen.dart';
import '../../devices/presentation/widgets/device_card.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(deviceViewsProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(devicesProvider);
            await ref.read(devicesProvider.future).catchError((_) => <String, Never>{});
          },
          child: AsyncView<List<DeviceView>>(
            value: views,
            onRetry: () => ref.invalidate(devicesProvider),
            loading: const _DashboardLoading(),
            data: (list) => _DashboardBody(views: list),
          ),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          _Header(attention: 0),
          Expanded(child: SkeletonList(count: 4, message: 'Loading devices...')),
        ],
      );
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.views});

  final List<DeviceView> views;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = DashboardCounts.of(views);
    final unread = ref.watch(unreadAlertCountProvider);
    final business = ref.watch(accountTypeProvider) == AccountType.business;
    final active = const DeviceQuery(sort: DeviceSort.status).apply(views).take(6).toList();
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    final tiles = [
      SummaryTile(
        label: 'Total Devices',
        value: counts.total,
        icon: AppIcons.devices,
        color: AppColors.iris,
        onTap: () => _openDevices(context, ref, StatusFilter.all),
      ),
      SummaryTile(
        label: 'Online',
        value: counts.online,
        icon: AppIcons.online,
        color: AppColors.stationary,
        onTap: () => _openDevices(context, ref, StatusFilter.online),
      ),
      SummaryTile(
        label: 'Moving',
        value: counts.moving,
        icon: AppIcons.navigation,
        color: AppColors.moving,
        onTap: () => _openDevices(context, ref, StatusFilter.moving),
      ),
      SummaryTile(
        label: 'Alerts',
        value: unread,
        icon: AppIcons.alerts,
        color: AppColors.emergency,
        onTap: () => context.go(Routes.alerts),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
      children: [
        ResponsiveCenter(
          maxWidth: 1100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(attention: counts.attention),
              Padding(
                padding: AppSpacing.screen,
                child: GridView.count(
                  crossAxisCount: wide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: wide ? 2.6 : 2.1,
                  children: tiles,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: LiveSimulationToggle(),
              ),
              SectionHeader(
                'LIVE TRACKING MAP',
                action: 'Full screen',
                onAction: () => context.go(Routes.map),
              ),
              Padding(padding: AppSpacing.screen, child: LiveMapCard(devices: views)),
              if (business) ...[
                AppSpacing.gapMd,
                Padding(padding: AppSpacing.screen, child: FleetDistributionBar(counts: counts)),
              ],
              const SectionHeader('Quick actions'),
              Padding(
                padding: AppSpacing.screen,
                child: Row(
                  children: [
                    Expanded(
                      child: QuickAction(
                          icon: AppIcons.add, label: 'Add tracker', onTap: () => context.push(Routes.addDevice)),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: QuickAction(
                          icon: AppIcons.geofence,
                          label: 'Geofences',
                          color: AppColors.signal,
                          onTap: () => context.push(Routes.geofences)),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: business
                          ? QuickAction(
                              icon: AppIcons.driver,
                              label: 'Drivers',
                              color: AppColors.warning,
                              onTap: () => context.push(Routes.drivers))
                          : QuickAction(
                              icon: AppIcons.devices,
                              label: 'All devices',
                              color: AppColors.warning,
                              onTap: () => context.go(Routes.devices)),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: QuickAction(
                          icon: AppIcons.assets,
                          label: 'Assets',
                          color: AppColors.stationary,
                          onTap: () => context.push(Routes.assets)),
                    ),
                  ],
                ),
              ),
              SectionHeader(
                'Active Devices',
                action: 'View all',
                onAction: () => context.go(business ? Routes.fleet : Routes.devices),
              ),
              if (active.isEmpty)
                EmptyView(
                  icon: AppIcons.devices,
                  title: 'No devices found.',
                  message: 'Add your first tracker to start tracking.',
                  actionLabel: 'Add Tracker',
                  onAction: () => context.push(Routes.addDevice),
                )
              else
                Padding(
                  padding: AppSpacing.screen,
                  child: Column(
                    children: [
                      for (final v in active)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: DeviceCard(key: ValueKey(v.id), view: v),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDevices(BuildContext context, WidgetRef ref, StatusFilter f) {
    ref.read(deviceQueryProvider.notifier).set(DeviceQuery(status: f));
    context.go(Routes.devices);
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.attention});

  final int attention;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(sessionProvider).value;
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
    final ok = attention == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Fmt.greeting(clock.now())}, ${user?.firstName ?? ''}',
                  style: theme.textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(ok ? AppIcons.success : AppIcons.warning,
                        size: 15, color: ok ? AppColors.moving : AppColors.warning),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ok
                            ? 'All systems operational'
                            : '$attention device${attention == 1 ? '' : 's'} need${attention == 1 ? 's' : ''} attention',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push(Routes.notifications),
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              child: const Icon(AppIcons.bellRing),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(Routes.profile),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: theme.colorScheme.primary,
              child: Text(user?.initials ?? '',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
            ),
          ),
          AppSpacing.gapSm,
        ],
      ),
    );
  }
}
