import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' show Response;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class WebtoonsRipper extends AbstractHTMLRipper {
  static final RegExp _canRipPattern = RegExp(
    r'^https?://www\.webtoons\.com/[a-zA-Z-_]+/[a-zA-Z_-]+/([a-zA-Z0-9_-]*)/[a-zA-Z0-9_-]+/\S*$',
  );
  static final RegExp _gidPattern = RegExp(
    r'^https?://www\.webtoons\.com/[a-zA-Z]+/[a-zA-Z]+/([a-zA-Z0-9_-]*)/[a-zA-Z0-9_-]+/\S*$',
  );

  WebtoonsRipper(super.url);

  Map<String, String> _cookies = const {};

  @override
  String getHost() => 'webtoons';

  String getDomain() => 'www.webtoons.com';

  @override
  bool canRip(Uri url) => _canRipPattern.hasMatch(url.toString());

  @override
  Future<String> getAlbumTitle(Uri url) async {
    final match = _canRipPattern.firstMatch(url.toString());
    if (match != null) return '${getHost()}_${match.group(1)!}';
    return super.getAlbumTitle(url);
  }

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected URL format: http://www.webtoons.com/LANG/CAT/TITLE/VOL/, got: $url',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      var page = await getFirstPage();
      var index = 0;
      while (!isStopped) {
        final downloads = <RipperDownload>[];
        for (final imageUrl in await getURLsFromPage(page)) {
          if (isStopped) break;
          index++;
          final imageUri = Uri.parse(imageUrl);
          downloads.add(
            RipperDownload(
              url: imageUri,
              saveAs: File(
                p.join(
                  workingDir.path,
                  fileNameForUrl(imageUri, prefixForIndex(index)),
                ),
              ),
              headers: {'Referer': url.toString()},
              cookies: _cookies,
            ),
          );
        }
        await downloadFiles(downloads);

        final nextUrl = await getNextPage(page);
        if (nextUrl == null) break;
        sendUpdate(RipStatus.loadingResource, nextUrl.toString());
        page = await Http.get(nextUrl);
      }
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    final response = await Http.getResponse(url);
    _cookies = {
      ...cookiesFromResponse(response),
      'needCOPPA': 'false',
      'needCCPA': 'false',
      'needGDPR': 'false',
    };
    return Http.get(url, cookies: _cookies);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final href = page.querySelector('a.pg_next')?.attributes['href'] ?? '';
    if (href.isEmpty || href == '#') return null;
    return Uri.parse(href);
  }

  static Document documentFromHtml(String html) => html_parser.parse(html);

  static List<String> imageUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final image in page.querySelectorAll('div.viewer_img > img')) {
      final originalUrl = image.attributes['data-url'] ?? '';
      result.add(originalUrl.split(RegExp(r'\?type')).first);
    }
    return result;
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, String prefix) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  static Map<String, String> cookiesFromResponse(Response response) {
    final cookies = <String, String>{};
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return cookies;
    for (final cookie in setCookie.split(',')) {
      final firstPart = cookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator <= 0) continue;
      cookies[firstPart.substring(0, separator)] =
          firstPart.substring(separator + 1);
    }
    return cookies;
  }
}
