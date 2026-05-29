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

class StaRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(r'https://sta\.sh/([A-Za-z0-9]+)$');

  final Map<String, String> _cookies = <String, String>{};

  StaRipper(super.url);

  @override
  String getHost() => 'sta';

  String getDomain() => 'sta.sh';

  @override
  bool canRip(Uri url) => url.host == getDomain();

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected sta.sh URL format: '
      'sta.sh/ALBUMID - got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await Http.get(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final imageUri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: imageUri,
          saveAs:
              File(p.join(workingDir.path, fileNameForUrl(imageUri, index))),
        ),
      );
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final result = <String>[];
    for (final thumbPageUrl in thumbPageUrlsFromDocument(page)) {
      if (!isAbsoluteUrl(thumbPageUrl)) continue;

      try {
        final thumbUri = Uri.parse(thumbPageUrl);
        final response = await Http.getResponse(thumbUri);
        _cookies
            .addAll(cookiesFromSetCookieHeader(response.headers['set-cookie']));
        final thumbPage = html.parse(response.body, sourceUrl: thumbPageUrl);
        final downloadUrl = downloadLinkFromThumbPage(thumbPage);
        if (downloadUrl == null || downloadUrl.isEmpty) continue;

        final imageUrl = await imageLinkFromDownloadLink(
          Uri.parse(downloadUrl),
          cookies: _cookies,
        );
        if (imageUrl != null && imageUrl.isNotEmpty) result.add(imageUrl);
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> thumbPageUrlsFromDocument(Document page) {
    return [
      for (final element in page.querySelectorAll('span > span > a.thumb'))
        element.attributes['href'] ?? '',
    ];
  }

  static String? downloadLinkFromThumbPage(Document page) {
    final href = page.querySelector('a.dev-page-download')?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return href;
  }

  static bool isAbsoluteUrl(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.hasScheme && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> imageLinkFromDownloadLink(
    Uri url, {
    Map<String, String> cookies = const {},
    http.Client? client,
  }) async {
    final closeClient = client == null;
    final activeClient = client ?? http.Client();
    try {
      final request = http.Request('GET', url)
        ..followRedirects = false
        ..headers['User-Agent'] = Http.userAgent;
      if (cookies.isNotEmpty) {
        request.headers['Cookie'] = cookieHeader(cookies);
      }
      final response = await activeClient.send(request);
      return response.headers['location'] ?? response.headers['Location'];
    } catch (_) {
      return null;
    } finally {
      if (closeClient) activeClient.close();
    }
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

  static String cookieHeader(Map<String, String> cookies) =>
      cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${prefix(index)}$fileName');
  }

  static String prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
