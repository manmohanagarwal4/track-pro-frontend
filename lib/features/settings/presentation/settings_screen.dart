import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/trackpro_logo.dart';
import '../../../data/models/enums.dart';
import '../../alerts/application/alerts_controller.dart';
import '../../assets/application/assets_controller.dart';
import '../../auth/application/session_controller.dart';
import '../../devices/application/devices_controller.dart';
import '../../drivers/application/drivers_controller.dart';
import '../../geofences/application/geofences_controller.dart';
import '../../tracking/application/connectivity_controller.dart';
import '../application/settings_controller.dart';
import 'settings_widgets.dart';

class _Section {
  const _Section(this.id, this.title, this.icon, this.subtitle);

  final String id;
  final String title;
  final IconData icon;
  final String subtitle;
}

const _sections = [
  _Section('account', 'Account', AppIcons.user, 'Profile and workspace'),
  _Section('notifications', 'Notifications', AppIcons.bellRing, 'Alert types and banners'),
  _Section('map', 'Map Settings', AppIcons.map, 'Layers, clustering, labels'),
  _Section('tracking', 'Tracking Settings', AppIcons.navigation, 'Live simulation and speed'),
  _Section('units', 'Units', AppIcons.ruler, 'Kilometers or miles'),
  _Section('appearance', 'Appearance', AppIcons.sun, 'Light, dark or system'),
  _Section('security', 'Security', AppIcons.lock, 'Password, 2FA, sessions'),
  _Section('privacy', 'Privacy', AppIcons.shield, 'History retention, analytics'),
  _Section('demo', 'Demo & Developer', AppIcons.flask, 'Offline mode, errors, reset'),
  _Section('about', 'About', AppIcons.info, 'Version and demo mode'),
];

const _groups = [
  ('Account', {'account', 'notifications'}),
  ('Preferences', {'map', 'tracking', 'units', 'appearance'}),
  ('Privacy & security', {'security', 'privacy'}),
  ('Demo', {'demo', 'about'}),
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.huge),
        children: [
          ResponsiveCenter(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, g) in _groups.indexed) ...[
                    SettingsSectionLabel(g.$1, first: i == 0),
                    SettingsGroup(children: [
                      for (final s in _sections.where((s) => g.$2.contains(s.id)))
                        SettingsTile(
                          key: Key('settings-${s.id}'),
                          icon: s.icon,
                          title: s.title,
                          subtitle: s.subtitle,
                          onTap: () => context.push(Routes.settingsSection(s.id)),
                        ),
                    ]),
                  ],
                  AppSpacing.gapXl,
                  const DemoModeNotice(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSectionScreen extends ConsumerWidget {
  const SettingsSectionScreen({super.key, required this.section});

  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = _sections.where((s) => s.id == section).firstOrNull;
    final s = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;

    final Widget body = switch (section) {
      'account' => _account(context, ref),
      'notifications' => SettingsGroup(children: [
          SwitchListTile(
            secondary: const Icon(AppIcons.bellRing),
            title: const Text('In-app alert banners'),
            subtitle: const Text('Show a banner when an alert fires'),
            value: s.inAppBanners,
            onChanged: (v) => update((x) => x.copyWith(inAppBanners: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.overspeed),
            title: const Text('Overspeed'),
            value: s.pushOverspeed,
            onChanged: (v) => update((x) => x.copyWith(pushOverspeed: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.geofence),
            title: const Text('Geofence enter / exit'),
            value: s.pushGeofence,
            onChanged: (v) => update((x) => x.copyWith(pushGeofence: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.batteryLow),
            title: const Text('Low battery'),
            value: s.pushBattery,
            onChanged: (v) => update((x) => x.copyWith(pushBattery: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.offline),
            title: const Text('Device offline'),
            value: s.pushOffline,
            onChanged: (v) => update((x) => x.copyWith(pushOffline: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.trips),
            title: const Text('Trip summaries'),
            value: s.pushTrips,
            onChanged: (v) => update((x) => x.copyWith(pushTrips: v)),
          ),
        ]),
      'map' => SettingsGroup(children: [
          ListTile(
            leading: const Icon(AppIcons.map),
            title: const Text('Map provider'),
            subtitle: Text(ref.watch(mapServiceProvider).name),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.devices),
            title: const Text('Cluster nearby devices'),
            value: s.clustering,
            onChanged: (v) => update((x) => x.copyWith(clustering: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.route),
            title: const Text('Show live trails'),
            value: s.showTrails,
            onChanged: (v) => update((x) => x.copyWith(showTrails: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.geofence),
            title: const Text('Show geofences'),
            value: s.showGeofences,
            onChanged: (v) => update((x) => x.copyWith(showGeofences: v)),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.pin),
            title: const Text('Show place labels'),
            value: s.showMapLabels,
            onChanged: (v) => update((x) => x.copyWith(showMapLabels: v)),
          ),
        ]),
      'tracking' => _tracking(context, ref),
      'units' => SettingsGroup(children: [
          RadioGroup<DistanceUnit>(
            groupValue: s.unit,
            onChanged: (v) => update((x) => x.copyWith(unit: v)),
            child: Column(
              children: [
                for (final u in DistanceUnit.values)
                  RadioListTile<DistanceUnit>(value: u, title: Text(u.label), subtitle: Text('Speed in ${u.speed}')),
              ],
            ),
          ),
        ]),
      'appearance' => SettingsGroup(children: [
          RadioGroup<ThemeMode>(
            groupValue: s.themeMode,
            onChanged: (v) => update((x) => x.copyWith(themeMode: v)),
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                    key: Key('theme-light'), value: ThemeMode.light, title: Text('Light'), secondary: Icon(AppIcons.sun)),
                RadioListTile<ThemeMode>(
                    key: Key('theme-dark'), value: ThemeMode.dark, title: Text('Dark'), secondary: Icon(AppIcons.moon)),
                RadioListTile<ThemeMode>(
                    key: Key('theme-system'),
                    value: ThemeMode.system,
                    title: Text('System'),
                    secondary: Icon(AppIcons.system)),
              ],
            ),
          ),
        ]),
      'security' => _security(context, ref),
      'privacy' => SettingsGroup(children: [
          ListTile(
            leading: const Icon(AppIcons.history),
            title: const Text('Location history retention'),
            subtitle: Text('${s.historyRetentionDays} days'),
            trailing: DropdownButton<int>(
              value: s.historyRetentionDays,
              underline: const SizedBox.shrink(),
              items: const [30, 90, 180, 365]
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d days')))
                  .toList(),
              onChanged: (v) => update((x) => x.copyWith(historyRetentionDays: v)),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.sparkles),
            title: const Text('Share anonymous usage analytics'),
            value: s.shareAnalytics,
            onChanged: (v) => update((x) => x.copyWith(shareAnalytics: v)),
          ),
          ListTile(
            leading: const Icon(AppIcons.delete),
            title: const Text('Clear read alerts'),
            onTap: () {
              ref.read(alertsProvider.notifier).clearRead();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Read alerts cleared')));
            },
          ),
        ]),
      'demo' => _demo(context, ref),
      'about' => _about(context),
      _ => const Text('Unknown section'),
    };

    return Scaffold(
      appBar: AppBar(title: Text(meta?.title ?? 'Settings')),
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.huge),
        children: [
          ResponsiveCenter(child: Padding(padding: AppSpacing.screen, child: body)),
        ],
      ),
    );
  }

  Widget _account(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(children: [
          SettingsTile(icon: AppIcons.user, title: user?.name ?? '', subtitle: user?.email, onTap: () => context.push(Routes.profile)),
          SettingsTile(icon: AppIcons.building, title: user?.organization ?? '', subtitle: 'Organization'),
        ]),
        AppSpacing.gapMd,
        const WorkspaceSwitcher(),
      ],
    );
  }

  Widget _tracking(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(children: [
          SwitchListTile(
            secondary: const Icon(AppIcons.navigation),
            title: const Text('Live Simulation'),
            subtitle: Text(s.liveSimulation ? 'ON · devices move automatically' : 'OFF · positions frozen'),
            value: s.liveSimulation,
            onChanged: (v) => update((x) => x.copyWith(liveSimulation: v)),
          ),
          ListTile(
            leading: const Icon(AppIcons.timer),
            title: const Text('Simulation speed'),
            subtitle: const Text('Speeds up simulated time for demos'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1x')),
                ButtonSegment(value: 2, label: Text('2x')),
                ButtonSegment(value: 5, label: Text('5x')),
                ButtonSegment(value: 10, label: Text('10x')),
              ],
              selected: {s.simulationSpeed},
              onSelectionChanged: (v) => update((x) => x.copyWith(simulationSpeed: v.first)),
            ),
          ),
        ]),
        AppSpacing.gapMd,
        Text(
          'Per-device update intervals are set by each device\'s tracking mode (Device → Settings).',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: context.tones.neutral500),
        ),
      ],
    );
  }

  Widget _security(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;
    return SettingsGroup(children: [
      SettingsTile(
        icon: AppIcons.lock,
        title: 'Change password',
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Change password'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(obscureText: true, decoration: InputDecoration(hintText: 'Current password')),
                  SizedBox(height: AppSpacing.md),
                  TextField(obscureText: true, decoration: InputDecoration(hintText: 'New password')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
          }
        },
      ),
      SwitchListTile(
        secondary: const Icon(AppIcons.shield),
        title: const Text('Two-factor authentication'),
        value: s.twoFactor,
        onChanged: (v) => update((x) => x.copyWith(twoFactor: v)),
      ),
      SwitchListTile(
        secondary: const Icon(AppIcons.eye),
        title: const Text('Biometric app lock'),
        value: s.biometricLock,
        onChanged: (v) => update((x) => x.copyWith(biometricLock: v)),
      ),
      const ListTile(
        leading: Icon(AppIcons.system),
        title: Text('Active sessions'),
        subtitle: Text('This device · active now'),
      ),
    ]);
  }

  Widget _demo(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final update = ref.read(settingsProvider.notifier).update;
    final conn = ref.watch(connectivityProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(children: [
          SwitchListTile(
            secondary: const Icon(AppIcons.offline),
            title: const Text('Simulate Offline Mode'),
            subtitle: const Text('Pause realtime updates and show cached data'),
            value: conn.offline,
            onChanged: (v) => ref.read(connectivityProvider.notifier).setOffline(v),
          ),
          SwitchListTile(
            secondary: const Icon(AppIcons.warning),
            title: const Text('Simulate occasional errors'),
            subtitle: const Text('About 8% of data loads fail so Retry can be tested'),
            value: s.simulateErrors,
            onChanged: (v) => update((x) => x.copyWith(simulateErrors: v)),
          ),
          SettingsTile(
            icon: AppIcons.refresh,
            title: 'Reset demo data',
            subtitle: 'Restore the original devices, alerts and geofences',
            color: AppColors.emergency,
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset demo data?'),
                  content: const Text('Added devices, geofences and alert history will be discarded.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        foregroundColor: ctx.tones.critInk,
                        side: BorderSide(color: ctx.tones.crit),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              await ref.read(mockBackendProvider).reset();
              ref
                ..invalidate(devicesProvider)
                ..invalidate(assetsProvider)
                ..invalidate(driversProvider)
                ..invalidate(geofencesProvider)
                ..invalidate(alertsProvider)
                ..invalidate(notificationsProvider)
                ..invalidate(liveTrailsProvider)
                ..invalidate(geofenceEngineProvider);
              ref.read(liveLocationSourceProvider).resume(catchUp: false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo data restored')));
              }
            },
          ),
        ]),
        AppSpacing.gapMd,
        const DemoModeNotice(),
      ],
    );
  }

  Widget _about(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              const TrackProLogo(size: 48),
              AppSpacing.gapMd,
              Text('Version 1.0.0 (1) · Phase 1 prototype', style: theme.textTheme.bodyMedium),
              AppSpacing.gapSm,
              Text(
                'Universal GPS tracking for pets, people, keys, vehicles, taxis, trucks and equipment.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: context.tones.neutral500),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        const DemoModeNotice(),
        AppSpacing.gapMd,
        AppCard(
          child: Text(
            'This build runs entirely on-device. Devices, GPS positions, trips, alerts and the map of Delhi NCR '
            'are generated by a local simulation engine. No backend, API key or network connection is required.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
