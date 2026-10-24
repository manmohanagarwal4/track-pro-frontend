import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/headline_reveal.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/trackpro_logo.dart';
import '../../settings/application/settings_controller.dart';
import '../application/session_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  late final _sonar = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), _route);
  }

  Future<void> _route() async {
    final user = await ref.read(sessionProvider.future).catchError((_) => null);
    if (!mounted) return;
    final onboarded = ref.read(settingsProvider).onboardingDone;
    if (user != null) {
      context.go(Routes.home);
    } else {
      context.go(onboarded ? Routes.login : Routes.onboarding);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    _sonar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final accent = theme.colorScheme.primary;
    final pop = CurvedAnimation(parent: _c, curve: const Interval(0, 0.6, curve: AppCurves.spring));
    final tagline = CurvedAnimation(parent: _c, curve: const Interval(0.45, 1, curve: AppCurves.enter));
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sonar: three rings pulsing out from the mark, staggered.
                  AnimatedBuilder(
                    animation: _sonar,
                    builder: (_, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var k = 0; k < 3; k++)
                          _Ring(t: (_sonar.value + k / 3) % 1, color: accent),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: pop,
                    builder: (_, child) => Transform.rotate(
                      angle: (1 - pop.value) * -math.pi / 10,
                      child: Transform.scale(scale: pop.value, child: child),
                    ),
                    child: Container(
                      width: 92,
                      height: 92,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppShadows.glow(accent, strength: 1.3),
                      ),
                      child: const TrackProMark(size: 62, outline: Color(0x00000000), glyph: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            HeadlineReveal(
              delay: const Duration(milliseconds: 300),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('TRACK', style: _wordmark.copyWith(color: theme.colorScheme.onSurface)),
                  ShimmerText('PRO', style: _wordmark, colors: [AppColors.crimsonLight, AppColors.crimsonDeep]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: tagline,
              builder: (_, _) => Opacity(
                opacity: tagline.value,
                child: Text(
                  'Track anything. Anywhere.'.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2 + (1 - tagline.value) * 8,
                    color: tones.neutral400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _wordmark = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1,
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 92 + t * 128;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5 * (1 - t)), width: 1.5),
      ),
    );
  }
}
