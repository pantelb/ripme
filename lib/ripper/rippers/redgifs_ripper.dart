import 'dart:io';

import 'package:path/path.dart' as p;

import '../abstract_ripper.dart';
import '../abstract_json_ripper.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';

enum _RedgifsMode { singleton, profile, search, tags }

class RedgifsRipper extends AbstractJSONRipper {
  RedgifsRipper(Uri url) : super(sanitizeUrl(url));

  static const String _temporaryAuthEndpoint =
      'https://api.redgifs.com/v2/auth/temporary';
  static const String _gifsDetailEndpoint = 'https://api.redgifs.com/v2/gifs';
  static const String _usersSearchEndpoint = 'https://api.redgifs.com/v2/users';
  static const String _galleryEndpoint = 'https://api.redgifs.com/v2/gallery';
  static const String _searchEndpoint = 'https://api.redgifs.com/v2/search';
  static const String _tagsEndpoint = 'https://api.redgifs.com/v2/gifs/search';
  static const int _pageSize = 40;

  static String? _authToken;

  int _currentPage = 1;
  int _maxPages = 1;

  @override
  String getHost() => 'redgifs';

  @override
  bool canRip(Uri url) {
    final host = url.host.toLowerCase();
    return host.endsWith('redgifs.com') ||
        host.endsWith('gifdeliverynetwork.com');
  }

  static Uri sanitizeUrl(Uri url) {
    var text = url.toString();
    text = text.replaceFirst('thumbs.', '');
    text = text.replaceFirst('/gifs/detail/', '/watch/');
    text = text.replaceFirst('/amp', '');
    text = text.replaceFirst('gifdeliverynetwork.com', 'redgifs.com/watch');
    return Uri.parse(text);
  }

  @override
  Future<String> getGID(Uri url) async {
    final sanitized = sanitizeUrl(url);
    final mode = _getMode(sanitized);
    switch (mode) {
      case _RedgifsMode.profile:
        return sanitized.pathSegments[1];
      case _RedgifsMode.search:
        final query = sanitized.queryParameters['query'];
        if (query == null || query.trim().isEmpty) {
          throw FormatException(
              'Expected redgifs.com/search?query=searchtext, got $url');
        }
        return _safeId(query);
      case _RedgifsMode.tags:
        final tags = sanitized.pathSegments[1]
            .split(',')
            .where((tag) => tag.trim().isNotEmpty)
            .toList()
          ..sort();
        if (tags.isEmpty) {
          throw FormatException(
              'Expected redgifs.com/gifs/searchtags, got $url');
        }
        return _safeId(tags.join('_'));
      case _RedgifsMode.singleton:
        return sanitized.pathSegments.last.split('-').first;
    }
  }

  @override
  Future<void> parseJSON(Uri url) async {
    await _ensureAuthToken();
    final mode = _getMode(this.url);

    while (!isStopped) {
      final json = await _loadPage(mode);
      final urls = await _getUrlsFromJson(json, mode);
      final downloads = <RipperDownload>[];
      for (var i = 0; i < urls.length; i++) {
        if (isStopped) break;
        final mediaUri = Uri.parse(urls[i]);
        final fileName = _fileNameFor(mediaUri, i + 1);
        downloads.add(
          RipperDownload(
            url: mediaUri,
            saveAs: File(p.join(workingDir.path, fileName)),
            headers: {'Referer': 'https://www.redgifs.com/'},
          ),
        );
      }
      await downloadFiles(downloads);

      if (mode == _RedgifsMode.singleton || _currentPage >= _maxPages) {
        break;
      }
      _currentPage++;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  static Future<String> getVideoUrl(Uri url) async {
    await _ensureAuthToken();
    final sanitized = sanitizeUrl(url);
    if (_getMode(sanitized) != _RedgifsMode.singleton) {
      throw FormatException(
          'Cannot fetch a single Redgifs media URL from $url');
    }

    final gid = sanitized.pathSegments.last.split('-').first;
    final json = await Http.getJSON(
      Uri.parse('$_gifsDetailEndpoint/$gid'),
      headers: _authHeaders,
    );
    final gif = json['gif'];
    if (gif == null) {
      throw FormatException(
          'Redgifs response did not include gif details for $url');
    }
    if (gif['gallery'] != null) {
      throw FormatException(
          'Redgifs URL points to a gallery, not a single media item: $url');
    }
    return gif['urls']?['hd'] ?? gif['urls']?['sd'];
  }

  Future<dynamic> _loadPage(_RedgifsMode mode) async {
    switch (mode) {
      case _RedgifsMode.singleton:
        final gid = await getGID(url);
        _maxPages = 1;
        return Http.getJSON(Uri.parse('$_gifsDetailEndpoint/$gid'),
            headers: _authHeaders);
      case _RedgifsMode.profile:
        final username = await getGID(url);
        final pageUri =
            Uri.parse('$_usersSearchEndpoint/$username/search').replace(
          queryParameters: {
            'order': 'new',
            'count': '$_pageSize',
            'page': '$_currentPage',
          },
        );
        final json = await Http.getJSON(pageUri, headers: _authHeaders);
        _maxPages = json['pages'] ?? 1;
        return json;
      case _RedgifsMode.search:
      case _RedgifsMode.tags:
        final pageUri = _searchOrTagsUri(mode);
        final json = await Http.getJSON(pageUri, headers: _authHeaders);
        _maxPages = json['pages'] ?? 1;
        return json;
    }
  }

  Future<List<String>> _getUrlsFromJson(dynamic json, _RedgifsMode mode) async {
    final urls = <String>[];
    final gifs = mode == _RedgifsMode.singleton
        ? [json['gif']]
        : (json['gifs'] as List? ?? const []);

    for (final gif in gifs) {
      if (gif == null) continue;
      final galleryId = gif['gallery'];
      if (galleryId == null) {
        final hd = gif['urls']?['hd'] ?? gif['urls']?['sd'];
        if (hd != null) urls.add(hd);
      } else {
        urls.addAll(await _getUrlsForGallery(galleryId.toString()));
      }
    }
    return urls;
  }

  Future<List<String>> _getUrlsForGallery(String galleryId) async {
    final json = await Http.getJSON(Uri.parse('$_galleryEndpoint/$galleryId'),
        headers: _authHeaders);
    final gifs = json['gifs'] as List? ?? const [];
    return gifs
        .map((gif) => gif['urls']?['hd'] ?? gif['urls']?['sd'])
        .whereType<String>()
        .toList();
  }

  Uri _searchOrTagsUri(_RedgifsMode mode) {
    final params = <String, String>{};

    for (final entry in url.queryParameters.entries) {
      switch (entry.key) {
        case 'query':
          params['query'] = entry.value;
          break;
        case 'tab':
          if (entry.value == 'gifs') params['type'] = 'g';
          if (entry.value == 'images') params['type'] = 'i';
          break;
        case 'verified':
          if (entry.value == '1') {
            params['verified'] = mode == _RedgifsMode.tags ? 'y' : 'yes';
          }
          break;
        case 'order':
          params['order'] = entry.value;
          break;
      }
    }

    params['page'] = '$_currentPage';
    params['count'] = '$_pageSize';

    if (mode == _RedgifsMode.tags) {
      params['search_text'] = url.pathSegments[1];
      params.putIfAbsent('type', () => 'g');
      return Uri.parse(_tagsEndpoint).replace(queryParameters: params);
    }

    var tabType = 'gifs';
    if (url.pathSegments.length > 1 && url.pathSegments.last == 'images') {
      tabType = 'images';
    }
    return Uri.parse('$_searchEndpoint/$tabType')
        .replace(queryParameters: params);
  }

  String _fileNameFor(Uri uri, int index) {
    final rawName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : '${index.toString().padLeft(3, '0')}.mp4';
    final fileName = rawName.contains('.') ? rawName : '$rawName.mp4';
    return '${index.toString().padLeft(3, '0')}_${Utils.sanitizeSaveAs(fileName)}';
  }

  static Future<void> _ensureAuthToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) return;
    final json = await Http.getJSON(Uri.parse(_temporaryAuthEndpoint));
    _authToken = json['token'];
  }

  static Map<String, String> get _authHeaders => {
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  static _RedgifsMode _getMode(Uri url) {
    final segments = url.pathSegments;
    if (segments.length >= 2 && segments.first == 'users') {
      return _RedgifsMode.profile;
    }
    if (segments.isNotEmpty && segments.first == 'search') {
      return _RedgifsMode.search;
    }
    if (segments.length >= 2 && segments.first == 'gifs') {
      return _RedgifsMode.tags;
    }
    if (segments.length >= 2 && segments.first == 'watch') {
      return _RedgifsMode.singleton;
    }
    throw FormatException(
      'Expected redgifs.com/watch/id, redgifs.com/users/id, '
      'redgifs.com/gifs/tags, or redgifs.com/search?query=text. Got: $url',
    );
  }

  static String _safeId(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
  }
}
