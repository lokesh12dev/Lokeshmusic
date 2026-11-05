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
import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:lokeshmusic/constants/version.dart';
import 'package:lokeshmusic/extensions/l10n.dart';
import 'package:lokeshmusic/main.dart';
import 'package:lokeshmusic/services/data_manager.dart';
import 'package:lokeshmusic/services/router_service.dart';
import 'package:lokeshmusic/services/settings_manager.dart';
import 'package:lokeshmusic/utilities/platform_utils.dart';
import 'package:lokeshmusic/utilities/url_launcher.dart';
import 'package:lokeshmusic/widgets/auto_format_text.dart';

const String checkUrl =
    'https://raw.githubusercontent.com/lokesh12dev/Lokeshmusic/update/check.json';
const String releasesUrl =
    'https://api.github.com/repos/lokesh12dev/Lokeshmusic/releases/latest';
const String releasesPageUrl =
    'https://github.com/lokesh12dev/Lokeshmusic/releases/latest';

Future<void> checkAppUpdates() async {
  // Update distribution targets Android APK builds only.
  if (!isMobilePlatform) return;
  try {
    final response = await http.get(
      Uri.parse(releasesUrl),
      headers: const {'Accept': 'application/vnd.github+json'},
    );

    if (response.statusCode != 200) {
      logger.log(
        'Fetch update API (releasesUrl) returned status code ${response.statusCode}',
      );
      return;
    }

    final releasesResponse = json.decode(response.body) as Map<String, dynamic>;
    final latestVersion =
        (releasesResponse['tag_name'] ?? releasesResponse['name'] ?? '')
            .toString();

    if (latestVersion.isEmpty ||
        !isLatestVersionHigher(appVersion, latestVersion)) {
      return;
    }

    final displayVersion = normalizeVersion(latestVersion);
    final downloadUrl = await getReleaseDownloadUrl(releasesResponse);

    await showDialog(
      context: NavigationManager().context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FluentIcons.arrow_download_24_regular,
                  color: colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n!.appUpdateIsAvailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'V$displayVersion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height / 2.5,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: AutoFormatText(
                    text: releasesResponse['body']?.toString() ?? '',
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.l10n!.cancel),
            ),
            FilledButton.icon(
              onPressed: () {
                launchURL(Uri.parse(downloadUrl));
                Navigator.pop(context);
              },
              icon: const Icon(FluentIcons.arrow_download_20_regular),
              label: Text(context.l10n!.download),
            ),
          ],
        );
      },
    );
  } catch (e, stackTrace) {
    logger.log('Error in checkAppUpdates', error: e, stackTrace: stackTrace);
  }
}

void showUpdateCheckDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        icon: Icon(
          FluentIcons.arrow_sync_circle_24_regular,
          color: colorScheme.primary,
          size: 40,
        ),
        title: Text(
          context.l10n!.checkForUpdates,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          context.l10n!.enableUpdateChecksDescription,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () {
              shouldWeCheckUpdates.value = false;
              addOrUpdateData<bool>('settings', 'shouldWeCheckUpdates', false);
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.l10n!.no),
          ),
          FilledButton(
            onPressed: () {
              shouldWeCheckUpdates.value = true;
              addOrUpdateData<bool>('settings', 'shouldWeCheckUpdates', true);
              if (!isFdroidBuild && kReleaseMode && !offlineMode.value) {
                checkAppUpdates();
                isUpdateChecked = true;
              }
              Navigator.of(context).pop();
            },
            child: Text(context.l10n!.yes),
          ),
        ],
      );
    },
  );
}

/// Strips a leading `v` and any build metadata so tags like `v10.6.0` and
/// versions like `10.6.0+186` compare cleanly.
String normalizeVersion(String version) {
  final trimmed = version.trim();
  final withoutPrefix = trimmed.startsWith(RegExp('[vV]'))
      ? trimmed.substring(1)
      : trimmed;
  return withoutPrefix.split('+').first;
}

List<int> _parseVersion(String version) {
  return normalizeVersion(version).split('.').map((part) {
    final match = RegExp(r'^\d+').firstMatch(part.trim());
    return match == null ? 0 : int.parse(match.group(0)!);
  }).toList();
}

bool isLatestVersionHigher(String appVersion, String latestVersion) {
  final parsedAppVersion = _parseVersion(appVersion);
  final parsedAppLatestVersion = _parseVersion(latestVersion);
  final length = parsedAppVersion.length > parsedAppLatestVersion.length
      ? parsedAppVersion.length
      : parsedAppLatestVersion.length;
  for (var i = 0; i < length; i++) {
    final value1 = i < parsedAppVersion.length ? parsedAppVersion[i] : 0;
    final value2 = i < parsedAppLatestVersion.length
        ? parsedAppLatestVersion[i]
        : 0;
    if (value2 > value1) {
      return true;
    } else if (value2 < value1) {
      return false;
    }
  }

  return false;
}

Future<String> getCPUArchitecture() async {
  try {
    final info = await Process.run('uname', ['-m']);
    return info.stdout.toString().trim();
  } catch (_) {
    return '';
  }
}

/// Picks the best APK asset from a GitHub release, preferring the smaller
/// arm64 build on 64-bit devices and the universal build elsewhere.
Future<String> getReleaseDownloadUrl(Map<String, dynamic> release) async {
  final assets = release['assets'] as List<dynamic>? ?? const [];
  String? universal;
  String? arm64;
  String? firstApk;

  for (final asset in assets) {
    if (asset is! Map) continue;
    final name = (asset['name'] ?? '').toString().toLowerCase();
    final url = asset['browser_download_url']?.toString();
    if (url == null || !name.endsWith('.apk')) continue;
    firstApk ??= url;
    if (name.contains('arm64')) {
      arm64 = url;
    } else if (name.contains('universal')) {
      universal = url;
    }
  }

  if (await getCPUArchitecture() == 'aarch64' && arm64 != null) {
    return arm64;
  }
  return universal ?? arm64 ?? firstApk ?? releasesPageUrl;
}

/// Fetch only the announcement URL from the `check.json` file and set the
/// global `announcementURL` ValueNotifier. This does not trigger releases
/// fetching or any update dialogs/downloads and is safe to call for F‑Droid
/// builds where update prompts are not allowed.
Future<void> fetchAnnouncementOnly() async {
  try {
    final response = await http.get(Uri.parse(checkUrl));

    if (response.statusCode != 200) {
      logger.log(
        'Fetch announcement (checkUrl) call returned status code ${response.statusCode}',
      );
      return;
    }

    final map = json.decode(response.body) as Map<String, dynamic>;
    final ann = map['announcementurl'];
    if (ann != null) {
      announcementURL.value = ann.toString();
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error in fetchAnnouncementOnly',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
