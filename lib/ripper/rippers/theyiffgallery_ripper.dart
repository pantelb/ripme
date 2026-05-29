import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class TheyiffgalleryRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?://theyiffgallery\.com/index\?/category/(\d+)$',
  );
  static final RegExp _thumbnailSuffixPattern = RegExp(r'-\w\w_\w\d+x\d+');

  TheyiffgalleryRipper(super.url);

  @override
  String getHost() => 'theyiffgallery';

  String getDomain() => 'theyiffgallery.com';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected theyiffgallery URL format: '
      'theyiffgallery.com/index?/category/#### - got $url instead',
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
        index++;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(workingDir.path, fileNameForUrl(imageUri, index)),
            ),
          ),
        );
      }

      await downloadFiles(downloads);
      if (isStopped) break;

      final nextPage = await getNextPage(page);
      if (nextPage == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextPage.toString());
        page = await Http.get(nextPage);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async =>
      imageUrlsFromDocument(page);

  @override
  Future<Uri?> getNextPage(Document page) async => nextPageFromDocument(page);

  static List<String> imageUrlsFromDocument(Document page) {
    return [
      for (final thumbnail in page.querySelectorAll('img.thumbnail'))
        'https://theyiffgallery.com${fullImagePath(thumbnail.attributes['src'] ?? '')}',
    ];
  }

  static String fullImagePath(String imageSource) {
    return imageSource
        .replaceAll('_data/i', '')
        .replaceAll(_thumbnailSuffixPattern, '');
  }

  static Uri? nextPageFromDocument(Document page) {
    final nextPage =
        page.querySelector('span.navPrevNext > a')?.attributes['href'];
    if (nextPage != null &&
        nextPage.isNotEmpty &&
        nextPage.contains('start-')) {
      return Uri.parse('https://theyiffgallery.com/$nextPage');
    }
    return null;
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
