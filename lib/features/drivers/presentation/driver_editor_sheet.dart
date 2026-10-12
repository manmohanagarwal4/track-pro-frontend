import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/driver.dart';
import '../application/drivers_controller.dart';

/// Add (driver == null) or edit a driver. Returns the saved driver.
Future<Driver?> showDriverEditor(BuildContext context, {Driver? driver}) => showModalBottomSheet<Driver>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _DriverEditor(driver: driver),
      ),
    );

/// Confirms and deletes a driver, offering Undo. Returns true if deleted.
Future<bool> confirmDeleteDriver(BuildContext context, WidgetRef ref, Driver driver, {String? vehicleName}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(AppIcons.delete, color: AppColors.emergency),
      title: Text('Delete ${driver.name}?'),
      content: Text(vehicleName == null
          ? 'The driver will be removed from your fleet.'
          : 'The driver will be removed from your fleet and $vehicleName will have no driver.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          key: const Key('driver-delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(driversProvider.notifier);
  await notifier.delete(driver.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('${driver.name} deleted'),
      action: SnackBarAction(label: 'Undo', onPressed: () => notifier.restore(driver)),
    ));
  return true;
}

class _DriverEditor extends ConsumerStatefulWidget {
  const _DriverEditor({this.driver});

  final Driver? driver;

  @override
  ConsumerState<_DriverEditor> createState() => _DriverEditorState();
}

class _DriverEditorState extends ConsumerState<_DriverEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.driver?.name);
  late final _phone = TextEditingController(text: widget.driver?.phone ?? '+91 ');
  late final _licence = TextEditingController(text: widget.driver?.licenseNo);
  bool _busy = false;
  String? _error;

  bool get _editing => widget.driver != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _licence.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final notifier = ref.read(driversProvider.notifier);
    try {
      final Driver saved;
      if (_editing) {
        saved = widget.driver!.copyWith(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          licenseNo: _licence.text.trim().toUpperCase(),
        );
        await notifier.edit(saved);
      } else {
        saved = await notifier.create(name: _name.text, phone: _phone.text, licenseNo: _licence.text);
      }
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_editing ? 'Edit driver' : 'Add driver', style: theme.textTheme.titleLarge),
              AppSpacing.gapLg,
              TextFormField(
                key: const Key('driver-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Full name', prefixIcon: Icon(AppIcons.user, size: 20)),
                validator: (v) => v == null || v.trim().length < 2 ? 'Enter the driver\'s name' : null,
              ),
              AppSpacing.gapMd,
              TextFormField(
                key: const Key('driver-phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'Phone', prefixIcon: Icon(AppIcons.phone, size: 20)),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  return digits.length < 10 ? 'Enter a valid phone number' : null;
                },
              ),
              AppSpacing.gapMd,
              TextFormField(
                key: const Key('driver-licence'),
                controller: _licence,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    hintText: 'Driving licence number', prefixIcon: Icon(AppIcons.driver, size: 20)),
                validator: (v) => v == null || v.trim().length < 6 ? 'Enter the licence number' : null,
              ),
              if (_error != null) ...[
                AppSpacing.gapMd,
                Row(
                  children: [
                    Icon(AppIcons.warning, size: 16, color: theme.colorScheme.error),
                    AppSpacing.gapSm,
                    Expanded(
                      child: Text(_error!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              ],
              AppSpacing.gapXl,
              FilledButton(
                key: const Key('driver-save'),
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_editing ? 'Save changes' : 'Add driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
