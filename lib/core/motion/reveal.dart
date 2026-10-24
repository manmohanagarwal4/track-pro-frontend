import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_spacing.dart';

/// Fades and lifts its child into place the first time it is laid out.
///
/// With no explicit [delay] the delay is taken from where the child lands on
/// screen, so a column of cards cascades top to bottom without any index
/// bookkeeping. Children that first appear below the fold (pre-built in a
/// list's cache extent) show immediately.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay,
    this.offset = 22,
    this.duration = AppDurations.reveal,
    this.enabled = true,
  });

  final Widget child;
  final Duration? delay;

  /// Distance in logical pixels the child rises from.
  final double offset;
  final Duration duration;
  final bool enabled;

  /// Longest automatic delay, for a child at the bottom of the screen.
  static const maxCascade = Duration(milliseconds: 260);

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  Animation<double> _t = kAlwaysCompleteAnimation;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _c.value = 1;
      return;
    }
    _t = CurvedAnimation(parent: _c, curve: AppCurves.enter);
    SchedulerBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
      return;
    }
    var delay = widget.delay;
    if (delay == null) {
      final box = context.findRenderObject() as RenderBox?;
      final screen = MediaQuery.sizeOf(context).height;
      if (box == null || !box.hasSize || !box.attached || screen <= 0) {
        delay = Duration.zero;
      } else {
        final top = box.localToGlobal(Offset.zero).dy;
        if (top >= screen) {
          _c.value = 1;
          return;
        }
        delay = Reveal.maxCascade * (top / screen).clamp(0.0, 1.0);
      }
    }
    // Fold the delay into the timeline instead of a Timer, so nothing is left
    // pending when the widget goes away.
    final total = delay + widget.duration;
    _c.duration = total;
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: AppCurves.enter),
    );
    setState(() {});
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      // Same widget structure at every t, so the child's state survives the
      // end of the animation.
      builder: (_, child) {
        final t = _t.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: Transform.scale(scale: 0.97 + 0.03 * t, child: child),
          ),
        );
      },
    );
  }
}
