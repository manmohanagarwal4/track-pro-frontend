import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../data/models/driver.dart';
import '../../../domain/device_query.dart';
import '../../devices/application/devices_controller.dart';
import '../../devices/presentation/widgets/device_card.dart';
import '../application/drivers_controller.dart';

Future<void> showAssignVehicleSheet(BuildContext context, Driver driver) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssignVehicleSheet(driver: driver),
    );

class _AssignVehicleSheet extends ConsumerStatefulWidget {
  const _AssignVehicleSheet({required this.driver});

  final Driver driver;

  @override
  ConsumerState<_AssignVehicleSheet> createState() => _AssignVehicleSheetState();
}

class _AssignVehicleSheetState extends ConsumerState<_AssignVehicleSheet> {
  String _text = '';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final views = ref.watch(allDeviceViewsProvider).value ?? const [];
    final vehicles = DeviceQuery(text: _text).apply(views.where((v) => v.type.isVehicle && v.asset != null)).toList()
      ..sort((a, b) {
        final fa = a.driver == null ? 0 : 1;
        final fb = b.driver == null ? 0 : 1;
        return fa != fb ? fa - fb : a.name.compareTo(b.name);
      });
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: Text('Assign vehicle to ${widget.driver.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.4)),
          ),
          AppSpacing.gapMd,
          Padding(
            padding: AppSpacing.screen,
            child: SearchField(hint: 'Search vehicles', onChanged: (t) => setState(() => _text = t)),
          ),
          AppSpacing.gapSm,
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: vehicles.isEmpty
                ? const LoadingView(message: 'Loading vehicles...')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.xl),
                    itemCount: vehicles.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, indent: AppSpacing.sm, endIndent: AppSpacing.sm, color: tones.divider),
                    itemBuilder: (_, i) {
                      final v = vehicles[i];
                      final current = v.driver?.id == widget.driver.id;
                      return ListTile(
                        key: Key('assign-${v.id}'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        leading: DeviceAvatar(v, size: 40),
                        title: Text(v.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          v.driver == null ? '${v.registration ?? v.id} · No driver' : '${v.registration ?? v.id} · ${v.driver!.name}',
                        ),
                        trailing: current ? const Pill(label: 'Current', color: AppColors.iris) : null,
                        onTap: current || _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                await ref.read(driversProvider.notifier).assign(widget.driver.id, v.asset!.id);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${widget.driver.name} assigned to ${v.name}')),
                                );
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
