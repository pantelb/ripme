import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class SankakuComplexRipper extends AbstractHTMLRipper {
  static final RegExp _tagPattern = RegExp(
    r'^https?://([a-zA-Z0-9]+\.)?sankakucomplex\.com/.*tags=([^&]+).*$',
  );

  Document? _albumDoc;
  Uri? _currentPage;
  final Map<String, String> _cookies = {};

  SankakuComplexRipper(super.url);

  @override
  String getHost() => 'sankakucomplex';

  String getDomain() => 'sankakucomplex.com';

  @override
  bool canRip(Uri url) => _tagPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _tagPattern.firstMatch(url.toString());
    if (match != null) {
      return Uri.decodeComponent('${match.group(1)}_${match.group(2)}');
    }

    throw FormatException(
      'Expected sankakucomplex.com URL format: '
      'idol.sankakucomplex.com?...&tags=something... - got ${url}instead',
    );
  }

  String? getSubDomain(Uri url) {
    final match = _tagPattern.firstMatch(url.toString());
    if (match == null) return null;
    return Uri.decodeComponent(match.group(1) ?? '');
  }

  Future<Document> getFirstPage() async {
    if (_albumDoc != null) return _albumDoc!;

    final response = await Http.getResponse(url);
    _cookies.addAll(cookiesFromHeaders(response.headers));
    _albumDoc = html.parse(response.body);
    return _albumDoc!;
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      _currentPage = url;
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        await Http.delay(const Duration(seconds: 8));
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForUrl(imageUri, prefix: prefixForIndex(index)),
              ),
            ),
          ),
        );
      }

      await downloadFiles(downloads);
      if (isStopped) break;

      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        _currentPage = nextUri;
        page = await Http.get(nextUri, cookies: _cookies);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final imageUrls = <String>[];
    final siteUrl = Uri.parse('https://${getSubDomain(url)}sankakucomplex.com');

    for (final thumbSpan in page.querySelectorAll(
      'div.content > div > span.thumb > a',
    )) {
      final postLink = thumbSpan.attributes['href'] ?? '';
      try {
        final subPage = await getPostPage(siteUrl.resolve(postLink));
        imageUrls.add(highresUrlFromPostPage(subPage));
      } on IOException {
        continue;
      }
    }

    return imageUrls;
  }

  Future<Document> getPostPage(Uri postUri) => Http.get(postUri);

  @override
  Future<Uri?> getNextPage(Document page) async {
    final pagination = page.querySelector('div.pagination');
    if (pagination == null) return null;

    final nextPage = pagination.attributes['next-page-url'];
    if (nextPage == null || nextPage.isEmpty) return null;
    if (nextPage.contains('page=26')) return null;

    return (_currentPage ?? url).resolve(nextPage);
  }

  static String highresUrlFromPostPage(Document page) {
    final href = page
            .querySelector('div[id=stats] > ul > li > a[id=highres]')
            ?.attributes['href'] ??
        '';
    return 'https:$href';
  }

  static Map<String, String> cookiesFromHeaders(Map<String, String> headers) {
    final setCookie = headers['set-cookie'];
    if (setCookie == null || setCookie.trim().isEmpty) return const {};

    final cookies = <String, String>{};
    for (final cookie in setCookie.split(',')) {
      final firstPart = cookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator <= 0) continue;
      cookies[firstPart.substring(0, separator)] =
          firstPart.substring(separator + 1);
    }
    return cookies;
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
