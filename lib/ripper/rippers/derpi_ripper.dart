import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';

class DerpiRipper extends AbstractJSONRipper {
  DerpiRipper(Uri url) : super(sanitizeUrl(url));

  static const String domain = 'derpibooru.org';

  Uri _currentUrl = Uri();
  int _currentPage = 1;

  @override
  String getHost() => 'DerpiBooru';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  static Uri sanitizeUrl(Uri url) {
    final text = url.toString();
    final parts = text.split(RegExp(r'\?', multiLine: false));
    var base = parts.first;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    final buffer = StringBuffer('$base.json?');
    if (parts.length > 1) {
      buffer.write(parts.sublist(1).join('?'));
    }

    final key = Utils.getConfigString('derpi.key', '') ?? '';
    if (key.isNotEmpty) {
      buffer.write('&key=$key');
    }

    return Uri.parse(buffer.toString());
  }

  @override
  Future<String> getGID(Uri url) async {
    _currentUrl = url;
    _currentPage = 1;

    final text = url.toString();

    var match = RegExp(r'^https?://derpibooru\.org/search\.json\?q=([^&]+).*?$')
        .firstMatch(text);
    if (match != null) {
      return 'search_${match.group(1)}';
    }

    match = RegExp(r'^https?://derpibooru\.org/tags/([^.]+)\.json.*?$')
        .firstMatch(text);
    if (match != null) {
      return 'tags_${match.group(1)}';
    }

    match =
        RegExp(r'^https?://derpibooru\.org/galleries/([^/]+)/(\d+)\.json.*?$')
            .firstMatch(text);
    if (match != null) {
      return 'galleries_${match.group(1)}_${match.group(2)}';
    }

    match =
        RegExp(r'^https?://derpibooru\.org/(\d+)\.json.*?$').firstMatch(text);
    if (match != null) {
      return 'image_${match.group(1)}';
    }

    throw FormatException('Unable to find image in $url');
  }

  @override
  Future<void> parseJSON(Uri url) async {
    _currentUrl = url;
    _currentPage = 1;
    var index = 0;
    Map<String, dynamic>? json = await getFirstPage();

    while (json != null && !isStopped) {
      final urls = urlsFromJson(json);
      if (urls.isEmpty) {
        throw StateError('No images found at $url');
      }

      final downloads = <RipperDownload>[];
      for (final urlText in urls) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(urlText);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, downloadFileName(uri, index))),
          ),
        );
      }
      await downloadFiles(downloads);

      if (isStopped) break;
      sendUpdate(RipStatus.loadingResource, 'next page');
      json = await getNextPage();
    }
  }

  Future<Map<String, dynamic>> getFirstPage() async {
    return _getJson(url);
  }

  Future<Map<String, dynamic>?> getNextPage() async {
    _currentPage++;
    final nextUrl = Uri.parse('$_currentUrl&page=$_currentPage');
    final json = await _getJson(nextUrl);
    final resources = _pageResources(json);
    if (resources == null || resources.isEmpty) return null;
    return json;
  }

  Future<Map<String, dynamic>> _getJson(Uri url) async {
    final response = await Http.getResponse(url, defaultTimeoutMs: 60000);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static List<String> urlsFromJson(Map<String, dynamic> json) {
    final resources = _pageResources(json);
    if (resources != null) {
      return [
        for (final resource in resources)
          if (resource is Map<String, dynamic>) getImageUrlFromJson(resource),
      ];
    }

    return [getImageUrlFromJson(json)];
  }

  static List<dynamic>? _pageResources(Map<String, dynamic> json) {
    final images = json['images'];
    if (images is List) return images;

    final search = json['search'];
    if (search is List) return search;

    return null;
  }

  static String getImageUrlFromJson(Map<String, dynamic> json) {
    final representations = json['representations'];
    if (representations is! Map) {
      throw const FormatException('Derpibooru image has no representations');
    }

    final full = representations['full'];
    if (full is! String) {
      throw const FormatException(
          'Derpibooru image has no full representation');
    }

    return 'https:$full';
  }

  static String downloadFileName(Uri uri, int index) {
    var fileName =
        uri.toString().substring(uri.toString().lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) {
        fileName = fileName.substring(0, separatorIndex);
      }
    }
    return Utils.sanitizeSaveAs(fileName);
  }
}
