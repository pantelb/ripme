import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/utils.dart';
import '../abstract_ripper.dart';

class LusciousRipper extends AbstractRipper {
  LusciousRipper(
    Uri url, {
    Uri? apiBaseUri,
    http.Client? apiClient,
  })  : apiBaseUri = apiBaseUri ??
            Uri.parse('https://apicdn.luscious.net/graphql/nobatch/'),
        _apiClient = apiClient,
        super(sanitizeUrl(url));

  static final RegExp _gidPattern = RegExp(
    r'^https?://(?:www\.)?(?:(?:members|legacy|old)\.)?luscious\.net/albums/([-_.0-9a-zA-Z]+).*$',
  );
  static const String _apiQuery =
      '%2520query%2520PictureListInsideAlbum%28%2524input%253A%2520PictureListInput%21%29%2520%257B%2520picture%2520%257B%2520list%28input%253A%2520%2524input%29%2520%257B%2520info%2520%257B%2520...FacetCollectionInfo%2520%257D%2520items%2520%257B%2520__typename%2520id%2520title%2520description%2520created%2520like_status%2520number_of_comments%2520number_of_favorites%2520moderation_status%2520width%2520height%2520resolution%2520aspect_ratio%2520url_to_original%2520url_to_video%2520is_animated%2520position%2520permissions%2520url%2520tags%2520%257B%2520category%2520text%2520url%2520%257D%2520thumbnails%2520%257B%2520width%2520height%2520size%2520url%2520%257D%2520%257D%2520%257D%2520%257D%2520%257D%2520fragment%2520FacetCollectionInfo%2520on%2520FacetCollectionInfo%2520%257B%2520page%2520has_next_page%2520has_previous_page%2520total_items%2520total_pages%2520items_per_page%2520url_complete%2520%257D%2520';
  static const Map<String, String> requestHeaders = {
    'User-Agent':
        'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0',
  };

  final Uri apiBaseUri;
  final http.Client? _apiClient;
  String? _albumId;

  @override
  String getHost() => 'luscious';

  String getDomain() => 'luscious.net';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  static Uri sanitizeUrl(Uri url) {
    final sanitized = url.toString().replaceAll(
          RegExp(r'https?://(?:www\.)?luscious\.'),
          'https://old.luscious.',
        );
    return Uri.parse(sanitized);
  }

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) {
      final gid = match.group(1)!;
      _albumId = gid.split('_').last;
      return gid;
    }

    throw FormatException(
      'Expected luscious.net URL format: '
      'luscious.net/albums/albumname \n members.luscious.net/albums/albumname  - got $url instead.',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    try {
      await getGID(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    var totalPages = 1;
    for (var page = 1; page <= totalPages && !isStopped; page++) {
      Map<String, dynamic> json;
      try {
        final pageUrl = buildApiUrl(page, _albumId!);
        sendUpdate(RipStatus.loadingResource, pageUrl.toString());
        json = await getApiJson(pageUrl);
      } catch (e) {
        sendUpdate(RipStatus.ripErrored, e.toString());
        return;
      }

      totalPages = totalPagesFromJson(json);
      final downloads = <RipperDownload>[];
      for (final urlText in urlsFromJson(json)) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(urlText);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
            headers: {'Referer': url.toString()},
          ),
        );
      }
      await downloadFiles(downloads);
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Map<String, dynamic>> getApiJson(Uri pageUrl) async {
    Object? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      final client = _apiClient ?? http.Client();
      try {
        final response = await client.get(pageUrl, headers: requestHeaders);
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        throw const FormatException('Expected Luscious API object response');
      } catch (e) {
        lastError = e;
      } finally {
        if (_apiClient == null) client.close();
      }
    }
    if (lastError is Exception) throw lastError;
    throw HttpException('Failed to load $pageUrl');
  }

  Uri buildApiUrl(int page, String albumId) {
    return Uri.parse(
      '$apiBaseUri?'
      'operationName=PictureListInsideAlbum'
      '&query=$_apiQuery'
      '&variables=${encodeVariablesPartOfURL(page, albumId)}',
    );
  }

  String? get albumIdForTesting => _albumId;

  static String encodeVariablesPartOfURL(int page, String albumId) {
    final json =
        '{"input":{"filters":[{"name":"album_id","value":"$albumId"}],"display":"rating_all_time","items_per_page":50,"page":$page}}';
    return Uri.encodeQueryComponent(json);
  }

  static int totalPagesFromJson(Map<String, dynamic> json) {
    final info = _listObject(json)?['info'];
    if (info is Map && info['total_pages'] is int) {
      return info['total_pages'] as int;
    }
    return 1;
  }

  static List<String> urlsFromJson(Map<String, dynamic> json) {
    final items = _listObject(json)?['items'];
    if (items is! List) return const [];

    final urls = <String>[];
    for (final item in items) {
      if (item is! Map) continue;
      final original = item['url_to_original'];
      if (original is String) urls.add(original);
    }
    return urls;
  }

  static Map? _listObject(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) return null;
    final picture = data['picture'];
    if (picture is! Map) return null;
    final list = picture['list'];
    return list is Map ? list : null;
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) {
        fileName = fileName.substring(0, separatorIndex);
      }
    }
    return Utils.sanitizeSaveAs('${prefixForIndex(index)}$fileName');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
