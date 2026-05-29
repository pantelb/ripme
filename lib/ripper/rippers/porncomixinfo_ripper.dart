import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class PorncomixinfoRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https://porncomixinfo\.net/chapter/([a-zA-Z1-9_-]*)/([a-zA-Z1-9_-]*)/?$',
  );

  PorncomixinfoRipper(super.url);

  @override
  String getHost() => 'porncomixinfo';

  String getDomain() => 'porncomixinfo.net';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected porncomixinfo URL format: '
      'porncomixinfo.net/chapter/CHAP/ID - got $url instead',
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
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => nextPageUrl(page);

  static List<String> imageUrlsFromDocument(Document page) {
    return [
      for (final image in page.querySelectorAll('img.wp-manga-chapter-img'))
        image.attributes['src'] ?? '',
    ];
  }

  static Uri? nextPageUrl(Document page) {
    final next = page.querySelector('a.next_page');
    if (next == null) return null;
    final href = next.attributes['href'] ?? '';
    if (href.isEmpty) return null;
    return Uri.parse(href);
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
