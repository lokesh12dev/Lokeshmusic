/*
 *     Copyright (C) 2026 Lokesh
 *
 *     Lokeshmusic is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Lokeshmusic is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Lokeshmusic, including how to contribute,
 *     please visit: https://github.com/lokesh/Lokeshmusic
 */

import 'package:flutter/scheduler.dart';
import 'package:lokeshmusic/services/settings_manager.dart';
import 'package:lokeshmusic/theme/design_tokens.dart';
import 'package:material_ui/material_ui.dart';

ThemeMode themeMode = getThemeMode(themeModeSetting);
Brightness brightness = getBrightnessFromThemeMode(themeMode);

Brightness getBrightnessFromThemeMode(ThemeMode themeMode) {
  final themeBrightnessMapping = {
    ThemeMode.light: Brightness.light,
    ThemeMode.dark: Brightness.dark,
    ThemeMode.system:
        SchedulerBinding.instance.platformDispatcher.platformBrightness,
  };

  return themeBrightnessMapping[themeMode] ?? Brightness.dark;
}

ThemeMode getThemeMode(int themeModeIndex) {
  const themeModes = ThemeMode.values;
  if (themeModeIndex >= 0 && themeModeIndex < themeModes.length) {
    return themeModes[themeModeIndex];
  }
  return ThemeMode.system;
}

/// Builds the effective ColorScheme.
///
/// When the user opts into system (Material You) colors and the platform
/// provides a dynamic scheme, that scheme wins. Otherwise we generate a
/// Spotify-inspired scheme: flat neutral surfaces stepped up from
/// #121212, with the chosen accent color on top.
ColorScheme getAppColorScheme(
  ColorScheme? lightColorScheme,
  ColorScheme? darkColorScheme,
) {
  final selectedScheme = (brightness == Brightness.light)
      ? lightColorScheme
      : darkColorScheme;

  if (useSystemColor.value && selectedScheme != null) {
    return selectedScheme;
  } else {
    return _spotifyColorScheme(brightness, primaryColorSetting);
  }
}

/// Spotify-inspired color scheme: neutral dark surfaces, bold accent.
ColorScheme _spotifyColorScheme(Brightness themeBrightness, Color accent) {
  final base = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: themeBrightness,
  );

  // Black label-on-accent when the accent is light enough (green passes).
  final onAccent =
      accent.computeLuminance() > 0.175 ? Colors.black : Colors.white;

  if (themeBrightness == Brightness.dark) {
    return base.copyWith(
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: accent,
      onPrimaryContainer: onAccent,
      secondaryContainer: SpotifyPalette.card,
      onSecondaryContainer: SpotifyPalette.textPrimary,
      surface: SpotifyPalette.base,
      surfaceContainerLowest: SpotifyPalette.lowest,
      surfaceContainerLow: SpotifyPalette.elevated,
      surfaceContainer: SpotifyPalette.containerMid,
      surfaceContainerHigh: SpotifyPalette.card,
      surfaceContainerHighest: SpotifyPalette.highlight,
      onSurface: SpotifyPalette.textPrimary,
      onSurfaceVariant: SpotifyPalette.textSecondary,
      outlineVariant: SpotifyPalette.hairline,
      inverseSurface: SpotifyLightPalette.base,
      onInverseSurface: SpotifyLightPalette.textPrimary,
      inversePrimary: SpotifyPalette.accent,
    );
  }

  return base.copyWith(
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: accent,
    onPrimaryContainer: onAccent,
    secondaryContainer: SpotifyLightPalette.card,
    onSecondaryContainer: SpotifyLightPalette.textPrimary,
    surface: SpotifyLightPalette.base,
    surfaceContainerLowest: SpotifyLightPalette.lowest,
    surfaceContainerLow: SpotifyLightPalette.elevated,
    surfaceContainer: SpotifyLightPalette.containerMid,
    surfaceContainerHigh: SpotifyLightPalette.card,
    surfaceContainerHighest: SpotifyLightPalette.highlight,
    onSurface: SpotifyLightPalette.textPrimary,
    onSurfaceVariant: SpotifyLightPalette.textSecondary,
    outlineVariant: SpotifyLightPalette.hairline,
    inverseSurface: SpotifyPalette.base,
    onInverseSurface: SpotifyPalette.textPrimary,
    inversePrimary: SpotifyPalette.accent,
  );
}

ThemeData getAppTheme(ColorScheme colorScheme) {
  final base = colorScheme.brightness == Brightness.light
      ? ThemeData.light()
      : ThemeData.dark();

  final isLight = colorScheme.brightness == Brightness.light;
  final isPureBlack =
      colorScheme.brightness == Brightness.dark && usePureBlackColor.value;

  // Pure black theme colors
  const pureBlack = Color(0xFF000000);
  const pureBlackElevated = Color(0xFF0A0A0A);
  const pureBlackContainer = Color(0xFF121212);
  const pureBlackContainerHigh = Color(0xFF1A1A1A);

  final bgColor = isLight
      ? colorScheme.surface
      : (isPureBlack ? pureBlack : colorScheme.surface);

  final cardBgColor = isLight
      ? colorScheme.surfaceContainerLow
      : (isPureBlack ? pureBlackElevated : colorScheme.surfaceContainerLow);

  // Elevated surfaces used by sheets, dialogs and menus.
  final bottomSheetBgColor = isLight
      ? colorScheme.surfaceContainerLow
      : (isPureBlack ? pureBlackElevated : colorScheme.surfaceContainerLow);
  final dialogBgColor = isLight
      ? colorScheme.surfaceContainerLow
      : (isPureBlack ? pureBlackContainer : colorScheme.surfaceContainer);
  final menuBgColor = isLight
      ? colorScheme.surfaceContainerLow
      : (isPureBlack ? pureBlackContainer : colorScheme.surfaceContainer);
  final inputBgColor = isLight
      ? colorScheme.surfaceContainerHighest
      : (isPureBlack
            ? pureBlackContainerHigh
            : colorScheme.surfaceContainerHigh);

  // modified color scheme for pure black theme
  final effectiveColorScheme = isPureBlack
      ? colorScheme.copyWith(
          surface: pureBlack,
          surfaceContainerLowest: pureBlack,
          surfaceContainerLow: pureBlackElevated,
          surfaceContainer: pureBlackContainer,
          surfaceContainerHigh: pureBlackContainerHigh,
          surfaceContainerHighest: pureBlackContainerHigh,
        )
      : colorScheme;

  return ThemeData(
    scaffoldBackgroundColor: bgColor,
    colorScheme: effectiveColorScheme,
    cardColor: cardBgColor,
    cardTheme: base.cardTheme.copyWith(
      elevation: SpotifyElevation.none,
      color: cardBgColor,
      shape: const RoundedRectangleBorder(borderRadius: SpotifyRadii.md),
    ),
    // Spotify type scale: bold headers, tight tracking on large titles.
    textTheme: base.textTheme.copyWith(
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: SpotifyTypography.labelSmall.fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontSize: SpotifyTypography.labelMedium.fontSize,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: SpotifyTypography.labelLarge.fontSize,
        fontWeight: FontWeight.w600,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: SpotifyTypography.bodySmall.fontSize,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: SpotifyTypography.bodyMedium.fontSize,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: SpotifyTypography.bodyLarge.fontSize,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontSize: SpotifyTypography.titleSmall.fontSize,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: SpotifyTypography.titleMedium.fontSize,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: SpotifyTypography.titleLarge.fontSize,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: SpotifyTypography.headlineSmall.fontSize,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: SpotifyTypography.headlineMedium.fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: SpotifyTypography.displaySmall.fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: bgColor,
      foregroundColor: effectiveColorScheme.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: SpotifyTypography.brandTitle.copyWith(
        color: effectiveColorScheme.primary,
      ),
      toolbarHeight: 64,
      iconTheme: IconThemeData(
        color: effectiveColorScheme.onSurfaceVariant,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: effectiveColorScheme.onSurfaceVariant,
        size: 24,
      ),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      textColor: effectiveColorScheme.onSurface,
      iconColor: effectiveColorScheme.onSurfaceVariant,
      titleTextStyle: base.listTileTheme.titleTextStyle?.copyWith(
        fontSize: SpotifyTypography.titleMedium.fontSize,
        fontWeight: FontWeight.w600,
        color: effectiveColorScheme.onSurface,
      ),
    ),
    // Spotify-style slider: thin 4px track, small round thumb.
    sliderTheme: base.sliderTheme.copyWith(
      year2023: false,
      trackHeight: 4,
      thumbSize: WidgetStateProperty.all(const Size(12, 12)),
      overlayShape: SliderComponentShape.noOverlay,
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: bottomSheetBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      isDense: true,
      fillColor: inputBgColor,
      border: const OutlineInputBorder(
        borderRadius: SpotifyRadii.md,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 20, 14),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: dialogBgColor,
      shape: const RoundedRectangleBorder(borderRadius: SpotifyRadii.lg),
    ),
    // Chips: flat, 8dp corners, card-level fill — Spotify filter look.
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: effectiveColorScheme.surfaceContainerHigh,
      side: BorderSide.none,
      shape: const RoundedRectangleBorder(borderRadius: SpotifyRadii.sm),
      labelStyle: TextStyle(
        color: effectiveColorScheme.onSurface,
        fontSize: SpotifyTypography.labelLarge.fontSize,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SpotifySpacing.md,
        vertical: SpotifySpacing.sm,
      ),
      elevation: SpotifyElevation.none,
    ),
    // Spotify switches: accent track with dark knob when on.
    switchTheme: base.switchTheme.copyWith(
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return effectiveColorScheme.primary;
        }
        return effectiveColorScheme.surfaceContainerHighest;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return effectiveColorScheme.onPrimary;
        }
        return effectiveColorScheme.onSurfaceVariant;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackOutlineWidth: const WidgetStatePropertyAll(0),
    ),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
      color: effectiveColorScheme.primary,
      linearTrackColor: effectiveColorScheme.surfaceContainerHigh,
      circularTrackColor: effectiveColorScheme.surfaceContainerHigh,
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: bgColor,
      elevation: 0,
      height: 70,
      indicatorColor: effectiveColorScheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: effectiveColorScheme.onPrimaryContainer,
            size: 24,
          );
        }
        return IconThemeData(
          color: effectiveColorScheme.onSurfaceVariant,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: effectiveColorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: effectiveColorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );
      }),
    ),
    navigationRailTheme: base.navigationRailTheme.copyWith(
      backgroundColor: bgColor,
      elevation: 0,
      indicatorColor: effectiveColorScheme.primaryContainer,
      selectedIconTheme: IconThemeData(
        color: effectiveColorScheme.onPrimaryContainer,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: effectiveColorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: effectiveColorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: effectiveColorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: menuBgColor,
      shape: const RoundedRectangleBorder(borderRadius: SpotifyRadii.sm),
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: base.dividerTheme.copyWith(
      color: effectiveColorScheme.outlineVariant,
      thickness: 1,
    ),
    // Spotify toasts: inverted contrast (white on dark, near-black on light).
    snackBarTheme: SnackBarThemeData(
      backgroundColor: effectiveColorScheme.inverseSurface,
      closeIconColor: effectiveColorScheme.onInverseSurface,
      contentTextStyle: TextStyle(
        color: effectiveColorScheme.onInverseSurface,
        fontSize: SpotifyTypography.labelLarge.fontSize,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: SpotifyRadii.sm),
      elevation: 0,
      actionTextColor: effectiveColorScheme.inversePrimary,
    ),
    // Motion: predictive back gesture on Android (Pixel target), smooth
    // forward-fade on Apple platforms, zoom elsewhere.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      },
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );
}
