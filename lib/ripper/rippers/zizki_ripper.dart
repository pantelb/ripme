import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class ZizkiRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?://(www\.)?zizki\.com/([a-zA-Z0-9\-_]+).*$',
  );

  final Map<String, String> _cookies = <String, String>{};

  ZizkiRipper(super.url);

  @override
  String getHost() => 'zizki';

  String getDomain() => 'zizki.com';

  @override
  bool canRip(Uri url) =>
      url.host == 'zizki.com' || url.host == 'www.zizki.com';

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(2)!;

    throw FormatException(
      'Expected URL format: http://www.zizki.com/author/albumname, got: $url',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await getFirstPage();
      final title = albumTitleFromDocument(page);
      if (title != null) return title;
    } catch (_) {
      // Java falls back to the inherited host_GID name when the first page fails.
    }
    return super.getAlbumTitle(url);
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final uri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: uri,
          saveAs: File(
            p.join(
              workingDir.path,
              fileNameForUrl(uri, prefix: prefix(index)),
            ),
          ),
          headers: {'Referer': url.toString()},
          cookies: _cookies,
        ),
      );
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    final response = await Http.getResponse(url);
    _cookies.addAll(cookiesFromSetCookieHeader(response.headers['set-cookie']));
    if (response.statusCode != 200) {
      throw HttpException('Failed to load $url: Status ${response.statusCode}');
    }
    return html.parse(response.body, sourceUrl: url.toString());
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  Map<String, String> get cookiesForTesting => Map.unmodifiable(_cookies);

  static String? albumTitleFromDocument(Document page) {
    final title = page.querySelector('h1.title')?.text;
    final author = page.querySelector('span[class=creator] a')?.text;
    if (title == null || author == null) return null;
    return 'zizki_${author}_${title.trim()}';
  }

  static List<String> imageUrlsFromDocument(Document page) {
    final imageUrls = <String>[];
    for (final thumb in page.querySelectorAll('img')) {
      if (thumb.attributes['typeof'] != 'foaf:Image') continue;

      final parent = thumb.parent;
      if (parent == null) continue;
      if (!(parent.attributes['class'] ?? '').contains('colorbox')) continue;

      final href = parent.attributes['href'];
      if (href == null || !href.contains('zizki.com')) continue;

      imageUrls.add(
        href.replaceFirst('/styles/medium/public/', '/styles/large/public/'),
      );
    }
    return imageUrls;
  }

  static String prefix(int index) => '${index.toString().padLeft(3, '0')}_';

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  static Map<String, String> cookiesFromSetCookieHeader(String? header) {
    if (header == null || header.trim().isEmpty) return const {};

    final cookies = <String, String>{};
    final parts = header.split(RegExp(r',\s*(?=[^;,]+=)'));
    for (final rawCookie in parts) {
      final firstPart = rawCookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator <= 0) continue;

      final name = firstPart.substring(0, separator).trim();
      final value = firstPart.substring(separator + 1).trim();
      if (name.isNotEmpty) cookies[name] = value;
    }
    return cookies;
  }
}
