import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/headline_reveal.dart';
import '../../../core/motion/reveal.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_shadows.dart';
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
    AppColors.crimson,
  ),
  _Page(
    'Live location, every second',
    'Watch assets move in real time with speed, heading, battery and full telemetry.',
    [AppIcons.speed, AppIcons.route, AppIcons.satellite],
    AppColors.rose,
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
                      curve: AppCurves.spring,
                      width: i == _index ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? theme.colorScheme.primary : context.tones.neutral700,
                        borderRadius: AppRadius.pillAll,
                        boxShadow: i == _index ? AppShadows.glow(theme.colorScheme.primary, strength: 0.5) : const [],
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
                    child: AnimatedSwitcher(
                      duration: AppDurations.medium,
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(a),
                          child: c,
                        ),
                      ),
                      child: Text(last ? 'Get started' : 'Next', key: ValueKey(last)),
                    ),
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
          HeadlineReveal(
            delay: const Duration(milliseconds: 150),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
            ),
          ),
          AppSpacing.gapMd,
          Reveal(
            delay: const Duration(milliseconds: 450),
            offset: 12,
            child: Text(
              page.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: context.tones.neutral400),
            ),
          ),
        ],
      ),
    );
  }
}

/// A breathing crimson core with tracker chips orbiting it on two rings.
class _Illustration extends StatefulWidget {
  const _Illustration({required this.page});

  final _Page page;

  @override
  State<_Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<_Illustration> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final accent = theme.colorScheme.primary;
    final page = widget.page;
    // (ring radius, start angle, chip) — inner ring turns forwards, outer back.
    final orbiters = [
      (80.0, 0.0, _Chip(icon: page.icons[1], color: tones.tone(page.color))),
      (80.0, math.pi, _Chip(icon: page.icons[2], color: tones.tone(page.color))),
      (110.0, math.pi / 2, _Chip(icon: AppIcons.asset(AssetType.pet), color: AppColors.moving, small: true)),
      (110.0, -math.pi / 2, _Chip(icon: AppIcons.asset(AssetType.truck), color: AppColors.idle, small: true)),
    ];
    return SizedBox(
      width: 260,
      height: 240,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final a = _c.value * 2 * math.pi;
          final breathe = 1 + 0.04 * math.sin(a * 4);
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final r in [220.0, 160.0])
                Container(
                  width: r,
                  height: r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.18)),
                  ),
                ),
              Transform.scale(
                scale: breathe,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: AppShadows.glow(accent, strength: 1.1 * breathe),
                  ),
                  child: Icon(page.icons.first, color: AppColors.white, size: 40),
                ),
              ),
              for (final (radius, start, chip) in orbiters)
                Transform.translate(
                  offset: Offset.fromDirection(start + (radius < 100 ? a : -a), radius),
                  child: chip,
                ),
            ],
          );
        },
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
        color: small ? tag.bg : null,
        gradient: small ? null : tones.glassGradient,
        borderRadius: small ? BorderRadius.circular(12) : BorderRadius.circular(16),
        border: Border.all(color: small ? color.withValues(alpha: 0.35) : tones.glassBorder, width: 1.2),
        boxShadow: [BoxShadow(color: (small ? color : tones.shadow).withValues(alpha: 0.35), blurRadius: 14)],
      ),
      child: Icon(icon, color: small ? tag.ink : tones.accent300, size: s * 0.48),
    );
  }
}
