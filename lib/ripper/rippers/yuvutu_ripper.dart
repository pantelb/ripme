import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class YuvutuRipper extends AbstractHTMLRipper {
  static final RegExp _urlPattern = RegExp(
    r'^http://www\.yuvutu\.com/modules\.php\?name=YuGallery&action=view&set_id=([0-9]+)$',
  );

  YuvutuRipper(super.url);

  @override
  String getHost() => 'yuvutu';

  String getDomain() => 'yuvutu.com';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _urlPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected yuvutu.com URL format: '
      'yuvutu.com/modules.php?name=YuGallery&action=view&set_id=albumid '
      '- got ${url}instead',
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
              p.join(
                workingDir.path,
                fileNameForUrl(imageUri, prefix: prefix(index)),
              ),
            ),
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
      for (final thumb in page.querySelectorAll('div#galleria > a > img'))
        thumb.attributes['src'] ?? '',
    ];
  }

  static String prefix(int index) => '${index.toString().padLeft(3, '0')}_';

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
