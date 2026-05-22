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

  /// Returns true if the URL is a single tweet (contains /status/ in path)
  bool _isTweetUrl(Uri url) {
    return url.path.contains('/status/');
  }

  /// Extracts username from profile URL (e.g., https://twitter.com/username)
  String? _getUsernameFromUrl(Uri url) {
    final path = url.path;
    if (path.isEmpty || path == '/') return null;

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final username = segments[0];
    // Check for special paths like 'with_replies', 'media', 'statuses'
    if (username == 'with_replies' ||
        username == 'media' ||
        username == 'statuses') {
      return null;
    }

    return username;
  }

  /// Gets Bearer token for Twitter API v2
  Future<String> _getBearerToken() async {
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
    return tokenData['access_token'] as String;
  }

  /// Gets user ID from username using Twitter API v2
  Future<String> _getUserIdFromUsername(
      String username, String bearerToken) async {
    final response = await http.get(
      Uri.parse('https://api.twitter.com/2/users/by/username/$username'),
      headers: {
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to get user ID for $username: ${response.statusCode}");
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final userData = data['data'] as Map<String, dynamic>?;
    if (userData == null) {
      throw Exception("User $username not found");
    }

    return userData['id'] as String;
  }

  /// Fetches user timeline with pagination
  Future<void> _fetchUserTimeline(String userId, String bearerToken) async {
    String? nextToken;
    int pageCount = 0;
    const maxPages = 10; // Limit to avoid rate limits

    do {
      final queryParams = {
        'max_results': '100', // Max per page
        'expansions': 'attachments.media_keys',
        'media.fields': 'url,preview_image_url,type',
        'exclude': 'retweets,replies', // Only original tweets with media
      };

      if (nextToken != null) {
        queryParams['pagination_token'] = nextToken;
      }

      final uri = Uri.parse('https://api.twitter.com/2/users/$userId/tweets')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $bearerToken',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to fetch user timeline: ${response.statusCode}");
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Extract media from tweets in this page
      await _extractMediaFromTweets(
          data, 'user_timeline_page_${pageCount + 1}');

      // Get next token for pagination
      final meta = data['meta'] as Map<String, dynamic>?;
      nextToken = meta?['next_token'] as String?;

      pageCount++;
      if (pageCount >= maxPages) {
        break;
      }

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(seconds: 1));
    } while (nextToken != null);
  }

  /// Extracts media from tweet data and downloads it
  Future<void> _extractMediaFromTweets(
      Map<String, dynamic> tweetData, String pageId) async {
    final includes = tweetData['includes'] as Map<String, dynamic>?;
    if (includes == null) return;

    final media = includes['media'] as List<dynamic>?;
    if (media == null || media.isEmpty) return;

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
            : 'twitter_${pageId}_${media.indexOf(mediaItem)}.jpg';
        final saveAs =
            File(workingDir.path + Platform.pathSeparator + fileName);
        await downloadFile(uri, saveAs);
      }
    }
  }

  /// Extracts media from a single tweet
  Future<void> _extractMediaFromSingleTweet(
      Map<String, dynamic> tweetData, String tweetId) async {
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
    throw Exception("No media found in tweet $tweetId");
  }

  @override
  Future<void> parseJSON(Uri url) async {
    final bearerToken = await _getBearerToken();

    if (_isTweetUrl(url)) {
      // Single tweet URL
      final tweetId = await getGID(url);

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
      await _extractMediaFromSingleTweet(tweetData, tweetId);
    } else {
      // User profile URL
      final username = _getUsernameFromUrl(url);
      if (username == null) {
        throw Exception("Could not extract username from URL: $url");
      }

      final userId = await _getUserIdFromUsername(username, bearerToken);
      await _fetchUserTimeline(userId, bearerToken);
    }
  }
}
