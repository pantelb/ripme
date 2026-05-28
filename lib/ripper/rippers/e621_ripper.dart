import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class E621Ripper extends AbstractHTMLRipper {
  E621Ripper(Uri url) : super(sanitizeUrl(url));

  static const String domain = 'e621.net';
  static const Duration postDelay = Duration(seconds: 3);

  static final RegExp _oldPostPattern = RegExp(
    r"^https?://(www\.)?e621\.net/post/index/[^/]+/([a-zA-Z0-9$_.+!*'():,%-]+)(/.*)?(#.*)?$",
  );
  static final RegExp _oldPoolPattern = RegExp(
    r"^https?://(www\.)?e621\.net/pool/show/([a-zA-Z0-9$_.+!*'(),%:-]+)(\?.*)?(/.*)?(#.*)?$",
  );
  static final RegExp _newPostPattern = RegExp(
    r"^https?://(www\.)?e621\.net/posts\?([\S]*?)tags=([a-zA-Z0-9$_.+!*'(),%:-]+)(\&[\S]+)?",
  );
  static final RegExp _newPoolPattern =
      RegExp(r'^https?://(www\.)?e621\.net/pools/([\d]+)(\?[\S]*)?');
  static final RegExp _oldSearchPattern = RegExp(
    r"^https?://(www\.)?e621\.net/post/search\?tags=([a-zA-Z0-9$_.+!*'():,%-]+)(/.*)?(#.*)?$",
  );

  Map<String, String> _cookies = const {};
  String _userAgent = Http.userAgent;

  @override
  String getHost() => 'e621';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  static Uri sanitizeUrl(Uri url) {
    final match = _oldSearchPattern.firstMatch(url.toString());
    if (match != null) {
      return Uri.parse(
        'https://e621.net/post/index/1/${match.group(2)!.replaceAll('+', '%20')}',
      );
    }
    return url;
  }

  @override
  Future<String> getGID(Uri url) async {
    final prefix = url.path.startsWith('/pool') ? 'pool_' : '';
    return Utils.filesystemSafe('$prefix${termFromUrl(url)}');
  }

  static String termFromUrl(Uri url) {
    final text = url.toString();
    for (final entry in [
      (_oldPostPattern, 2),
      (_oldPoolPattern, 2),
      (_newPostPattern, 3),
      (_newPoolPattern, 2),
    ]) {
      final match = entry.$1.firstMatch(text);
      if (match != null) return match.group(entry.$2)!;
    }

    throw FormatException(
      'Expected e621.net URL format: e621.net/posts?tags=searchterm - got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    loadConfig();
    sendUpdate(RipStatus.loadingResource, url.toString());
    Document page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    var index = 0;
    while (!isStopped) {
      warnAboutBlacklist(page);
      final downloads = <RipperDownload>[];
      for (final postUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        await Http.delay(postDelay);
        final fullSize = await fullSizedImage(Uri.parse(postUrl));
        if (fullSize == null || fullSize.isEmpty) continue;
        final uri = Uri.parse(fullSize);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, downloadFileName(uri, index))),
          ),
        );
      }

      if (downloads.isEmpty) {
        sendUpdate(RipStatus.ripErrored, 'No images found at $url');
        break;
      }
      await downloadFiles(downloads);
      if (isStopped) break;

      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await getDocument(nextUri, retries: 1);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  void loadConfig() {
    final cookiesString = Utils.getConfigString('e621.cookies', '') ?? '';
    _cookies = parseCookies(cookiesString);
    if (_cookies.containsKey('cf_clearance')) {
      sendUpdate(
        RipStatus.downloadWarn,
        "Using CloudFlare captcha cookies, make sure to update them and set your browser's useragent in config!",
      );
    }
    if (_cookies.containsKey('remember')) {
      sendUpdate(RipStatus.downloadWarn, 'Logging in using auth cookie.');
    }

    _userAgent = Utils.getConfigString('e621.useragent', Http.userAgent) ??
        Http.userAgent;
  }

  Future<Document> getFirstPage() {
    if (url.path.startsWith('/pool')) {
      return getDocument(
          Uri.parse('https://e621.net/pools/${termFromUrl(url)}'));
    }
    return getDocument(
        Uri.parse('https://e621.net/posts?tags=${termFromUrl(url)}'));
  }

  Future<Document> getDocument(Uri uri, {int retries = 1}) {
    return Http.get(
      uri,
      headers: {'User-Agent': _userAgent},
      cookies: _cookies,
    );
  }

  void warnAboutBlacklist(Document page) {
    if (page.querySelectorAll('div.hidden-posts-notice').isNotEmpty) {
      sendUpdate(
        RipStatus.downloadWarn,
        'Some posts are blacklisted. Consider logging in. Search for "e621" in this wiki page: https://github.com/RipMeApp/ripme/wiki/Config-options',
      );
    }
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return postUrlsFromPage(page);
  }

  static List<String> postUrlsFromPage(Document page) {
    final urls = <String>[];
    for (final link in page.querySelectorAll('article > a')) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;
      urls.add(Uri.parse('https://e621.net').resolve(href).toString());
    }
    return urls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    warnAboutBlacklist(page);
    final link = page.querySelector('a#paginator-next');
    final href = link?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return Uri.parse('https://e621.net').resolve(href);
  }

  Future<String?> fullSizedImage(Uri postUrl) async {
    try {
      final page = await getDocument(postUrl, retries: 3);
      final url = fullSizedImageFromPage(page);
      if (url != null) return url;

      if (page.querySelectorAll('#blacklist-box').isNotEmpty) {
        sendUpdate(
          RipStatus.ripErrored,
          'Cannot download image - blocked by blacklist. Consider logging in. Search for "e621" in this wiki page: https://github.com/RipMeApp/ripme/wiki/Config-options',
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? fullSizedImageFromPage(Document page) {
    final link = page.querySelector('div#image-download-link > a');
    final href = link?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return Uri.parse('https://e621.net').resolve(href).toString();
  }

  static Map<String, String> parseCookies(String cookiesString) {
    final cookies = <String, String>{};
    for (final rawPart in cookiesString.split(';')) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;
      final separator = part.indexOf('=');
      if (separator <= 0) continue;
      cookies[part.substring(0, separator).trim()] =
          part.substring(separator + 1).trim();
    }
    return cookies;
  }

  static String downloadFileName(Uri uri, int index) {
    var fileName =
        uri.toString().substring(uri.toString().lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) {
        fileName = fileName.substring(0, separatorIndex);
      }
    }
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
