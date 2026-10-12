import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/alert.dart';
import '../../features/alerts/application/alerts_controller.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/tracking/application/connectivity_controller.dart';
import '../routing/app_router.dart';
import '../routing/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/status_style.dart';
import '../utils/formatters.dart';

/// App-wide overlays: offline / sync banner and in-app alert toasts.
class GlobalBanners extends ConsumerWidget {
  const GlobalBanners({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(sessionProvider.select((s) => s.value != null));
    final conn = ref.watch(connectivityProvider);
    final showConn = signedIn && (conn.offline || conn.syncing);
    return Stack(
      children: [
        Column(
          children: [
            AnimatedSize(
              duration: AppDurations.medium,
              curve: Curves.easeOut,
              child: showConn ? _ConnectivityBanner(state: conn) : const SizedBox(width: double.infinity),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: showConn,
                child: child,
              ),
            ),
          ],
        ),
        if (signedIn) const _AlertToast(),
      ],
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner({required this.state});

  final ConnectivityState state;

  @override
  Widget build(BuildContext context) {
    final syncing = state.syncing;
    final color = syncing ? AppColors.moving : AppColors.lightText;
    final top = MediaQuery.paddingOf(context).top;
    final last = state.lastSyncedAt;
    return Material(
      color: color,
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, top + 8, AppSpacing.lg, 8),
        child: Row(
          children: [
            if (syncing)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(AppIcons.offline, size: 16, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                syncing
                    ? 'Back online · Synchronizing...'
                    : 'You\'re offline · Showing cached data'
                        '${last == null ? '' : ' · Last synced ${Fmt.time(last)}'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertToast extends ConsumerStatefulWidget {
  const _AlertToast();

  @override
  ConsumerState<_AlertToast> createState() => _AlertToastState();
}

class _AlertToastState extends ConsumerState<_AlertToast> {
  Timer? _hide;
  TrackerAlert? _shown;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = ref.watch(alertBannerProvider);
    if (alert != null && alert.id != _shown?.id) {
      _shown = alert;
      _hide?.cancel();
      _hide = Timer(const Duration(seconds: 5), () {
        if (mounted) ref.read(alertBannerProvider.notifier).dismiss();
      });
    }
    final visible = alert != null;
    final a = alert ?? _shown;
    final top = MediaQuery.paddingOf(context).top + AppSpacing.sm;
    return AnimatedPositioned(
      duration: AppDurations.slow,
      curve: Curves.easeOutBack,
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: visible ? top : -140,
      child: a == null
          ? const SizedBox.shrink()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _ToastCard(
                  alert: a,
                  onTap: () {
                    ref.read(alertBannerProvider.notifier).dismiss();
                    ref.read(alertsProvider.notifier).markRead(a.id);
                    final ctx = rootNavigatorKey.currentContext;
                    if (ctx != null) GoRouter.of(ctx).push(Routes.device(a.deviceId));
                  },
                  onClose: () => ref.read(alertBannerProvider.notifier).dismiss(),
                ),
              ),
            ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.alert, required this.onTap, required this.onClose});

  final TrackerAlert alert;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = StatusStyle.alert(alert.type, alert.severity);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.lgAll,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          boxShadow: AppShadows.floating(theme.brightness),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
            child: Row(
              children: [
                Icon(AppIcons.alert(alert.type), color: color, size: 22),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(alert.title, style: theme.textTheme.titleSmall?.copyWith(color: color)),
                      const SizedBox(height: 2),
                      Text(
                        alert.value == null ? alert.message : '${alert.message} ${alert.value}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(AppIcons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
