import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';
import 'fuskator_ripper.dart';

class TwodgalleriesRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern =
      RegExp(r'^.*2dgalleries\.com/artist/([a-zA-Z0-9\-]+).*$');

  int _offset = 0;
  Map<String, String> _cookies = {};

  TwodgalleriesRipper(super.url);

  @override
  String getHost() => '2dgalleries';

  String getDomain() => '2dgalleries.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected 2dgalleries.com album format: '
      '2dgalleries.com/artist/... Got: $url',
    );
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
                javaDownloadFileName(imageUri, prefixForIndex(index)),
              ),
            ),
          ),
        );
      }
      await downloadFiles(downloads);

      try {
        page = await getNextDocument();
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    try {
      await login();
    } on IOException {
      // Java logs the login IOException and still attempts the gallery request.
    }
    return getPage(pageUrlForUser(await getGID(url), _offset));
  }

  Future<Document> getNextDocument() async {
    _offset += 24;
    await Http.delay(const Duration(milliseconds: 500));
    final nextPage = await getPage(pageUrlForUser(await getGID(url), _offset));
    if (nextPage.querySelectorAll('div.hcaption > img').isEmpty) {
      throw const HttpException('No more images to retrieve');
    }
    return nextPage;
  }

  Future<Document> getPage(Uri uri) async {
    final response = await Http.getResponse(uri, cookies: _cookies);
    if (response.statusCode != 200) {
      throw HttpException('Failed to load $uri: Status ${response.statusCode}');
    }
    return html_parser.parse(response.body, sourceUrl: uri.toString());
  }

  Future<void> login({http.Client? client}) async {
    final initialResponse = await Http.getResponse(url);
    _cookies = FuskatorRipper.cookiesFromSetCookieHeader(
      initialResponse.headers['set-cookie'],
    );
    final page = html_parser.parse(
      initialResponse.body,
      sourceUrl: url.toString(),
    );
    final ctoken = loginTokenFromPage(page);
    if (ctoken == null) {
      throw const FormatException('Could not find 2dgalleries login token');
    }

    final activeClient = client ?? http.Client();
    try {
      final response = await activeClient.post(
        Uri.parse('http://en.2dgalleries.com/account/login'),
        headers: {
          'User-Agent': Http.userAgent,
          'Referer': 'http://en.2dgalleries.com/',
          if (_cookies.isNotEmpty)
            'Cookie': FuskatorRipper.cookieHeader(_cookies),
        },
        body: loginPostData(ctoken),
      );
      _cookies = FuskatorRipper.cookiesFromSetCookieHeader(
        response.headers['set-cookie'],
      );
    } finally {
      if (client == null) activeClient.close();
    }
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    _offset += 24;
    return pageUrlForUser(await getGID(url), _offset);
  }

  static Uri pageUrlForUser(String userId, int offset) {
    return Uri.parse(
      'http://en.2dgalleries.com/artist/$userId'
      '?timespan=4'
      '&order=1'
      '&catid=2'
      '&offset=$offset'
      '&ajx=1&pager=1',
    );
  }

  static String? loginTokenFromPage(Document page) {
    return page.querySelector('form > input[name=ctoken]')?.attributes['value'];
  }

  static Map<String, String> loginPostData(String ctoken) {
    return {
      'user[login]': utf8.decode(base64.decode('cmlwbWU=')),
      'user[password]': utf8.decode(base64.decode('cmlwcGVy')),
      'rememberme': '1',
      'ctoken': ctoken,
    };
  }

  static List<String> imageUrlsFromPage(Document page) {
    final imageUrls = <String>[];
    for (final thumb in page.querySelectorAll('div.hcaption > img')) {
      var image = thumb.attributes['src'] ?? '';
      image = image.replaceAll('/200H/', '/');
      if (image.startsWith('//')) {
        image = 'http:$image';
      } else if (image.startsWith('/')) {
        image = 'http://en.2dgalleries.com$image';
      }
      imageUrls.add(image);
    }
    return imageUrls;
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String javaDownloadFileName(Uri uri, String prefix) {
    final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
