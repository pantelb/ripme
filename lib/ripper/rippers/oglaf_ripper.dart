import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_ripper.dart';
import '../abstract_html_ripper.dart';

class OglafRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^http://oglaf\.com/([a-zA-Z1-9_-]*)/?$',
  );

  OglafRipper(super.url);

  @override
  String getHost() => 'oglaf';

  String getDomain() => 'oglaf.com';

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected oglaf URL format: oglaf.com/NAME - got $url instead',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async => getDomain();

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
    while (true) {
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(workingDir.path, downloadFileName(imageUri, index)),
            ),
          ),
        );
      }

      await downloadFiles(downloads);
      if (isStopped) break;

      final next = await getNextPage(page);
      if (next == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, next.toString());
        page = await Http.get(next);
      } catch (e) {
        break;
      }
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return stripImageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final next = nextPageUrlFromPage(page);
    if (next == null) return null;

    await Future<void>.delayed(const Duration(seconds: 1));
    return next;
  }

  static List<String> stripImageUrlsFromPage(Document page) {
    return [
      for (final image in page.querySelectorAll('b > img#strip'))
        image.attributes['src'] ?? '',
    ];
  }

  static Uri? nextPageUrlFromPage(Document page) {
    final nextDiv = page.querySelector('div#nav > a > div#nx');
    final href = nextDiv?.parent?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return Uri.parse('http://oglaf.com$href');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String downloadFileName(Uri uri, int index) {
    final path = uri.toString().split(RegExp(r'[?#]')).first;
    final fileName =
        path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : 'file';
    return Utils.sanitizeSaveAs('${prefixForIndex(index)}$fileName');
  }
}
