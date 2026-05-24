import 'dart:io';
import 'dart:math';

import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';

enum TumblrAlbumType { subdomain, tag, post, liked }

class TumblrUrlMatch {
  final TumblrAlbumType type;
  final String subdomain;
  final String gid;
  final String? tagName;
  final String? postNumber;

  const TumblrUrlMatch({
    required this.type,
    required this.subdomain,
    required this.gid,
    this.tagName,
    this.postNumber,
  });
}

class TumblrMedia {
  final Uri url;
  final String date;

  const TumblrMedia(this.url, this.date);
}

class TumblrRipper extends AbstractJSONRipper {
  TumblrRipper(super.url);

  static const String _authConfigKey = 'tumblr.auth';
  static const List<String> _defaultApiKeys = [
    'JFNLu3CbINQjRdUvZibXW9VpSEVYYtiPJ86o8YmvgLZIoKyuNX',
    'FQrwZMCxVnzonv90rgNUJcAk4FpnoS0mYuSuGYqIpM2cFgp9L4',
    'qpdkY6nMknksfvYAhf2xIHp0iNRLkMlcWShxqzXyFJRxIsZ1Zz',
  ];

  TumblrUrlMatch? _match;
  int _index = 1;
  bool _useDefaultApiKey = false;
  String? _selectedDefaultApiKey;

  @override
  String getHost() => 'tumblr';

  @override
  bool canRip(Uri url) => classifyUrl(url) != null;

  @override
  Future<String> getGID(Uri url) async {
    final parsed = classifyUrl(url);
    if (parsed == null) {
      throw const FormatException(
          'Expected format: http://subdomain[.tumblr.com][/tagged/tag|/post/postno]');
    }
    _match = parsed;
    return parsed.gid;
  }

  @override
  Future<void> parseJSON(Uri url) async {
    final parsed = _match ?? classifyUrl(this.url);
    if (parsed == null) {
      throw const FormatException(
          'Expected format: http://subdomain[.tumblr.com][/tagged/tag|/post/postno]');
    }

    final mediaTypes = parsed.type == TumblrAlbumType.post
        ? const ['post']
        : const ['photo', 'video', 'audio'];

    for (final mediaType in mediaTypes) {
      if (isStopped) break;
      var offset = 0;
      while (!isStopped) {
        var apiUrl = getTumblrApiUrl(parsed, mediaType, offset, getApiKey());
        sendUpdate(RipStatus.loadingResource, apiUrl);
        dynamic json;
        try {
          json = await Http.getJSON(Uri.parse(apiUrl));
        } catch (e) {
          if (!_useDefaultApiKey && e.toString().contains('401')) {
            _useDefaultApiKey = true;
            final key = getApiKey();
            await Utils.setConfigString(_authConfigKey, key);
            sendUpdate(RipStatus.downloadWarn,
                '401 Unauthorized. Will retry with default Tumblr API key: $key');
            apiUrl = getTumblrApiUrl(parsed, mediaType, offset, key);
            sendUpdate(RipStatus.loadingResource, apiUrl);
            json = await Http.getJSON(Uri.parse(apiUrl));
          } else {
            rethrow;
          }
        }

        await Http.delay(const Duration(seconds: 1));
        final media = mediaFromJson(json, parsed.type);
        if (media.isEmpty) break;
        await _downloadMedia(media, parsed.type);
        if (parsed.type == TumblrAlbumType.post) break;
        offset += 20;
      }
    }
  }

  Future<void> _downloadMedia(
      List<TumblrMedia> media, TumblrAlbumType albumType) async {
    final downloads = <RipperDownload>[];
    for (final item in media) {
      if (isStopped) break;
      if (albumType == TumblrAlbumType.tag) {
        downloads.add(RipperDownload(
          url: item.url,
          saveAs: File(p.join(
              workingDir.path, '${item.date} ${_fileNameFor(item.url)}')),
        ));
      }
      final prefix = Utils.getConfigBoolean('download.save_order', true)
          ? '${_index.toString().padLeft(3, '0')}_'
          : '';
      downloads.add(RipperDownload(
        url: item.url,
        saveAs:
            File(p.join(workingDir.path, '$prefix${_fileNameFor(item.url)}')),
      ));
      _index++;
    }
    await downloadFiles(downloads);
  }

  String getApiKey() {
    _selectedDefaultApiKey ??=
        _defaultApiKeys[Random(0).nextInt(_defaultApiKeys.length)];
    final configured =
        Utils.getConfigString(_authConfigKey, _defaultApiKeys.first);
    if (_useDefaultApiKey || configured == _defaultApiKeys.first) {
      return _selectedDefaultApiKey!;
    }
    return configured ?? _selectedDefaultApiKey!;
  }

  static TumblrUrlMatch? classifyUrl(Uri url) {
    final text = url.toString();
    const domainRegex = r'^https?://([a-zA-Z0-9\-.]+)';

    var match =
        RegExp('$domainRegex/tagged/([a-zA-Z0-9\\-%]+).*\$').firstMatch(text);
    if (match != null) {
      final subdomain = match.group(1)!;
      final tag = match.group(2)!.replaceAll('-', '+').replaceAll('_', '%20');
      return TumblrUrlMatch(
        type: TumblrAlbumType.tag,
        subdomain: subdomain,
        tagName: tag,
        gid: '${subdomain}_tag_${tag.replaceAll('%20', ' ')}',
      );
    }

    match = RegExp('$domainRegex/post/([0-9]+).*\$').firstMatch(text);
    if (match != null) {
      final subdomain = match.group(1)!;
      final postNumber = match.group(2)!;
      return TumblrUrlMatch(
        type: TumblrAlbumType.post,
        subdomain: subdomain,
        postNumber: postNumber,
        gid: '${subdomain}_post_$postNumber',
      );
    }

    match =
        RegExp(r'https?://([a-z0-9_-]+)\.tumblr\.com/likes').firstMatch(text);
    if (match != null) {
      final subdomain = match.group(1)!;
      return TumblrUrlMatch(
        type: TumblrAlbumType.liked,
        subdomain: subdomain,
        gid: '${subdomain}_liked',
      );
    }

    match = RegExp(r'https://www\.tumblr\.com/liked/by/([a-z0-9_-]+)')
        .firstMatch(text);
    if (match != null) {
      final subdomain = match.group(1)!;
      return TumblrUrlMatch(
        type: TumblrAlbumType.liked,
        subdomain: subdomain,
        gid: '${subdomain}_liked',
      );
    }

    match = RegExp('$domainRegex/?\$').firstMatch(text);
    if (match != null && url.host.endsWith('tumblr.com')) {
      final subdomain = match.group(1)!;
      return TumblrUrlMatch(
        type: TumblrAlbumType.subdomain,
        subdomain: subdomain,
        gid: subdomain,
      );
    }

    return null;
  }

  static String getTumblrApiUrl(
      TumblrUrlMatch match, String mediaType, int offset, String apiKey) {
    if (match.type == TumblrAlbumType.liked) {
      return 'http://api.tumblr.com/v2/blog/${match.subdomain}/likes?api_key=$apiKey&offset=$offset';
    }
    if (match.type == TumblrAlbumType.post) {
      return 'http://api.tumblr.com/v2/blog/${match.subdomain}/posts?id=${match.postNumber}&api_key=$apiKey';
    }
    var url =
        'http://api.tumblr.com/v2/blog/${match.subdomain}/posts/$mediaType?api_key=$apiKey&offset=$offset';
    if (match.type == TumblrAlbumType.tag) {
      url += '&tag=${match.tagName}';
    }
    return url;
  }

  static List<TumblrMedia> mediaFromJson(dynamic json, TumblrAlbumType type) {
    final response = json is Map ? json['response'] : null;
    if (response is! Map) return const [];
    final posts = type == TumblrAlbumType.liked
        ? response['liked_posts']
        : response['posts'];
    if (posts is! List || posts.isEmpty) return const [];

    final result = <TumblrMedia>[];
    for (final rawPost in posts.whereType<Map>()) {
      final date = rawPost['date']?.toString() ?? '';
      final photos = rawPost['photos'];
      if (photos is List) {
        for (final rawPhoto in photos.whereType<Map>()) {
          final original = rawPhoto['original_size'];
          final photoUrl = original is Map ? original['url']?.toString() : null;
          if (photoUrl != null) {
            result.add(TumblrMedia(_highestQualityImage(photoUrl), date));
          }
        }
      } else if (rawPost['video_url'] != null) {
        result.add(TumblrMedia(_https(rawPost['video_url'].toString()), date));
      } else if (rawPost['audio_url'] != null) {
        result.add(TumblrMedia(_https(rawPost['audio_url'].toString()), date));
        if (rawPost['album_art'] != null) {
          result
              .add(TumblrMedia(_https(rawPost['album_art'].toString()), date));
        }
      } else if (rawPost['body'] != null) {
        final body = html.parse(rawPost['body'].toString());
        final image = body.querySelector('img')?.attributes['src'];
        if (image != null && image.isNotEmpty) {
          result.add(TumblrMedia(_highestQualityImage(image), date));
        }
      }
      if (type == TumblrAlbumType.post) break;
    }
    return result;
  }

  static Uri _highestQualityImage(String url) {
    final secure = _https(url).toString();
    return Uri.parse(secure.replaceFirstMapped(
      RegExp(r'_[0-9]+\.(jpg|png|gif|bmp)$', caseSensitive: false),
      (match) => '_1280.${match.group(1)}',
    ));
  }

  static Uri _https(String url) =>
      Uri.parse(url.replaceFirst('http:', 'https:'));

  static String _fileNameFor(Uri url) =>
      url.pathSegments.isNotEmpty ? url.pathSegments.last : 'file';
}
