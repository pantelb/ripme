import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_ripper.dart';

enum InstagramUrlType {
  hashtag,
  stories,
  userTagged,
  igtv,
  singlePost,
  pinned,
  userProfile,
}

class InstagramUrlMatch {
  final InstagramUrlType type;
  final String value;

  const InstagramUrlMatch(this.type, this.value);
}

class InstagramMedia {
  final Uri url;
  final String prefix;

  const InstagramMedia(this.url, this.prefix);
}

class InstagramRipper extends AbstractRipper {
  final Map<String, String> _cookies = <String, String>{};
  final List<String> _failedItems = <String>[];

  InstagramRipper(super.url);

  @override
  String getHost() => 'instagram';

  @override
  bool canRip(Uri url) => url.host.endsWith('instagram.com');

  @override
  Future<String> getGID(Uri url) async {
    final match = classifyUrl(url);
    return switch (match.type) {
      InstagramUrlType.hashtag => 'tag_${match.value}',
      InstagramUrlType.pinned => '${match.value}_pinned',
      InstagramUrlType.stories => '${match.value}_stories',
      InstagramUrlType.userTagged => '${match.value}_tagged',
      InstagramUrlType.igtv => '${match.value}_igtv',
      InstagramUrlType.singlePost => 'post_${match.value}',
      InstagramUrlType.userProfile => match.value,
    };
  }

  @override
  Future<void> rip() async {
    final match = classifyUrl(url);
    try {
      _setAuthCookie(match);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    Map<String, dynamic> firstJson;
    try {
      page = await Http.get(url, cookies: _cookies);
      firstJson = jsonObjectFromDocument(page) ?? <String, dynamic>{};
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    try {
      final qHash = await _queryHash(page, match);
      final idString = idStringFromJson(firstJson, match);
      final downloads = <RipperDownload>[];

      var currentJson =
          await _initialJson(firstJson, page, match, idString, qHash);
      while (currentJson != null && !isStopped) {
        final media = await _mediaFromJson(currentJson, match, idString, qHash);
        for (final item in media) {
          if (isStopped) break;
          if (Utils.getConfigBoolean('instagram.download_images_only', false) &&
              item.url.toString().contains('.mp4?')) {
            sendUpdate(
                RipStatus.downloadSkip, 'Skipped video url: ${item.url}');
            continue;
          }

          downloads.add(RipperDownload(
            url: item.url,
            saveAs: File(p.join(
              workingDir.path,
              fileNameForUrl(item.url, prefix: item.prefix),
            )),
            cookies: _cookies,
          ));
        }

        currentJson = await _nextPage(currentJson, match, idString, qHash);
      }

      for (final failed in _failedItems) {
        sendUpdate(RipStatus.downloadWarn, failed);
      }
      await downloadFiles(downloads);
      sendUpdate(RipStatus.ripComplete, workingDir.path);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
  }

  void _setAuthCookie(InstagramUrlMatch match) {
    final sessionId = Utils.getConfigString('instagram.session_id', null);
    if ((match.type == InstagramUrlType.stories ||
            match.type == InstagramUrlType.pinned) &&
        sessionId == null) {
      throw const FormatException(
          'instagram.session_id should be set up for Instagram stories');
    }
    if (sessionId != null) _cookies['sessionid'] = sessionId;
  }

  Future<Map<String, dynamic>?> _initialJson(
    Map<String, dynamic> firstJson,
    Document page,
    InstagramUrlMatch match,
    String idString,
    String? qHash,
  ) async {
    return switch (match.type) {
      InstagramUrlType.userTagged => _nextPage(null, match, idString, qHash),
      InstagramUrlType.pinned => _pinnedItems(page, idString, qHash),
      InstagramUrlType.stories => _storiesItems(idString, qHash),
      _ => Future.value(firstJson),
    };
  }

  Future<String?> _queryHash(Document page, InstagramUrlMatch match) async {
    if (match.type == InstagramUrlType.singlePost) return null;

    final href = preloadHref(page, match);
    if (href == null || href.isEmpty) return null;

    final jsUrl = Uri.parse('https://www.instagram.com$href');
    final body = await Http.getText(jsUrl, cookies: _cookies);
    return queryHashFromJavaScript(body, match);
  }

  Future<Map<String, dynamic>?> _nextPage(
    Map<String, dynamic>? source,
    InstagramUrlMatch match,
    String idString,
    String? qHash,
  ) async {
    if (match.type == InstagramUrlType.singlePost ||
        match.type == InstagramUrlType.stories) {
      return null;
    }

    final variables = <String, dynamic>{
      match.type == InstagramUrlType.hashtag ? 'tag_name' : 'id': idString,
      'first': 12,
    };

    if (source != null) {
      final pageInfo = jsonObjectByPath(source, mediaRootPath(source, match));
      final info = pageInfo == null
          ? null
          : jsonObjectByPath(pageInfo, 'page_info', allowRoot: true);
      if (info == null || info['has_next_page'] != true) return null;
      variables['after'] = info['end_cursor'];
    }

    return _graphqlRequest(qHash, variables);
  }

  Future<Map<String, dynamic>?> _storiesItems(
    String idString,
    String? qHash,
  ) {
    return _graphqlRequest(qHash, {
      'reel_ids': [idString],
      'precomposed_overlay': false,
    });
  }

  Future<Map<String, dynamic>?> _pinnedItems(
    Document page,
    String idString,
    String? qHash,
  ) async {
    final pinnedIdsJson = await _graphqlRequest(qHash, {
      'user_id': idString,
      'include_highlight_reels': true,
    });
    if (pinnedIdsJson == null) return null;

    final pinnedItems =
        jsonArrayByPath(pinnedIdsJson, 'data.user.edge_highlight_reels.edges');
    final pinnedQHash = await _queryHash(
      page,
      const InstagramUrlMatch(InstagramUrlType.stories, ''),
    );

    return _graphqlRequest(pinnedQHash, {
      'highlight_reel_ids': [
        for (final item in pinnedItems)
          if (item is Map)
            if (jsonStringByPath(item, 'node.id') != null)
              jsonStringByPath(item, 'node.id'),
      ],
      'precomposed_overlay': false,
    });
  }

  Future<Map<String, dynamic>?> _graphqlRequest(
    String? qHash,
    Map<String, dynamic> variables,
  ) async {
    await Http.delay(const Duration(milliseconds: 2500));
    final encodedVariables = jsonEncode(variables);
    final uri = Uri.parse(
      'https://www.instagram.com/graphql/query/?query_hash=$qHash&variables=$encodedVariables',
    );
    final json = await Http.getJSON(uri, cookies: _cookies);
    return json is Map<String, dynamic> ? json : null;
  }

  Future<List<InstagramMedia>> _mediaFromJson(
    Map<String, dynamic> json,
    InstagramUrlMatch match,
    String idString,
    String? qHash,
  ) async {
    if (match.type == InstagramUrlType.stories ||
        match.type == InstagramUrlType.pinned) {
      return storyMediaFromJson(json);
    }

    if (match.type == InstagramUrlType.singlePost) {
      final details = await _downloadItemDetailsJson(idString);
      if (details == null) return const <InstagramMedia>[];
      return _itemDetailsMedia(details);
    }

    final root = jsonObjectByPath(json, mediaRootPath(json, match));
    final edges = root == null
        ? const <Object?>[]
        : jsonArrayByPath(root, 'edges', allowRoot: true);
    final media = <InstagramMedia>[];
    for (final edge in edges) {
      final shortcode =
          edge is Map ? jsonStringByPath(edge, 'node.shortcode') : null;
      if (shortcode == null) continue;

      final details = await _downloadItemDetailsJson(shortcode);
      if (details != null) media.addAll(await _itemDetailsMedia(details));
    }
    return media;
  }

  Future<List<InstagramMedia>> _itemDetailsMedia(
    Map<String, dynamic> details,
  ) async {
    final mediaItem =
        jsonObjectByPath(details, 'graphql.shortcode_media') ?? details;
    final prefixInfo = prefixInfoForItem(mediaItem);

    if (mediaItem['__typename'] == 'GraphVideo') {
      final shortcode = mediaItem['shortcode']?.toString();
      final pageVideo =
          shortcode == null ? '' : await _videoUrlFromPage(shortcode);
      final urls = parseRootForUrls(mediaItem);
      final media = <InstagramMedia>[
        for (var i = 0; i < urls.length; i++)
          InstagramMedia(
              urls[i], prefixInfo[i.clamp(0, prefixInfo.length - 1)]),
      ];
      if (pageVideo.isNotEmpty && shortcode != null) {
        media.add(InstagramMedia(
          Uri.parse(pageVideo),
          '${timestampPrefix(mediaItem)}${shortcode}_extra_',
        ));
      }
      return media;
    }

    final urls = parseRootForUrls(mediaItem);
    return [
      for (var i = 0; i < urls.length; i++)
        InstagramMedia(urls[i], prefixInfo[i.clamp(0, prefixInfo.length - 1)]),
    ];
  }

  Future<Map<String, dynamic>?> _downloadItemDetailsJson(
      String shortcode) async {
    final uri = Uri.parse('https://www.instagram.com/p/$shortcode/?__a=1');
    try {
      final response = await Http.getResponse(uri, cookies: _cookies);
      if (response.statusCode == 302) {
        final location = response.headers['location'];
        final redirectMatch = location == null
            ? null
            : RegExp(r'/p/([^?/]+)').firstMatch(location);
        return redirectMatch == null
            ? null
            : _downloadItemDetailsJson(redirectMatch.group(1)!);
      }
      final json = jsonDecode(response.body);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      _failedItems.add(shortcode);
      return null;
    }
  }

  Future<String> _videoUrlFromPage(String shortcode) async {
    try {
      final doc = await Http.get(
        Uri.parse('https://www.instagram.com/p/$shortcode'),
        cookies: _cookies,
      );
      return doc
              .querySelector('meta[property=og:video]')
              ?.attributes['content'] ??
          '';
    } catch (_) {
      sendUpdate(
        RipStatus.downloadWarn,
        'Unable to get page https://www.instagram.com/p/$shortcode',
      );
      return '';
    }
  }

  static InstagramUrlMatch classifyUrl(Uri uri) {
    final text = uri.toString();
    final patterns = <InstagramUrlType, RegExp>{
      InstagramUrlType.hashtag: RegExp(
          r'^https?://(?:www\.)?instagram\.com/explore/tags/([^?/]+)(?:[?/].*)?$'),
      InstagramUrlType.stories: RegExp(
          r'^https?://(?:www\.)?instagram\.com/stories/([^?/]+)(?:[?/].*)?$'),
      InstagramUrlType.userTagged: RegExp(
          r'^https?://(?:www\.)?instagram\.com/([^?/]+)/tagged(?:[?/].*)?$'),
      InstagramUrlType.igtv: RegExp(
          r'^https?://(?:www\.)?instagram\.com/([^?/]+)/channel(?:[?/].*)?$'),
      InstagramUrlType.singlePost: RegExp(
          r'^https?://(?:www\.)?instagram\.com/(?:p|tv)/([^?/]+)(?:[?/].*)?$'),
      InstagramUrlType.pinned: RegExp(
          r'^https?://(?:www\.)?instagram\.com/([^?/]+)/?\?pinned(?:[?/].*)?$'),
      InstagramUrlType.userProfile:
          RegExp(r'^https?://(?:www\.)?instagram\.com/([^?/]+)(?:[?/].*)?$'),
    };

    for (final entry in patterns.entries) {
      final match = entry.value.firstMatch(text);
      if (match != null) return InstagramUrlMatch(entry.key, match.group(1)!);
    }
    throw const FormatException("This URL can't be ripped");
  }

  static Map<String, dynamic>? jsonObjectFromDocument(Document document) {
    for (final script
        in document.querySelectorAll('script[type="text/javascript"]')) {
      final scriptText = script.innerHtml.trim();
      if (!scriptText.startsWith('window._sharedData') &&
          !scriptText.startsWith('window.__additionalDataLoaded')) {
        continue;
      }

      final start = scriptText.indexOf('{');
      final end = scriptText.lastIndexOf('}');
      if (start < 0 || end <= start) continue;

      final jsonText = scriptText.substring(start, end + 1);
      if (!jsonText.contains('graphql') && !jsonText.contains('StoriesPage')) {
        continue;
      }

      final decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return null;
  }

  static String? preloadHref(Document document, InstagramUrlMatch match) {
    bool filter(String href) {
      if (match.type == InstagramUrlType.userTagged) {
        return href.contains('ProfilePageContainer.js') ||
            href.contains('TagPageContainer.js');
      }
      return href.contains('Consumer.js');
    }

    for (final link in document.querySelectorAll('link[rel=preload]')) {
      final href = link.attributes['href'] ?? '';
      if (filter(href)) return href;
    }
    return null;
  }

  static String? queryHashFromJavaScript(
    String javaScriptData,
    InstagramUrlMatch match,
  ) {
    final keyword = switch (match.type) {
      InstagramUrlType.stories || InstagramUrlType.pinned => 'loadStoryViewers',
      InstagramUrlType.hashtag => 'requestNextTagMedia',
      InstagramUrlType.userTagged => 'requestNextTaggedPosts',
      _ => 'loadProfilePageExtras',
    };

    final index = javaScriptData.indexOf(keyword);
    if (index < 0) return null;
    final start = (index - 1200).clamp(0, javaScriptData.length);
    final end = (index + 1200).clamp(0, javaScriptData.length);
    final window = javaScriptData.substring(start, end);

    if (match.type == InstagramUrlType.userProfile ||
        match.type == InstagramUrlType.igtv) {
      final queryId = RegExp(r'queryId\s?:\s?"([0-9a-f]+)"').firstMatch(window);
      if (queryId != null) return queryId.group(1);
    }

    final hashes = RegExp(r'"([0-9a-f]{8,})"')
        .allMatches(window)
        .map((match) => match.group(1)!)
        .toList();
    return hashes.isEmpty ? null : hashes.last;
  }

  static String idStringFromJson(
    Map<String, dynamic> json,
    InstagramUrlMatch match,
  ) {
    final path = switch (match.type) {
      InstagramUrlType.hashtag => 'entry_data.TagPage[0].graphql.hashtag.name',
      InstagramUrlType.stories => 'entry_data.StoriesPage[0].user.id',
      InstagramUrlType.singlePost => 'graphql.shortcode_media.shortcode',
      _ => 'entry_data.ProfilePage[0].graphql.user.id',
    };
    return jsonStringByPath(json, path) ?? '';
  }

  static String mediaRootPath(
    Map<String, dynamic> json,
    InstagramUrlMatch match,
  ) {
    final hasEntryData = json['entry_data'] is Map;
    if (hasEntryData) {
      return switch (match.type) {
        InstagramUrlType.hashtag =>
          'entry_data.TagPage[0].graphql.hashtag.edge_hashtag_to_media',
        InstagramUrlType.igtv =>
          'entry_data.ProfilePage[0].graphql.user.edge_felix_video_timeline',
        _ =>
          'entry_data.ProfilePage[0].graphql.user.edge_owner_to_timeline_media',
      };
    }

    return switch (match.type) {
      InstagramUrlType.hashtag => 'data.hashtag.edge_hashtag_to_media',
      InstagramUrlType.igtv => 'data.user.edge_felix_video_timeline',
      InstagramUrlType.userTagged => 'data.user.edge_user_to_photos_of_you',
      _ => 'data.user.edge_owner_to_timeline_media',
    };
  }

  static List<InstagramMedia> storyMediaFromJson(Map<String, dynamic> json) {
    final albums = jsonArrayByPath(json, 'data.reels_media');
    final media = <InstagramMedia>[];
    for (final album in albums) {
      final items = album is Map
          ? jsonArrayByPath(album, 'items', allowRoot: true)
          : const <Object?>[];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;

        final prefix = timestampPrefix(item);
        if (item['is_video'] == true) {
          final resources = item['video_resources'];
          if (resources is List && resources.isNotEmpty) {
            final last = resources.last;
            final src = last is Map ? last['src'] : null;
            if (src != null) {
              media.add(InstagramMedia(Uri.parse('$src'), prefix));
            }
          }
          final displayUrl = item['display_url'];
          if (displayUrl != null) {
            media.add(InstagramMedia(
              Uri.parse('$displayUrl'),
              '${prefix}preview_',
            ));
          }
        } else {
          final displayUrl = item['display_url'];
          if (displayUrl != null) {
            media.add(InstagramMedia(Uri.parse('$displayUrl'), prefix));
          }
        }
      }
    }
    return media;
  }

  static List<String> prefixInfoForItem(Map<String, dynamic> mediaItem) {
    final shortcode = mediaItem['shortcode']?.toString() ?? '';
    final subItemsCount = mediaItem['__typename'] == 'GraphSidecar'
        ? jsonArrayByPath(mediaItem, 'edge_sidecar_to_children.edges',
                allowRoot: true)
            .length
        : 1;
    return List.generate(
      subItemsCount,
      (_) => '${timestampPrefix(mediaItem)}${shortcode}_',
    );
  }

  static List<Uri> parseRootForUrls(Map<String, dynamic> mediaItem) {
    return switch (mediaItem['__typename']) {
      'GraphImage' => [
          if (mediaItem['display_url'] != null)
            Uri.parse(mediaItem['display_url'].toString()),
        ],
      'GraphVideo' => [
          if (mediaItem['video_url'] != null)
            Uri.parse(mediaItem['video_url'].toString()),
        ],
      'GraphSidecar' => [
          for (final child in jsonArrayByPath(
              mediaItem, 'edge_sidecar_to_children.edges', allowRoot: true))
            if (child is Map)
              ...parseRootForUrls(
                  Map<String, dynamic>.from(child['node'] as Map)),
        ],
      _ => const <Uri>[],
    };
  }

  static String timestampPrefix(Map<String, dynamic> item) {
    final timestamp = item['taken_at_timestamp'];
    final seconds =
        timestamp is int ? timestamp : int.tryParse('$timestamp') ?? 0;
    final date =
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${two(date.month)}-${two(date.day)}_'
        '${two(date.hour)}-${two(date.minute)}-${two(date.second)}_';
  }

  static Map<String, dynamic>? jsonObjectByPath(
    Object? object,
    String key, {
    bool allowRoot = false,
  }) {
    final value = valueByPath(object, key, allowRoot: allowRoot);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static List<Object?> jsonArrayByPath(
    Object? object,
    String key, {
    bool allowRoot = false,
  }) {
    final value = valueByPath(object, key, allowRoot: allowRoot);
    return value is List ? value.cast<Object?>() : const [];
  }

  static String? jsonStringByPath(
    Object? object,
    String key, {
    bool allowRoot = false,
  }) {
    final value = valueByPath(object, key, allowRoot: allowRoot);
    return value?.toString();
  }

  static Object? valueByPath(
    Object? object,
    String key, {
    bool allowRoot = false,
  }) {
    Object? current = object;
    final parts = allowRoot ? key.split('.') : key.split('.');
    for (final part in parts) {
      if (part.isEmpty) continue;
      final match = RegExp(r'^(.*)\[(\d+)]$').firstMatch(part);
      final property = match?.group(1) ?? part;
      if (property.isNotEmpty) {
        if (current is! Map) return null;
        current = current[property];
      }
      if (match != null) {
        if (current is! List) return null;
        final index = int.parse(match.group(2)!);
        if (index < 0 || index >= current.length) return null;
        current = current[index];
      }
    }
    return current;
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
