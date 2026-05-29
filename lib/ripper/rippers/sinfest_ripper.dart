import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class SinfestRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?://sinfest\.net/view\.php\?date=([0-9-]*)/?$',
  );

  SinfestRipper(super.url);

  @override
  String getHost() => 'sinfest';

  String getDomain() => 'sinfest.net';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected sinfest URL format: '
      'sinfest.net/view.php?date=XXXX-XX-XX/ - got $url instead',
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

      Uri? nextUri;
      try {
        nextUri = await getNextPage(page);
      } catch (_) {
        break;
      }
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
  Future<Uri?> getNextPage(Document page) async {
    return nextPageUrlFromDocument(page);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  static Uri? nextPageUrlFromDocument(Document page) {
    final elem = page.querySelectorAll('td.style5 > a > img').last;
    final nextPage = elem.parent?.attributes['href'] ?? '';
    if (nextPage == 'view.php?date=') {
      throw const HttpException('No more pages');
    }
    if (nextPage.isEmpty) return null;
    return Uri.parse('http://sinfest.net/$nextPage');
  }

  static List<String> imageUrlsFromDocument(Document page) {
    final elem = page.querySelectorAll('tbody > tr > td > img').last;
    return ['http://sinfest.net/${elem.attributes['src'] ?? ''}'];
  }

  static String fileNameForUrl(Uri uri, int index) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    final prefix = Utils.getConfigBoolean('download.save_order', true)
        ? '${index.toString().padLeft(3, '0')}_'
        : '';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
