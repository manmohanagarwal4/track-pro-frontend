import 'package:clock/clock.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';

abstract final class Fmt {
  static const _kmToMiles = 0.621371;

  static double convertDistance(double km, DistanceUnit unit) =>
      unit == DistanceUnit.km ? km : km * _kmToMiles;

  static String distance(double km, DistanceUnit unit, {int? decimals}) {
    final v = convertDistance(km, unit);
    if (unit == DistanceUnit.km && v < 1 && decimals == null) {
      return '${(v * 1000).round()} m';
    }
    return '${v.toStringAsFixed(decimals ?? (v >= 100 ? 0 : 1))} ${unit.short}';
  }

  static String speed(double kmh, DistanceUnit unit) =>
      '${convertDistance(kmh, unit).round()} ${unit.speed}';

  static String speedValue(double kmh, DistanceUnit unit) =>
      convertDistance(kmh, unit).round().toString();

  static String meters(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(m >= 10000 ? 0 : 1)} km' : '${m.round()} m';

  static String duration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String timeAgo(DateTime t, {DateTime? now}) {
    final diff = (now ?? clock.now()).difference(t);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds} seconds ago';
    if (diff.inMinutes < 60) {
      return diff.inMinutes == 1 ? '1 minute ago' : '${diff.inMinutes} minutes ago';
    }
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays < 7) return diff.inDays == 1 ? 'yesterday' : '${diff.inDays} days ago';
    return DateFormat('d MMM yyyy').format(t);
  }

  static String timeAgoShort(DateTime t, {DateTime? now}) {
    final diff = (now ?? clock.now()).difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds.clamp(0, 59)}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  static String time(DateTime t) => DateFormat('hh:mm a').format(t);
  static String date(DateTime t) => DateFormat('d MMM yyyy').format(t);
  static String dateShort(DateTime t) => DateFormat('EEE, d MMM').format(t);
  static String dateTime(DateTime t) => DateFormat('d MMM, hh:mm a').format(t);

  static String dayLabel(DateTime t, {DateTime? now}) {
    final n = now ?? clock.now();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return dateShort(t);
  }

  static String coordinates(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
