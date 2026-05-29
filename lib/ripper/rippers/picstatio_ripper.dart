import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class PicstatioRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?://www\.picstatio\.com/([a-zA-Z1-9_-]*)/?$',
  );

  PicstatioRipper(
    super.url, {
    Future<Document> Function(Uri uri)? downloadPageFetcher,
  }) : _downloadPageFetcher = downloadPageFetcher ?? Http.get;

  final Future<Document> Function(Uri uri) _downloadPageFetcher;

  @override
  String getHost() => 'picstatio';

  String getDomain() => 'picstatio.com';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected picstatio URL format: www.picstatio.com//ID - got $url instead',
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

    var index = 0;
    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        if (imageUrl.isEmpty) continue;
        index++;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForUrl(imageUri, prefix: prefixForIndex(index)),
              ),
            ),
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

  @override
  Future<Uri?> getNextPage(Document page) async => nextPageUrl(page);

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final result = <String>[];
    for (final slug in wallpaperSlugsFromDocument(page)) {
      final imageUrl = await fullSizedImageFromFileName(
        slug,
        pageFetcher: _downloadPageFetcher,
      );
      if (imageUrl != null) result.add(imageUrl);
    }
    return result;
  }

  static List<String> wallpaperSlugsFromDocument(Document page) {
    final result = <String>[];
    for (final image in page.querySelectorAll('img.img')) {
      final href = image.parent?.attributes['href'] ?? '';
      final slug = wallpaperSlugFromHref(href);
      if (slug != null) result.add(slug);
    }
    return result;
  }

  static String? wallpaperSlugFromHref(String href) {
    final parts = href.split('/');
    if (parts.length <= 2) return null;
    return parts[2];
  }

  static Uri downloadPageUrlForFileName(String fileName) {
    return Uri.parse(
      'https://www.picstatio.com/wallpaper/$fileName/download',
    );
  }

  static Future<String?> fullSizedImageFromFileName(
    String fileName, {
    Future<Document> Function(Uri uri)? pageFetcher,
  }) async {
    try {
      final page = await (pageFetcher ?? Http.get)(
        downloadPageUrlForFileName(fileName),
      );
      return fullSizedImageFromDocument(page);
    } catch (_) {
      return null;
    }
  }

  static String fullSizedImageFromDocument(Document page) {
    return page.querySelector('p.text-center > span > a')?.attributes['href'] ??
        '';
  }

  static Uri nextPageUrl(Document page) {
    final href = page.querySelector('a.next_page')?.attributes['href'] ?? '';
    return Uri.parse('https://www.picstatio.com$href');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
