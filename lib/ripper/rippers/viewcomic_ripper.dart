import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class ViewcomicRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?://view-comic\.com/([a-zA-Z1-9_-]*)/?$',
  );

  ViewcomicRipper(super.url);

  @override
  String getHost() => 'view-comic';

  String getDomain() => 'view-comic.com';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected view-comic URL format: '
      'view-comic.com/COMIC_NAME - got $url instead',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await Http.get(url);
      return '${getHost()}_${titleFromDocument(page)}';
    } catch (_) {
      return super.getAlbumTitle(url);
    }
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
      for (final image in page.querySelectorAll('div.separator > a > img'))
        image.attributes['src'] ?? '',
    ];
  }

  static String titleFromDocument(Document page) {
    final titleText = page.querySelector('title')?.text ?? '';
    return titleText
        .replaceAll('Viewcomic reading comics online for free', '')
        .replaceAll('_', '')
        .replaceAll('|', '')
        .replaceAll('…', '')
        .replaceAll('.', '')
        .trim();
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
