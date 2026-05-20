import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' show parseFragment;
import 'package:path/path.dart' as p;

import '../abstract_ripper.dart';
import '../abstract_json_ripper.dart';
import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import 'redgifs_ripper.dart';

class RedditMedia {
  final Uri url;
  final String prefix;
  final String? fileName;
  final String? subdirectory;
  final Map<String, String>? headers;

  const RedditMedia({
    required this.url,
    required this.prefix,
    this.fileName,
    this.subdirectory,
    this.headers,
  });
}

class RedditSelfPostHtml {
  final String id;
  final String title;
  final String html;

  const RedditSelfPostHtml({
    required this.id,
    required this.title,
    required this.html,
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
      await _saveSelfPostHtmlFiles(json);
      final media = await extractMediaFromJson(json);
      final downloads = <RipperDownload>[];
      for (final item in media) {
        if (isStopped) break;
        final directory = item.subdirectory == null
            ? workingDir
            : Directory(p.join(
                workingDir.path, Utils.filesystemSafe(item.subdirectory!)));
        final fileName = downloadFileNameFor(item);
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

  Future<void> _saveSelfPostHtmlFiles(dynamic json) async {
    for (final selfPost in extractSelfPostHtmlFromJson(json)) {
      if (isStopped) break;
      final file = File(p.join(
        workingDir.path,
        Utils.sanitizeSaveAs(
            '${selfPost.id}_${Utils.filesystemSafe(selfPost.title)}.html'),
      ));
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(selfPost.html);
      sendUpdate(RipStatus.downloadComplete, file.path);
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

  static List<RedditSelfPostHtml> extractSelfPostHtmlFromJson(dynamic json) {
    final posts = <RedditSelfPostHtml>[];
    final listings = _asListings(json);
    if (listings.length < 2) return posts;
    for (var i = 0; i < listings.length; i++) {
      final children = listings[i]['data']?['children'];
      if (children is! List) continue;

      final nextListingData =
          (i + 1 < listings.length) ? listings[i + 1]['data'] : null;
      final comments =
          nextListingData is Map ? nextListingData['children'] : const [];
      for (final child in children) {
        final data = child['data'];
        if (child['kind'] != 't3' || data is! Map || data['is_self'] != true) {
          continue;
        }
        final selfText = data['selftext']?.toString() ?? '';
        if (selfText.isEmpty) continue;
        posts
            .add(_selfPostHtmlFromData(data, comments is List ? comments : []));
      }
      if (posts.isNotEmpty) break;
    }
    return posts;
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

    if (kind == 't3' && _shouldSkipByUpvotes(data)) {
      return const [];
    }

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
          prefix: _singleUrlPrefix(id, title),
        ),
      ];
    }

    if (host.contains('i.reddituploads.com')) {
      final uploadId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : id;
      final cleanUploadId = uploadId.split('?').first;
      return [
        RedditMedia(
          url: uri,
          prefix: '',
          fileName: '$id-$cleanUploadId${_javaSingleTitleSuffix(title)}.jpg',
        ),
      ];
    }

    if (host.contains('v.redd.it')) {
      final videoUrl = await _bestRedditVideoUrl(uri);
      if (videoUrl == null) return const [];
      return [
        RedditMedia(
          url: videoUrl,
          prefix: '',
          fileName:
              '$id-${uri.pathSegments.first}${_javaSingleTitleSuffix(title)}.mp4',
        ),
      ];
    }

    if (host.contains('redgifs.com') ||
        host.contains('gifdeliverynetwork.com')) {
      final videoUrl = await RedgifsRipper.getVideoUrl(uri);
      return [
        RedditMedia(
          url: Uri.parse(videoUrl),
          prefix: _singleUrlPrefix(id, title),
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
      final orderPrefix = Utils.getConfigBoolean('download.save_order', true)
          ? '${(i + 1).toString().padLeft(2, '0')}-'
          : '';
      result.add(
        RedditMedia(
          url: Uri.parse(url.replaceAll('&amp;', '&')),
          prefix: '$id-$orderPrefix',
          subdirectory: _redditSubdirectory(title),
        ),
      );
    }
    return result;
  }

  static RedditSelfPostHtml _selfPostHtmlFromData(
      Map data, List<dynamic> comments) {
    final title = data['title']?.toString() ?? '';
    final id = data['id']?.toString() ?? 'reddit';
    final author = data['author']?.toString() ?? '';
    final subreddit = data['subreddit']?.toString() ?? '';
    final permalink = data['url']?.toString() ??
        (data['permalink'] == null
            ? ''
            : 'https://www.reddit.com${data['permalink']}');
    final created = _redditDate(data['created']);
    final selfText = _plainTextFromHtml(
      data['selftext_html']?.toString() ?? data['selftext']?.toString() ?? '',
    );
    final escapedTitle = const HtmlEscape().convert(title);
    final escapedAuthor = const HtmlEscape().convert(author);
    final escapedSubreddit = const HtmlEscape().convert(subreddit);
    final escapedPermalink = const HtmlEscape().convert(permalink);
    final escapedSelfText = const HtmlEscape().convert(selfText);
    final renderedComments = comments
        .map((comment) => _renderComment(comment, author))
        .where((comment) => comment.isNotEmpty)
        .join();

    return RedditSelfPostHtml(
      id: id,
      title: title,
      html: '''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>$escapedTitle</title>
<style>$_htmlStyling</style>
</head>
<body>
<div class="thing">
<h1>$escapedTitle</h1>
<a href="https://www.reddit.com/r/$escapedSubreddit">$escapedSubreddit</a>
<a href="$escapedPermalink">Original</a><br>
</div>
<div class="flex"><div class="thing oppost"><span class="author op">$escapedAuthor</span> $created<div class="md">$escapedSelfText</div></div></div>
<div id="comments">$renderedComments</div>
<script>$_htmlScript</script>
</body>
</html>
''',
    );
  }

  static String _renderComment(dynamic comment, String originalAuthor) {
    final data = comment is Map ? comment['data'] : null;
    if (data is! Map) return '';
    final author = data['author']?.toString() ?? '';
    if (author.isEmpty) return '';
    final name = data['name']?.toString() ?? '';
    final body = _plainTextFromHtml(
      data['body_html']?.toString() ?? data['body']?.toString() ?? '',
    );
    final authorClass = author == originalAuthor ? 'author op' : 'author';
    final replies = data['replies'];
    var children = '';
    if (replies is Map) {
      final replyChildren = replies['data']?['children'];
      if (replyChildren is List) {
        children = replyChildren
            .map((reply) => _renderComment(reply, originalAuthor))
            .where((reply) => reply.isNotEmpty)
            .join();
        if (children.isNotEmpty) {
          children = '<div class="child">$children</div>';
        }
      }
    }
    return '<div class="thing comment" id="${const HtmlEscape().convert(name)}">'
        '<span class="$authorClass">${const HtmlEscape().convert(author)}</span> '
        '<a href="#${const HtmlEscape().convert(name)}">${_redditDate(data['created'])}</a>'
        '<div class="md">${const HtmlEscape().convert(body)}</div>'
        '$children</div>';
  }

  static String _plainTextFromHtml(String value) {
    return parseFragment(value).text ?? value;
  }

  static String _redditDate(dynamic value) {
    final seconds =
        value is num ? value : num.tryParse(value?.toString() ?? '');
    if (seconds == null) return '';
    return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round())
        .toLocal()
        .toString();
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

  static String downloadFileNameFor(RedditMedia media) {
    final explicitFileName = media.fileName;
    if (explicitFileName != null && explicitFileName.isNotEmpty) {
      return Utils.sanitizeSaveAs(explicitFileName);
    }
    final sourceName = media.url.pathSegments.isNotEmpty
        ? media.url.pathSegments.last
        : 'file';
    final name = sourceName.contains('.') ? sourceName : '$sourceName.mp4';
    return Utils.sanitizeSaveAs('${media.prefix}$name');
  }

  static String _singleUrlPrefix(String id, String title) {
    return Utils.filesystemSafe('$id${_javaSingleTitleSuffix(title)}');
  }

  static String _javaSingleTitleSuffix(String title) {
    var suffix = title;
    if (Utils.getConfigBoolean('reddit.use_sub_dirs', true)) {
      suffix =
          Utils.getConfigBoolean('album_titles.save', true) && title.isNotEmpty
              ? '-$title-'
              : '';
    }
    return Utils.filesystemSafe(suffix);
  }

  static String? _redditSubdirectory(String title) {
    if (title.isEmpty) return null;
    if (!Utils.getConfigBoolean('reddit.use_sub_dirs', true)) return null;
    if (!Utils.getConfigBoolean('album_titles.save', true)) return null;
    return title;
  }

  static bool _shouldSkipByUpvotes(Map data) {
    if (!Utils.getConfigBoolean('reddit.rip_by_upvote', false)) {
      return false;
    }
    final score = data['score'];
    if (score is! int) return false;
    final minScore = Utils.getConfigInteger('reddit.min_upvotes', 0);
    final maxScore = Utils.getConfigInteger('reddit.max_upvotes', 10000);
    return score < minScore || score > maxScore;
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

  static const String _htmlStyling =
      ' .author { font-weight: bold; } .op { color: blue; } .comment { border: 0px; margin: 0 0 25px; padding-left: 5px; } .child { margin: 2px 0 0 20px; border-left: 2px dashed #AAF; } .md { max-width: 840px; padding-right: 1em; } h1 { margin: 0; } body { position: relative; background-color: #eeeeec; color: #00000a; font-family: Helvetica,Arial,sans-serif; line-height: 1.4 } .thing { overflow: hidden; margin: 0 5px 3px 40px; border: 1px solid #e0e0e0; background-color: #fcfcfb; } .oppost { background-color: #EEF; } .flex { display: flex; flex-flow: wrap; flex-direction: row-reverse; justify-content: flex-end; } ';
  static const String _htmlScript =
      "document.addEventListener('mousedown', function(e) { var t = e.target; if (t.className == 'author') { t = t.parentElement; } if (t.classList.contains('comment')) { t.classList.toggle('collapsed'); e.preventDefault(); e.stopPropagation(); return false; } });";
}
