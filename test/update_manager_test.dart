import 'package:flutter_test/flutter_test.dart';
import 'package:lokeshmusic/services/update_manager.dart';

void main() {
  group('normalizeVersion', () {
    test('strips a leading v', () {
      expect(normalizeVersion('v10.6.0'), '10.6.0');
    });

    test('strips build metadata', () {
      expect(normalizeVersion('10.6.0+186'), '10.6.0');
    });

    test('handles tags with both prefix and metadata', () {
      expect(normalizeVersion('V10.6.0+186'), '10.6.0');
    });
  });

  group('isLatestVersionHigher', () {
    test('detects a newer patch release', () {
      expect(isLatestVersionHigher('10.6.0', 'v10.6.1'), isTrue);
    });

    test('detects a newer major release', () {
      expect(isLatestVersionHigher('9.9.9', 'v10.0.0'), isTrue);
    });

    test('treats equal versions as current', () {
      expect(isLatestVersionHigher('10.6.0', 'v10.6.0'), isFalse);
      expect(isLatestVersionHigher('10.6.0', '10.6.0+186'), isFalse);
    });

    test('does not downgrade', () {
      expect(isLatestVersionHigher('10.6.0', 'v10.5.9'), isFalse);
    });
  });

  group('getReleaseDownloadUrl', () {
    test(
      'uses the universal APK when no architecture-specific build exists',
      () async {
        final url = await getReleaseDownloadUrl({
          'assets': [
            {
              'name': 'LokeshMusic-v10.6.0-universal.apk',
              'browser_download_url': 'https://github.com/lokesh12dev/Lokeshmusic/releases/download/v10.6.0/LokeshMusic-v10.6.0-universal.apk',
            },
            {
              'name': 'SHA256SUMS.txt',
              'browser_download_url': 'https://github.com/lokesh12dev/Lokeshmusic/releases/download/v10.6.0/SHA256SUMS.txt',
            },
          ],
        });

        expect(url, endsWith('LokeshMusic-v10.6.0-universal.apk'));
      },
    );

    test('falls back to the release page when no APK is attached', () async {
      final url = await getReleaseDownloadUrl({'assets': const []});
      expect(url, releasesPageUrl);
    });
  });
}
