import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Squashes its child while a pointer is down and springs it back on release.
///
/// Purely visual: it listens to raw pointer events so it never competes with
/// the child's own tap handling in the gesture arena.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.96, this.enabled = true});

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? const Duration(milliseconds: 110) : const Duration(milliseconds: 420),
        curve: _down ? Curves.easeOutCubic : AppCurves.spring,
        child: widget.child,
      ),
    );
  }
}
