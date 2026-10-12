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
import '../../../core/theme/status_style.dart';
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Create Geofence' : 'Edit Geofence'),
        actions: [
          if (_existing != null)
            IconButton(onPressed: _delete, icon: const Icon(AppIcons.delete, color: AppColors.emergency)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          ResponsiveCenter(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.lgAll,
                    child: SizedBox(
                      height: 280,
                      child: Stack(
                        children: [
                          TrackerMap(
                            controller: _controller,
                            devices: monitored,
                            geofences: [draft],
                            highlightGeofenceId: draft.id,
                            initialCenter: _center,
                            initialZoom: 14,
                            onTap: (_, p) => setState(() => _center = p),
                          ),
                          Positioned(
                            left: AppSpacing.md,
                            top: AppSpacing.md,
                            right: AppSpacing.md,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.94),
                                borderRadius: AppRadius.mdAll,
                              ),
                              child: Text('Tap the map to place the centre · $place',
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
                            ),
                          ),
                          Positioned(
                            right: AppSpacing.md,
                            bottom: AppSpacing.md,
                            child: Column(
                              children: [
                                MapButton(
                                  icon: AppIcons.locate,
                                  tooltip: 'My location',
                                  onPressed: () {
                                    setState(() => _center = NcrGeo.userLocation);
                                    animateCamera(NcrGeo.userLocation, 14);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (views.isNotEmpty) ...[
                    AppSpacing.gapSm,
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Text('Centre on: ', style: theme.textTheme.bodySmall),
                          for (final v in (_devices.isEmpty ? views.take(6) : monitored.take(6)))
                            if (v.position != null)
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm),
                                child: ActionChip(
                                  avatar: Icon(AppIcons.asset(v.iconType), size: 14),
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
                  ],
                  AppSpacing.gapLg,
                  Text('Name', style: theme.textTheme.titleSmall),
                  AppSpacing.gapSm,
                  TextField(
                    key: const Key('geofence-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: 'e.g. Home'),
                  ),
                  AppSpacing.gapLg,
                  Text('Type', style: theme.textTheme.titleSmall),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final t in GeofenceType.values)
                        ChoiceChip(
                          avatar: Icon(AppIcons.geofenceType(t), size: 16, color: StatusStyle.geofence(t)),
                          label: Text(t.label),
                          selected: _type == t,
                          onSelected: (_) => setState(() {
                            final old = _type.label;
                            _type = t;
                            if (_name.text.isEmpty || _name.text == old) _name.text = t.label;
                          }),
                        ),
                    ],
                  ),
                  AppSpacing.gapLg,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Shape', style: theme.textTheme.titleSmall),
                            const Spacer(),
                            const Pill(label: 'Circle', color: AppColors.iris, icon: AppIcons.circle),
                          ],
                        ),
                        AppSpacing.gapMd,
                        Row(
                          children: [
                            Text('Radius', style: theme.textTheme.titleSmall),
                            const Spacer(),
                            Text(Fmt.meters(_radius), style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                          ],
                        ),
                        Slider(
                          key: const Key('geofence-radius'),
                          value: _radius,
                          min: 100,
                          max: 5000,
                          divisions: 49,
                          label: Fmt.meters(_radius),
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  Text('Events', style: theme.textTheme.titleSmall),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: _enter,
                          onChanged: (v) => setState(() => _enter = v ?? false),
                          title: const Text('Enter'),
                          subtitle: const Text('Alert when a device arrives'),
                          secondary: const Icon(AppIcons.geofenceEnter),
                        ),
                        CheckboxListTile(
                          value: _exit,
                          onChanged: (v) => setState(() => _exit = v ?? false),
                          title: const Text('Exit'),
                          subtitle: const Text('Alert when a device leaves'),
                          secondary: const Icon(AppIcons.geofenceExit),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  Text('Devices', style: theme.textTheme.titleSmall),
                  AppSpacing.gapSm,
                  AppCard(
                    onTap: () => _pickDevices(views),
                    child: Row(
                      children: [
                        const Icon(AppIcons.devices, size: 20),
                        AppSpacing.gapMd,
                        Expanded(
                          child: Text(
                            _devices.isEmpty ? 'All devices (${views.length})' : '${_devices.length} selected',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const Icon(AppIcons.chevronRight, size: 18),
                      ],
                    ),
                  ),
                  AppSpacing.gapXxl,
                  FilledButton(
                    key: const Key('geofence-save'),
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ],
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
