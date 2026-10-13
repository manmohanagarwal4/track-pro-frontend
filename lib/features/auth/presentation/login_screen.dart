import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/trackpro_logo.dart';
import '../application/session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'demo@example.com');
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _demoBusy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).signIn(_email.text, _password.text);
      if (mounted) context.go(Routes.home);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _demo() async {
    setState(() {
      _error = null;
      _demoBusy = true;
    });
    try {
      await ref.read(sessionProvider.notifier).signInWithDemo();
      if (mounted) context.go(Routes.home);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _demoBusy = false);
    }
  }

  Future<void> _forgot() async {
    final controller = TextEditingController(text: _email.text);
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We\'ll send a reset link to your email.'),
            AppSpacing.gapMd,
            TextField(controller: controller, decoration: const InputDecoration(hintText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send link')),
        ],
      ),
    );
    if (sent == true) {
      await ref.read(authRepositoryProvider).requestPasswordReset(controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset link sent to ${controller.text}')),
        );
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final busy = _busy || _demoBusy;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 48, 22, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: TrackProMark(size: 48)),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome back',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'Sign in to see where everything is right now.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: tones.neutral500),
                    ),
                    const SizedBox(height: 24),
                    const AuthFieldLabel('Email'),
                    TextFormField(
                      key: const Key('login-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        constraints: const BoxConstraints(minHeight: 48),
                        prefixIcon: Icon(AppIcons.mail, size: 20, color: tones.neutral400),
                      ),
                      validator: (v) => v == null || !v.contains('@') || !v.contains('.')
                          ? 'Enter a valid email'
                          : null,
                    ),
                    AppSpacing.gapLg,
                    const AuthFieldLabel('Password'),
                    TextFormField(
                      key: const Key('login-password'),
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _signIn(),
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        constraints: const BoxConstraints(minHeight: 48),
                        prefixIcon: Icon(AppIcons.lock, size: 20, color: tones.neutral400),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 20, color: tones.neutral400),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 4 ? 'Password must be at least 4 characters' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: busy ? null : _forgot, child: const Text('Forgot password?')),
                    ),
                    AnimatedSwitcher(
                      duration: AppDurations.medium,
                      child: _error == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Row(
                                children: [
                                  Icon(AppIcons.warning, size: 16, color: tones.critInk),
                                  AppSpacing.gapSm,
                                  Expanded(
                                    child: Text(_error!,
                                        style: theme.textTheme.bodySmall?.copyWith(color: tones.critInk)),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    FilledButton(
                      key: const Key('login-submit'),
                      onPressed: busy ? null : _signIn,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      child: _busy ? const _ButtonSpinner() : const Text('Sign in'),
                    ),
                    AppSpacing.gapSm,
                    OutlinedButton.icon(
                      key: const Key('login-demo'),
                      onPressed: busy ? null : _demo,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      icon: _demoBusy ? const _ButtonSpinner() : const Icon(AppIcons.sparkles, size: 18),
                      label: const Text('Continue with Demo Account'),
                    ),
                    AppSpacing.gapLg,
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('New to TrackPro?', style: theme.textTheme.bodyMedium?.copyWith(color: tones.neutral500)),
                        TextButton(
                          onPressed: busy ? null : () => context.push(Routes.register),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                    AppSpacing.gapXl,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(AppIcons.info, size: 16, color: tones.neutral500),
                        AppSpacing.gapSm,
                        Expanded(
                          child: Text(
                            'Demo mode: any email and a password of 4+ characters will work.',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small muted label above an auth form field (`.field label` in the design).
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, color: context.tones.neutral400),
        ),
      );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
}
