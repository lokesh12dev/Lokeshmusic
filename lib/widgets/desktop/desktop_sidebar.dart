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

import 'dart:convert';

import 'package:lokeshmusic/extensions/l10n.dart';
import 'package:lokeshmusic/services/playlists_manager.dart';
import 'package:lokeshmusic/services/router_service.dart';
import 'package:lokeshmusic/utilities/playlist_dialogs.dart';
import 'package:material_ui/material_ui.dart';

/// Width of the Spotify-style library sidebar.
const desktopSidebarWidth = 280.0;

/// Spotify-style left sidebar: primary nav (Home / Search) on top, a
/// "Your Library" panel with liked, offline and current playlists below.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    required this.currentShellIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentShellIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: desktopSidebarWidth,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: _SidePanelCard(
              child: Column(
                children: [
                  _SidePanelNavItem(
                    icon: Icons.home,
                    label: context.l10n?.home ?? 'Home',
                    selected: currentShellIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  const SizedBox(height: 4),
                  _SidePanelNavItem(
                    icon: Icons.search,
                    label: context.l10n?.search ?? 'Search',
                    selected: currentShellIndex == 1,
                    onTap: () => onDestinationSelected(1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: _SidePanelCard(child: _LibraryPanel()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanelCard extends StatelessWidget {
  const _SidePanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

class _SidePanelNavItem extends StatelessWidget {
  const _SidePanelNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.surfaceContainer : Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                icon,
                size: 24,
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryPanel extends StatelessWidget {
  const _LibraryPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 2),
          child: Row(
            children: [
              Icon(
                Icons.library_music,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your Library',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Tooltip(
                message: context.l10n?.addPlaylist ?? 'Create playlist',
                waitDuration: const Duration(milliseconds: 600),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: Icon(
                    Icons.add,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => showCreatePlaylistDialog(context),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              userCustomPlaylists,
              userLikedPlaylists,
              pinnedPlaylistIds,
            ]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 12),
              children: _tiles(context),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _tiles(BuildContext context) {
    return [
      const _LikedSongsTile(),
      _LibraryTile(
        leading: _TileColorLeading(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          icon: Icons.cloud_download,
          iconColor: Theme.of(context).colorScheme.onSurface,
        ),
        title: context.l10n?.offlineSongs ?? 'Offline songs',
        subtitle: 'Downloads',
        onTap: () =>
            NavigationManager.router.go('/library/userSongs/offline'),
      ),
      ..._pinnedPlaylistTiles(),
      ..._likedPlaylistTiles(),
      ..._customPlaylistTiles(),
    ];
  }

  List<Widget> _pinnedPlaylistTiles() {
    return [
      for (final id in pinnedPlaylistIds.value)
        if (_playlistById(id) case final playlist?)
          _playlistTile(playlist, isPinned: true),
    ];
  }

  List<Widget> _likedPlaylistTiles() {
    final pinned = pinnedPlaylistIds.value.toSet();
    return [
      for (final playlist in userLikedPlaylists.value.cast<Map>())
        if (!pinned.contains(_playlistId(playlist))) _playlistTile(playlist),
    ];
  }

  List<Widget> _customPlaylistTiles() {
    return [
      for (final playlist in getUserCustomPlaylists())
        if (!userLikedPlaylists.value.cast<Map>().any(
              (liked) => _playlistId(liked) == _playlistId(playlist),
            ))
          _playlistTile(playlist),
    ];
  }

  static String? _playlistId(Map playlist) =>
      playlist['ytid']?.toString().trim();

  static Map? _playlistById(String id) {
    for (final playlist in playlists) {
      if (_playlistId(playlist) == id) return playlist;
    }
    return null;
  }

  Widget _playlistTile(Map playlist, {bool isPinned = false}) {
    return _LibraryTile(
      leading: _PlaylistThumbnail(image: playlist['image']?.toString()),
      title: playlist['title']?.toString() ?? 'Playlist',
      subtitle: 'Playlist • ${(playlist['list'] as List?)?.length ?? 0} songs',
      isPinned: isPinned,
      onTap: () => NavigationManager.router.go(
        '/home/playlist/${Uri.encodeComponent(_playlistId(playlist) ?? '')}',
      ),
    );
  }
}

/// A single sidebar library entry: square art, two-line text, hover state.
class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPinned = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: title,
      waitDuration: const Duration(milliseconds: 600),
      child: SizedBox(
        height: 60,
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.hovered)
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.all(colorScheme.onSurface),
            shape: WidgetStateProperty.all(
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
          ),
          onPressed: onTap,
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPinned) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.pin_drop,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Spotify's signature gradient tile for Liked Songs.
class _LikedSongsTile extends StatelessWidget {
  const _LikedSongsTile();

  @override
  Widget build(BuildContext context) {
    return _LibraryTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
          ),
        ),
        child: const Icon(
          Icons.favorite,
          size: 22,
          color: Colors.white,
        ),
      ),
      title: context.l10n?.likedSongs ?? 'Liked songs',
      subtitle: 'Playlist',
      onTap: () => NavigationManager.router.go('/library/userSongs/liked'),
    );
  }
}

/// Uniform rounded colour block with an icon, used when no artwork exists.
class _TileColorLeading extends StatelessWidget {
  const _TileColorLeading({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        color: backgroundColor,
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}

/// 48x48 square playlist art. Supports http(s) URLs and base64 data URLs
/// (custom cover art), falling back to a music note block.
class _PlaylistThumbnail extends StatelessWidget {
  const _PlaylistThumbnail({required this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      child: SizedBox(
        width: 48,
        height: 48,
        child: _buildImage(Theme.of(context).colorScheme),
      ),
    );
  }

  Widget _buildImage(ColorScheme colorScheme) {
    final fallback = _FallbackThumbnail(colorScheme: colorScheme);
    final uri = image;

    if (uri == null || uri.isEmpty) return fallback;

    if (uri.startsWith('data:')) {
      try {
        final bytes = base64Decode(uri.split(',').last);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
        );
      } on FormatException {
        return fallback;
      }
    }

    if (uri.startsWith('http')) {
      return Image.network(
        uri,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return fallback;
  }
}

class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
