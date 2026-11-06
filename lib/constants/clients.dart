import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Clients tried in order - the next one is used only if the previous fails.
///
/// `visionOs` is first because it returns direct audio-only URLs (up to
/// ~160 kbps) without requiring a PO token or signature deciphering.
/// `android` is the fallback: without a PO token it only exposes a playable
/// **muxed** stream (itag 18), but that is enough to keep playback working.
/// [YoutubeApiClient.ios] is not used: it returns no host for many tracks.
const fallbackClients = [YoutubeApiClient.visionOs, YoutubeApiClient.android];

// Cap on a single client attempt. The overall budget is shared, so a client
// that stalls cannot prevent the fallback from being tried.
const Duration _clientAttemptTimeout = Duration(seconds: 8);

// Client that produced the stream URL of each song, so playback can send
// the matching headers.
final Map<String, YoutubeApiClient> _songClients = {};

Future<StreamManifest> getManifestWithFallback(
  YoutubeExplode yt,
  String songId, {
  required Duration timeout,
}) async {
  Object? lastError;
  StackTrace? lastStack;
  // Share one budget across all clients so a hanging request cannot stack
  // up into a minute-long wait before the song starts (or fails).
  final deadline = DateTime.now().add(timeout);

  for (final client in fallbackClients) {
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) break;

    final attemptTimeout = remaining < _clientAttemptTimeout
        ? remaining
        : _clientAttemptTimeout;

    try {
      final manifest = await yt.videos.streams
          .getManifest(
            songId,
            ytClients: [client],
            // Skipping the watch page avoids YouTube's aggressive rate
            // limiting on that endpoint. These clients expose their audio
            // URLs directly in the player response, so no signature
            // deciphering is needed.
            requireWatchPage: false,
          )
          .timeout(attemptTimeout);

      // A manifest can contain formats whose `url` is empty (ANDROID does
      // this for every adaptive audio entry when no PO token is supplied).
      // Keep only streams that can actually be played, and require at least
      // one audio-bearing stream; otherwise try the next client.
      final playableStreams = manifest.streams
          .where((stream) => stream.url.hasScheme && stream.url.host.isNotEmpty)
          .toList();
      final playable = StreamManifest(playableStreams);
      if (playable.audio.isEmpty) {
        throw VideoUnavailableException(
          'No playable audio streams for "$songId"',
        );
      }

      _songClients[songId] = client;
      return playable;
    } catch (e, s) {
      lastError = e;
      lastStack = s;
    }
  }

  Error.throwWithStackTrace(lastError!, lastStack!);
}

/// Returns the client that minted a googlevideo URL by reading its `c` query
/// parameter (e.g. `ANDROID`, `VISIONOS`). Returns null when the URL does not
/// identify a known client.
YoutubeApiClient? clientFromStreamUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final name = Uri.tryParse(url)?.queryParameters['c']?.toUpperCase();
  if (name == null) return null;
  for (final client in fallbackClients) {
    final clientName = client.payload['context']?['client']?['clientName'];
    if (clientName is String && clientName.toUpperCase() == name) {
      return client;
    }
  }
  return null;
}

/// Headers googlevideo.com expects for URLs minted by the client that served
/// [songId]; a mismatched User-Agent can cause HTTP 403.
///
/// When [url] is provided it takes precedence over the in-memory mapping,
/// because cached URLs can outlive the process that resolved them.
Map<String, String> streamPlaybackHeaders(String? songId, {String? url}) {
  final client =
      clientFromStreamUrl(url) ?? _songClients[songId] ?? fallbackClients.first;
  final userAgent = client.payload['context']?['client']?['userAgent'];
  return {
    if (userAgent is String) 'user-agent': userAgent,
    for (final entry in client.headers.entries) entry.key: '${entry.value}',
  };
}
