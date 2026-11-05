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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lokeshmusic/constants/app_constants.dart';
import 'package:lokeshmusic/extensions/l10n.dart';
import 'package:lokeshmusic/main.dart';
import 'package:lokeshmusic/services/artist_service.dart' show ytMusicClient;
import 'package:lokeshmusic/services/listening_stats_service.dart';
import 'package:lokeshmusic/services/settings_manager.dart';
import 'package:lokeshmusic/utilities/app_utils.dart';
import 'package:lokeshmusic/utilities/async_loader.dart';
import 'package:lokeshmusic/utilities/formatter.dart' show returnSongLayout;
import 'package:lokeshmusic/utilities/listening_stats_utils.dart';
import 'package:lokeshmusic/widgets/announcement_box.dart';
import 'package:lokeshmusic/widgets/listening_recap_card.dart';
import 'package:lokeshmusic/widgets/mini_player_bottom_space.dart';
import 'package:lokeshmusic/widgets/recommended_songs_section.dart';
import 'package:lokeshmusic/widgets/section_header.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _songCategories = <({String title, String query, String key})>[
    (title: 'Tamil Songs', query: 'Tamil songs', key: 'home_tamil_songs'),
    (
      title: 'Tamil Trending Song Recommendations',
      query: 'Tamil trending songs',
      key: 'home_tamil_trending',
    ),
    (
      title: 'Popular English Trending Music',
      query: 'popular English trending music',
      key: 'home_english_trending',
    ),
  ];

  Future<List<dynamic>>? _lastCategorySearch;

  @override
  void initState() {
    super.initState();
  }

  Future<List<dynamic>> _queueCategorySearch(String query) {
    final previous = _lastCategorySearch;
    final future = previous == null
        ? _fetchCategorySongs(query)
        : previous.then((_) => _fetchCategorySongs(query));
    _lastCategorySearch = future;
    return future;
  }

  Future<List> _fetchCategorySongs(String query) async {
    try {
      final videos = await ytMusicClient.music
          .searchSongs(query, limit: 5)
          .timeout(const Duration(seconds: 20));
      return videos
          .asMap()
          .entries
          .map((entry) => returnSongLayout(entry.key, entry.value))
          .toList();
    } catch (error, stackTrace) {
      logger.log(
        'Home music search failed for "$query"',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lokeshmusic')),
      body: CustomScrollView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(250),
        slivers: [
          SliverPadding(
            padding: commonSingleChildScrollViewPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ValueListenableBuilder<String?>(
                  valueListenable: announcementURL,
                  builder: (_, _url, __) {
                    if (_url == null) return const SizedBox.shrink();
                    final isSponsorshipAnnouncement =
                        isSponsorshipAnnouncementUrl(_url);
                    final _message = isSponsorshipAnnouncement
                        ? context.l10n!.sponsorProject
                        : context.l10n!.newAnnouncement;
                    final _icon = isSponsorshipAnnouncement
                        ? FluentIcons.heart_24_filled
                        : FluentIcons.megaphone_24_filled;

                    return AnnouncementBox(
                      message: _message,
                      url: _url,
                      icon: _icon,
                      onDismiss: () async {
                        announcementURL.value = null;
                      },
                    );
                  },
                ),
                ..._songCategories.map(
                  (category) => _SongCategorySection(
                    category: category,
                    loadSongs: _queueCategorySearch,
                  ),
                ),
                _buildCurrentMonthRecapSection(),
                const MiniPlayerBottomSpace(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthRecapSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: wrappedEnabled,
      builder: (_, isEnabled, __) {
        if (!isEnabled) return const SizedBox.shrink();

        final currentMonthKey = listeningStatsMonthKey(DateTime.now());
        final monthStats = listeningStatsService.monthStats(currentMonthKey);
        final songs = listeningStatsService.monthTopSongs(currentMonthKey);
        final displayMinutes = monthDisplayMinutes(monthStats);
        if (displayMinutes <= 0 && songs.isEmpty) {
          return const SizedBox.shrink();
        }

        final previewSongs = songs.take(wrappedShareSongsLimit).toList();
        final periodLabel = formatMonthPeriodLabel(
          Localizations.localeOf(context),
          currentMonthKey,
        );

        return Column(
          children: [
            SectionHeader(
              title: context.l10n!.timeMachine,
              icon: FluentIcons.data_trending_24_filled,
            ),
            ListeningRecapCard(
              periodLabel: periodLabel,
              minutes: displayMinutes,
              songs: previewSongs,
              onSongTap: (index) => _playRecapSongs(previewSongs, index),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/home/timeMachine'),
                  icon: const Icon(FluentIcons.arrow_right_24_regular),
                  label: Text(context.l10n!.listeningStats),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _playRecapSongs(
    List<Map<String, dynamic>> songs,
    int index,
  ) async {
    if (songs.isEmpty) return;
    await audioHandler.playPlaylistSong(
      playlist: {'title': context.l10n!.timeMachine, 'list': songs},
      songIndex: index,
    );
  }
}

class _SongCategorySection extends StatefulWidget {
  const _SongCategorySection({required this.category, required this.loadSongs});

  final ({String title, String query, String key}) category;
  final Future<List<dynamic>> Function(String query) loadSongs;

  @override
  State<_SongCategorySection> createState() => _SongCategorySectionState();
}

class _SongCategorySectionState extends State<_SongCategorySection> {
  late final Future<List<dynamic>> _songs;

  @override
  void initState() {
    super.initState();
    _songs = widget.loadSongs(widget.category.query);
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return AsyncLoader<List<dynamic>>(
      future: _songs,
      loadingWidget: Column(
        children: [
          SectionHeader(
            title: category.title,
            icon: FluentIcons.sparkle_24_filled,
          ),
          const SizedBox(height: 64),
        ],
      ),
      emptyWidget: SectionHeader(
        title: category.title,
        icon: FluentIcons.sparkle_24_filled,
      ),
      builder: (context, songs) => RecommendedSongsSection(
        title: category.title,
        songs: songs,
        listKeyPrefix: category.key,
      ),
    );
  }
}
