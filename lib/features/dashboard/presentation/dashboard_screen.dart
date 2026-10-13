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

    final tiles = [
      SummaryTile(
        label: 'Total Devices',
        value: counts.total,
        color: AppColors.iris,
        onTap: () => _openDevices(context, ref, StatusFilter.all),
      ),
      SummaryTile(
        label: 'Online',
        value: counts.online,
        color: AppColors.stationary,
        onTap: () => _openDevices(context, ref, StatusFilter.online),
      ),
      SummaryTile(
        label: 'Moving',
        value: counts.moving,
        color: AppColors.moving,
        onTap: () => _openDevices(context, ref, StatusFilter.moving),
      ),
      SummaryTile(
        label: 'Alerts',
        value: unread,
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
              Padding(padding: AppSpacing.screen, child: KpiRow(children: tiles)),
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
                    AppSpacing.gapSm,
                    Expanded(
                      child: QuickAction(
                          icon: AppIcons.geofence, label: 'Geofences', onTap: () => context.push(Routes.geofences)),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: business
                          ? QuickAction(
                              icon: AppIcons.driver, label: 'Drivers', onTap: () => context.push(Routes.drivers))
                          : QuickAction(
                              icon: AppIcons.devices, label: 'All devices', onTap: () => context.go(Routes.devices)),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: QuickAction(
                          icon: AppIcons.assets, label: 'Assets', onTap: () => context.push(Routes.assets)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
                child: GroupLabel(
                  'Active Devices',
                  uppercase: false,
                  action: 'View all',
                  onAction: () => context.go(business ? Routes.fleet : Routes.devices),
                ),
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
                  child: GroupedTile(
                    children: [
                      for (final v in active) DeviceCard(key: ValueKey(v.id), view: v, dense: true),
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
    final tones = context.tones;
    final user = ref.watch(sessionProvider).value;
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
    final ok = attention == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Fmt.greeting(clock.now())}, ${user?.firstName ?? ''}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, letterSpacing: -0.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(ok ? AppIcons.success : AppIcons.warning, size: 14, color: ok ? tones.ok : tones.warn),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ok
                            ? 'All systems operational'
                            : '$attention device${attention == 1 ? '' : 's'} need${attention == 1 ? 's' : ''} attention',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: tones.neutral500),
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
              child: const Icon(AppIcons.bellRing, size: 22),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(Routes.profile),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: tones.accent800,
              child: Text(user?.initials ?? '',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tones.accent200)),
            ),
          ),
          AppSpacing.gapSm,
        ],
      ),
    );
  }
}
