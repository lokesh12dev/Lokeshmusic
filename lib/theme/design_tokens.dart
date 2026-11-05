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

import 'package:material_ui/material_ui.dart';

/// ---------------------------------------------------------------------------
/// Spotify-inspired design tokens for Lokeshmusic.
///
/// Dark-first palette. Every token is a compile-time constant so widget
/// trees stay const-correct and allocation-free at runtime.
///
/// Usage:
///   Container(color: SpotifyPalette.elevated)
///   padding: EdgeInsets.all(SpotifySpacing.lg)
///   duration: SpotifyMotion.base, curve: SpotifyMotion.emphasized
/// ---------------------------------------------------------------------------
abstract final class SpotifyPalette {
  // Surfaces (dark gradient steps)
  static const Color lowest = Color(0xFF0D0D0D); // deepest bars / scrims
  static const Color base = Color(0xFF121212); // app background
  static const Color elevated = Color(0xFF1E1E1E); // cards, sheets, lists
  static const Color containerMid = Color(0xFF232323); // intermediate fills
  static const Color card = Color(0xFF282828); // interactive cards, chips
  static const Color highlight = Color(0xFF2E2E2E); // hover / pressed fills

  // Accent
  static const Color accent = Color(0xFF1DB954); // Spotify green
  static const Color accentBright = Color(0xFF1ED760); // hover / trailing
  static const Color onAccent = Color(0xFF000000); // black label on green

  // Text (dark)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3); // artists, subtitles
  static const Color textMuted = Color(0xFF8C8C8C); // captions, meta

  // Strokes & overlays
  static const Color hairline = Color(0xFF333333); // dividers in dark
  static const Color scrim = Color(0x8C000000); // 55% black

  // Semantic
  static const Color danger = Color(0xFFE91429); // Spotify "unfollow" red
}

/// Light-mode counterparts (Spotify canvas white look).
abstract final class SpotifyLightPalette {
  static const Color lowest = Color(0xFFFAFAFA);
  static const Color base = Color(0xFFFFFFFF);
  static const Color elevated = Color(0xFFF7F7F7);
  static const Color containerMid = Color(0xFFF0F0F0);
  static const Color card = Color(0xFFEDEDED);
  static const Color highlight = Color(0xFFE4E4E4);

  static const Color accent = SpotifyPalette.accent;
  static const Color onAccent = Color(0xFF000000);

  static const Color textPrimary = Color(0xFF121212);
  static const Color textSecondary = Color(0xFF6A6A6A);
  static const Color textMuted = Color(0xFF9B9B9B);

  static const Color hairline = Color(0xFFE5E5E5);
}

/// ---------------------------------------------------------------------------
/// Type scale. Sized to Material 3 roles with Spotify-style weights
/// (bold headers, tight tracking on large titles).
/// ---------------------------------------------------------------------------
abstract final class SpotifyTypography {
  static const String brandFamily = 'paytoneOne';

  static const TextStyle brandTitle = TextStyle(
    fontFamily: brandFamily,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

/// 4pt grid spacing.
abstract final class SpotifySpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard horizontal page gutter (Spotify uses 16 on phones).
  static const EdgeInsets pageH = EdgeInsets.symmetric(horizontal: lg);

  /// Vertical rhythm between sections.
  static const EdgeInsets sectionV = EdgeInsets.symmetric(vertical: xl);
}

/// Corner radius scale.
abstract final class SpotifyRadii {
  static const double smValue = 8;
  static const double mdValue = 12;
  static const double lgValue = 16;
  static const double xlValue = 24;
  static const double pillValue = 999;

  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));
  static const BorderRadius pill = BorderRadius.all(
    Radius.circular(pillValue),
  );
}

/// Elevation levels + matching soft shadows (Spotify avoids hard drop shadows).
abstract final class SpotifyElevation {
  static const double none = 0;
  static const double sheet = 2;
  static const double overlay = 8;
}

abstract final class SpotifyShadows {
  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> low = <BoxShadow>[
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x33000000)),
  ];

  static const List<BoxShadow> medium = <BoxShadow>[
    BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x4D000000)),
  ];

  static const List<BoxShadow> high = <BoxShadow>[
    BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x66000000)),
  ];
}

/// Motion: durations and easing. Material 3 emphasized cubic is the default
/// character for entry/exit transitions across the app.
abstract final class SpotifyMotion {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration dramatic = Duration(milliseconds: 550);

  // Curves
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0, 0.8, 0.15);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
}
