import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/asset.dart';
import '../../../data/models/enums.dart';
import '../../auth/application/session_controller.dart';
import '../application/assets_controller.dart';

/// Create (asset == null) or edit an asset. Returns the saved asset.
Future<Asset?> showAssetEditor(BuildContext context, {Asset? asset}) => showModalBottomSheet<Asset>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _AssetEditor(asset: asset),
      ),
    );

class _AssetEditor extends ConsumerStatefulWidget {
  const _AssetEditor({this.asset});

  final Asset? asset;

  @override
  ConsumerState<_AssetEditor> createState() => _AssetEditorState();
}

class _AssetEditorState extends ConsumerState<_AssetEditor> {
  late final _name = TextEditingController(text: widget.asset?.name);
  late final _reg = TextEditingController(text: widget.asset?.registration);
  late AssetType _type = widget.asset?.type ?? AssetType.car;
  bool _busy = false;
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _reg.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final base = widget.asset;
    final reg = _type.usesRegistration && _reg.text.trim().isNotEmpty ? _reg.text.trim().toUpperCase() : null;
    final asset = base == null
        ? Asset(
            id: '',
            name: _name.text.trim(),
            type: _type,
            registration: reg,
            createdAt: clock.now(),
            categoryOverride: ref.read(accountTypeProvider) == AccountType.personal
                ? AssetCategory.personal
                : AssetCategory.business,
          )
        : Asset(
            id: base.id,
            name: _name.text.trim(),
            type: _type,
            registration: reg,
            description: base.description,
            createdAt: base.createdAt,
            categoryOverride: base.categoryOverride,
          );
    final saved = await ref.read(assetsProvider.notifier).save(asset);
    if (mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.asset == null ? 'New asset' : 'Edit asset',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.4)),
              AppSpacing.gapLg,
              Text('KIND', style: AppTypography.overline.copyWith(color: tones.neutral500)),
              AppSpacing.gapSm,
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.05,
                children: [
                  for (final t in AssetType.selectable)
                    _KindTile(type: t, selected: _type == t, onTap: () => setState(() => _type = t)),
                ],
              ),
              AppSpacing.gapLg,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Asset name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              if (_type.usesRegistration) ...[
                AppSpacing.gapMd,
                TextFormField(
                  controller: _reg,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'Registration number (optional)'),
                ),
              ],
              AppSpacing.gapXl,
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save asset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kind picker tile: icon above label, accent ring when selected.
class _KindTile extends StatelessWidget {
  const _KindTile({required this.type, required this.selected, required this.onTap});

  final AssetType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    return Material(
      color: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: selected ? theme.colorScheme.primary : AppColors.transparent, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.asset(type), size: 22, color: selected ? tones.accent300 : tones.neutral400),
              const SizedBox(height: 6),
              Text(type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: selected ? theme.colorScheme.onSurface : tones.neutral400)),
            ],
          ),
        ),
      ),
    );
  }
}
