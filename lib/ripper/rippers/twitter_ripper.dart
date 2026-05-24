import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';

enum TwitterAlbumType { account, search }

class TwitterUrlMatch {
  final TwitterAlbumType type;
  final String gid;
  final String? accountName;
  final String? searchText;

  const TwitterUrlMatch({
    required this.type,
    required this.gid,
    this.accountName,
    this.searchText,
  });
}

class TwitterPageMedia {
  final List<Uri> urls;
  final int? lastMaxId;

  const TwitterPageMedia(this.urls, this.lastMaxId);
}

class TwitterRipper extends AbstractJSONRipper {
  TwitterRipper(super.url);

  TwitterUrlMatch? _match;
  String? _accessToken;
  int _currentRequest = 0;
  int _lastMaxId = 0;

  @override
  String getHost() => 'twitter';

  @override
  bool canRip(Uri url) => classifyUrl(url) != null;

  @override
  Future<String> getGID(Uri url) async {
    final parsed = classifyUrl(url);
    if (parsed == null) {
      throw FormatException('Expected username or search string in url: $url');
    }
    _match = parsed;
    return parsed.gid;
  }

  @override
  Future<void> parseJSON(Uri url) async {
    final parsed = _match ?? classifyUrl(this.url);
    if (parsed == null) {
      throw FormatException('Expected username or search string in url: $url');
    }

    _accessToken = await getAccessToken();
    await checkRateLimits(parsed);

    final maxRequests = Utils.getConfigInteger('twitter.max_requests', 10);
    while (!isStopped && _currentRequest <= maxRequests) {
      final json = await getTweets(parsed, _lastMaxId > 0 ? _lastMaxId - 1 : 0);
      final extracted = mediaFromTweets(
        json,
        ripRetweets: Utils.getConfigBoolean('twitter.rip_retweets', true),
      );
      if (extracted.lastMaxId != null) _lastMaxId = extracted.lastMaxId!;
      final downloads = <RipperDownload>[];
      for (var i = 0; i < extracted.urls.length; i++) {
        final mediaUri = extracted.urls[i];
        final prefix = Utils.getConfigBoolean('download.save_order', true)
            ? '${(i + 1).toString().padLeft(3, '0')}_'
            : '';
        downloads.add(RipperDownload(
          url: mediaUri,
          saveAs:
              File(p.join(workingDir.path, '$prefix${_fileNameFor(mediaUri)}')),
        ));
      }
      await downloadFiles(downloads);
      _currentRequest++;
      if (_currentRequest > maxRequests) break;
      await Http.delay(const Duration(seconds: 2));
    }
  }

  Future<String> getAccessToken() async {
    final authKey = Utils.getConfigString('twitter.auth', null);
    if (authKey == null) {
      throw const FormatException('Twitter auth key not found in config');
    }
    final response = await http.post(
      Uri.parse('https://api.twitter.com/oauth2/token'),
      headers: {
        'Authorization': 'Basic $authKey',
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
        'User-Agent': 'ripe and zipe',
      },
      body: 'grant_type=client_credentials',
    );
    if (response.statusCode != 200) {
      throw HttpException(
          'Failed to get Twitter access token: ${response.statusCode}');
    }
    final json = jsonDecode(response.body);
    return json['access_token'].toString();
  }

  Future<void> checkRateLimits(TwitterUrlMatch match) async {
    final resource =
        match.type == TwitterAlbumType.account ? 'statuses' : 'search';
    final api = match.type == TwitterAlbumType.account
        ? '/statuses/user_timeline'
        : '/search/tweets';
    final response = await http.get(
      Uri.parse(
          'https://api.twitter.com/1.1/application/rate_limit_status.json?resources=$resource'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
        'User-Agent': 'ripe and zipe',
      },
    );
    if (response.statusCode != 200) {
      throw HttpException(
          'Failed to check Twitter rate limits: ${response.statusCode}');
    }
    final json = jsonDecode(response.body);
    final remaining =
        json['resources']?[resource]?[api]?['remaining'] as int? ?? 0;
    if (remaining < 20) {
      throw const HttpException(
          'Less than 20 API calls remaining; not enough to rip.');
    }
  }

  Future<dynamic> getTweets(TwitterUrlMatch match, int maxId) async {
    final uri = getApiUrl(match, maxId);
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'User-Agent': 'ripe and zipe',
    });
    if (response.statusCode != 200) {
      throw HttpException(
          'Failed to fetch Twitter page: ${response.statusCode}');
    }
    final json = jsonDecode(response.body);
    if (json is Map && json['errors'] != null) {
      throw HttpException('Twitter responded with errors: ${json['errors']}');
    }
    return json is Map && json['statuses'] != null
        ? {'tweets': json['statuses']}
        : {'tweets': json};
  }

  static TwitterUrlMatch? classifyUrl(Uri url) {
    final text = url.toString();
    var match = RegExp(
            r'^https?://(m\.)?(twitter|x)\.com/search\?(.*)q=([a-zA-Z0-9%_-]+).*$')
        .firstMatch(text);
    if (match != null) {
      var search = match.group(4)!;
      if (search.startsWith('from%3A')) search = search.substring(7);
      if (search.contains('x')) search = search.replaceAll('x', '');
      return TwitterUrlMatch(
        type: TwitterAlbumType.search,
        searchText: search,
        gid: 'search_${_searchGid(search)}',
      );
    }

    match = RegExp(r'^https?://(m\.)?(twitter|x)\.com/([a-zA-Z0-9_-]+).*$')
        .firstMatch(text);
    if (match != null) {
      final account = match.group(3)!;
      if (account == 'search') return null;
      return TwitterUrlMatch(
        type: TwitterAlbumType.account,
        accountName: account,
        gid: 'account_$account',
      );
    }
    return null;
  }

  static Uri getApiUrl(TwitterUrlMatch match, int maxId) {
    final params = <String, String>{};
    if (match.type == TwitterAlbumType.account) {
      params.addAll({
        'screen_name': match.accountName!,
        'include_entities': 'true',
        'exclude_replies':
            Utils.getConfigBoolean('twitter.exclude_replies', true).toString(),
        'trim_user': 'true',
        'count': '${Utils.getConfigInteger('twitter.max_items_request', 200)}',
        'tweet_mode': 'extended',
      });
    } else {
      params.addAll({
        'q': match.searchText!,
        'include_entities': 'true',
        'result_type': 'recent',
        'count': '100',
        'tweet_mode': 'extended',
      });
    }
    if (maxId > 0) params['max_id'] = '$maxId';
    return Uri.https(
      'api.twitter.com',
      match.type == TwitterAlbumType.account
          ? '/1.1/statuses/user_timeline.json'
          : '/1.1/search/tweets.json',
      params,
    );
  }

  static TwitterPageMedia mediaFromTweets(dynamic json,
      {required bool ripRetweets}) {
    final tweets = json is Map ? json['tweets'] : null;
    if (tweets is! List || tweets.isEmpty) {
      return const TwitterPageMedia([], null);
    }

    final urls = <Uri>[];
    int? lastMaxId;
    for (final rawTweet in tweets.whereType<Map>()) {
      final id = rawTweet['id'];
      if (id is int) lastMaxId = id;
      if (!ripRetweets && rawTweet.containsKey('retweeted_status')) continue;
      final entities = rawTweet['extended_entities'];
      final media = entities is Map ? entities['media'] : null;
      if (media is! List) continue;
      for (final rawMedia in media.whereType<Map>()) {
        final url = mediaUrl(rawMedia);
        if (url != null) urls.add(url);
      }
    }
    return TwitterPageMedia(urls, lastMaxId);
  }

  static Uri? mediaUrl(Map media) {
    final type = media['type']?.toString();
    if (type == 'photo') {
      final mediaUrl = media['media_url']?.toString();
      if (mediaUrl != null && mediaUrl.contains('.twimg.com/')) {
        return Uri.parse('$mediaUrl:orig');
      }
      return null;
    }

    if (type == 'video' || type == 'animated_gif') {
      final variants = media['video_info'] is Map
          ? (media['video_info']['variants'] as List?)
          : null;
      if (variants == null) return null;
      Map? selected;
      var largestBitrate = 0;
      for (final rawVariant in variants.whereType<Map>()) {
        if (!rawVariant.containsKey('bitrate')) continue;
        if (type == 'animated_gif') {
          selected = rawVariant;
          continue;
        }
        final bitrate = (rawVariant['bitrate'] as num?)?.toInt() ?? 0;
        if (bitrate > largestBitrate) {
          largestBitrate = bitrate;
          selected = rawVariant;
        }
      }
      final selectedUrl = selected?['url']?.toString();
      return selectedUrl == null ? null : Uri.parse(selectedUrl);
    }

    return null;
  }

  static String _searchGid(String searchText) {
    final gid = StringBuffer();
    for (var i = 0; i < searchText.length; i++) {
      final code = searchText.codeUnitAt(i);
      final char = searchText[i];
      if (char == '%') {
        gid.write('_');
        i += 2;
      } else if ((code >= 65 && code <= 90) ||
          (code >= 97 && code <= 122) ||
          (code >= 48 && code <= 57)) {
        gid.write(char);
      }
    }
    return gid.toString();
  }

  static String _fileNameFor(Uri url) =>
      url.pathSegments.isNotEmpty ? url.pathSegments.last : 'file';
}
