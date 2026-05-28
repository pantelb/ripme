import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class FuraffinityRipper extends AbstractHTMLRipper {
  FuraffinityRipper(super.url);

  static const String urlBase = 'https://www.furaffinity.net';
  static const String defaultCookies =
      'a=897bc45b-1f87-49f1-8a85-9412bc103e7a;b=c8807f36-7a85-4caf-80ca-01c2a2368267';
  static const Duration pageDelay = Duration(milliseconds: 500);
  static const Duration postDelay = Duration(seconds: 1);
  static final RegExp _galleryPattern =
      RegExp(r'^https?://www\.furaffinity\.net/gallery/([-_.0-9a-zA-Z]+).*$');
  static final RegExp _scrapsPattern =
      RegExp(r'^https?://www\.furaffinity\.net/scraps/([-_.0-9a-zA-Z]+).*$');

  Map<String, String> _cookies = <String, String>{};

  @override
  String getHost() => 'furaffinity';

  String getDomain() => 'furaffinity.net';

  @override
  bool canRip(Uri url) {
    final text = url.toString();
    return _galleryPattern.hasMatch(text) || _scrapsPattern.hasMatch(text);
  }

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    final gallery = _galleryPattern.firstMatch(text);
    if (gallery != null) return gallery.group(1)!;

    final scraps = _scrapsPattern.firstMatch(text);
    if (scraps != null) return scraps.group(1)!;

    throw FormatException('Unable to find images in$url');
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
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
          ),
        );
      }
      await downloadFiles(downloads);

      if (isStopped) break;
      final nextUri = await getNextPage(page);
      if (nextUri == null) break;
      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await Http.get(nextUri, cookies: _cookies);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    setCookies();
    return Http.get(url, cookies: _cookies);
  }

  void setCookies() {
    if (!Utils.getConfigBoolean('furaffinity.login', true)) {
      _cookies = <String, String>{};
      return;
    }

    final cookieText =
        Utils.getConfigString('furaffinity.cookies', defaultCookies) ??
            defaultCookies;
    if (cookieText == defaultCookies) {
      sendUpdate(
        RipStatus.downloadErrored,
        'WARNING: Using the shared furaffinity account exposes both your IP and how many items you downloaded to the other users of the share account',
      );
    }
    _cookies = parseCookies(cookieText);
  }

  Map<String, String> get cookiesForTesting => Map.unmodifiable(_cookies);

  @override
  Future<Uri?> getNextPage(Document page) async {
    final href = page.querySelector('a.right')?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    await Http.delay(pageDelay);
    return Uri.parse('$urlBase$href');
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final urls = <String>[];
    for (final postUrl in postUrlsFromPage(page)) {
      if (isStopped) break;
      final imageUrl = await getImageFromPost(postUrl);
      if (imageUrl != null && imageUrl.startsWith('http')) urls.add(imageUrl);
    }
    return urls;
  }

  Future<String?> getImageFromPost(String postUrl) async {
    await Http.delay(postDelay);
    try {
      final page = await Http.get(Uri.parse(postUrl), cookies: _cookies);
      return imageFromPostPage(page);
    } catch (_) {
      return null;
    }
  }

  static List<String> postUrlsFromPage(Document page) {
    return [
      for (final element in page.querySelectorAll('figure.t-image > b > u > a'))
        '$urlBase${element.attributes['href'] ?? ''}',
    ];
  }

  static String? imageFromPostPage(Document page) {
    for (final link in page.getElementsByTagName('a')) {
      if (link.text == 'Download') {
        return 'https:${link.attributes['href'] ?? ''}';
      }
    }
    return null;
  }

  static Map<String, String> parseCookies(String cookieText) {
    final cookies = <String, String>{};
    for (final part in cookieText.split(';')) {
      final separator = part.indexOf('=');
      if (separator <= 0) continue;
      cookies[part.substring(0, separator).trim()] =
          part.substring(separator + 1).trim();
    }
    return cookies;
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
}
