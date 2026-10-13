import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/enums.dart';
import '../../alerts/application/alerts_controller.dart';
import '../../auth/application/session_controller.dart';
import '../../tracking/application/connectivity_controller.dart';
import 'settings_widgets.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final user = ref.watch(sessionProvider).value;
    final type = ref.watch(accountTypeProvider);
    final offline = ref.watch(connectivityProvider.select((c) => c.offline));
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
    final business = type == AccountType.business;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.bottomSafe),
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: AppSpacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('More', style: theme.textTheme.headlineMedium),
                    AppSpacing.gapLg,
                    InkWell(
                      borderRadius: AppRadius.lgAll,
                      onTap: () => context.push(Routes.profile),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: tones.accent800, shape: BoxShape.circle),
                            child: Text(
                              user?.initials ?? '',
                              style: theme.textTheme.titleLarge?.copyWith(fontSize: 21, color: tones.accent200),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.name ?? '', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
                                Text(user?.email ?? '',
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral500)),
                              ],
                            ),
                          ),
                          Icon(AppIcons.chevronRight, size: 16, color: tones.neutral600),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const WorkspaceSwitcher(),
                    const SettingsSectionLabel('Manage'),
                    SettingsGroup(children: [
                      if (business)
                        SettingsTile(icon: AppIcons.devices, title: 'All devices', onTap: () => context.go(Routes.devices)),
                      SettingsTile(icon: AppIcons.assets, title: 'Assets', onTap: () => context.push(Routes.assets)),
                      SettingsTile(icon: AppIcons.geofence, title: 'Geofences', onTap: () => context.push(Routes.geofences)),
                      if (business)
                        SettingsTile(icon: AppIcons.driver, title: 'Drivers', onTap: () => context.push(Routes.drivers)),
                      SettingsTile(
                        icon: AppIcons.bellRing,
                        title: 'Notifications',
                        meta: unreadNotifications == 0 ? null : '$unreadNotifications new',
                        onTap: () => context.push(Routes.notifications),
                      ),
                      SettingsTile(icon: AppIcons.add, title: 'Add tracker', onTap: () => context.push(Routes.addDevice)),
                    ]),
                    const SettingsSectionLabel('App'),
                    SettingsGroup(children: [
                      SettingsTile(icon: AppIcons.settings, title: 'Settings', onTap: () => context.push(Routes.settings)),
                      SettingsTile(
                        icon: AppIcons.offline,
                        title: 'Simulate Offline Mode',
                        trailing: Switch(
                          key: const Key('offline-toggle'),
                          value: offline,
                          onChanged: (v) => ref.read(connectivityProvider.notifier).setOffline(v),
                        ),
                      ),
                      SettingsTile(
                        icon: AppIcons.info,
                        title: 'About TrackPro',
                        onTap: () => context.push(Routes.settingsSection('about')),
                      ),
                    ]),
                    AppSpacing.gapXl,
                    const DemoModeNotice(),
                    AppSpacing.gapXl,
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tones.critInk,
                        iconColor: tones.critInk,
                        side: BorderSide(color: tones.crit),
                      ),
                      onPressed: () => confirmLogout(context, ref),
                      icon: const Icon(AppIcons.logout, size: 18),
                      label: const Text('Log out'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
