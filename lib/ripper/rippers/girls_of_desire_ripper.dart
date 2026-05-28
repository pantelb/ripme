import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class GirlsOfDesireRipper extends AbstractHTMLRipper {
  GirlsOfDesireRipper(super.url);

  static const String domain = 'girlsofdesire.org';
  static final RegExp _galleryPattern =
      RegExp(r'^(?:https?://)?www\.girlsofdesire\.org/galleries/([\w\d-]+)/$');

  @override
  String getHost() => 'GirlsOfDesire';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => _galleryPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _galleryPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected girlsofdesire.org gallery format: http://www.girlsofdesire.org/galleries/<name>/ Got: $url',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await Http.get(url);
      final title = albumTitleFromPage(page);
      if (title != null) return '${getHost()}_$title';
    } catch (_) {
      // Fall back to Java's default album naming convention.
    }
    return super.getAlbumTitle(url);
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
    var index = 0;
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final uri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: uri,
          saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
          headers: {'Referer': url.toString()},
        ),
      );
    }
    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static String? albumTitleFromPage(Document page) {
    final text = page.querySelector('.albumName')?.text.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static List<String> imageUrlsFromPage(Document page) {
    return [
      for (final thumb in page.querySelectorAll('td.vtop > a > img'))
        normalizeImageUrl(thumb.attributes['src'] ?? ''),
    ];
  }

  static String normalizeImageUrl(String src) {
    var image = src.replaceAll(RegExp(r'_thumb\.'), '.');
    if (image.startsWith('/')) {
      image = 'http://www.girlsofdesire.org$image';
    }
    return image;
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
