import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../abstract_json_ripper.dart';
import '../../utils/utils.dart';

class TwitterRipper extends AbstractJSONRipper {
  TwitterRipper(super.url);

  @override
  String getHost() => "twitter";

  @override
  bool canRip(Uri url) =>
      url.host.endsWith("twitter.com") || url.host.endsWith("x.com");

  @override
  Future<String> getGID(Uri url) async {
    return url.pathSegments.last;
  }

  @override
  Future<void> parseJSON(Uri url) async {
    // Twitter ripping requires complex OAuth or guest tokens usually.
    // Original code used a configured auth key.
    String? authKey = Utils.getConfigString("twitter.auth", null);
    if (authKey == null) {
      throw Exception("Twitter auth key not found in config");
    }

    // Decode base64 auth key (format: API_KEY:API_SECRET)
    final decoded = String.fromCharCodes(base64.decode(authKey));
    final parts = decoded.split(':');
    if (parts.length != 2) {
      throw Exception("Invalid Twitter auth key format");
    }

    final apiKey = parts[0];
    final apiSecret = parts[1];

    // First, we need to get a Bearer token using app-only authentication
    // This is a simplified implementation - the Java version may be more complex
    final basicAuth = base64.encode(utf8.encode('$apiKey:$apiSecret'));

    final tokenResponse = await http.post(
      Uri.parse('https://api.twitter.com/oauth2/token'),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      },
      body: 'grant_type=client_credentials',
    );

    if (tokenResponse.statusCode != 200) {
      throw Exception(
          "Failed to get Twitter Bearer token: ${tokenResponse.statusCode}");
    }

    final tokenData = json.decode(tokenResponse.body);
    final bearerToken = tokenData['access_token'] as String;

    // Now we can use the Bearer token to make API calls
    // Extract tweet ID from URL
    final tweetId = await getGID(url);

    // Fetch the tweet using Twitter API v2
    final tweetResponse = await http.get(
      Uri.parse(
          'https://api.twitter.com/2/tweets/$tweetId?expansions=attachments.media_keys&media.fields=url,preview_image_url,type'),
      headers: {
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (tweetResponse.statusCode != 200) {
      throw Exception("Failed to fetch tweet: ${tweetResponse.statusCode}");
    }

    final tweetData = json.decode(tweetResponse.body) as Map<String, dynamic>;

    // Extract media URLs from tweet data
    final includes = tweetData['includes'] as Map<String, dynamic>?;
    if (includes != null) {
      final media = includes['media'] as List<dynamic>?;
      if (media != null && media.isNotEmpty) {
        for (final mediaItem in media) {
          final item = mediaItem as Map<String, dynamic>;
          final type = item['type'] as String?;
          String? mediaUrl;

          if (type == 'photo') {
            mediaUrl = item['url'] as String?;
          } else if (type == 'video' || type == 'animated_gif') {
            // For videos, use preview image or try to get video URL
            mediaUrl = item['preview_image_url'] as String?;
          }

          if (mediaUrl != null) {
            final uri = Uri.parse(mediaUrl);
            final fileName = uri.pathSegments.isNotEmpty
                ? uri.pathSegments.last
                : 'twitter_${tweetId}_${media.indexOf(mediaItem)}.jpg';
            final saveAs =
                File(workingDir.path + Platform.pathSeparator + fileName);
            await downloadFile(uri, saveAs);
          }
        }
        return; // Successfully downloaded media
      }
    }

    // If no media found in includes, check for text attachments or throw
    throw Exception("No media found in tweet $tweetId");
  }
}
