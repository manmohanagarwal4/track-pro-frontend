import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../../settings/application/settings_controller.dart';

class _Page {
  const _Page(this.title, this.body, this.icons, this.color);

  final String title;
  final String body;
  final List<IconData> icons;
  final Color color;
}

const _pages = [
  _Page(
    'Track anything that matters',
    'Pets, keys, people, cars, taxis, trucks and equipment — one app for every tracker you own.',
    [AppIcons.pin, AppIcons.navigation, AppIcons.devices],
    AppColors.iris,
  ),
  _Page(
    'Live location, every second',
    'Watch assets move in real time with speed, heading, battery and full telemetry.',
    [AppIcons.speed, AppIcons.route, AppIcons.satellite],
    AppColors.signal,
  ),
  _Page(
    'Alerts & geofences that act for you',
    'Get notified on overspeed, zone entry/exit, low battery or SOS — and manage your whole fleet.',
    [AppIcons.bellRing, AppIcons.geofence, AppIcons.shield],
    AppColors.warning,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _finish() {
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(onboardingDone: true));
    context.go(Routes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveOnboarding(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _finish, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _OnboardingPage(page: _pages[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: AppDurations.medium,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? theme.colorScheme.primary : theme.colorScheme.outline,
                        borderRadius: AppRadius.pillAll,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(
                            duration: AppDurations.slow, curve: Curves.easeOutCubic),
                    child: Text(last ? 'Get started' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResponsiveOnboarding extends StatelessWidget {
  const ResponsiveOnboarding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: child));
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Illustration(page: page),
          const SizedBox(height: 40),
          Text(page.title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          AppSpacing.gapMd,
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final c = page.color;
    return SizedBox(
      width: 240,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final r in [220.0, 160.0, 100.0])
            Container(
              width: r,
              height: r,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.06 + (220 - r) / 1500)),
            ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Icon(page.icons.first, color: Colors.white, size: 40),
          ),
          Positioned(left: 18, top: 40, child: _Chip(icon: page.icons[1], color: c)),
          Positioned(right: 14, bottom: 46, child: _Chip(icon: page.icons[2], color: c)),
          Positioned(
            right: 34,
            top: 22,
            child: _Chip(icon: AppIcons.asset(AssetType.pet), color: AppColors.moving, small: true),
          ),
          Positioned(
            left: 34,
            bottom: 26,
            child: _Chip(icon: AppIcons.asset(AssetType.truck), color: AppColors.stationary, small: true),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.color, this.small = false});

  final IconData icon;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final s = small ? 36.0 : 48.0;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(s * 0.32),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Icon(icon, color: color, size: s * 0.48),
    );
  }
}
