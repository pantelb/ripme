import 'dart:io';

import 'package:path/path.dart' as p;

import '../abstract_ripper.dart';
import '../abstract_json_ripper.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import 'redgifs_ripper.dart';

class RedditMedia {
  final Uri url;
  final String prefix;
  final String? subdirectory;
  final Map<String, String>? headers;

  const RedditMedia({
    required this.url,
    required this.prefix,
    this.subdirectory,
    this.headers,
  });
}

class RedditRipper extends AbstractJSONRipper {
  RedditRipper(Uri url) : super(sanitizeUrl(url));

  static const String _redditUserAgent =
      'RipMe:github.com/RipMeApp/ripme:flutter-port';
  DateTime? _lastRequestAt;

  @override
  String getHost() => 'reddit';

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith('reddit.com');

  static Uri sanitizeUrl(Uri url) {
    return Uri.parse(
        url.toString().replaceAll('reddit.com/u/', 'reddit.com/user/'));
  }

  @override
  Future<String> getGID(Uri url) async {
    final sanitized = sanitizeUrl(url);
    final text = sanitized.toString();

    RegExpMatch? match = RegExp(
            r'^https?://[a-zA-Z0-9.]*reddit\.com/(user|u)/([a-zA-Z0-9_-]{3,}).*$')
        .firstMatch(text);
    if (match != null) return 'user_${match.group(2)}';

    match = RegExp(
            r'^https?://[a-zA-Z0-9.]*reddit\.com/.*comments/([a-zA-Z0-9]{1,8}).*$')
        .firstMatch(text);
    if (match != null) return 'post_${match.group(1)}';

    match =
        RegExp(r'^https?://[a-zA-Z0-9.]*reddit\.com/gallery/([a-zA-Z0-9]+).*$')
            .firstMatch(text);
    if (match != null) return 'post_${match.group(1)}';

    match = RegExp(r'^https?://[a-zA-Z0-9.]*reddit\.com/r/([a-zA-Z0-9_]+).*$')
        .firstMatch(text);
    if (match != null) return 'sub_${match.group(1)}';

    throw FormatException(
        "Only accepts Reddit user pages, subreddits, posts, or galleries. Got $url");
  }

  @override
  Future<void> parseJSON(Uri url) async {
    Uri? jsonUrl = getJsonUrl(this.url);
    while (jsonUrl != null && !isStopped) {
      final json = await _getRedditJson(jsonUrl);
      final media = await extractMediaFromJson(json);
      final downloads = <RipperDownload>[];
      for (final item in media) {
        if (isStopped) break;
        final directory = item.subdirectory == null
            ? workingDir
            : Directory(p.join(
                workingDir.path, Utils.filesystemSafe(item.subdirectory!)));
        final fileName = _fileNameFor(item);
        downloads.add(
          RipperDownload(
            url: item.url,
            saveAs: File(p.join(directory.path, fileName)),
            headers: item.headers,
          ),
        );
      }
      await downloadFiles(downloads);
      jsonUrl = nextPageUrl(json, jsonUrl);
    }
  }

  static Uri getJsonUrl(Uri url) {
    final sanitized = sanitizeUrl(url);
    final galleryMatch =
        RegExp(r'^https?://[a-zA-Z0-9.]*reddit\.com/gallery/([a-zA-Z0-9]+).*$')
            .firstMatch(sanitized.toString());
    if (galleryMatch != null) {
      return Uri.parse('https://reddit.com/${galleryMatch.group(1)}.json');
    }

    final path = sanitized.path.endsWith('/')
        ? sanitized.path.substring(0, sanitized.path.length - 1)
        : sanitized.path;
    return sanitized.replace(path: '$path.json');
  }

  static Uri? nextPageUrl(dynamic json, Uri currentUrl) {
    final listings = _asListings(json);
    for (final listing in listings) {
      final after = listing['data']?['after'];
      if (after is String && after.isNotEmpty) {
        final params = Map<String, String>.from(currentUrl.queryParameters)
          ..['after'] = after;
        return currentUrl.replace(queryParameters: params);
      }
    }
    return null;
  }

  static Future<List<RedditMedia>> extractMediaFromJson(dynamic json) async {
    final result = <RedditMedia>[];
    for (final child in _childrenFromListings(json)) {
      result.addAll(await _mediaFromChild(child));
    }
    return result;
  }

  Future<dynamic> _getRedditJson(Uri url) async {
    final now = DateTime.now();
    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final elapsed = now.difference(lastRequestAt);
      if (elapsed < const Duration(seconds: 2)) {
        await Future<void>.delayed(const Duration(seconds: 2) - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();

    return Http.getJSON(url, headers: {
      'User-Agent': _redditUserAgent,
    });
  }

  static Future<List<RedditMedia>> _mediaFromChild(dynamic child) async {
    final data = child['data'];
    if (data is! Map) return const [];

    final media = <RedditMedia>[];
    final kind = child['kind'];
    final id = data['id']?.toString() ?? 'reddit';
    final title = data['title']?.toString() ?? '';

    if (kind == 't1') {
      media.addAll(
          await _mediaFromBody(data['body']?.toString() ?? '', id, title));
    } else if (kind == 't3') {
      if (data['gallery_data'] != null && data['media_metadata'] != null) {
        media.addAll(_mediaFromGallery(
            data['gallery_data'], data['media_metadata'], id, title));
      } else if (data['is_self'] == true) {
        media.addAll(await _mediaFromBody(
            data['selftext']?.toString() ?? '', id, title));
      } else {
        final url = data['url']?.toString();
        if (url != null) {
          media.addAll(await _mediaFromUrl(url, id, title));
        }
      }
    }

    final replies = data['replies'];
    if (replies is Map) {
      final children = replies['data']?['children'];
      if (children is List) {
        for (final reply in children) {
          media.addAll(await _mediaFromChild(reply));
        }
      }
    }

    return media;
  }

  static Future<List<RedditMedia>> _mediaFromBody(
      String body, String id, String title) async {
    final media = <RedditMedia>[];
    final matches = RegExp(r'https?://[^\s<>()"]+').allMatches(body);
    for (final match in matches) {
      var url = match.group(0)!;
      while (url.endsWith(')') || url.endsWith('.') || url.endsWith(',')) {
        url = url.substring(0, url.length - 1);
      }
      media.addAll(await _mediaFromUrl(url, id, title));
    }
    return media;
  }

  static Future<List<RedditMedia>> _mediaFromUrl(
      String value, String id, String title) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return const [];

    final host = uri.host.toLowerCase();
    if (_isDirectMedia(uri)) {
      return [
        RedditMedia(
          url: uri,
          prefix: _safePrefix(id, title),
          subdirectory: title.isEmpty ? null : title,
        ),
      ];
    }

    if (host.contains('i.reddituploads.com')) {
      final uploadId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : id;
      return [
        RedditMedia(
          url: uri,
          prefix: _safePrefix('$id-$uploadId', title),
          subdirectory: title.isEmpty ? null : title,
        ),
      ];
    }

    if (host.contains('v.redd.it')) {
      final videoUrl = await _bestRedditVideoUrl(uri);
      if (videoUrl == null) return const [];
      return [
        RedditMedia(
          url: videoUrl,
          prefix: _safePrefix('$id-${uri.pathSegments.first}', title),
          subdirectory: title.isEmpty ? null : title,
        ),
      ];
    }

    if (host.contains('redgifs.com') ||
        host.contains('gifdeliverynetwork.com')) {
      final videoUrl = await RedgifsRipper.getVideoUrl(uri);
      return [
        RedditMedia(
          url: Uri.parse(videoUrl),
          prefix: _safePrefix(id, title),
          subdirectory: title.isEmpty ? null : title,
          headers: {'Referer': 'https://www.redgifs.com/'},
        ),
      ];
    }

    return const [];
  }

  static List<RedditMedia> _mediaFromGallery(
      dynamic galleryData, dynamic metadata, String id, String title) {
    final items = galleryData['items'];
    if (items is! List || metadata is! Map) return const [];

    final result = <RedditMedia>[];
    for (var i = 0; i < items.length; i++) {
      final mediaId = items[i]['media_id'];
      final media = metadata[mediaId];
      final source = media?['s'];
      final url = source?['gif'] ?? source?['u'];
      if (url is! String) continue;
      result.add(
        RedditMedia(
          url: Uri.parse(url.replaceAll('&amp;', '&')),
          prefix: '$id-${(i + 1).toString().padLeft(2, '0')}-',
          subdirectory: title.isEmpty ? null : title,
        ),
      );
    }
    return result;
  }

  static Future<Uri?> _bestRedditVideoUrl(Uri uri) async {
    try {
      final manifest =
          await Http.get(Uri.parse('${uri.toString()}/DASHPlaylist.mpd'));
      var largestHeight = -1;
      String? baseUrl;
      for (final representation in manifest
          .querySelectorAll('MPD > Period > AdaptationSet > Representation')) {
        final height =
            int.tryParse(representation.attributes['height'] ?? '') ?? 0;
        if (height > largestHeight) {
          largestHeight = height;
          baseUrl = representation.querySelector('BaseURL')?.text;
        }
      }
      if (baseUrl == null || baseUrl.isEmpty) return null;
      return Uri.parse('${uri.toString()}/$baseUrl');
    } catch (_) {
      return null;
    }
  }

  String _fileNameFor(RedditMedia media) {
    final sourceName = media.url.pathSegments.isNotEmpty
        ? media.url.pathSegments.last
        : 'file';
    final name = sourceName.contains('.') ? sourceName : '$sourceName.mp4';
    return Utils.sanitizeSaveAs('${media.prefix}_$name');
  }

  static String _safePrefix(String id, String title) {
    final safeTitle = title.isEmpty ? '' : '-${Utils.filesystemSafe(title)}-';
    return Utils.filesystemSafe('$id$safeTitle');
  }

  static bool _isDirectMedia(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.endsWith('.mp4') ||
        path.endsWith('.webm');
  }

  static List<dynamic> _childrenFromListings(dynamic json) {
    final children = <dynamic>[];
    for (final listing in _asListings(json)) {
      final listingChildren = listing['data']?['children'];
      if (listingChildren is List) {
        children.addAll(listingChildren);
      }
    }
    return children;
  }

  static List<dynamic> _asListings(dynamic json) {
    if (json is List) return json;
    if (json is Map) return [json];
    return const [];
  }
}
