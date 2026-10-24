import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';
import '../application/session_controller.dart';
import 'login_screen.dart' show AuthFieldLabel;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  AccountType _type = AccountType.personal;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            accountType: _type,
          );
      if (mounted) context.go(Routes.home);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    const fieldBox = BoxConstraints(minHeight: 48);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, AppSpacing.sm, 18, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How will you use TrackPro?',
                    style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  AppSpacing.gapMd,
                  _AccountOption(
                    icon: AppIcons.user,
                    title: 'Personal',
                    body: 'Keys, bags, pets, family and your own car.',
                    selected: _type == AccountType.personal,
                    onTap: () => setState(() => _type = AccountType.personal),
                  ),
                  AppSpacing.gapMd,
                  _AccountOption(
                    icon: AppIcons.building,
                    title: 'Business',
                    body: 'Fleets, drivers, groups and shared workspaces.',
                    selected: _type == AccountType.business,
                    onTap: () => setState(() => _type = AccountType.business),
                  ),
                  AppSpacing.gapXl,
                  const AuthFieldLabel('Full name'),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Full name',
                      constraints: fieldBox,
                      prefixIcon: Icon(AppIcons.user, size: 20, color: tones.neutral400),
                    ),
                    validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name' : null,
                  ),
                  AppSpacing.gapLg,
                  const AuthFieldLabel('Email'),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      constraints: fieldBox,
                      prefixIcon: Icon(AppIcons.mail, size: 20, color: tones.neutral400),
                    ),
                    validator: (v) => v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                        ? 'Enter a valid email'
                        : null,
                  ),
                  AppSpacing.gapLg,
                  const AuthFieldLabel('Password'),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      constraints: fieldBox,
                      prefixIcon: Icon(AppIcons.lock, size: 20, color: tones.neutral400),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Use at least 6 characters' : null,
                  ),
                  AppSpacing.gapXxl,
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable account-type tile (`is.acctType` option card).
class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final accent = theme.colorScheme.primary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: selected ? accent : tones.divider, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 26, color: tones.accent300),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
                      AppSpacing.gapXs,
                      Text(body, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral400)),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: AppDurations.fast,
                  opacity: selected ? 1 : 0,
                  child: Icon(AppIcons.success, size: 22, color: accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
