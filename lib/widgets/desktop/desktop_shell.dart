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

import 'package:go_router/go_router.dart';
import 'package:lokeshmusic/services/navigation_history.dart';
import 'package:lokeshmusic/widgets/desktop/desktop_now_playing_bar.dart';
import 'package:lokeshmusic/widgets/desktop/desktop_sidebar.dart';
import 'package:material_ui/material_ui.dart';

/// Window width from which the Spotify-style desktop chrome replaces the
/// mobile / tablet navigation.
const desktopShellBreakpoint = 900.0;

/// Spotify-style desktop chrome: a library sidebar, a floating rounded main
/// surface with a top bar, and a full-width now-playing bar.
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    required this.navigationShell,
    required this.onDestinationSelected,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: colorScheme.surface,
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DesktopSidebar(
                    currentShellIndex: navigationShell.currentIndex,
                    onDestinationSelected: onDestinationSelected,
                  ),
                  Expanded(
                    child: _MainSurface(
                      navigationShell: navigationShell,
                      mediaQuery: mediaQuery,
                      colorScheme: colorScheme,
                      onSettings: () => onDestinationSelected(3),
                    ),
                  ),
                ],
              ),
            ),
            const DesktopNowPlayingBar(),
          ],
        ),
      ),
    );
  }
}

class _MainSurface extends StatelessWidget {
  const _MainSurface({
    required this.navigationShell,
    required this.mediaQuery,
    required this.colorScheme,
    required this.onSettings,
  });

  final StatefulNavigationShell navigationShell;
  final MediaQueryData mediaQuery;
  final ColorScheme colorScheme;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: colorScheme.surfaceContainerLow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              // Every page gets bottom room for the now-playing bar.
              data: mediaQuery.copyWith(
                padding: mediaQuery.padding.copyWith(
                  bottom: desktopNowPlayingBarHeight,
                ),
              ),
              child: navigationShell,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DesktopTopBar(onSettings: onSettings),
          ),
        ],
      ),
    );
  }
}

/// Floating Spotify-style top bar: back / forward history buttons over a
/// gradient scrim, plus a profile shortcut on the right.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({required this.onSettings, super.key});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.6, 1],
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.surfaceContainerLow.withValues(alpha: 0),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListenableBuilder(
        listenable: NavigationHistory.instance,
        builder: (context, _) {
          final history = NavigationHistory.instance;

          return Row(
            children: [
              _ChromeIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Back',
                enabled: history.canBack,
                onPressed: history.back,
              ),
              const SizedBox(width: 8),
              _ChromeIconButton(
                icon: Icons.chevron_right,
                tooltip: 'Forward',
                enabled: history.canForward,
                onPressed: history.forward,
              ),
              const Spacer(),
              _ChromeIconButton(
                icon: Icons.settings,
                tooltip: 'Settings',
                enabled: true,
                onPressed: onSettings,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Circular chrome button, mirroring Spotify's dark circle nudges.
class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Material(
            color: colorScheme.surfaceContainer,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
