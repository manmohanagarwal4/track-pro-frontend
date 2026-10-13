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
                        color: i == _index ? theme.colorScheme.primary : context.tones.neutral700,
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
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          AppSpacing.gapMd,
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: context.tones.neutral500),
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
    final theme = Theme.of(context);
    final tones = context.tones;
    final accent = theme.colorScheme.primary;
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tones.divider),
              ),
            ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: tones.accent900,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent, width: 1.5),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 40)],
            ),
            child: Icon(page.icons.first, color: tones.accent300, size: 38),
          ),
          Positioned(left: 18, top: 40, child: _Chip(icon: page.icons[1], color: tones.tone(page.color))),
          Positioned(right: 14, bottom: 46, child: _Chip(icon: page.icons[2], color: tones.tone(page.color))),
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

/// Satellite tile: a surface option tile (large) or a tonal status tag (small).
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.color, this.small = false});

  final IconData icon;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final s = small ? 36.0 : 48.0;
    final tag = tones.tag(color);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: small ? tag.bg : Theme.of(context).colorScheme.surface,
        borderRadius: small ? BorderRadius.circular(10) : AppRadius.lgAll,
        border: small ? null : Border.all(color: tones.divider, width: 1.5),
      ),
      child: Icon(icon, color: small ? tag.ink : tones.accent300, size: s * 0.48),
    );
  }
}
