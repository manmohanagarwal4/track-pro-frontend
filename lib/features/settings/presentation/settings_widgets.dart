import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/enums.dart';
import '../../auth/application/session_controller.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(indent: 56),
          ],
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? (onTap == null ? null : const Icon(AppIcons.chevronRight, size: 18)),
      onTap: onTap,
    );
  }
}

/// Personal / Business workspace toggle. Navigation adapts immediately.
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(accountTypeProvider);
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workspace', style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            type == AccountType.business
                ? 'Fleet tools, drivers and trips for your organisation'
                : 'Your pets, keys, family and personal vehicles',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          AppSpacing.gapMd,
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AccountType>(
              key: const Key('workspace-switch'),
              segments: const [
                ButtonSegment(value: AccountType.personal, label: Text('Personal'), icon: Icon(AppIcons.user)),
                ButtonSegment(value: AccountType.business, label: Text('Business'), icon: Icon(AppIcons.building)),
              ],
              selected: {type},
              onSelectionChanged: (s) => ref.read(sessionProvider.notifier).switchAccountType(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoModeNotice extends StatelessWidget {
  const DemoModeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.iris.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.iris.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.flask, color: AppColors.iris, size: 20),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DEMO MODE', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.iris, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('All locations and devices are simulated.', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You can sign back in with the demo account at any time.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(key: const Key('logout-confirm'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final router = GoRouter.of(context);
  await ref.read(sessionProvider.notifier).signOut();
  router.go(Routes.login);
}
