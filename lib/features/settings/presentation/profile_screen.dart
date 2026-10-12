import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/user.dart';
import '../../auth/application/session_controller.dart';
import '../../devices/application/devices_controller.dart';
import 'settings_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, AppUser user) async {
    final name = TextEditingController(text: user.name);
    final phone = TextEditingController(text: user.phone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(hintText: 'Name')),
            AppSpacing.gapMd,
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await ref.read(sessionProvider.notifier).updateProfile(user.copyWith(name: name.text.trim(), phone: phone.text.trim()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    }
    name.dispose();
    phone.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(sessionProvider).value;
    final devices = ref.watch(deviceViewsProvider).value?.length ?? 0;
    if (user == null) return const Scaffold();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(user.initials,
                              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
                        ),
                        AppSpacing.gapMd,
                        Text(user.name, style: theme.textTheme.titleLarge),
                        Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        AppSpacing.gapSm,
                        Pill(label: user.accountType.label, color: AppColors.iris, icon: AppIcons.building),
                        AppSpacing.gapLg,
                        Row(
                          children: [
                            Expanded(child: _Stat(value: '$devices', label: 'Devices')),
                            const Expanded(child: _Stat(value: '1', label: 'Organizations')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,
                  const WorkspaceSwitcher(),
                  AppSpacing.gapMd,
                  SettingsGroup(children: [
                    SettingsTile(icon: AppIcons.edit, title: 'Edit Profile', onTap: () => _edit(context, ref, user)),
                    SettingsTile(icon: AppIcons.lock, title: 'Security', onTap: () => context.push(Routes.settingsSection('security'))),
                    SettingsTile(
                        icon: AppIcons.bellRing,
                        title: 'Notifications',
                        onTap: () => context.push(Routes.settingsSection('notifications'))),
                    SettingsTile(icon: AppIcons.settings, title: 'Preferences', onTap: () => context.push(Routes.settings)),
                    SettingsTile(
                      icon: AppIcons.logout,
                      title: 'Logout',
                      color: AppColors.emergency,
                      onTap: () => confirmLogout(context, ref),
                    ),
                  ]),
                  AppSpacing.gapMd,
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(AppIcons.building),
                      title: Text(user.organization),
                      subtitle: Text(user.phone.isEmpty ? 'Owner' : 'Owner · ${user.phone}'),
                    ),
                  ),
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
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: AppTypography.metric),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
