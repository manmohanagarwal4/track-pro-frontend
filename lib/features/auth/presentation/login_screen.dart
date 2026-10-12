import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/routing/routes.dart';
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
    final busy = _busy || _demoBusy;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: TrackProLogo(size: 40)),
                    const SizedBox(height: 36),
                    Text('Welcome back', style: theme.textTheme.headlineMedium),
                    AppSpacing.gapSm,
                    Text(
                      'Sign in to see where everything is right now.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('login-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(AppIcons.mail, size: 20),
                      ),
                      validator: (v) => v == null || !v.contains('@') || !v.contains('.')
                          ? 'Enter a valid email'
                          : null,
                    ),
                    AppSpacing.gapMd,
                    TextFormField(
                      key: const Key('login-password'),
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(AppIcons.lock, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 20),
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
                                  Icon(AppIcons.warning, size: 16, color: theme.colorScheme.error),
                                  AppSpacing.gapSm,
                                  Expanded(
                                    child: Text(_error!,
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    FilledButton(
                      key: const Key('login-submit'),
                      onPressed: busy ? null : _signIn,
                      child: _busy ? const _ButtonSpinner() : const Text('Sign in'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text('or', style: theme.textTheme.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      key: const Key('login-demo'),
                      onPressed: busy ? null : _demo,
                      icon: _demoBusy ? const _ButtonSpinner() : const Icon(AppIcons.sparkles, size: 18),
                      label: const Text('Continue with Demo Account'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('New to TrackPro?', style: theme.textTheme.bodyMedium),
                        TextButton(
                          onPressed: busy ? null : () => context.push(Routes.register),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'Demo mode: any email and a password of 4+ characters will work.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
}
