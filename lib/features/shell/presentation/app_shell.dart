import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/trackpro_logo.dart';
import '../../../data/models/enums.dart';
import '../../alerts/application/alerts_controller.dart';
import '../../auth/application/session_controller.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

/// Navigation adapts to the workspace: one app, two layouts.
List<NavItem> navItemsFor(AccountType type) => type == AccountType.personal
    ? const [
        NavItem(Routes.home, 'Home', AppIcons.home),
        NavItem(Routes.devices, 'Devices', AppIcons.devices),
        NavItem(Routes.map, 'Map', AppIcons.map),
        NavItem(Routes.alerts, 'Alerts', AppIcons.alerts),
        NavItem(Routes.more, 'More', AppIcons.more),
      ]
    : const [
        NavItem(Routes.home, 'Dashboard', AppIcons.dashboard),
        NavItem(Routes.fleet, 'Fleet', AppIcons.fleet),
        NavItem(Routes.map, 'Map', AppIcons.map),
        NavItem(Routes.trips, 'Trips', AppIcons.trips),
        NavItem(Routes.alerts, 'Alerts', AppIcons.alerts),
        NavItem(Routes.more, 'More', AppIcons.more),
      ];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(accountTypeProvider);
    final items = navItemsFor(type);
    final unread = ref.watch(unreadAlertCountProvider);
    var index = items.indexWhere((i) => location.startsWith(i.path));
    if (index < 0) index = 0;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    Widget icon(NavItem item, {bool selected = false}) {
      final i = Icon(item.icon);
      if (item.path != Routes.alerts || unread == 0) return i;
      return Badge(label: Text(unread > 99 ? '99+' : '$unread'), child: i);
    }

    void go(int i) {
      if (i != index) context.go(items[i].path);
    }

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: go,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: TrackProMark(size: 40),
              ),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(icon: icon(item), label: Text(item.label)),
              ],
            ),
            VerticalDivider(width: 1, color: context.tones.divider),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Frosted glass tab bar over the content, hairline on top.
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.tones.divider)),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: go,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final item in items)
                  NavigationDestination(icon: icon(item), label: item.label, tooltip: item.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
