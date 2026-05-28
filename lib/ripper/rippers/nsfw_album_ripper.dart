import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class NsfwAlbumRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern =
      RegExp(r'(?!https:\/\/nsfwalbum\.com\/album\/)\d+');

  NsfwAlbumRipper(super.url);

  @override
  String getHost() => 'nsfwalbum';

  String getDomain() => 'nsfwalbum.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(0)!;
    throw FormatException(
      'Expected nsfwalbum.com URL format nsfwalbum.com/album/albumid '
      '- got $url instead.',
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
    for (final imageUrl in imageUrlsFromDocument(page)) {
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
    final results = <String>[];
    for (final img in page.querySelectorAll('.album img')) {
      final thumbURL = img.attributes['data-src'] ?? '';
      final fullResURL = fullResolutionUrl(thumbURL);
      if (fullResURL != null) results.add(fullResURL);
    }
    return results;
  }

  static String? fullResolutionUrl(String thumbURL) {
    if (thumbURL.contains('imgspice.com')) {
      return thumbURL.replaceAll('_t.jpg', '.jpg');
    }
    if (thumbURL.contains('imagetwist.com')) {
      return thumbURL.replaceAll('/th/', '/i/');
    }
    if (thumbURL.contains('pixhost.com')) {
      return thumbURL
          .replaceAll('https://t', 'https://img')
          .replaceAll('/thumbs/', '/images/');
    }
    if (thumbURL.contains('imx.to')) {
      return thumbURL.replaceAll('/t/', '/i/');
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
