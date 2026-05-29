import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class VidbleRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern =
      RegExp(r'^.*vidble\.com/album/([a-zA-Z0-9_\-]+).*$');
  static final RegExp _thumbnailMarkerPattern = RegExp(r'_[a-zA-Z]{3,5}');

  VidbleRipper(super.url);

  @override
  String getHost() => 'vidble';

  String getDomain() => 'vidble.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected vidble.com album format: '
      'vidble.com/album/#### Got: $url',
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
    return imageUrlsFromDocument(page, url);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> imageUrlsFromDocument(Document page, Uri pageUrl) {
    final imageUrls = <String>[];
    final containers = page.querySelectorAll('#ContentPlaceHolder1_divContent');
    for (final img in containers.expand((element) => element.querySelectorAll(
          'img',
        ))) {
      final src = img.attributes['src'];
      if (src == null || src.isEmpty) continue;
      final resolved = pageUrl.resolve(src).toString();
      final image = resolved.replaceAll(_thumbnailMarkerPattern, '');
      if (image.isNotEmpty) imageUrls.add(image);
    }
    return imageUrls;
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
