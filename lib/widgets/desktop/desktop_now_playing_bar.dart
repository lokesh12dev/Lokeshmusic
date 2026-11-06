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

import 'package:audio_service/audio_service.dart';
import 'package:lokeshmusic/main.dart' show audioHandler;
import 'package:lokeshmusic/models/position_data.dart';
import 'package:lokeshmusic/screens/now_playing_page.dart';
import 'package:lokeshmusic/services/common_services.dart';
import 'package:lokeshmusic/utilities/mediaitem.dart';
import 'package:lokeshmusic/widgets/song_artwork.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rxdart/rxdart.dart';

/// Height of the Spotify-style full-width now-playing bar.
const desktopNowPlayingBarHeight = 84.0;

@immutable
class _ProgressSnapshot {
  const _ProgressSnapshot({
    required this.playbackState,
    required this.position,
  });

  final PlaybackState playbackState;
  final PositionData position;

  @override
  bool operator ==(Object other) =>
      other is _ProgressSnapshot &&
      other.playbackState.playing == playbackState.playing &&
      other.playbackState.processingState == playbackState.processingState &&
      other.playbackState.shuffleMode == playbackState.shuffleMode &&
      other.playbackState.repeatMode == playbackState.repeatMode &&
      other.position.position == position.position &&
      other.position.duration == position.duration;

  @override
  int get hashCode => Object.hash(
        playbackState.playing,
        playbackState.processingState,
        playbackState.shuffleMode,
        playbackState.repeatMode,
        position.position,
        position.duration,
      );
}

/// Spotify-style bottom bar: track info, playback controls and volume,
/// always visible on the desktop shell.
class DesktopNowPlayingBar extends StatefulWidget {
  const DesktopNowPlayingBar({super.key});

  @override
  State<DesktopNowPlayingBar> createState() => _DesktopNowPlayingBarState();
}

class _DesktopNowPlayingBarState extends State<DesktopNowPlayingBar> {
  static final Stream<_ProgressSnapshot> _progressStream =
      Rx.combineLatest2(
            audioHandler.playbackStateStream,
            audioHandler.positionDataStream,
            (
              PlaybackState playbackState,
              PositionData position,
            ) =>
                _ProgressSnapshot(
              playbackState: playbackState,
              position: position,
            ),
          )
              .throttleTime(const Duration(milliseconds: 120), trailing: true)
              .distinct()
              .asBroadcastStream();

  final ValueNotifier<bool> _songLiked = ValueNotifier<bool>(false);
  bool _songLikedKnown = false;
  double _volume = 1;
  double? _lastPositiveVolume;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    audioHandler.mediaItem.listen(_onMediaItemChanged);
  }

  @override
  void dispose() {
    _songLiked.dispose();
    super.dispose();
  }

  void _onMediaItemChanged(MediaItem? mediaItem) {
    var liked = false;
    if (mediaItem != null) {
      final ytid = mediaItemToMap(mediaItem)['ytid']?.toString().trim() ?? '';
      if (ytid.isNotEmpty) liked = isSongAlreadyLiked(ytid);
    }
    _songLikedKnown = true;
    if (_songLiked.value != liked) _songLiked.value = liked;
  }

  Future<void> _toggleLike(MediaItem mediaItem) async {
    final song = mediaItemToMap(mediaItem);
    final songId = song['ytid']?.toString().trim() ?? '';
    if (songId.isEmpty) return;

    final wasLiked = _songLiked.value;
    _songLiked.value = !wasLiked;

    try {
      await updateSongLikeStatus(songId, !wasLiked, songData: song);
    } catch (_) {
      _songLiked.value = wasLiked; // Revert on failure.
    }
  }

  void _openNowPlayingView() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, _) => const NowPlayingPage(),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: desktopNowPlayingBarHeight,
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, mediaSnapshot) {
            final mediaItem = mediaSnapshot.data;
            final hasTrack = mediaItem != null;

            return StreamBuilder<_ProgressSnapshot>(
              stream: _progressStream,
              builder: (context, progressSnapshot) {
                final progress = progressSnapshot.data ??
                    _ProgressSnapshot(
                      playbackState: PlaybackState(),
                      position: PositionData(
                        Duration.zero,
                        Duration.zero,
                        Duration.zero,
                      ),
                    );

                return Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _TrackSection(
                        mediaItem: mediaItem,
                        songLiked: _songLiked,
                        songLikedKnown: _songLikedKnown,
                        onLikeToggle: hasTrack
                            ? () => _toggleLike(mediaItem)
                            : null,
                        onOpen: hasTrack ? _openNowPlayingView : null,
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: _ControlsSection(
                        colorScheme: colorScheme,
                        playbackState: progress.playbackState,
                        positionData: progress.position,
                        duration:
                            mediaItem?.duration ?? progress.position.duration,
                        dragValue: _dragValue,
                        onSeekStartDisabled: !hasTrack,
                        onDrag: (value) => setState(() => _dragValue = value),
                        onDragEnd: _commitSeek,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: _ExtrasSection(
                        colorScheme: colorScheme,
                        volume: _volume,
                        enabled: hasTrack,
                        onVolumeChanged: _setVolume,
                        onToggleMute: _toggleMute,
                        onOpenQueue: _openNowPlayingView,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _commitSeek(double value, Duration duration) {
    if (duration == Duration.zero) return;
    final milliseconds = (duration.inMilliseconds * value).round();
    if (milliseconds < 0) return;
    audioHandler.seek(Duration(milliseconds: milliseconds));
    if (mounted) setState(() => _dragValue = null);
  }

  void _setVolume(double value) {
    _volume = value.clamp(0, 1);
    if (_volume > 0) _lastPositiveVolume = _volume;
    audioHandler.setVolume(_volume);
    if (mounted) setState(() {});
  }

  void _toggleMute() {
    _setVolume(_volume > 0 ? 0 : (_lastPositiveVolume ?? 1));
  }
}

class _TrackSection extends StatelessWidget {
  const _TrackSection({
    required this.mediaItem,
    required this.songLiked,
    required this.songLikedKnown,
    required this.onLikeToggle,
    required this.onOpen,
  });

  final MediaItem? mediaItem;
  final ValueNotifier<bool> songLiked;
  final bool songLikedKnown;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaItem = this.mediaItem;
    final isLiked = songLikedKnown && songLiked.value;

    return Row(
      children: [
        const SizedBox(width: 8),
        Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: SizedBox(
              width: 56,
              height: 56,
              child: mediaItem != null
                  ? SongArtworkWidget(
                      metadata: mediaItem,
                      size: 56,
                      borderRadius: 6,
                    )
                  : Icon(
                      Icons.music_note,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mediaItem != null) ...[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onOpen,
                    child: Text(
                      mediaItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mediaItem.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Tooltip(
          message: (isLiked
                  ? 'Remove from liked songs'
                  : 'Add to liked songs'),
          waitDuration: const Duration(milliseconds: 600),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: mediaItem == null ? null : onLikeToggle,
            icon: Icon(
              isLiked && mediaItem != null
                  ? Icons.favorite
                  : Icons.favorite_border,
              size: 20,
              color: isLiked && mediaItem != null
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ControlsSection extends StatelessWidget {
  const _ControlsSection({
    required this.colorScheme,
    required this.playbackState,
    required this.positionData,
    required this.duration,
    required this.dragValue,
    required this.onSeekStartDisabled,
    required this.onDrag,
    required this.onDragEnd,
  });

  final ColorScheme colorScheme;
  final PlaybackState playbackState;
  final PositionData positionData;
  final Duration? duration;
  final double? dragValue;
  final bool onSeekStartDisabled;
  final ValueChanged<double> onDrag;
  final void Function(double value, Duration duration) onDragEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButtons(context),
        const SizedBox(height: 6),
        _buildSeekRow(context),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    final isPlaying = playbackState.playing;
    final processingState = playbackState.processingState;
    final isLoading = processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering;
    final isCompleted = processingState == AudioProcessingState.completed;
    final shuffleActive =
        playbackState.shuffleMode != AudioServiceShuffleMode.none;
    final repeatMode = playbackState.repeatMode;
    final repeatActive = repeatMode != AudioServiceRepeatMode.none;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BarIconButton(
          icon: Icons.shuffle,
          tooltip: 'Shuffle',
          color: shuffleActive
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          activeIndicator: shuffleActive,
          onPressed: () => audioHandler.setShuffleMode(
            shuffleActive
                ? AudioServiceShuffleMode.none
                : AudioServiceShuffleMode.all,
          ),
        ),
        const SizedBox(width: 14),
        _BarIconButton(
          icon: Icons.skip_previous,
          tooltip: 'Previous',
          color: colorScheme.onSurfaceVariant,
          activeIndicator: false,
          onPressed: audioHandler.skipToPrevious,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 34,
          height: 34,
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.primary,
                  ),
                )
              : Material(
                  color: colorScheme.onSurface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isCompleted
                        ? audioHandler.playAgain
                        : (isPlaying ? audioHandler.pause : audioHandler.play),
                    child: Center(
                      child: Icon(
                        isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 20,
                        color: colorScheme.surface,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        _BarIconButton(
          icon: Icons.skip_next,
          tooltip: 'Next',
          color: colorScheme.onSurfaceVariant,
          activeIndicator: false,
          onPressed: audioHandler.skipToNext,
        ),
        const SizedBox(width: 14),
        _BarIconButton(
          icon: repeatMode == AudioServiceRepeatMode.one
              ? Icons.repeat
              : Icons.repeat,
          tooltip: repeatMode == AudioServiceRepeatMode.one
              ? 'Repeat one'
              : repeatActive
                  ? 'Repeat all'
                  : 'Repeat',
          color: repeatActive
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          activeIndicator: repeatActive,
          onPressed: () => audioHandler.setRepeatMode(
            repeatMode == AudioServiceRepeatMode.none
                ? AudioServiceRepeatMode.all
                : repeatMode == AudioServiceRepeatMode.all
                    ? AudioServiceRepeatMode.one
                    : AudioServiceRepeatMode.none,
          ),
        ),
      ],
    );
  }

  Widget _buildSeekRow(BuildContext context) {
    final duration = this.duration ?? Duration.zero;
    final seekable = duration > Duration.zero && !onSeekStartDisabled;

    final remaining = duration - positionData.position;
    final remainingLabel =
        remaining > Duration.zero && (duration > remaining)
            ? _formatDuration(remaining)
            : _formatDuration(Duration.zero);

    final progress = dragValue ??
        (seekable
            ? (positionData.position.inMilliseconds /
                    duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0);

    return Row(
      children: [
        Text(
          _formatDuration(positionData.position),
          style: TextStyle(
            fontSize: 11,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
                elevation: 0,
              ),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: colorScheme.onSurfaceVariant,
              inactiveTrackColor: colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3),
              thumbColor: colorScheme.onSurface,
            ),
            child: Slider(
              value: progress,
              onChanged: seekable ? onDrag : null,
              onChangeEnd: seekable
                  ? (value) => onDragEnd(value, duration)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '-$remainingLabel',
          style: TextStyle(
            fontSize: 11,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.activeIndicator,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final bool activeIndicator;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: tooltip,
          waitDuration: const Duration(milliseconds: 600),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: Icon(icon, size: 20, color: color),
            onPressed: onPressed,
          ),
        ),
        if (activeIndicator)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}

class _ExtrasSection extends StatelessWidget {
  const _ExtrasSection({
    required this.colorScheme,
    required this.volume,
    required this.enabled,
    required this.onVolumeChanged,
    required this.onToggleMute,
    required this.onOpenQueue,
  });

  final ColorScheme colorScheme;
  final double volume;
  final bool enabled;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: 'Now playing view',
          waitDuration: const Duration(milliseconds: 600),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(
              Icons.fullscreen,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: enabled ? onOpenQueue : null,
          ),
        ),
        Tooltip(
          message: 'Queue',
          waitDuration: const Duration(milliseconds: 600),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: Icon(
              Icons.queue_music,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: enabled ? onOpenQueue : null,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: Icon(
            volume > 0
                ? Icons.volume_up
                : Icons.volume_off,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: enabled ? onToggleMute : null,
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 96,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
                elevation: 0,
              ),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: colorScheme.onSurfaceVariant,
              inactiveTrackColor: colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3),
              thumbColor: colorScheme.onSurface,
            ),
            child: Slider(
              value: volume,
              onChanged: enabled ? onVolumeChanged : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
