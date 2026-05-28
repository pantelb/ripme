import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class EromeRipper extends AbstractHTMLRipper {
  EromeRipper(Uri url) : super(sanitizeUrl(url));

  static const String domain = 'erome.com';
  static final RegExp _albumPattern =
      RegExp(r'^https?://www\.erome\.com/[ai]/([a-zA-Z0-9]*)/?$');
  static final RegExp _profilePattern =
      RegExp(r'^https?://www\.erome\.com/([a-zA-Z0-9_\-?=]+)/?$');
  static final RegExp _queuePattern =
      RegExp(r'https?://www\.erome\.com/([a-zA-Z0-9_\-?=]*)/?$');

  final Map<String, String> _cookies = <String, String>{};
  Document? _firstPage;

  @override
  String getHost() => 'erome';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  static Uri sanitizeUrl(Uri url) {
    return Uri.parse(url.toString().replaceFirst(
        RegExp(r'^https?://erome\.com'), 'https://www.erome.com'));
  }

  @override
  Future<String> getGID(Uri url) async {
    final text = sanitizeUrl(url).toString();
    final album = _albumPattern.firstMatch(text);
    if (album != null) return album.group(1)!;

    final profile = _profilePattern.firstMatch(text);
    if (profile != null) return profile.group(1)!;

    throw FormatException(
      'erome album not found in $url, expected https://www.erome.com/album',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      _firstPage ??= await getFirstPage();
      final title = _firstPage!
          .querySelector('meta[property="og:title"]')
          ?.attributes['content'];
      if (title != null) {
        final suffix = title.substring(title.lastIndexOf('/') + 1).trim();
        return '${getHost()}_${await getGID(url)}_$suffix';
      }
      return '${getHost()}_${await getGID(url)}';
    } catch (_) {
      return super.getAlbumTitle(url);
    }
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = _firstPage ?? await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    if (hasQueueSupport() && pageContainsAlbums(url)) {
      for (final childUrl in await getAlbumsToQueue(page)) {
        if (isStopped) break;
        sendUpdate(RipStatus.queueAdd, childUrl);
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final mediaUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final uri = Uri.parse(mediaUrl);
      downloads.add(
        RipperDownload(
          url: uri,
          saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
          cookies: _cookies,
        ),
      );
    }
    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    setAuthCookie();
    _firstPage = await Http.get(url, cookies: _cookies);
    return _firstPage!;
  }

  void setAuthCookie() {
    final sessionId = Utils.getConfigString('erome.laravel_session', null);
    if (sessionId != null && sessionId.isNotEmpty) {
      _cookies['laravel_session'] = sessionId;
    }
  }

  Map<String, String> get cookiesForTesting => Map.unmodifiable(_cookies);

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) => _queuePattern.hasMatch(url.toString());

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return [
      for (final album in page.querySelectorAll('div#albums > div.album > a'))
        if ((album.attributes['href'] ?? '').isNotEmpty)
          album.attributes['href']!,
    ];
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final results = mediaFromPage(page);
    if (results.isEmpty && _cookies.isEmpty) {
      sendUpdate(
        RipStatus.downloadWarn,
        'You might try setting erome.laravel_session manually if you think this page definitely contains media.',
      );
    }
    return results;
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> mediaFromPage(Document page) {
    final results = <String>[];
    for (final image in page.querySelectorAll('img.img-front')) {
      final dataSrc = image.attributes['data-src'];
      if (dataSrc != null) {
        results.add(dataSrc);
      } else {
        final src = image.attributes['src'];
        if (src == null) continue;
        results.add(src.startsWith('https:') ? src : 'https:$src');
      }
    }

    for (final video in page.querySelectorAll('source[label=HD]')) {
      final src = video.attributes['src'] ?? '';
      results.add(src.startsWith('https:') ? src : 'https:$src');
    }
    for (final video in page.querySelectorAll('source[label=SD]')) {
      final src = video.attributes['src'] ?? '';
      results.add(src.startsWith('https:') ? src : 'https:$src');
    }

    return results;
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
