import 'dart:io';

import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';

class NsfwXxxRipper extends AbstractJSONRipper {
  NsfwXxxRipper(Uri url) : super(sanitizeUrl(url));

  static const String domain = 'nsfw.xxx';

  final List<String> descriptions = <String>[];

  @override
  String getHost() => 'nsfw_xxx';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  static Uri sanitizeUrl(Uri url) {
    final sanitized = url.toString().replaceFirstMapped(
          RegExp(r'https?://nsfw\.xxx/user/([^/]+)/?.*'),
          (match) => 'https://nsfw.xxx/user/${match.group(1)}',
        );
    if (!sanitized.contains('nsfw.xxx/user')) {
      throw FormatException('Invalid URL: $url');
    }
    return Uri.parse(sanitized);
  }

  @override
  Future<String> getGID(Uri url) async {
    final match = RegExp(r'^https://nsfw\.xxx/user/([^/]+)/?$')
        .firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected URL format: nsfw.xxx/user/USER - got $url instead',
    );
  }

  Future<String> getUser() => getGID(url);

  Future<Uri> getPage(int page) async {
    final user = await getUser();
    return Uri.parse(
      'https://nsfw.xxx/slide-page/$page'
      '?nsfw%5B%5D=0&types%5B%5D=image&types%5B%5D=video'
      '&types%5B%5D=gallery&slider=1&jsload=1&user=$user',
    );
  }

  @override
  Future<void> parseJSON(Uri url) async {
    descriptions.clear();
    var index = 0;
    Map<String, dynamic>? json = await getFirstPage();

    while (json != null && !isStopped) {
      final urls = getURLsFromJSON(json);
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
            saveAs: File(
              p.join(
                workingDir.path,
                downloadFileName(uri, index, descriptions[index - 1]),
              ),
            ),
          ),
        );
      }
      await downloadFiles(downloads);

      if (isStopped) break;
      json = await getNextPage(json);
    }
  }

  Future<Map<String, dynamic>> getFirstPage() async {
    final json = await Http.getJSON(await getPage(1));
    if (json is Map<String, dynamic>) return json;
    throw const FormatException('Expected nsfw.xxx JSON object');
  }

  Future<Map<String, dynamic>?> getNextPage(Map<String, dynamic> doc) async {
    final page = doc['page'];
    if (page is! int) return null;

    final nextJson = await Http.getJSON(await getPage(page + 1));
    if (nextJson is! Map<String, dynamic>) {
      throw const FormatException('Expected nsfw.xxx JSON object');
    }
    final items = nextJson['items'];
    if (items is! List || items.isEmpty) return null;
    return nextJson;
  }

  List<String> getURLsFromJSON(Map<String, dynamic> json) {
    final entries = entriesFromJson(json);
    descriptions.addAll(entries.map((entry) => entry.title));
    return entries.map((entry) => entry.srcUrl).toList();
  }

  static List<NsfwXxxEntry> entriesFromJson(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) return const [];

    return [
      for (final item in items)
        if (item is Map<String, dynamic>) entryFromItem(item),
    ];
  }

  static NsfwXxxEntry entryFromItem(Map<String, dynamic> item) {
    final src = item.containsKey('src')
        ? item['src'].toString()
        : videoSrcFromHtml(item['html'].toString());
    return NsfwXxxEntry(
      srcUrl: src,
      author: item['author'].toString(),
      title: item['title'].toString(),
    );
  }

  static String videoSrcFromHtml(String htmlText) {
    final match = RegExp(r'src="([^"]+)"').firstMatch(htmlText);
    if (match == null) {
      throw const FormatException('Unable to find video source');
    }
    return html.parseFragment(match.group(1)!).text ?? match.group(1)!;
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String downloadFileName(Uri uri, int index, String title) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('${prefixForIndex(index)}${title}_$fileName');
  }
}

class NsfwXxxEntry {
  final String srcUrl;
  final String author;
  final String title;

  const NsfwXxxEntry({
    required this.srcUrl,
    required this.author,
    required this.title,
  });
}
