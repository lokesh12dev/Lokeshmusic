import 'package:flutter_test/flutter_test.dart';
import 'package:lokeshmusic/utilities/artwork_provider.dart';

void main() {
  setUp(ArtworkProvider.clearCache);
  tearDown(ArtworkProvider.clearCache);

  test('reuses providers for artwork already in the cache', () {
    final first = ArtworkProvider.get('https://example.com/cover.jpg');

    expect(
      identical(first, ArtworkProvider.get('https://example.com/cover.jpg')),
      isTrue,
    );
  });

  test('evicts the least recently used provider when the cache is full', () {
    final leastRecent = ArtworkProvider.get('https://example.com/0.jpg');
    final refreshed = ArtworkProvider.get('https://example.com/1.jpg');

    for (var index = 2; index < 256; index++) {
      ArtworkProvider.get('https://example.com/$index.jpg');
    }

    // Refresh the oldest entry so the next insertion evicts entry 1 instead.
    expect(
      identical(leastRecent, ArtworkProvider.get('https://example.com/0.jpg')),
      isTrue,
    );
    ArtworkProvider.get('https://example.com/256.jpg');

    expect(
      identical(leastRecent, ArtworkProvider.get('https://example.com/0.jpg')),
      isTrue,
    );
    expect(
      identical(refreshed, ArtworkProvider.get('https://example.com/1.jpg')),
      isFalse,
    );
  });
}
