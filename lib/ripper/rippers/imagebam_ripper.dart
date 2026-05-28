import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';

class ImagebamRipper extends AbstractHTMLRipper {
  ImagebamRipper(super.url);

  static final RegExp _gidPattern = RegExp(
    r'^https?://[wm.]*imagebam\.com/(gallery|view)/([a-zA-Z0-9]+).*$',
  );

  @override
  String getHost() => 'imagebam';

  String getDomain() => 'imagebam.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected imagebam gallery format: '
      'http://www.imagebam.com/gallery/galleryid Got: $url',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await Http.get(url);
      final title = albumTitleFromDocument(page);
      if (title != null) return '${getHost()}_${await getGID(url)} ($title)';
    } catch (_) {
      // Java falls back to the default album naming convention.
    }
    return super.getAlbumTitle(url);
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
      for (final imagePageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        final directImageUrl = await directImageUrlFromPageUrl(
          Uri.parse(imagePageUrl),
        );
        if (directImageUrl == null) continue;

        final imageUri = Uri.parse(directImageUrl);
        await downloadFile(
          imageUri,
          File(
            p.join(
              workingDir.path,
              fileNameForUrl(imageUri, prefix: prefixForIndex(index)),
            ),
          ),
        );
        await Http.delay(const Duration(milliseconds: 500));
      }

      if (isStopped) break;
      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        await Http.delay(const Duration(milliseconds: 500));
        page = await Http.get(nextUri);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final hrefs = page.querySelectorAll(
      'a.pagination_current + a.pagination_link',
    );
    if (hrefs.isEmpty) return null;

    return Uri.parse(
        'http://www.imagebam.com${hrefs.first.attributes['href']}');
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imagePageUrlsFromDocument(page);
  }

  static List<String> imagePageUrlsFromDocument(Document page) {
    return [
      for (final thumb
          in page.querySelectorAll('div > a.thumbnail:not(.footera)'))
        if ((thumb.attributes['href'] ?? '').isNotEmpty)
          thumb.attributes['href']!,
    ];
  }

  static String? directImageUrlFromDocument(Document page) {
    final source =
        page.querySelector('img[class*="main-image"]')?.attributes['src'];
    if (source == null || source.isEmpty) return null;
    return normalizeImageUrl(source);
  }

  static Future<String?> directImageUrlFromPageUrl(Uri imagePageUrl) async {
    final page = await Http.get(
      imagePageUrl,
      cookies: const {'nsfw_inter': '1'},
    );
    return directImageUrlFromDocument(page);
  }

  static String? albumTitleFromDocument(Document page) {
    final title = page.querySelector('[id="gallery-name"]')?.text.trim();
    if (title == null || title.isEmpty) return null;
    return title;
  }

  static String normalizeImageUrl(String source) {
    if (source.startsWith('//')) return 'https:$source';
    return source;
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
