import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class JagodibujaRipper extends AbstractHTMLRipper {
  JagodibujaRipper(super.url);

  static final RegExp _gidPattern =
      RegExp(r'^https?://www\.jagodibuja\.com/([a-zA-Z0-9_-]*)/?$');

  @override
  String getHost() => 'jagodibuja';

  String getDomain() => 'jagodibuja.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected jagodibuja.com gallery format: '
      'www.jagodibuja.com/Comic-name/ - got $url instead',
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

    final downloads = <RipperDownload>[];
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      try {
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(workingDir.path, fileNameForUrl(imageUri)),
            ),
          ),
        );
      } on FormatException {
        // Java logs malformed URLs after parsing but continues the gallery.
      }
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final result = <String>[];
    for (final comicPageUrl in comicPageUrlsFromDocument(page)) {
      if (isStopped) return result;
      try {
        await Http.delay(const Duration(milliseconds: 500));
        final comicPage = await Http.get(Uri.parse(comicPageUrl));
        result.add(fullSizeHrefFromDocument(comicPage));
      } catch (_) {
        // Java skips comic pages that fail while loading.
      }
    }
    return result;
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> comicPageUrlsFromDocument(Document page) {
    return [
      for (final link in page.querySelectorAll('div.gallery-icon > a'))
        link.attributes['href'] ?? '',
    ];
  }

  static String fullSizeHrefFromDocument(Document page) {
    final href =
        page.querySelector('span.full-size-link > a')?.attributes['href'];
    if (href == null) {
      throw StateError('Missing span.full-size-link > a href');
    }
    return href;
  }

  static String fileNameForUrl(Uri uri) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs(fileName);
  }
}
