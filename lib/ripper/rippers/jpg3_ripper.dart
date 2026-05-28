import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class Jpg3Ripper extends AbstractHTMLRipper {
  Jpg3Ripper(Uri url) : super(sanitizeUrl(url));

  @override
  String getHost() => 'jpg3';

  String getDomain() => 'jpg3.su';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final parts = url.toString().split('/')..removeWhere((part) => part == '');
    return parts.isNotEmpty ? parts.last : '';
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
              p.join(
                workingDir.path,
                fileNameForUrl(imageUri, prefix: prefixForIndex(index)),
              ),
            ),
            headers: {'Referer': url.toString()},
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
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final href =
        page.querySelector('[data-pagination="next"]')?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return Uri.parse(href);
  }

  static Uri sanitizeUrl(Uri url) {
    final sanitized = url.toString().replaceAllMapped(
          RegExp(r'https?://jpg3\.su/a/([^/]+)/?.*'),
          (match) => 'https://jpg3.su/a/${match.group(1)}',
        );
    return Uri.parse(sanitized);
  }

  static List<String> imageUrlsFromDocument(Document page) {
    return [
      for (final image in page.querySelectorAll('.image-container > img'))
        (image.attributes['src'] ?? '').replaceAll(RegExp(r'\.md'), ''),
    ];
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
