import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';
import 'fuskator_ripper.dart';

class HentaifoundryRipper extends AbstractHTMLRipper {
  HentaifoundryRipper(super.url);

  static const String domain = 'hentai-foundry.com';
  static const String baseUrl = 'https://www.hentai-foundry.com';
  static final RegExp _gidPattern = RegExp(
      r'^.*hentai-foundry\.com/(pictures|stories)/user/([a-zA-Z0-9\-_]+).*$');
  static final RegExp _thumbHrefPattern =
      RegExp(r'.*/user/([a-zA-Z0-9\-_]+)/(\d+)/.*');

  final Map<String, String> _cookies = <String, String>{};

  @override
  String getHost() => 'hentai-foundry';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(2)!;
    throw FormatException(
      'Expected hentai-foundry.com gallery format: hentai-foundry.com/pictures/user/USERNAME Got: $url',
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
        final uri = Uri.parse(imageUrl);
        final isPdf = uri.path.endsWith('.pdf');
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
            headers: isPdf ? {'Referer': url.toString()} : null,
            cookies: isPdf ? _cookies : null,
          ),
        );
      }
      await downloadFiles(downloads);

      if (isStopped) break;
      final nextUri = await getNextPage(page);
      if (nextUri == null) break;
      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await getPage(nextUri);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    final agreeUri = Uri.parse('$baseUrl/?enterAgree=1&size=1500');
    var response = await Http.getResponse(
      agreeUri,
      headers: {'Referer': '$baseUrl/'},
      cookies: _cookies,
    );
    _cookies.addAll(FuskatorRipper.cookiesFromSetCookieHeader(
        response.headers['set-cookie']));
    var page = html.parse(response.body, sourceUrl: agreeUri.toString());

    final csrfToken =
        page.querySelector('input[name=YII_CSRF_TOKEN]')?.attributes['value'];
    if (csrfToken != null) {
      response = await http.post(
        Uri.parse('$baseUrl/site/filters'),
        headers: {
          'User-Agent': Http.userAgent,
          'Referer': '$baseUrl/',
          'Cookie': FuskatorRipper.cookieHeader(_cookies),
        },
        body: filterFormData(csrfToken),
      );
      _cookies.addAll(FuskatorRipper.cookiesFromSetCookieHeader(
          response.headers['set-cookie']));
    }

    return getPage(url);
  }

  Future<Document> getPage(Uri uri) async {
    final response = await Http.getResponse(
      uri,
      headers: {'Referer': '$baseUrl/'},
      cookies: _cookies,
    );
    _cookies.addAll(FuskatorRipper.cookiesFromSetCookieHeader(
        response.headers['set-cookie']));
    if (response.statusCode != 200) {
      throw HttpException('Failed to load $uri: Status ${response.statusCode}');
    }
    return html.parse(response.body, sourceUrl: uri.toString());
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    if (page.querySelector('li.next.hidden') != null) return null;
    final href = page.querySelector('li.next > a')?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return Uri.parse('$baseUrl$href');
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    if (url.toString().contains('/stories/')) return pdfUrlsFromPage(page);

    final imageUrls = <String>[];
    for (final imagePageUrl in imagePageUrlsFromPage(page)) {
      if (isStopped) break;
      try {
        final imagePage =
            await Http.get(Uri.parse(imagePageUrl), cookies: _cookies);
        final imageUrl = imageUrlFromImagePage(imagePage);
        if (imageUrl != null) imageUrls.add(imageUrl);
      } catch (_) {
        continue;
      }
    }
    return imageUrls;
  }

  Map<String, String> get cookiesForTesting => Map.unmodifiable(_cookies);

  static Map<String, String> filterFormData(String csrfToken) {
    return {
      'YII_CSRF_TOKEN': csrfToken,
      'rating_nudity': '3',
      'rating_violence': '3',
      'rating_profanity': '3',
      'rating_racism': '3',
      'rating_sex': '3',
      'rating_spoilers': '3',
      'rating_yaoi': '1',
      'rating_yuri': '1',
      'rating_teen': '1',
      'rating_guro': '1',
      'rating_furry': '1',
      'rating_beast': '1',
      'rating_male': '1',
      'rating_female': '1',
      'rating_futa': '1',
      'rating_other': '1',
      'rating_scat': '1',
      'rating_incest': '1',
      'rating_rape': '1',
      'filter_media': 'A',
      'filter_order':
          Utils.getConfigString('hentai-foundry.filter_order', 'date_old') ??
              'date_old',
      'filter_type': '0',
    };
  }

  static List<String> pdfUrlsFromPage(Document page) {
    return [
      for (final link in page.querySelectorAll('a.pdfLink'))
        '$baseUrl${link.attributes['href'] ?? ''}',
    ];
  }

  static List<String> imagePageUrlsFromPage(Document page) {
    final urls = <String>[];
    for (final thumb
        in page.querySelectorAll('div.thumb_square > a.thumbLink')) {
      final href = thumb.attributes['href'] ?? '';
      if (!_thumbHrefPattern.hasMatch(href)) continue;
      urls.add('$baseUrl$href');
    }
    return urls;
  }

  static String? imageUrlFromImagePage(Document page) {
    final image = page.querySelector('div.boxbody > img.center');
    final src = image?.attributes['src'];
    if (src == null || src.isEmpty) return null;
    if (src.contains('thumbs.')) {
      final onclick = image?.attributes['onclick'];
      if (onclick == null || onclick.isEmpty) return null;
      final fullSrc = onclick
          .replaceAll('this.src=', '')
          .replaceAll("'", '')
          .replaceAll(r'; $(#resize_message).hide();', '');
      return 'https:$fullSrc';
    }
    return 'https:$src';
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    final usePrefix = Utils.getConfigBoolean('hentai-foundry.use_prefix', true);
    if (!usePrefix || !Utils.getConfigBoolean('download.save_order', true)) {
      return '';
    }
    return '${index.toString().padLeft(3, '0')}_';
  }
}
