import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/mock/geo/ncr_geo.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/geofence.dart';
import '../../../domain/device_view.dart';
import '../../devices/application/devices_controller.dart';
import '../../map/presentation/widgets/tracker_map.dart';
import '../application/geofences_controller.dart';

class GeofenceEditorScreen extends ConsumerStatefulWidget {
  const GeofenceEditorScreen({super.key, this.geofenceId, this.deviceId});

  final String? geofenceId;

  /// Prefill: center on this device and monitor it.
  final String? deviceId;

  @override
  ConsumerState<GeofenceEditorScreen> createState() => _GeofenceEditorScreenState();
}

class _GeofenceEditorScreenState extends ConsumerState<GeofenceEditorScreen>
    with TickerProviderStateMixin, AnimatedMapMixin<GeofenceEditorScreen> {
  final _controller = MapController();
  final _name = TextEditingController();
  GeofenceType _type = GeofenceType.home;
  LatLng _center = NcrGeo.userLocation;
  double _radius = 500;
  bool _enter = true;
  bool _exit = true;
  Set<String> _devices = {};
  Geofence? _existing;
  bool _busy = false;
  bool _initialised = false;

  @override
  MapController get mapController => _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final id = widget.geofenceId;
    if (id != null) {
      final g = ref.read(geofencesProvider).value?.where((g) => g.id == id).firstOrNull;
      if (g != null) {
        _existing = g;
        _name.text = g.name;
        _type = g.type;
        _center = g.center;
        _radius = g.radiusM;
        _enter = g.notifyEnter;
        _exit = g.notifyExit;
        _devices = g.deviceIds.toSet();
      }
    } else if (widget.deviceId != null) {
      final v = ref.read(deviceViewProvider(widget.deviceId!));
      if (v?.position != null) _center = v!.position!;
      _devices = {widget.deviceId!};
      _name.text = v == null ? '' : '${v.name} zone';
      _type = v?.type == AssetType.pet ? GeofenceType.safeZone : GeofenceType.home;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDevices(List<DeviceView> views) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DevicePicker(views: views, selected: _devices),
    );
    if (result != null) setState(() => _devices = result);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give the geofence a name')));
      return;
    }
    setState(() => _busy = true);
    final base = _existing;
    final fence = Geofence(
      id: base?.id ?? '',
      name: name,
      type: _type,
      center: _center,
      radiusM: _radius,
      createdAt: base?.createdAt ?? clock.now(),
      notifyEnter: _enter,
      notifyExit: _exit,
      deviceIds: _devices.toList(),
      active: base?.active ?? true,
    );
    await ref.read(geofencesProvider.notifier).save(fence);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Geofence "$name" saved')));
    context.pop();
  }

  Future<void> _delete() async {
    final g = _existing;
    if (g == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${g.name}?'),
        content: const Text('Alerts for this zone will stop immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: ctx.tones.critInk,
              side: BorderSide(color: ctx.tones.crit),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(geofencesProvider.notifier).delete(g.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final views = ref.watch(deviceViewsProvider).value ?? const <DeviceView>[];
    final draft = Geofence(
      id: '__draft__',
      name: _name.text.isEmpty ? 'New zone' : _name.text,
      type: _type,
      center: _center,
      radiusM: _radius,
      createdAt: clock.now(),
    );
    final monitored = _devices.isEmpty ? views : views.where((v) => _devices.contains(v.id)).toList();
    final place = ref.read(placeResolverProvider).describe(_center);
    final tones = context.tones;
    final label = theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: tones.neutral400);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final mapH = box.maxHeight * 0.52 < 440 ? box.maxHeight * 0.52 : 440.0;
          final sheetTop = mapH - 40;
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: mapH,
                child: TrackerMap(
                  controller: _controller,
                  devices: monitored,
                  geofences: [draft],
                  highlightGeofenceId: draft.id,
                  initialCenter: _center,
                  initialZoom: 14,
                  onTap: (_, p) => setState(() => _center = p),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 110,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [context.tones.groundBase, context.tones.groundBase.withAlpha(0)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        _Glass(
                          child: IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Icon(AppIcons.close, size: 20, color: theme.colorScheme.onSurface),
                          ),
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: _Glass(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tap the map to place the centre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.md,
                top: sheetTop - 56,
                child: MapButton(
                  icon: AppIcons.locate,
                  tooltip: 'My location',
                  onPressed: () {
                    setState(() => _center = NcrGeo.userLocation);
                    animateCamera(NcrGeo.userLocation, 14);
                  },
                ),
              ),
              Positioned(
                top: sheetTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.sheet,
                    boxShadow: AppShadows.floating(theme.brightness),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.sheet,
                    child: ResponsiveCenter(
                      // Eager column so the Save button always exists in the tree.
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          34 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: tones.neutral700,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            AppSpacing.gapMd,
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _existing == null ? 'Create Geofence' : 'Edit Geofence',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                if (_existing != null)
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: _delete,
                                    icon: Icon(AppIcons.delete, size: 20, color: tones.crit),
                                  ),
                              ],
                            ),
                            AppSpacing.gapMd,
                            Text('Name', style: label),
                            const SizedBox(height: 6),
                            TextField(
                              key: const Key('geofence-name'),
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(hintText: 'e.g. Home'),
                            ),
                            AppSpacing.gapMd,
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<String>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: 'circle',
                                    label: Text('Circle'),
                                    icon: Icon(AppIcons.circle, size: 16),
                                  ),
                                  ButtonSegment(value: 'polygon', label: Text('Polygon'), enabled: false),
                                ],
                                selected: const {'circle'},
                                onSelectionChanged: (_) {},
                              ),
                            ),
                            AppSpacing.gapMd,
                            Row(
                              children: [
                                Text('Radius', style: label),
                                Expanded(
                                  child: Slider(
                                    key: const Key('geofence-radius'),
                                    value: _radius,
                                    min: 100,
                                    max: 5000,
                                    divisions: 49,
                                    label: Fmt.meters(_radius),
                                    onChanged: (v) => setState(() => _radius = v),
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    Fmt.meters(_radius),
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 13,
                                      fontFeatures: AppTypography.tabular,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapSm,
                            Text('Type', style: label),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final t in GeofenceType.values)
                                  _RuleChip(
                                    icon: AppIcons.geofenceType(t),
                                    label: t.label,
                                    selected: _type == t,
                                    onTap: () => setState(() {
                                      final old = _type.label;
                                      _type = t;
                                      if (_name.text.isEmpty || _name.text == old) _name.text = t.label;
                                    }),
                                  ),
                              ],
                            ),
                            AppSpacing.gapMd,
                            Text('Alert on', style: label),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _RuleChip(
                                  icon: AppIcons.geofenceEnter,
                                  label: 'Enter',
                                  selected: _enter,
                                  onTap: () => setState(() => _enter = !_enter),
                                ),
                                _RuleChip(
                                  icon: AppIcons.geofenceExit,
                                  label: 'Exit',
                                  selected: _exit,
                                  onTap: () => setState(() => _exit = !_exit),
                                ),
                              ],
                            ),
                            AppSpacing.gapMd,
                            if (views.isNotEmpty) ...[
                              SizedBox(
                                height: 36,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    Center(child: Text('Centre on  ', style: label)),
                                    for (final v in (_devices.isEmpty ? views.take(6) : monitored.take(6)))
                                      if (v.position != null)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: ActionChip(
                                            avatar: Icon(AppIcons.asset(v.iconType), size: 14, color: tones.neutral400),
                                            label: Text(v.name),
                                            onPressed: () {
                                              setState(() => _center = v.position!);
                                              animateCamera(v.position!, 14);
                                            },
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                              AppSpacing.gapSm,
                            ],
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.symmetric(horizontal: BorderSide(color: tones.divider)),
                              ),
                              child: InkWell(
                                onTap: () => _pickDevices(views),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  child: Row(
                                    children: [
                                      Icon(AppIcons.devices, size: 19, color: tones.neutral400),
                                      AppSpacing.gapMd,
                                      Expanded(
                                        child: Text(
                                          'Devices',
                                          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                                        ),
                                      ),
                                      Text(
                                        _devices.isEmpty
                                            ? 'All devices (${views.length})'
                                            : '${_devices.length} selected',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 13,
                                          color: tones.neutral500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(AppIcons.chevronRight, size: 16, color: tones.neutral600),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            AppSpacing.gapMd,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(AppIcons.pin, size: 14, color: tones.neutral500),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Centre · $place',
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapMd,
                            FilledButton(
                              key: const Key('geofence-save'),
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                              onPressed: _busy ? null : _save,
                              child: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Glass control floating over the map.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding, this.alignment});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      constraints: const BoxConstraints(minWidth: 44),
      padding: padding,
      alignment: alignment ?? Alignment.center,
      decoration: BoxDecoration(
        color: context.tones.glass,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.hairline(Theme.of(context).brightness),
      ),
      child: child,
    );
  }
}

/// Pill toggle (32px): accent border and ink when on.
class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillAll,
            border: Border.all(color: selected ? theme.colorScheme.primary : context.tones.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevicePicker extends StatefulWidget {
  const _DevicePicker({required this.views, required this.selected});

  final List<DeviceView> views;
  final Set<String> selected;

  @override
  State<_DevicePicker> createState() => _DevicePickerState();
}

class _DevicePickerState extends State<_DevicePicker> {
  late final Set<String> _sel = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...widget.views]..sort((a, b) => a.name.compareTo(b.name));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: Row(
              children: [
                Expanded(child: Text('Monitor devices', style: theme.textTheme.titleLarge)),
                TextButton(onPressed: () => setState(_sel.clear), child: const Text('All devices')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final v in sorted)
                  CheckboxListTile(
                    value: _sel.contains(v.id),
                    onChanged: (c) => setState(() => c == true ? _sel.add(v.id) : _sel.remove(v.id)),
                    secondary: Icon(AppIcons.asset(v.iconType)),
                    title: Text(v.name),
                    subtitle: Text(v.id),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: AppSpacing.screenAll,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _sel),
                  child: Text(_sel.isEmpty ? 'Monitor all devices' : 'Monitor ${_sel.length} devices'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
