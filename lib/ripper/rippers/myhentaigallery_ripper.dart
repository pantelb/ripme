import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class MyhentaigalleryRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https://myhentaigallery\.com/gallery/thumbnails/([0-9]+)/?$',
  );

  MyhentaigalleryRipper(super.url);

  @override
  String getHost() => 'myhentaigallery';

  String getDomain() => 'myhentaigallery.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected myhentaigallery.com URL format: '
      'myhentaigallery.com/gallery/thumbnails/ID - got $url instead',
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
    final result = <String>[];
    for (final image in page.querySelectorAll('.comic-thumb > img')) {
      final imageSource = image.attributes['src'] ?? '';
      result.add(imageSource.replaceAll('thumbnail', 'original'));
    }
    return result;
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    var fileName = uri.toString();
    if (fileName.endsWith('/')) {
      fileName = fileName.substring(0, fileName.length - 1);
    }
    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
    final question = fileName.indexOf('?');
    if (question >= 0) fileName = fileName.substring(0, question);
    final hash = fileName.indexOf('#');
    if (hash >= 0) fileName = fileName.substring(0, hash);
    final ampersand = fileName.indexOf('&');
    if (ampersand >= 0) fileName = fileName.substring(0, ampersand);
    if (fileName.isEmpty) fileName = 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
