import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class Hentai2readRipper extends AbstractHTMLRipper {
  Hentai2readRipper(super.url);

  static const String domain = 'hentai2read.com';
  static const Duration pageDelay = Duration(milliseconds: 500);
  static final RegExp _rootPattern =
      RegExp(r'^https?://hentai2read\.com/([a-zA-Z0-9_-]*)/?$');
  static final RegExp _gidPattern =
      RegExp(r'^https?://hentai2read\.com/([a-zA-Z0-9_-]*)/(\d+)?/?$');

  String? _lastPage;

  @override
  String getHost() => 'hentai2read';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) =>
      _rootPattern.hasMatch(url.toString()) ||
      _gidPattern.hasMatch(url.toString());

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) => _rootPattern.hasMatch(url.toString());

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return chapterUrlsFromPage(page);
  }

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return '${match.group(1)}_${match.group(2)}';
    throw FormatException(
      'Expected hentai2read.com URL format: hentai2read.com/COMICID - got $url instead',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async =>
      '${getHost()}_${await getGID(url)}';

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

    if (pageContainsAlbums(url)) {
      for (final childUrl in await getAlbumsToQueue(page)) {
        if (isStopped) break;
        sendUpdate(RipStatus.queueAdd, childUrl);
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
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
        page = await Http.get(nextUri);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    if (pageContainsAlbums(url)) return Http.get(url);

    try {
      final page = await Http.get(url);
      final thumbnailLink = thumbnailPageUrlFromReader(page);
      if (thumbnailLink == null || thumbnailLink.isEmpty) {
        throw const HttpException('Unable to get first page');
      }
      return Http.get(Uri.parse(thumbnailLink));
    } catch (_) {
      throw const HttpException('Unable to get first page');
    }
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final href = page
        .querySelectorAll('div.bg-white > ul.pagination > li > a')
        .lastOrNull
        ?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    if (href == _lastPage) return null;
    _lastPage = href;
    await Http.delay(pageDelay);
    return Uri.parse(href);
  }

  static List<String> chapterUrlsFromPage(Document page) {
    return [
      for (final element
          in page.querySelectorAll('.nav-chapters > li > div.media > a'))
        element.attributes['href'] ?? '',
    ];
  }

  static String? thumbnailPageUrlFromReader(Document page) {
    final primary = page
        .querySelector(
            'div.col-xs-12 > div.reader-controls > div.controls-block > button > a')
        ?.attributes['href'];
    if (primary != null && primary.isNotEmpty) return primary;
    return page
        .querySelector('a[data-original-title="Thumbnails"]')
        ?.attributes['href'];
  }

  static List<String> imageUrlsFromPage(Document page) {
    return [
      for (final image in page.querySelectorAll(
          'div.block-content > div > div.img-container > a > img.img-responsive'))
        normalizeImageUrl(image.attributes['src'] ?? ''),
    ];
  }

  static String normalizeImageUrl(String src) {
    return 'https:$src'
        .replaceAll('hentaicdn.com', 'static.hentaicdn.com')
        .replaceAll('thumbnails/', '')
        .replaceAll('tmb', '');
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
