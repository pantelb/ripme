import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class PichunterRipper extends AbstractHTMLRipper {
  static final RegExp _listingGidPattern = RegExp(
    r'^https?://www\.pichunter\.com/(|tags|models|sites)/(\S*)/?$',
  );
  static final RegExp _photosGidPattern = RegExp(
    r'^https?://www\.pichunter\.com/(tags|models|sites)/(\S*)/photos/\d+/?$',
  );
  static final RegExp _tagPageGidPattern = RegExp(
    r'^https?://www\.pichunter\.com/tags/all/(\S*)/\d+/?$',
  );
  static final RegExp _galleryGidPattern = RegExp(
    r'^https?://www\.pichunter\.com/gallery/\d+/(\S*)/?$',
  );

  PichunterRipper(super.url);

  @override
  String getHost() => 'pichunter';

  String getDomain() => 'pichunter.com';

  @override
  bool canRip(Uri url) {
    final text = url.toString();
    return _listingGidPattern.hasMatch(text) ||
        _photosGidPattern.hasMatch(text) ||
        _tagPageGidPattern.hasMatch(text) ||
        _galleryGidPattern.hasMatch(text);
  }

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    var match = _listingGidPattern.firstMatch(text);
    if (match != null) return match.group(2)!;

    match = _photosGidPattern.firstMatch(text);
    if (match != null) return match.group(2)!;

    match = _tagPageGidPattern.firstMatch(text);
    if (match != null) return match.group(1)!;

    match = _galleryGidPattern.firstMatch(text);
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected pichunter URL format: '
      'pichunter.com/(tags|models|sites)/Name/ - got $url instead',
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
  Future<Uri?> getNextPage(Document page) async => nextPageUrl(page);

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page, isPhotoSet: isPhotoSet(url));
  }

  static bool isPhotoSet(Uri url) =>
      _galleryGidPattern.hasMatch(url.toString());

  static Uri? nextPageUrl(Document page) {
    final arrows = page.querySelectorAll('div.paperSpacings > ul > li.arrow');
    if (arrows.isEmpty) return null;

    final href = arrows.last.querySelector('a')?.attributes['href'] ?? '';
    return Uri.parse('http://www.pichunter.com$href');
  }

  static List<String> imageUrlsFromDocument(
    Document page, {
    required bool isPhotoSet,
  }) {
    final selector = isPhotoSet
        ? 'div.flex-images > figure > a.item > img'
        : 'div.thumbtable > a.thumb > img';

    return [
      for (final image in page.querySelectorAll(selector))
        (image.attributes['src'] ?? '').replaceAll('_i', '_o'),
    ];
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${prefix(index)}$fileName');
  }

  static String prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
