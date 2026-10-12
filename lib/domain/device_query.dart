import '../data/models/enums.dart';
import 'device_status_engine.dart';
import 'device_view.dart';

/// Search / filter / sort criteria for device lists.
class DeviceQuery {
  const DeviceQuery({
    this.text = '',
    this.status = StatusFilter.all,
    this.asset = AssetFilter.all,
    this.sort = DeviceSort.status,
  });

  final String text;
  final StatusFilter status;
  final AssetFilter asset;
  final DeviceSort sort;

  bool get isFiltered => text.isNotEmpty || status != StatusFilter.all || asset != AssetFilter.all;

  DeviceQuery copyWith({
    String? text,
    StatusFilter? status,
    AssetFilter? asset,
    DeviceSort? sort,
  }) =>
      DeviceQuery(
        text: text ?? this.text,
        status: status ?? this.status,
        asset: asset ?? this.asset,
        sort: sort ?? this.sort,
      );

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');

  /// Matches device name, device ID, IMEI, asset name, registration and driver.
  static bool matchesText(DeviceView v, String text) {
    final q = _norm(text.trim());
    if (q.isEmpty) return true;
    final fields = [
      v.name,
      v.device.id,
      v.device.imei,
      v.asset?.name,
      v.registration,
      v.driver?.name,
      v.type.label,
    ];
    return fields.any((f) => f != null && _norm(f).contains(q));
  }

  List<DeviceView> apply(Iterable<DeviceView> source) {
    final out = source.where((v) {
      if (asset != AssetFilter.all && v.type.filterGroup != asset) return false;
      if (!DeviceStatusEngine.matchesFilter(v.status, status)) return false;
      return matchesText(v, text);
    }).toList();
    out.sort(_comparator(sort));
    return out;
  }

  static int Function(DeviceView, DeviceView) _comparator(DeviceSort sort) {
    int byName(DeviceView a, DeviceView b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return switch (sort) {
      DeviceSort.name => byName,
      DeviceSort.status => (a, b) {
          final c = a.status.priority.compareTo(b.status.priority);
          return c != 0 ? c : byName(a, b);
        },
      DeviceSort.speed => (a, b) {
          final c = b.speedKmh.compareTo(a.speedKmh);
          return c != 0 ? c : byName(a, b);
        },
      DeviceSort.battery => (a, b) {
          final c = (a.battery ?? 101).compareTo(b.battery ?? 101);
          return c != 0 ? c : byName(a, b);
        },
      DeviceSort.lastUpdate => (a, b) {
          final ta = a.lastUpdate?.millisecondsSinceEpoch ?? 0;
          final tb = b.lastUpdate?.millisecondsSinceEpoch ?? 0;
          final c = tb.compareTo(ta);
          return c != 0 ? c : byName(a, b);
        },
    };
  }
}
