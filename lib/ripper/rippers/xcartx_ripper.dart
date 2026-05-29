import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class XcartxRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern =
      RegExp(r'^https?://xcartx.com/([a-zA-Z0-9_\-]+).html$');

  XcartxRipper(super.url);

  @override
  String getHost() => 'xcartx';

  String getDomain() => 'xcartx.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected URL format: http://xcartx.com/comic, got: $url',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      final page = await Http.get(url);
      final downloads = <RipperDownload>[];
      var index = 0;
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
            headers: {'Referer': url.toString()},
          ),
        );
      }
      await downloadFiles(downloads);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> imageUrlsFromDocument(Document page) {
    return [
      for (final image in page.querySelectorAll('div.f-desc img'))
        'https://xcartx.com${image.attributes['data-src'] ?? ''}',
    ];
  }

  static String fileNameForUrl(Uri uri, int index) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('${prefixForIndex(index)}$fileName');
  }

  static String prefixForIndex(int index) {
    return '${index.toString().padLeft(3, '0')}_';
  }
}
