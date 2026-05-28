import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class HentaiimageRipper extends AbstractHTMLRipper {
  HentaiimageRipper(super.url);

  static final RegExp _gidPattern = RegExp(
    r'^https://(?:\w\w\.)?hentai-(image|comic|img-xxx)\.com/image/([a-zA-Z0-9_-]+)/?$',
  );

  @override
  String getHost() => url.host;

  String getDomain() => url.host;

  @override
  bool canRip(Uri url) {
    try {
      _gidFor(url);
      return true;
    } on FormatException {
      return false;
    }
  }

  @override
  Future<String> getGID(Uri url) async => _gidFor(url);

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
    return imageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    return nextPageFromDocument(page, getDomain());
  }

  static String _gidFor(Uri url) {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected hitomi URL format: https://hentai-img-xxx.com/image/ID - got $url instead',
    );
  }

  static List<String> imageUrlsFromPage(Document page) {
    return [
      for (final image in page.querySelectorAll('div.icon-overlay > a > img'))
        image.attributes['src'] ?? '',
    ];
  }

  static Uri? nextPageFromDocument(Document page, String domain) {
    for (final span in page.querySelectorAll('div#paginator > span')) {
      final anchor = span.querySelector('a');
      if (anchor == null) continue;
      if (anchor.text != 'next>') continue;
      return Uri.parse('https://$domain${anchor.attributes['href'] ?? ''}');
    }
    return null;
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
