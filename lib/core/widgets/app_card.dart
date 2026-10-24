import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/reveal.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The standard surface: a frosted glass tile — plum-tinted at the top-left
/// fading to navy, with a lit rim and a deep soft shadow.
///
/// Tappable cards squash on press, bloom an accent glow around the rim and
/// tick a selection haptic. Every card rises into place on first layout
/// (see [Reveal]); pass `reveal: false` for cards that are rebuilt often.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.card,
    this.color,
    this.radius = AppRadius.lgAll,
    this.border,
    this.reveal = true,
    this.blur = 0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// A flat fill instead of the glass gradient.
  final Color? color;
  final BorderRadius radius;

  /// Replaces the glass rim (e.g. to mark a selected card).
  final BoxBorder? border;
  final bool reveal;

  /// Frosts whatever is behind the card. Costly; for cards that overlap
  /// busy content, not for list rows.
  final double blur;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;
  bool _hovered = false;

  void _tap() {
    HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tones = context.tones;
    final tappable = widget.onTap != null;
    final active = tappable && (_pressed || _hovered);
    final accent = theme.colorScheme.primary;
    // Inside a grouped surface the group already draws the glass; this card
    // is just a row, tinted while active.
    final grouped = GlassGroup.contains(context);

    final shadows = active ? AppShadows.cardActive(theme.brightness, accent) : AppShadows.card(theme.brightness);
    final frosted = widget.blur > 0 && !grouped;

    Widget card = AnimatedContainer(
      duration: AppDurations.medium,
      curve: Curves.easeOut,
      decoration: grouped
          ? BoxDecoration(
              color: active ? accent.withValues(alpha: 0.08) : AppColors.transparent,
              borderRadius: widget.radius,
            )
          : BoxDecoration(
              color: widget.color,
              gradient: widget.color == null ? tones.glassGradient : null,
              borderRadius: widget.radius,
              border: widget.border,
              boxShadow: frosted ? null : shadows,
            ),
      child: CustomPaint(
        foregroundPainter: widget.border == null && !grouped
            ? GlassRimPainter(
                radius: widget.radius,
                highlight: active ? accent.withValues(alpha: 0.7) : tones.glassHighlight,
                edge: active ? accent.withValues(alpha: 0.25) : tones.glassBorder,
              )
            : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: tappable ? _tap : null,
            onHighlightChanged: tappable ? (v) => setState(() => _pressed = v) : null,
            onHover: tappable ? (v) => setState(() => _hovered = v) : null,
            borderRadius: widget.radius,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
    if (frosted) {
      card = DecoratedBox(
        decoration: BoxDecoration(borderRadius: widget.radius, boxShadow: shadows),
        child: ClipRRect(
          borderRadius: widget.radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: card,
          ),
        ),
      );
    }
    final pressed = tappable && _pressed;
    return Reveal(
      enabled: widget.reveal && !grouped,
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1,
        duration: pressed ? const Duration(milliseconds: 110) : const Duration(milliseconds: 420),
        curve: pressed ? Curves.easeOutCubic : AppCurves.spring,
        child: card,
      ),
    );
  }
}

/// Marks a subtree that already sits on a glass surface (a grouped list
/// row), so [AppCard]s inside it render as flat rows instead of nested cards.
class GlassGroup extends InheritedWidget {
  const GlassGroup({super.key, required super.child});

  static bool contains(BuildContext context) => context.getInheritedWidgetOfExactType<GlassGroup>() != null;

  @override
  bool updateShouldNotify(GlassGroup oldWidget) => false;
}

/// Glass rim: a 1px stroke that is brightest along the top-left edge, where
/// light catches the glass, and fades to a faint edge at the bottom-right.
class GlassRimPainter extends CustomPainter {
  const GlassRimPainter({required this.radius, required this.highlight, required this.edge});

  final BorderRadius radius;
  final Color highlight;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    canvas.drawRRect(
      radius.toRRect(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, edge, edge],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(GlassRimPainter old) => old.radius != radius || old.highlight != highlight || old.edge != edge;
}

/// Uppercase tracked section label with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 18, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(), style: AppTypography.overline.copyWith(color: context.tones.neutral500)),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 12.5),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// Constrains content width on tablets / desktop browsers.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = AppSpacing.maxContentWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Small tonal tag (`.tag`): tinted ground, deep ink.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color, this.icon, this.filled = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final tag = tones.tag(color);
    final fg = filled ? Theme.of(context).colorScheme.surface : tag.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? tones.tone(color) : tag.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.25)),
        boxShadow: filled ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

/// Rounded square icon tile, tinted by [color].
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tag = context.tones.tag(color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(tag.bg, color, 0.25)!, tag.bg],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: size * 0.4, offset: Offset(0, size * 0.1)),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: tag.ink),
    );
  }
}
