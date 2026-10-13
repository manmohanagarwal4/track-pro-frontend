import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../domain/device_status_engine.dart';
import '../../domain/device_view.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/status_style.dart';
import '../utils/formatters.dart';

/// Colored dot; pulses for live / emergency states.
class StatusDot extends StatefulWidget {
  const StatusDot({super.key, required this.color, this.pulse = false, this.size = 8});

  final Color color;
  final bool pulse;
  final double size;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot> with TickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StatusDot old) {
    super.didUpdateWidget(old);
    if (old.pulse != widget.pulse) _sync();
  }

  void _sync() {
    if (widget.pulse) {
      _c ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    } else {
      _c?.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    final c = _c;
    if (c == null) return dot;
    return SizedBox(
      width: widget.size * 2.2,
      height: widget.size * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: c,
            builder: (_, _) => Container(
              width: widget.size * (1 + c.value * 1.2),
              height: widget.size * (1 + c.value * 1.2),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.45 * (1 - c.value)),
                shape: BoxShape.circle,
              ),
            ),
          ),
          dot,
        ],
      ),
    );
  }
}

/// "● Moving" style badge.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.compact = false});

  final StatusSnapshot status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final color = tones.tone(StatusStyle.of(status));
    final tag = tones.tag(StatusStyle.of(status));
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: 3),
      decoration: BoxDecoration(
        color: tag.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(color: color, size: 6, pulse: status.isMoving || status.isEmergency),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              StatusStyle.label(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tag.ink, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet tile with the asset icon, ringed in its status color.
class DeviceAvatar extends StatelessWidget {
  const DeviceAvatar(this.view, {super.key, this.size = 46});

  final DeviceView view;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final color = tones.tone(StatusStyle.of(view.status));
    return AnimatedContainer(
      duration: AppDurations.medium,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tones.neutral800,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(AppIcons.asset(view.iconType), color: Theme.of(context).colorScheme.onSurface, size: size * 0.5),
    );
  }
}

class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator(this.level, {super.key, this.showLabel = true});

  final int? level;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = context.tones.tone(StatusStyle.battery(level));
    final l = (level ?? 0).clamp(0, 100);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 11,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.7), width: 1.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: l / 100,
              child: Container(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5)),
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 5),
          Text(level == null ? '--' : '$level%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ],
    );
  }
}

class SignalBars extends StatelessWidget {
  const SignalBars(this.quality, {super.key, this.color});

  final SignalQuality quality;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final active = color ?? (quality.bars >= 3 ? tones.ok : quality.bars >= 2 ? tones.warn : tones.crit);
    final inactive = tones.neutral700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            width: 3,
            height: 4.0 + i * 2.6,
            decoration: BoxDecoration(
              color: i < quality.bars ? active : inactive,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          if (i < 3) const SizedBox(width: 1.5),
        ],
      ],
    );
  }
}

/// Text that refreshes itself ("8 seconds ago").
class TimeAgoText extends StatefulWidget {
  const TimeAgoText(this.time, {super.key, this.style, this.prefix = '', this.short = false});

  final DateTime? time;
  final TextStyle? style;
  final String prefix;
  final bool short;

  @override
  State<TimeAgoText> createState() => _TimeAgoTextState();
}

class _TimeAgoTextState extends State<TimeAgoText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.time;
    final text = t == null
        ? 'never'
        : widget.short
            ? Fmt.timeAgoShort(t)
            : Fmt.timeAgo(t);
    return Text('${widget.prefix}$text', style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
