import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Nocturne theme, dark and light. Primary actions are accent-outlined
/// rather than filled; surfaces are flat tiles on the ground, separated by
/// hairline dividers.
abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A5DB3),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF6A5DB3),
          onPrimary: AppColors.white,
          primaryContainer: AppTones.light.accent800,
          onPrimaryContainer: AppTones.light.accent100,
          secondary: const Color(0xFF5D5294),
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
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: ColorScheme.fromSeed(
          seedColor: AppColors.irisLight,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.irisLight,
          onPrimary: AppColors.darkBackground,
          primaryContainer: AppTones.dark.accent800,
          onPrimaryContainer: AppTones.dark.accent100,
          secondary: AppColors.signal,
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
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required AppTones tones,
  }) {
    final text = AppTypography.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final accent = scheme.primary;
    final divider = tones.divider;

    // `.btn-primary`: accent text on a transparent ground, accent outline.
    final primaryButton = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.mdAll)),
      textStyle: WidgetStatePropertyAll(text.labelLarge?.copyWith(fontSize: 15)),
      elevation: const WidgetStatePropertyAll(0),
      iconSize: const WidgetStatePropertyAll(18),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? accent.withValues(alpha: 0.45) : accent,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? accent.withValues(alpha: 0.45) : accent,
      ),
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.pressed)) return accent.withValues(alpha: 0.22);
        if (s.contains(WidgetState.hovered)) return accent.withValues(alpha: 0.12);
        return AppColors.transparent;
      }),
      overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: 0.08)),
      side: WidgetStateProperty.resolveWith(
        (s) => BorderSide(color: s.contains(WidgetState.disabled) ? accent.withValues(alpha: 0.45) : accent),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: text,
      extensions: [tones],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
        floatingLabelStyle: text.bodySmall?.copyWith(color: accent),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: tones.neutral500,
        suffixIconColor: tones.neutral500,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
        selectionHandleColor: accent,
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      // `.btn-secondary`: text-colored, hairline divider outline.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          foregroundColor: scheme.onSurface,
          iconColor: scheme.onSurface,
          iconSize: 18,
          side: BorderSide(color: divider),
          textStyle: text.labelLarge,
        ),
      ),
      // `.btn-ghost`.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tones.glass,
        foregroundColor: accent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: text.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: accent),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.mdAll)),
          side: WidgetStatePropertyAll(BorderSide(color: divider)),
          textStyle: WidgetStatePropertyAll(text.bodySmall?.copyWith(fontSize: 13)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : scheme.onSurface,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent.withValues(alpha: 0.12) : AppColors.transparent,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        side: BorderSide(color: divider),
        backgroundColor: AppColors.transparent,
        selectedColor: accent.withValues(alpha: 0.12),
        secondarySelectedColor: accent.withValues(alpha: 0.12),
        labelStyle: text.bodySmall?.copyWith(fontSize: 12.5, color: scheme.onSurface),
        secondaryLabelStyle: text.bodySmall?.copyWith(fontSize: 12.5, color: accent),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        showCheckmark: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: AppColors.transparent,
        modalBarrierColor: tones.neutral900.withValues(alpha: 0.6),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        showDragHandle: true,
        dragHandleColor: tones.neutral700,
        dragHandleSize: const Size(38, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: AppColors.transparent,
        barrierColor: tones.neutral900.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        titleTextStyle: text.titleLarge,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: divider),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tones.glass,
        surfaceTintColor: AppColors.transparent,
        indicatorColor: AppColors.transparent,
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
          (s) => IconThemeData(
            size: 23,
            color: s.contains(WidgetState.selected) ? accent : tones.neutral500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: accent.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: tones.neutral500),
        selectedLabelTextStyle: text.labelSmall?.copyWith(color: accent),
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
        textColor: background,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: brightness == Brightness.dark ? const Color(0xFF595D6C) : const Color(0xFFCFD3E5),
          ),
        ),
        backgroundColor: scheme.surface,
        contentTextStyle: text.bodyMedium?.copyWith(fontSize: 13, color: scheme.onSurface),
        actionTextColor: accent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tones.neutral400,
        textColor: scheme.onSurface,
        titleTextStyle: text.bodyLarge?.copyWith(fontSize: 15),
        subtitleTextStyle: text.bodySmall?.copyWith(fontSize: 12, color: tones.neutral500),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Color(0xFFF3F5FE)),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : tones.neutral800,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.transparent),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : divider,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : AppColors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(background),
        side: BorderSide(color: tones.neutral600, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      ),
      sliderTheme: SliderThemeData(
        showValueIndicator: ShowValueIndicator.onDrag,
        activeTrackColor: accent,
        inactiveTrackColor: tones.neutral800,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: tones.neutral800,
        circularTrackColor: AppColors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: divider),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onSurface),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
