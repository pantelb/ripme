import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';

class FitnakedgirlsRipper extends AbstractHTMLRipper {
  FitnakedgirlsRipper(super.url);

  static const Duration downloadDelay = Duration(seconds: 1);
  static final RegExp _galleryPattern =
      RegExp(r'^https?://(\w+\.)?fitnakedgirls\.com/photos/gallery/(.+)$');

  @override
  String getHost() => 'fitnakedgirls';

  String getDomain() => 'fitnakedgirls.com';

  @override
  bool canRip(Uri url) => _galleryPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _galleryPattern.firstMatch(url.toString());
    if (match != null) return match.group(2)!;
    throw FormatException(
      'Expected fitnakedgirls.com gallery format: fitnakedgirls.com/gallery/#### Got: $url',
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
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      await Http.delay(downloadDelay);
      final uri = Uri.parse(imageUrl);
      await downloadFile(
        uri,
        File(p.join(workingDir.path, fileNameForUrl(uri, index))),
        headers: {'Referer': url.toString()},
      );
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> imageUrlsFromPage(Document page) {
    final urls = <String>[];
    for (final image in page.querySelectorAll('.entry-inner img')) {
      var src = image.attributes['data-src'] ?? '';
      if (src.trim().isEmpty) {
        src = image.attributes['src'] ?? '';
        if (src.trim().isEmpty) continue;
      }
      urls.add(src);
    }
    return urls;
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
