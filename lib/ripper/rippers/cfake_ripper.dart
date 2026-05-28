import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class CfakeRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?://cfake\.com/images/celebrity/([a-zA-Z1-9_-]*)/\d+/?$',
  );

  CfakeRipper(super.url);

  @override
  String getHost() => 'cfake';

  String getDomain() => 'cfake.com';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected cfake URL format: cfake.com/images/celebrity/MODEL/ID - got $url instead',
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
  Future<Uri?> getNextPage(Document page) async {
    final pageNavs = page.querySelectorAll(
      'div#wrapper_path div#content_path div#num_page',
    );
    if (pageNavs.isEmpty) return null;

    final nextAnchor = pageNavs.last.querySelector('a');
    if (nextAnchor == null) return null;

    if (nextAnchor.querySelectorAll('span').isEmpty) return null;

    final nextPage = nextAnchor.attributes['href'] ?? '';
    if (nextPage.isEmpty) return null;

    return Uri.parse('https://cfake.com$nextPage');
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  static List<String> imageUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final image in page.querySelectorAll(
      'div#media_content .responsive .gallery > a img',
    )) {
      final source = image.attributes['src'];
      if (source == null || source.isEmpty) continue;
      result.add(photoUrlFromThumbnail(source).toString());
    }
    return result;
  }

  static Uri photoUrlFromThumbnail(String source) {
    return Uri.parse(
      'https://cfake.com${source.replaceAll('thumbs', 'photos')}',
    );
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
