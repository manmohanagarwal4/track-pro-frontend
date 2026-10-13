import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/alert.dart';
import '../../../data/models/enums.dart';
import '../../alerts/application/alerts_controller.dart';
import '../../alerts/presentation/alerts_screen.dart';
import '../../devices/presentation/widgets/device_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory? _category;

  static Color _color(NotificationCategory c) => switch (c) {
        NotificationCategory.alerts => AppColors.emergency,
        NotificationCategory.system => AppColors.iris,
        NotificationCategory.devices => AppColors.signal,
        NotificationCategory.trips => AppColors.stationary,
      };

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: AsyncView<List<AppNotification>>(
        value: items,
        onRetry: () => ref.invalidate(notificationsProvider),
        loading: const SkeletonList(message: 'Loading notifications...'),
        data: (all) {
          final list = _category == null ? all : all.where((n) => n.category == _category).toList();
          return ResponsiveCenter(
            child: Column(
              children: [
                ChipFilterBar<NotificationCategory?>(
                  values: const [null, ...NotificationCategory.values],
                  selected: _category,
                  label: (c) => c?.label ?? 'All',
                  onSelected: (c) => setState(() => _category = c),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: list.isEmpty
                      ? const EmptyView(icon: AppIcons.inbox, title: 'No notifications', message: 'You\'re all caught up.')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final n = list[i];
                            return Dismissible(
                              key: ValueKey(n.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => ref.read(notificationsProvider.notifier).delete(n.id),
                              background: const DeleteSwipeBackground(),
                              child: AlertRowTile(
                                icon: AppIcons.notification(n.category),
                                color: _color(n.category),
                                title: n.title,
                                time: n.timestamp,
                                body: n.body,
                                tag: n.category.label,
                                unread: !n.read,
                                onTap: () {
                                  ref.read(notificationsProvider.notifier).markRead(n.id);
                                  if (n.deviceId != null) context.push(Routes.device(n.deviceId!));
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
