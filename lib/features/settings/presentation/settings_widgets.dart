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

/// A single surface tile holding rows separated by hairline dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: ListTileTheme.merge(
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: AppSpacing.md,
        minLeadingWidth: 20,
        child: IconTheme.merge(
          data: const IconThemeData(size: 19),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const Divider(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercase overline above a [SettingsGroup].
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.title, {super.key, this.first = false});

  final String title;
  final bool first;

  @override
  Widget build(BuildContext context) => SectionHeader(
        title,
        padding: EdgeInsets.fromLTRB(2, first ? AppSpacing.xs : AppSpacing.xl, 0, AppSpacing.sm),
      );
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.meta,
    this.trailing,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Short trailing value shown before the chevron.
  final String? meta;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final theme = Theme.of(context);
    final chevron = onTap == null ? null : Icon(AppIcons.chevronRight, size: 16, color: tones.neutral600);
    return ListTile(
      leading: Icon(icon, size: 19, color: color == null ? tones.neutral400 : tones.tone(color!)),
      title: Text(title, style: color == null ? null : TextStyle(color: tones.tone(color!))),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ??
          (meta == null
              ? chevron
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(meta!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral500)),
                    if (chevron != null) ...[const SizedBox(width: 6), chevron],
                  ],
                )),
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
    final tones = context.tones;
    final business = type == AccountType.business;
    void switchTo(AccountType t) => ref.read(sessionProvider.notifier).switchAccountType(t);
    return AppCard(
      padding: const EdgeInsets.all(14),
      border: Border.all(color: tones.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: () => switchTo(business ? AccountType.personal : AccountType.business),
            child: Row(
              children: [
                Icon(business ? AppIcons.building : AppIcons.user, size: 22, color: tones.accent300),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Workspace', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500)),
                      Text(business ? 'Business' : 'Personal',
                          style: theme.textTheme.titleSmall?.copyWith(fontSize: 15)),
                    ],
                  ),
                ),
                Text('Switch', style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.accent300)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            business
                ? 'Fleet tools, drivers and trips for your organisation'
                : 'Your pets, keys, family and personal vehicles',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500),
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
              onSelectionChanged: (s) => switchTo(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info callout: the app runs on simulated data.
class DemoModeNotice extends StatelessWidget {
  const DemoModeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(color: tones.accent900, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          Icon(AppIcons.flask, color: tones.accent300, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DEMO MODE',
                    style: theme.textTheme.labelSmall?.copyWith(color: tones.accent300, letterSpacing: 0.9)),
                const SizedBox(height: 2),
                Text('All locations and devices are simulated.',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
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
        FilledButton(
          key: const Key('logout-confirm'),
          style: FilledButton.styleFrom(
            foregroundColor: ctx.tones.critInk,
            side: BorderSide(color: ctx.tones.crit),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final router = GoRouter.of(context);
  await ref.read(sessionProvider.notifier).signOut();
  router.go(Routes.login);
}
