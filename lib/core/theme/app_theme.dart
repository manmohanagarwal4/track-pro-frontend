import 'package:flutter/material.dart';

import '../motion/page_transitions.dart';
import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Crimson Night theme, dark and light. Primary actions are glowing crimson
/// pills; surfaces are frosted glass floating over an ambient backdrop, so
/// scaffolds are transparent. Every control answers a press with motion.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    scheme: ColorScheme.fromSeed(seedColor: AppColors.crimsonDeep, brightness: Brightness.light).copyWith(
      primary: AppColors.crimsonDeep,
      onPrimary: AppColors.white,
      primaryContainer: AppTones.light.accent800,
      onPrimaryContainer: AppTones.light.accent100,
      secondary: const Color(0xFF8A2B4A),
      onSecondary: AppColors.white,
      tertiary: AppTones.light.ok,
      error: AppTones.light.crit,
      errorContainer: AppTones.light.critBg,
      onErrorContainer: AppTones.light.critInk,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      onSurfaceVariant: AppColors.lightTextMuted,
      surfaceContainerLowest: AppColors.lightBackground,
      surfaceContainerLow: AppColors.lightSurface,
      surfaceContainer: AppColors.lightSurface,
      surfaceContainerHigh: AppColors.lightSurfaceHigh,
      surfaceContainerHighest: AppColors.lightSurfaceHigh,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutline,
      inverseSurface: AppColors.lightText,
      onInverseSurface: AppColors.lightSurface,
    ),
    background: AppColors.lightBackground,
    tones: AppTones.light,
    buttonGradient: const [AppColors.crimson, AppColors.crimsonDeep],
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scheme: ColorScheme.fromSeed(seedColor: AppColors.crimsonLight, brightness: Brightness.dark).copyWith(
      primary: AppColors.crimsonLight,
      onPrimary: AppColors.white,
      primaryContainer: AppTones.dark.accent800,
      onPrimaryContainer: AppTones.dark.accent100,
      secondary: AppColors.rose,
      onSecondary: AppColors.darkBackground,
      tertiary: AppTones.dark.ok,
      error: AppTones.dark.crit,
      errorContainer: AppTones.dark.critBg,
      onErrorContainer: AppTones.dark.critInk,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkTextMuted,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurfaceHigh,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutline,
      inverseSurface: AppColors.darkText,
      onInverseSurface: AppColors.darkBackground,
    ),
    background: AppColors.darkBackground,
    tones: AppTones.dark,
    buttonGradient: const [AppColors.crimsonLight, Color(0xFFD42A3C)],
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required AppTones tones,
    required List<Color> buttonGradient,
  }) {
    final dark = brightness == Brightness.dark;
    final text = AppTypography.textTheme.apply(
      fontFamily: AppTypography.family,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final accent = scheme.primary;
    final divider = tones.divider;
    final glassFill = dark ? const Color(0x0FFFFFFF) : const Color(0xB3FFFFFF);
    final sheetColor = dark ? const Color(0xF2161833) : const Color(0xF7FFFFFF);
    const buttonRadius = BorderRadius.all(Radius.circular(14));
    const pressIn = Duration(milliseconds: 110);
    const pressOut = Duration(milliseconds: 420);

    // Squash on press, spring back on release.
    Widget pressScale(Set<WidgetState> s, Widget? child, {double to = 0.95}) {
      final down = s.contains(WidgetState.pressed);
      return AnimatedScale(
        scale: down ? to : 1,
        duration: down ? pressIn : pressOut,
        curve: down ? Curves.easeOutCubic : AppCurves.spring,
        child: child,
      );
    }

    // `.btn-primary`: a crimson gradient pill that glows, brighter on hover,
    // tighter while pressed.
    final primaryButton = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: buttonRadius)),
      textStyle: WidgetStatePropertyAll(
        text.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
      elevation: const WidgetStatePropertyAll(0),
      iconSize: const WidgetStatePropertyAll(18),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? scheme.onSurface.withValues(alpha: 0.4) : AppColors.white,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? scheme.onSurface.withValues(alpha: 0.4) : AppColors.white,
      ),
      backgroundColor: const WidgetStatePropertyAll(AppColors.transparent),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.pressed)
            ? AppColors.white.withValues(alpha: 0.14)
            : AppColors.white.withValues(alpha: 0.06),
      ),
      backgroundBuilder: (context, s, child) {
        final disabled = s.contains(WidgetState.disabled);
        final hovered = s.contains(WidgetState.hovered) || s.contains(WidgetState.focused);
        final pressed = s.contains(WidgetState.pressed);
        return pressScale(
          s,
          AnimatedContainer(
            duration: AppDurations.medium,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: buttonRadius,
              color: disabled ? tones.neutral800 : null,
              gradient: disabled
                  ? null
                  : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: buttonGradient),
              boxShadow: disabled
                  ? const []
                  : AppShadows.glow(accent, strength: pressed ? 0.55 : (hovered ? 1.25 : 0.9)),
            ),
            child: child,
          ),
        );
      },
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.family,
      // Pages paint their own AmbientBackdrop (see page_transitions.dart).
      scaffoldBackgroundColor: AppColors.transparent,
      canvasColor: background,
      textTheme: text,
      extensions: [tones],
      splashFactory: InkSparkle.splashFactory,
      splashColor: accent.withValues(alpha: 0.16),
      highlightColor: accent.withValues(alpha: 0.06),
      hoverColor: accent.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: glassFill,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: tones.glassBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: tones.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: tones.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
        floatingLabelStyle: text.bodySmall?.copyWith(color: accent),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? accent : tones.neutral500,
        ),
        suffixIconColor: tones.neutral500,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
        selectionHandleColor: accent,
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      // `.btn-secondary`: frosted glass with a hairline rim.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: const Size(64, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
              foregroundColor: scheme.onSurface,
              iconColor: scheme.onSurface,
              backgroundColor: glassFill,
              iconSize: 18,
              side: BorderSide(color: tones.glassBorder),
              textStyle: text.labelLarge,
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (s) => BorderSide(
                  color: s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)
                      ? accent.withValues(alpha: 0.6)
                      : tones.glassBorder,
                ),
              ),
              foregroundBuilder: (context, s, child) => pressScale(s, child, to: 0.92),
            ),
      ),
      // `.btn-ghost`.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: text.labelLarge,
        ).copyWith(foregroundBuilder: (context, s, child) => pressScale(s, child, to: 0.9)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ).copyWith(foregroundBuilder: (context, s, child) => pressScale(s, child, to: 0.82)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: AppColors.white,
        elevation: 10,
        focusElevation: 12,
        hoverElevation: 14,
        highlightElevation: 4,
        extendedTextStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.mdAll)),
          side: WidgetStatePropertyAll(BorderSide(color: tones.glassBorder)),
          textStyle: WidgetStatePropertyAll(text.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.white : scheme.onSurface,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : glassFill,
          ),
          foregroundBuilder: (context, s, child) => pressScale(s, child, to: 0.9),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        side: BorderSide(color: tones.glassBorder),
        backgroundColor: glassFill,
        selectedColor: accent.withValues(alpha: 0.2),
        secondarySelectedColor: accent.withValues(alpha: 0.2),
        labelStyle: text.bodySmall?.copyWith(fontSize: 12.5, color: scheme.onSurface),
        secondaryLabelStyle: text.bodySmall?.copyWith(fontSize: 12.5, color: accent, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        showCheckmark: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetColor,
        modalBackgroundColor: sheetColor,
        surfaceTintColor: AppColors.transparent,
        modalBarrierColor: tones.neutral900.withValues(alpha: 0.65),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sheet,
          side: BorderSide(color: tones.glassBorder),
        ),
        showDragHandle: true,
        dragHandleColor: accent.withValues(alpha: 0.6),
        dragHandleSize: const Size(42, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheetColor,
        surfaceTintColor: AppColors.transparent,
        barrierColor: tones.neutral900.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlAll,
          side: BorderSide(color: tones.glassBorder),
        ),
        titleTextStyle: text.titleLarge,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: sheetColor,
        surfaceTintColor: AppColors.transparent,
        elevation: 12,
        shadowColor: tones.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: tones.glassBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tones.glass,
        surfaceTintColor: AppColors.transparent,
        indicatorColor: accent.withValues(alpha: 0.18),
        elevation: 0,
        height: 62,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0,
            color: s.contains(WidgetState.selected) ? accent : tones.neutral500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 23, color: s.contains(WidgetState.selected) ? accent : tones.neutral500),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tones.glass,
        indicatorColor: accent.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: tones.neutral500),
        selectedLabelTextStyle: text.labelSmall?.copyWith(color: accent, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: text.labelSmall?.copyWith(color: tones.neutral500),
        labelType: NavigationRailLabelType.all,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: tones.neutral500,
        indicatorColor: accent,
        dividerColor: divider,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.bodyMedium,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: tones.crit,
        textColor: AppColors.white,
        textStyle: const TextStyle(fontFamily: AppTypography.family, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        backgroundColor: sheetColor,
        contentTextStyle: text.bodyMedium?.copyWith(fontSize: 13.5, color: scheme.onSurface),
        actionTextColor: accent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tones.neutral400,
        textColor: scheme.onSurface,
        titleTextStyle: text.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : tones.neutral800,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
        overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.14)),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : tones.neutral600),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : AppColors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: BorderSide(color: tones.neutral600, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
      ),
      sliderTheme: SliderThemeData(
        showValueIndicator: ShowValueIndicator.onDrag,
        activeTrackColor: accent,
        inactiveTrackColor: tones.neutral800,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.16),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: tones.neutral800,
        circularTrackColor: AppColors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: tones.glassBorder),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onSurface),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: DepthPageTransitionsBuilder(),
          TargetPlatform.fuchsia: DepthPageTransitionsBuilder(),
          TargetPlatform.iOS: BackdropCupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: BackdropCupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: DepthPageTransitionsBuilder(),
          TargetPlatform.linux: DepthPageTransitionsBuilder(),
        },
      ),
    );
  }
}
