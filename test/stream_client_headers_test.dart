import 'package:flutter_test/flutter_test.dart';
import 'package:lokeshmusic/constants/clients.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  group('clientFromStreamUrl', () {
    test('maps the c parameter to the client that minted the URL', () {
      expect(
        clientFromStreamUrl(
          'https://rr1---sn.googlevideo.com/videoplayback?c=ANDROID&itag=18',
        ),
        same(YoutubeApiClient.android),
      );
      expect(
        clientFromStreamUrl(
          'https://rr1---sn.googlevideo.com/videoplayback?c=VISIONOS&itag=251',
        ),
        same(YoutubeApiClient.visionOs),
      );
    });

    test('returns null when the URL has no usable c parameter', () {
      expect(
        clientFromStreamUrl(
          'https://rr1---sn.googlevideo.com/videoplayback?itag=18',
        ),
        isNull,
      );
      expect(clientFromStreamUrl(''), isNull);
      expect(clientFromStreamUrl(null), isNull);
    });
  });

  test('streamPlaybackHeaders follows the URL instead of the first client', () {
    final headers = streamPlaybackHeaders(
      null,
      url: 'https://rr1---sn.googlevideo.com/videoplayback?c=VISIONOS',
    );

    expect(
      headers['user-agent'],
      YoutubeApiClient.visionOs.payload['context']['client']['userAgent'],
    );
  });
}
