import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/trackpro_logo.dart';
import '../../settings/application/settings_controller.dart';
import '../application/session_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.35, 1, curve: Curves.easeOut));
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.24),
            colors: [tones.accent900, theme.scaffoldBackgroundColor],
            stops: const [0, 0.7],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.35), blurRadius: 40),
                    ],
                  ),
                  child: const TrackProMark(size: 76),
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: fade,
                child: Column(
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Track'),
                        TextSpan(text: 'Pro', style: TextStyle(color: theme.colorScheme.primary)),
                      ]),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Track anything. Anywhere.'.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        letterSpacing: 1.9,
                        color: tones.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
