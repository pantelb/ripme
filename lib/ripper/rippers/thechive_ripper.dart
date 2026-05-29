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

class ThechiveJsonPage {
  final List<String> urls;
  final String? nextSeed;
  final Map<String, String> cookies;

  const ThechiveJsonPage({
    required this.urls,
    required this.nextSeed,
    required this.cookies,
  });
}

class ThechiveRipper extends AbstractHTMLRipper {
  static final RegExp _postPattern = RegExp(
    r'^https?://thechive\.com/[0-9]*/[0-9]*/[0-9]*/([a-zA-Z0-9_\-]*)/?$',
  );
  static final RegExp _userPattern =
      RegExp(r'^https?://i\.thechive\.com/([0-9a-zA-Z_]+)');
  static final RegExp _imageTagPattern = RegExp(
    r'<img\s(?:.|\n)+?>',
    multiLine: true,
  );

  static final Uri jsonUrl = Uri.parse('https://i.thechive.com/rest/uploads');

  Map<String, String> cookies = <String, String>{};
  String? nextSeed = '';
  String username = '';

  ThechiveRipper(super.url);

  @override
  String getHost() => isPostUrl(url) ? 'thechive' : 'i.thechive';

  String getDomain() => 'thechive.com';

  @override
  bool canRip(Uri url) =>
      isPostUrl(url) || _userPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final value = url.toString();
    final postMatch = _postPattern.firstMatch(value);
    if (postMatch != null) return postMatch.group(1)!;

    final userMatch = _userPattern.firstMatch(value);
    if (userMatch != null) {
      username = userMatch.group(1)!;
      return username;
    }

    throw FormatException(
      'Expected thechive.com URL format: '
      'thechive.com/YEAR/MONTH/DAY/POSTTITLE/ OR i.thechive.com/username, '
      'got $url instead.',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    final downloads = <RipperDownload>[];
    var index = 0;

    if (isPostUrl(url)) {
      Document page;
      try {
        page = await Http.get(url);
      } catch (e) {
        sendUpdate(RipStatus.ripErrored, e.toString());
        return;
      }

      for (final imageUrl in urlsFromThechiveDocument(page)) {
        if (isStopped) break;
        index++;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(downloadFor(imageUri, index));
      }
    } else {
      await getGID(url);
      while (!isStopped && nextSeed != null) {
        final page = await fetchIDotThechivePage(
          username: username,
          seed: nextSeed ?? '',
          cookies: cookies,
        );
        cookies = page.cookies;
        nextSeed = page.nextSeed;
        if (page.urls.isEmpty) break;
        for (final imageUrl in page.urls) {
          if (isStopped) break;
          index++;
          downloads.add(downloadFor(Uri.parse(imageUrl), index));
        }
      }
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    if (isPostUrl(url)) return urlsFromThechiveDocument(page);
    final jsonPage = await fetchIDotThechivePage(
      username: username,
      seed: nextSeed ?? '',
      cookies: cookies,
    );
    cookies = jsonPage.cookies;
    nextSeed = jsonPage.nextSeed;
    return jsonPage.urls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  RipperDownload downloadFor(Uri imageUri, int index) {
    return RipperDownload(
      url: imageUri,
      saveAs: File(
        p.join(workingDir.path, fileNameForUrl(imageUri, prefix(index))),
      ),
    );
  }

  static bool isPostUrl(Uri url) => _postPattern.hasMatch(url.toString());

  static List<String> urlsFromThechiveDocument(Document doc) {
    final result = <String>[];
    for (final script in doc.getElementsByTagName('script')) {
      final data = script.text;
      if (!data.contains('CHIVE_GALLERY_ITEMS')) continue;

      final buffer = StringBuffer();
      for (final match in _imageTagPattern.allMatches(data)) {
        buffer.write(match.group(0)!.replaceAll(r'\', ''));
      }

      final imgDoc = html.parse(buffer.toString());
      for (final img in imgDoc.getElementsByTagName('img')) {
        final url = img.attributes.containsKey('data-gifsrc')
            ? img.attributes['data-gifsrc'] ?? ''
            : img.attributes['src'] ?? '';
        result.add(stripAfterQuestionMark(url));
      }
    }
    return result;
  }

  static ThechiveJsonPage urlsFromIDotJson(
    String body, {
    Map<String, String> cookies = const {},
  }) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final uploads = json['uploads'] as List<dynamic>;
    String? seed;
    final urls = <String>[];

    for (final upload in uploads.cast<Map<String, dynamic>>()) {
      if (upload['mediaType'] == 'gif') {
        urls.add('https:${upload['mediaUrlOverlay'] as String}');
      } else {
        urls.add('https:${upload['mediaGifFrameUrl'] as String}');
      }
      seed = upload['activityId'] as String;
    }

    return ThechiveJsonPage(urls: urls, nextSeed: seed, cookies: cookies);
  }

  static Future<ThechiveJsonPage> fetchIDotThechivePage({
    required String username,
    required String seed,
    required Map<String, String> cookies,
    http.Client? client,
  }) async {
    final closeClient = client == null;
    final activeClient = client ?? http.Client();
    try {
      final response = await activeClient.post(
        jsonUrl,
        headers: {
          'User-Agent': Http.userAgent,
          if (cookies.isNotEmpty)
            'Cookie': cookies.entries
                .map((entry) => '${entry.key}=${entry.value}')
                .join('; '),
        },
        body: {
          'seed': seed,
          'queryType': 'by-username',
          'username': username,
        },
      );
      return urlsFromIDotJson(
        response.body,
        cookies: cookiesFromSetCookieHeader(response.headers['set-cookie']),
      );
    } finally {
      if (closeClient) activeClient.close();
    }
  }

  static Map<String, String> cookiesFromSetCookieHeader(String? header) {
    if (header == null || header.trim().isEmpty) return const {};
    final cookies = <String, String>{};
    for (final rawCookie in header.split(RegExp(r',\s*(?=[^;,]+=)'))) {
      final firstPart = rawCookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator <= 0) continue;
      cookies[firstPart.substring(0, separator)] =
          firstPart.substring(separator + 1);
    }
    return cookies;
  }

  static String stripAfterQuestionMark(String value) {
    final question = value.indexOf('?');
    if (question < 0) return value;
    return value.substring(0, question);
  }

  static String fileNameForUrl(Uri uri, String prefix) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  static String prefix(int index) => '${index.toString().padLeft(3, '0')}_';
}
