import 'package:http/http.dart' as http;

import 'artstation_ripper.dart';

class ArtstnRipper extends ArtStationRipper {
  ArtstnRipper(super.url);

  Uri? _artStationUrl;

  @override
  bool canRip(Uri url) => url.host.endsWith('artstn.co');

  @override
  Future<String> getGID(Uri url) async {
    _artStationUrl ??= await getFinalUrl(url);
    final resolved = _artStationUrl;
    if (resolved == null) {
      throw FormatException('Could not resolve ArtStation short URL: $url');
    }
    return super.getGID(resolved);
  }

  static Future<Uri?> getFinalUrl(Uri url, {http.Client? client}) async {
    if (url.host.endsWith('artstation.com')) return url;

    final closeClient = client == null;
    final activeClient = client ?? http.Client();
    try {
      final request = http.Request('GET', url)
        ..followRedirects = false
        ..headers['User-Agent'] =
            'RipMe:github.com/RipMeApp/ripme:flutter-port';
      final response = await activeClient.send(request);
      final next = redirectTarget(url, response.statusCode,
          response.headers['location'] ?? response.headers['Location']);
      if (next == null) return null;
      return getFinalUrl(next, client: activeClient);
    } finally {
      if (closeClient) activeClient.close();
    }
  }

  static Uri? redirectTarget(Uri source, int statusCode, String? location) {
    if (statusCode ~/ 100 != 3 || location == null || location.isEmpty) {
      return null;
    }
    return source.resolve(location);
  }
}
