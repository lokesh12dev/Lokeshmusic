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
import 'package:go_router/go_router.dart';
import 'package:lokeshmusic/constants/app_constants.dart';
import 'package:lokeshmusic/extensions/l10n.dart';
import 'package:lokeshmusic/main.dart';
import 'package:lokeshmusic/screens/search_page.dart';
import 'package:lokeshmusic/services/common_services.dart';
import 'package:lokeshmusic/services/data_manager.dart';
import 'package:lokeshmusic/services/listening_stats_service.dart';
import 'package:lokeshmusic/services/playlist_download_service.dart';
import 'package:lokeshmusic/services/playlists_manager.dart';
import 'package:lokeshmusic/services/router_service.dart';
import 'package:lokeshmusic/services/settings_manager.dart';
import 'package:lokeshmusic/services/update_manager.dart';
import 'package:lokeshmusic/theme/app_colors.dart';
import 'package:lokeshmusic/theme/app_themes.dart';
import 'package:lokeshmusic/utilities/flutter_bottom_sheet.dart';
import 'package:lokeshmusic/utilities/flutter_toast.dart';
import 'package:lokeshmusic/utilities/language_utils.dart';
import 'package:lokeshmusic/utilities/platform_utils.dart';
import 'package:lokeshmusic/utilities/url_launcher.dart';
import 'package:lokeshmusic/widgets/bottom_sheet_bar.dart';
import 'package:lokeshmusic/widgets/confirmation_dialog.dart';
import 'package:lokeshmusic/widgets/custom_bar.dart';
import 'package:lokeshmusic/widgets/mini_player_bottom_space.dart';
import 'package:lokeshmusic/widgets/section_header.dart';
import 'package:lokeshmusic/widgets/shapes/four_sided_cookie_shape.dart';
import 'package:material_ui/material_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final activatedColor = Theme.of(context).colorScheme.secondaryContainer;
    final inactivatedColor = Theme.of(context).colorScheme.surfaceContainerHigh;

    final content = Column(
      children: <Widget>[
        _buildPreferencesSection(
          context,
          primaryColor,
          activatedColor,
          inactivatedColor,
        ),
        if (!offlineMode.value) _buildOnlineFeaturesSection(context),
        _buildOthersSection(context),
        const SizedBox(height: 20),
        const MiniPlayerBottomSpace(),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.settings)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: isDesktopPlatform
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    Color primaryColor,
    Color activatedColor,
    Color inactivatedColor,
  ) {
    final isOffline = offlineMode.value;

    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.preferences,
          icon: Icons.settings,
        ),
        CustomBar(
          context.l10n!.accentColor,
          Icons.color_lens,
          borderRadius: commonCustomBarRadiusFirst,
          trailing: isDesktopPlatform
              ? Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: primaryColorSetting,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                )
              : null,
          onTap: () => _showAccentColorPicker(context),
        ),
        CustomBar(
          context.l10n!.themeMode,
          Icons.wb_sunny,
          onTap: () => _showThemeModePicker(context),
        ),
        CustomBar(
          context.l10n!.language,
          Icons.translate,
          onTap: () => _showLanguagePicker(context),
        ),
        CustomBar(
          context.l10n!.audioQuality,
          Icons.music_note,
          onTap: () => _showAudioQualityPicker(context),
        ),
        if (isAndroidPlatform)
          CustomBar(
            context.l10n!.equalizer,
            Icons.equalizer,
            onTap: () => context.push('/settings/equalizer'),
          ),
        if (themeMode == ThemeMode.dark)
          CustomBar(
            context.l10n!.pureBlackTheme,
            Icons.palette,
            description: context.l10n!.pureBlackThemeDescription,
            trailing: Switch(
              value: usePureBlackColor.value,
              onChanged: (value) => _togglePureBlack(context, value),
            ),
          ),
        if (isAndroidPlatform)
          CustomBar(
            context.l10n!.dynamicColor,
            Icons.tune,
            description: context.l10n!.dynamicColorDescription,
            trailing: Switch(
              value: useSystemColor.value,
              onChanged: (value) => _toggleSystemColor(context, value),
            ),
          ),

        ValueListenableBuilder<bool>(
          valueListenable: showAudioQualityBadge,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.audioQualityBadge,
              Icons.badge,
              description: context.l10n!.audioQualityBadgeDescription,
              trailing: Switch(
                value: value,
                onChanged: (value) => _toggleAudioQualityBadge(context, value),
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: syncedLyricsEnabled,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.syncedLyrics,
              Icons.format_quote,
              description: context.l10n!.syncedLyricsDescription,
              trailing: Switch(
                value: value,
                onChanged: (value) => _toggleSyncedLyrics(context, value),
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: useProxy,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.useProxy,
              Icons.shield,
              description: context.l10n!.useProxyDescription,
              trailing: Switch(
                value: value,
                onChanged: (value) {
                  useProxy.value = value;
                  addOrUpdateData<bool>('settings', 'useProxy', value);
                  showToast(context, context.l10n!.settingChangedMsg);
                },
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: wrappedEnabled,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.listeningStats,
              Icons.schedule,
              description: context.l10n!.listeningStatsDescription,
              trailing: Switch(
                value: value,
                onChanged: (value) => _toggleWrapped(context, value),
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: offlineMode,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.offlineMode,
              Icons.cloud_off,
              description: context.l10n!.offlineModeDescription,
              borderRadius: isOffline && isFdroidBuild
                  ? commonCustomBarRadiusLast
                  : BorderRadius.zero,
              trailing: Switch(
                value: value,
                onChanged: (value) => _toggleOfflineMode(context, value),
              ),
            );
          },
        ),
        if (!isFdroidBuild && isMobilePlatform)
          ValueListenableBuilder<bool?>(
            valueListenable: shouldWeCheckUpdates,
            builder: (_, value, __) {
              return CustomBar(
                context.l10n!.automaticUpdateChecks,
                Icons.sync,
                description: context.l10n!.automaticUpdateChecksDescription,
                borderRadius: offlineMode.value
                    ? commonCustomBarRadiusLast
                    : BorderRadius.zero,
                trailing: Switch(
                  value: value ?? false,
                  onChanged: (value) =>
                      _toggleAutomaticUpdateChecks(context, value),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOnlineFeaturesSection(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: sponsorBlockSupport,
          builder: (_, value, __) {
            return CustomBar(
              'SponsorBlock',
              Icons.content_cut,
              description: context.l10n!.sponsorBlockDescription,
              trailing: Switch(
                value: value,
                onChanged: (value) => _toggleSponsorBlock(context, value),
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: playNextSongAutomatically,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.automaticSongPicker,
              Icons.queue_music,
              description: context.l10n!.automaticSongPickerDescription,
              trailing: Switch(
                value: value,
                onChanged: (value) {
                  _toggleAutoPlayNext(context, value);
                  showToast(context, context.l10n!.settingChangedMsg);
                },
              ),
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: externalRecommendations,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.externalRecommendations,
              Icons.share,
              description: context.l10n!.externalRecommendationsDescription,
              borderRadius: commonCustomBarRadiusLast,
              trailing: Switch(
                value: value,
                onChanged: (value) =>
                    _toggleExternalRecommendations(context, value),
              ),
            );
          },
        ),

        _buildToolsSection(context),
        _buildSponsorSection(context),
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.tools,
          icon: Icons.build,
        ),
        CustomBar(
          context.l10n!.clearCache,
          Icons.cleaning_services,
          borderRadius: commonCustomBarRadiusFirst,
          onTap: () async {
            final cleared = await clearCache();
            showToast(
              context,
              cleared ? '${context.l10n!.cacheMsg}!' : context.l10n!.error,
            );
          },
        ),
        CustomBar(
          context.l10n!.clearSearchHistory,
          Icons.history,
          onTap: () => _showConfirmationDialog(
            context: context,
            confirmationMessage: context.l10n!.clearSearchHistoryQuestion,
            onSubmit: () {
              searchHistoryNotifier.value = [];
              deleteData('user', 'searchHistory');
              showToast(context, '${context.l10n!.searchHistoryMsg}!');
            },
          ),
        ),
        CustomBar(
          context.l10n!.clearRecentlyPlayed,
          Icons.receipt_long,
          onTap: () => _showConfirmationDialog(
            context: context,
            confirmationMessage: context.l10n!.clearRecentlyPlayedQuestion,
            onSubmit: () {
              userRecentlyPlayed.value = [];
              deleteData('user', 'recentlyPlayedSongs');
              showToast(context, '${context.l10n!.recentlyPlayedMsg}!');
            },
          ),
        ),
        CustomBar(
          context.l10n!.clearListeningStats,
          Icons.schedule,
          onTap: () => _showConfirmationDialog(
            context: context,
            confirmationMessage: context.l10n!.clearListeningStatsQuestion,
            submitMessage: context.l10n!.delete,
            isDangerous: true,
            onSubmit: () async {
              audioHandler.resetListeningStatsSession(flushStats: false);
              await listeningStatsService.clearStats();
              audioHandler.startListeningStatsSessionIfNeeded();
              if (context.mounted) {
                showToast(context, '${context.l10n!.listeningStatsCleared}!');
              }
            },
          ),
        ),
        CustomBar(
          context.l10n!.deleteDownloads,
          Icons.delete,
          onTap: () => _showConfirmationDialog(
            context: context,
            confirmationMessage: context.l10n!.deleteDownloadsQuestion,
            submitMessage: context.l10n!.delete,
            isDangerous: true,
            onSubmit: () async {
              try {
                await offlinePlaylistService.deleteAllDownloads();
                if (context.mounted) {
                  showToast(context, context.l10n!.downloadsDeleted);
                }
              } catch (e) {
                if (context.mounted) {
                  showToast(context, context.l10n!.error);
                }
              }
            },
          ),
        ),
        CustomBar(
          context.l10n!.importSpotifyPlaylist,
          Icons.upload_file,
          onTap: () => context.push('/settings/import-spotify-playlist'),
        ),
        CustomBar(
          context.l10n!.backupUserData,
          Icons.cloud_sync,
          onTap: () => _backupUserData(context),
        ),
        CustomBar(
          context.l10n!.restoreUserData,
          Icons.cloud_download,
          onTap: () async {
            try {
              final result = await restoreData(context);
              if (result.success) {
                reloadSettingsFromStorage();
                reloadSongLibraryStateFromStorage();
                reloadPlaylistLibraryStateFromStorage();
                reloadSearchHistoryFromStorage();
                listeningStatsService.reload();
                await audioHandler.setShuffleMode(
                  shuffleNotifier.value
                      ? AudioServiceShuffleMode.all
                      : AudioServiceShuffleMode.none,
                );
                await audioHandler.setRepeatMode(repeatNotifier.value);
                themeMode = getThemeMode(themeModeSetting);
                brightness = getBrightnessFromThemeMode(themeMode);
                if (context.mounted) {
                  await Lokeshmusic.updateAppState(
                    context,
                    newThemeMode: themeMode,
                    newLocale: languageSetting,
                    newAccentColor: primaryColorSetting,
                    useSystemColor: useSystemColor.value,
                  );
                  NavigationManager.refreshRouter();
                }
              }
              if (context.mounted) {
                showToast(
                  context,
                  result.message,
                  icon: result.success
                      ? null
                      : Icons.error,
                );
              }
            } catch (e, str) {
              logger.log('Error restoring data', error: e, stackTrace: str);
              if (context.mounted) {
                showToast(
                  context,
                  context.l10n!.error,
                  icon: Icons.error,
                );
              }
            }
          },
        ),
        if (!isFdroidBuild && isMobilePlatform)
          CustomBar(
            context.l10n!.downloadAppUpdate,
            Icons.download,
            borderRadius: commonCustomBarRadiusLast,
            onTap: checkAppUpdates,
          ),
      ],
    );
  }

  Widget _buildSponsorSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.becomeSponsor,
          icon: Icons.favorite,
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => launchURL(Uri.parse('https://ko-fi.com/lokesh')),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  FourSidedCookieShape(
                    size: 44,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.14,
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.l10n!.sponsorProject,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOthersSection(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.others,
          icon: Icons.more_horiz,
        ),
        CustomBar(
          context.l10n!.licenses,
          Icons.description,
          borderRadius: commonCustomBarRadiusFirst,
          onTap: () => NavigationManager.router.go('/settings/license'),
        ),
        CustomBar(
          context.l10n!.translate,
          Icons.translate,
          description: context.l10n!.translateDescription,
          onTap: () =>
              launchURL(Uri.parse('https://crowdin.com/project/lokeshmusic')),
        ),
        ValueListenableBuilder<int>(
          valueListenable: logger.logCount,
          builder: (context, logCount, _) => CustomBar(
            '${context.l10n!.copyLogs} ($logCount)',
            Icons.error,
            onTap: () async =>
                showToast(context, await logger.copyLogs(context)),
          ),
        ),
        CustomBar(
          context.l10n!.about,
          Icons.info,
          borderRadius: commonCustomBarRadiusLast,
          onTap: () => NavigationManager.router.go('/settings/about'),
        ),
      ],
    );
  }

  void _showAccentColorPicker(BuildContext context) {
    if (isDesktopPlatform) {
      _showPickerDialog(
        context,
        title: context.l10n!.accentColor,
        content: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: availableColors.length,
          itemBuilder: (context, index) {
            final color = availableColors[index];
            final isSelected = color == primaryColorSetting;

            return InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _selectAccentColor(context, color),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          },
        ),
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;

    showCustomBottomSheet(
      context,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: availableColors.length,
          itemBuilder: (context, index) {
            final color = availableColors[index];
            final isSelected = color == primaryColorSetting;

            return GestureDetector(
              onTap: () => _selectAccentColor(context, color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: colorScheme.onSurface, width: 3)
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  void _selectAccentColor(BuildContext context, Color color) {
    addOrUpdateData<int>('settings', 'accentColor', color.toARGB32());
    Lokeshmusic.updateAppState(
      context,
      newAccentColor: color,
      useSystemColor: false,
    );
    showToast(context, context.l10n!.accentChangeMsg);
    Navigator.of(context, rootNavigator: isDesktopPlatform).pop();
  }

  void _showThemeModePicker(BuildContext context) {
    final availableModes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final modeIcons = [
      if (isDesktopPlatform)
        Icons.desktop_windows
      else
        Icons.smartphone,
      Icons.light_mode,
      Icons.dark_mode,
    ];
    final modeNames = [
      context.l10n!.themeModeSystem,
      context.l10n!.themeModeLight,
      context.l10n!.themeModeDark,
    ];

    Widget buildModeBar(int index) {
      final mode = availableModes[index];

      return BottomSheetBar(
        modeNames[index],
        () {
          addOrUpdateData<int>('settings', 'themeIndex', mode.index);
          Lokeshmusic.updateAppState(context, newThemeMode: mode);
          Navigator.of(context, rootNavigator: isDesktopPlatform).pop();
        },
        themeMode == mode,
        icon: modeIcons[index],
      );
    }

    if (isDesktopPlatform) {
      _showPickerDialog(
        context,
        title: context.l10n!.themeMode,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < availableModes.length; index++)
              buildModeBar(index),
          ],
        ),
      );
      return;
    }

    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottomPadding,
        itemCount: availableModes.length,
        itemBuilder: (context, index) => buildModeBar(index),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final availableLanguages = appLanguages.toList();
    final activeLanguageCode = Localizations.localeOf(context).languageCode;
    final activeScriptCode = Localizations.localeOf(context).scriptCode;
    final activeLanguageFullCode = activeScriptCode != null
        ? '$activeLanguageCode-$activeScriptCode'
        : activeLanguageCode;

    Widget buildLanguageBar(int index) {
      final language = availableLanguages[index];
      final newLocale = getLocaleFromLanguageCode(language);
      final newLocaleFullCode = newLocale.scriptCode != null
          ? '${newLocale.languageCode}-${newLocale.scriptCode}'
          : newLocale.languageCode;

      return BottomSheetBar(getLanguageDisplayName(context, language), () {
        addOrUpdateData<String>('settings', 'languageCode', newLocaleFullCode);
        Lokeshmusic.updateAppState(context, newLocale: newLocale);
        showToast(context, context.l10n!.languageMsg);
        Navigator.of(context, rootNavigator: isDesktopPlatform).pop();
      }, activeLanguageFullCode == newLocaleFullCode);
    }

    if (isDesktopPlatform) {
      _showPickerDialog(
        context,
        title: context.l10n!.language,
        height: 460,
        content: ListView.builder(
          padding: commonListViewBottomPadding,
          itemCount: availableLanguages.length,
          itemBuilder: (context, index) => buildLanguageBar(index),
        ),
      );
      return;
    }

    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottomPadding,
        itemCount: availableLanguages.length,
        itemBuilder: (context, index) => buildLanguageBar(index),
      ),
    );
  }

  void _showAudioQualityPicker(BuildContext context) {
    final availableQualities = ['low', 'medium', 'high'];
    final qualityNames = [
      context.l10n!.audioQualityLow,
      context.l10n!.audioQualityMedium,
      context.l10n!.audioQualityHigh,
    ];
    const qualityIcons = [
      Icons.volume_down,
      Icons.volume_up,
      Icons.graphic_eq,
    ];

    Widget buildQualityBar(int index) {
      final quality = availableQualities[index];

      return BottomSheetBar(
        qualityNames[index],
        () {
          addOrUpdateData<String>('settings', 'audioQuality', quality);
          audioQualitySetting.value = quality;
          showToast(context, context.l10n!.audioQualityMsg);
          Navigator.of(context, rootNavigator: isDesktopPlatform).pop();
        },
        audioQualitySetting.value == quality,
        icon: qualityIcons[index],
      );
    }

    if (isDesktopPlatform) {
      _showPickerDialog(
        context,
        title: context.l10n!.audioQuality,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < availableQualities.length; index++)
              buildQualityBar(index),
          ],
        ),
      );
      return;
    }

    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottomPadding,
        itemCount: availableQualities.length,
        itemBuilder: (context, index) => buildQualityBar(index),
      ),
    );
  }

  void _showPickerDialog(
    BuildContext context, {
    required String title,
    required Widget content,
    double? height,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          content: SizedBox(width: 420, height: height, child: content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleSystemColor(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'useSystemColor', value);
    useSystemColor.value = value;
    Lokeshmusic.updateAppState(
      context,
      newAccentColor: primaryColorSetting,
      useSystemColor: value,
    );
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _togglePureBlack(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'usePureBlackColor', value);
    usePureBlackColor.value = value;
    Lokeshmusic.updateAppState(context);
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleAudioQualityBadge(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'showAudioQualityBadge', value);
    showAudioQualityBadge.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleSyncedLyrics(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'syncedLyricsEnabled', value);
    syncedLyricsEnabled.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  Future<void> _toggleWrapped(BuildContext context, bool value) async {
    if (!value) {
      audioHandler.resetListeningStatsSession(
        countCurrentTick: true,
        flushStats: false,
      );
      await listeningStatsService.flush();
    }

    await addOrUpdateData<bool>('settings', 'wrappedEnabled', value);
    wrappedEnabled.value = value;
    listeningStatsService.reload();
    if (value) {
      audioHandler.startListeningStatsSessionIfNeeded();
    }
    if (context.mounted) {
      showToast(context, context.l10n!.settingChangedMsg);
    }
  }

  void _toggleOfflineMode(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'offlineMode', value);
    offlineMode.value = value;

    // Trigger router refresh and notify about the change
    NavigationManager.refreshRouter();

    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleSponsorBlock(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'sponsorBlockSupport', value);
    sponsorBlockSupport.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleAutoPlayNext(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'playNextSongAutomatically', value);
    playNextSongAutomatically.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleAutomaticUpdateChecks(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'shouldWeCheckUpdates', value);
    shouldWeCheckUpdates.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleExternalRecommendations(BuildContext context, bool value) {
    addOrUpdateData<bool>('settings', 'externalRecommendations', value);
    externalRecommendations.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String confirmationMessage,
    required VoidCallback onSubmit,
    String? submitMessage,
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          submitMessage: submitMessage ?? context.l10n!.clear,
          confirmationMessage: confirmationMessage,
          isDangerous: isDangerous,
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: () {
            Navigator.of(context).pop();
            onSubmit();
          },
        );
      },
    );
  }

  Future<void> _backupUserData(BuildContext context) async {
    try {
      final result = await backupData(context);
      if (context.mounted) {
        showToast(
          context,
          result.message,
          icon: result.success ? null : Icons.error,
        );
      }
    } catch (e, stackTrace) {
      logger.log('Error backing up data', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showToast(
          context,
          context.l10n!.error,
          icon: Icons.error,
        );
      }
    }
  }
}
