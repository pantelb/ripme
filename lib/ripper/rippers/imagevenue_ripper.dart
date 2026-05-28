import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';

class ImagevenueRipper extends AbstractHTMLRipper {
  ImagevenueRipper(super.url);

  static final RegExp _gidPattern = RegExp(
    r'^https?://.*imagevenue\.com/galshow\.php\?gal=([a-zA-Z0-9\-_]+).*$',
  );

  @override
  String getHost() => 'imagevenue';

  String getDomain() => 'imagevenue.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected imagevenue gallery format: '
      'http://...imagevenue.com/galshow.php?gal=gallery_.... Got: $url',
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
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imagePageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> imagePageUrlsFromDocument(Document page) {
    return [
      for (final thumb in page.querySelectorAll('a[target="_blank"]'))
        if ((thumb.attributes['href'] ?? '').isNotEmpty)
          thumb.attributes['href']!,
    ];
  }

  static String? directImageUrlFromDocument(Document page, Uri imagePageUrl) {
    final source = page.querySelector('a > img')?.attributes['src'];
    if (source == null || source.isEmpty) return null;
    return 'http://${imagePageUrl.host}/$source';
  }

  static Future<String?> directImageUrlFromPageUrl(Uri imagePageUrl) async {
    final page = await Http.get(imagePageUrl);
    return directImageUrlFromDocument(page, imagePageUrl);
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
