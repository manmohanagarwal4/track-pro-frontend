import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/press_scale.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
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
      if (i == index) return;
      HapticFeedback.selectionClick();
      context.go(items[i].path);
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

    // Floating frosted-glass dock over the content.
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _GlowDock(items: items, index: index, onSelect: go, icon: icon),
    );
  }
}

/// Bottom navigation as a floating glass dock. A glowing crimson pill springs
/// between tabs; the selected icon pops and turns white on top of it.
class _GlowDock extends StatelessWidget {
  const _GlowDock({required this.items, required this.index, required this.onSelect, required this.icon});

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget Function(NavItem) icon;

  static const _radius = BorderRadius.all(Radius.circular(26));
  static const _pill = Size(52, 32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final accent = theme.colorScheme.primary;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, bottom > 0 ? bottom : AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: _radius, boxShadow: AppShadows.floating(theme.brightness)),
        child: ClipRRect(
          borderRadius: _radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(color: tones.glass, borderRadius: _radius),
              child: CustomPaint(
                foregroundPainter: GlassRimPainter(
                  radius: _radius,
                  highlight: tones.glassHighlight,
                  edge: tones.glassBorder,
                ),
                child: SizedBox(
                  height: 66,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final slot = box.maxWidth / items.length;
                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 520),
                            curve: AppCurves.spring,
                            left: slot * index + (slot - _pill.width) / 2,
                            top: 8,
                            width: _pill.width,
                            height: _pill.height,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                borderRadius: AppRadius.pillAll,
                                boxShadow: AppShadows.glow(accent, strength: 0.7),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < items.length; i++)
                                Expanded(
                                  child: _DockItem(
                                    item: items[i],
                                    selected: i == index,
                                    icon: icon(items[i]),
                                    onTap: () => onSelect(i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({required this.item, required this.selected, required this.icon, required this.onTap});

  final NavItem item;
  final bool selected;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: PressScale(
            scale: 0.86,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 32,
                  child: Center(
                    child: AnimatedScale(
                      scale: selected ? 1.12 : 1,
                      duration: const Duration(milliseconds: 420),
                      curve: AppCurves.spring,
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: selected ? AppColors.white : tones.neutral500),
                        duration: AppDurations.medium,
                        builder: (_, c, child) => IconTheme(
                          data: IconThemeData(size: 21, color: c),
                          child: child!,
                        ),
                        child: icon,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: AppDurations.medium,
                  style: TextStyle(
                    fontFamily: AppTypography.family,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? accent : tones.neutral500,
                    letterSpacing: 0.2,
                  ),
                  child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
