import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class ErofusRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https://www\.erofus\.com/comics/([a-zA-Z0-9\-_]+).*$',
  );

  ErofusRipper(super.url);

  @override
  String getHost() => 'erofus';

  String getDomain() => 'erofus.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected URL format: http://www.8muses.com/index/category/albumname, got: $url',
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

    final downloads = await downloadsFromPage(page);
    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<List<RipperDownload>> downloadsFromPage(
    Document page, {
    Future<Document> Function(Uri uri)? pageFetcher,
  }) async {
    return _downloadsFromPage(page, pageFetcher: pageFetcher);
  }

  Future<List<RipperDownload>> _downloadsFromPage(
    Document page, {
    Future<Document> Function(Uri uri)? pageFetcher,
  }) async {
    if (pageContainsImages(page)) {
      return albumDownloadsFromPage(page, workingDir.path);
    }

    final downloads = <RipperDownload>[];
    for (final subUrl in subalbumUrlsFromDocument(page)) {
      if (isStopped) break;
      try {
        sendUpdate(RipStatus.loadingResource, subUrl);
        final subPage = pageFetcher == null
            ? await Http.get(Uri.parse(subUrl))
            : await pageFetcher(Uri.parse(subUrl));
        downloads.addAll(
          await _downloadsFromPage(subPage, pageFetcher: pageFetcher),
        );
      } catch (e) {
        sendUpdate(RipStatus.downloadWarn, 'Error loading $subUrl: $e');
      }
    }
    return downloads;
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    if (!pageContainsImages(page)) return const [];
    return imageUrlsFromAlbumPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  List<RipperDownload> albumDownloadsFromPage(
    Document page,
    String workingDirectory,
  ) {
    final subdirectory =
        subdirectoryFromTitle(page.querySelector('title')?.text ?? '');
    final downloads = <RipperDownload>[];
    final imageUrls = imageUrlsFromAlbumPage(page);

    for (var index = 0; index < imageUrls.length; index++) {
      final uri = Uri.parse(imageUrls[index]);
      downloads.add(
        RipperDownload(
          url: uri,
          saveAs: File(
            p.join(
              workingDirectory,
              Utils.filesystemSafe(subdirectory),
              fileNameForUrl(uri, index + 1),
            ),
          ),
        ),
      );
    }
    return downloads;
  }

  static bool pageContainsImages(Document page) {
    return page
        .querySelectorAll('a.a-click')
        .any((link) => (link.attributes['href'] ?? '').contains('/pic/'));
  }

  static List<String> subalbumUrlsFromDocument(Document page) {
    return [
      for (final link in page.querySelectorAll('a.a-click'))
        if ((link.attributes['href'] ?? '').contains('comics'))
          'https://erofus.com${link.attributes['href'] ?? ''}',
    ];
  }

  static List<String> imageUrlsFromAlbumPage(Document page) {
    return [
      for (final thumb
          in page.querySelectorAll('a.a-click > div.thumbnail > img'))
        'https://www.erofus.com${(thumb.attributes['src'] ?? '').replaceAll('thumb', 'medium')}',
    ];
  }

  static String subdirectoryFromTitle(String title) {
    return title
        .replaceAll(' | Erofus - Sex and Porn Comics', '')
        .replaceAll(' ', '_');
  }

  static String fileNameForUrl(Uri uri, int index) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('${prefix(index)}$fileName');
  }

  static String prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
