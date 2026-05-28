import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class HentaifoxRipper extends AbstractHTMLRipper {
  HentaifoxRipper(super.url);

  static const String domain = 'hentaifox.com';
  static final RegExp _galleryPattern =
      RegExp(r'^https://hentaifox\.com/gallery/([\d]+)/?$');

  @override
  String getHost() => 'hentaifox';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => _galleryPattern.hasMatch(url.toString());

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
    var index = 0;
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final uri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: uri,
          saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
        ),
      );
    }
    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<String> getGID(Uri url) async {
    final match = _galleryPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected hentaifox URL format: https://hentaifox.com/gallery/ID - got $url instead',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await Http.get(url);
      final title = albumTitleFromPage(page);
      if (title != null) return '${getHost()}_${title}_${await getGID(url)}';
    } catch (_) {
      // Fall back to Java's default album naming convention.
    }
    return super.getAlbumTitle(url);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static String? albumTitleFromPage(Document page) {
    final title = page.querySelector('div.info > h1')?.text.trim();
    if (title == null || title.isEmpty) return null;
    return title;
  }

  static List<String> imageUrlsFromPage(Document page) {
    return [
      for (final image in page.querySelectorAll('div.preview_thumb > a > img'))
        normalizeImageUrl(image.attributes['data-src'] ?? ''),
    ];
  }

  static String normalizeImageUrl(String src) =>
      'https:${src.replaceAll(RegExp(r't\.jpg'), '.jpg')}';

  static String fileNameForUrl(Uri uri, int index) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
