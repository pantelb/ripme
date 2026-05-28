import 'dart:convert';
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

class FuskatorRipper extends AbstractHTMLRipper {
  FuskatorRipper(Uri url) : super(sanitizeUri(url));

  static const String jsonUrl = 'https://fuskator.com/ajax/gal.aspx';
  static const String xAuthUrl = 'https://fuskator.com/ajax/auth.aspx';
  static final RegExp _gidPattern =
      RegExp(r'^.*fuskator\.com/full/([a-zA-Z0-9\-~]+).*$');

  final Map<String, String> _cookies = <String, String>{};
  String? _xAuthToken;

  @override
  String getHost() => 'fuskator';

  String getDomain() => 'fuskator.com';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(sanitizeUri(url).toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(sanitizeUri(url).toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected fuskator.com gallery formats: fuskator.com/full/id/... Got: $url',
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

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final uri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: uri,
          saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
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
    try {
      await getXAuthToken();
      final token = _xAuthToken;
      if (token == null || token.isEmpty) {
        throw const HttpException('No xAuthToken found.');
      }

      final json = await Http.getJSON(
        Uri.parse(jsonUrl).replace(queryParameters: {
          'X-Auth': token,
          'hash': await getGID(url),
          '_': DateTime.now().millisecondsSinceEpoch.toString(),
        }),
        cookies: _cookies,
      );
      return imageUrlsFromJson(json);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  Future<void> getXAuthToken() async {
    if (_cookies.isEmpty) {
      throw const HttpException('Null cookies or no cookies found.');
    }

    final response = await http.post(
      Uri.parse(xAuthUrl),
      headers: {
        'User-Agent': Http.userAgent,
        'Cookie': cookieHeader(_cookies),
      },
    );
    _cookies.addAll(cookiesFromSetCookieHeader(response.headers['set-cookie']));
    if (response.statusCode != 200) {
      throw HttpException(
          'Failed to load auth token: Status ${response.statusCode}');
    }
    _xAuthToken = response.body;
  }

  Map<String, String> get cookiesForTesting => Map.unmodifiable(_cookies);

  static Uri sanitizeUri(Uri url) {
    var text = url.toString();
    if (text.contains('/thumbs/')) {
      text = text.replaceFirst('/thumbs/', '/full/');
    }
    if (text.contains('/expanded/')) {
      text = text.replaceAll('/expanded/', '/full/');
    }
    return Uri.parse(text);
  }

  static List<String> imageUrlsFromJson(dynamic json) {
    final decoded = json is String ? jsonDecode(json) : json;
    if (decoded is! Map) return const [];
    final images = decoded['images'];
    if (images is! List) return const [];

    return [
      for (final image in images)
        if (image is Map && image['imageUrl'] is String)
          'https:${image['imageUrl']}',
    ];
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
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String cookieHeader(Map<String, String> cookies) =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

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
