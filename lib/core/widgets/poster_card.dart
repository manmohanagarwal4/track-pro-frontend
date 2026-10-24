import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Crimson hero panel filled with oversized ghost lettering that drifts in
/// alternating directions, row by row — kinetic type behind hero content.
class PosterCard extends StatefulWidget {
  const PosterCard({
    super.key,
    this.word = 'TRACK',
    this.radius = AppRadius.xlAll,
    this.fontSize = 76,
    this.child,
  });

  final String word;
  final BorderRadius radius;
  final double fontSize;
  final Widget? child;

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppTypography.family,
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w800,
      height: 0.92,
      letterSpacing: -1,
    );
    // Width of one "WORD " so each row can loop seamlessly by exactly that much.
    final painter = TextPainter(
      text: TextSpan(text: '${widget.word} ', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final unit = painter.width;
    painter.dispose();
    final line = List.filled(8, widget.word).join(' ');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.radius,
        boxShadow: AppShadows.glow(AppColors.crimson, strength: 0.8),
      ),
      child: ClipRRect(
        borderRadius: widget.radius,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEA4651), Color(0xFFD02F3A), Color(0xFFB81D30)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, _) => OverflowBox(
                      alignment: Alignment.topLeft,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var row = 0; row < 5; row++)
                            Transform.translate(
                              offset: Offset(row.isEven ? -unit * _c.value : -unit * (1 - _c.value), 0),
                              child: Text(
                                line,
                                maxLines: 1,
                                softWrap: false,
                                style: style.copyWith(
                                  color: AppColors.white.withValues(alpha: row.isEven ? 0.2 : 0.32),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        ),
      ),
    );
  }
}
