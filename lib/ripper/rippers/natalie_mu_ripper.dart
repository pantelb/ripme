import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class NatalieMuRipper extends AbstractHTMLRipper {
  static final RegExp _newsIdPattern = RegExp(r'/news_id/([0-9]+)/');
  static final RegExp _newsPattern = RegExp(r'/news/([0-9]+)/?');
  static final RegExp _thumbnailStylePattern = RegExp(
    r'background-image: url\((.*list_thumb_inbox.*)\);',
    caseSensitive: false,
  );

  NatalieMuRipper(super.url);

  @override
  String getHost() {
    var host = url.host;
    host = host.substring(0, host.lastIndexOf('.'));
    if (host.contains('.')) {
      host = host.substring(host.lastIndexOf('.') + 1);
    }
    final board = url.toString().split('/')[3];
    return '${host}_$board';
  }

  String getDomain() => url.host;

  @override
  bool canRip(Uri url) {
    final external = url.toString();
    return external.contains('natalie.mu') &&
        (external.contains('/news_id/') || external.contains('/news/'));
  }

  @override
  Future<String> getGID(Uri url) async {
    final external = url.toString();
    if (external.contains('/news_id/')) {
      final match = _newsIdPattern.firstMatch(external);
      if (match != null) return match.group(1)!;
    } else if (external.contains('/news/')) {
      final match = _newsPattern.firstMatch(external);
      if (match != null) return match.group(1)!;
    }

    throw FormatException(
      'Expected natalie.mu URL formats: '
      'http://natalie.mu/music/news/xxxxxx or '
      'http://natalie.mu/music/gallery/show/news_id/xxxxxx/image_id/yyyyyy '
      'Got: $external',
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
          headers: downloadHeadersForPage(url),
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
    for (final span in page.querySelectorAll('.NA_articleGallery span')) {
      if (!span.attributes.containsKey('style')) continue;
      final style = span.attributes['style']!.trim();
      final match = _thumbnailStylePattern.firstMatch(style);
      if (match == null) continue;

      var imageUrl = match.group(1)!;
      if (imageUrl.startsWith('//')) {
        imageUrl = 'http:$imageUrl';
      }
      if (imageUrl.startsWith('/')) {
        imageUrl = 'http://${pageUrl.host}$imageUrl';
      }
      imageUrl = imageUrl.replaceAll('list_thumb_inbox', 'xlarge');
      if (imageUrls.contains(imageUrl)) continue;
      imageUrls.add(imageUrl);
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

  static Map<String, String> downloadHeadersForPage(Uri pageUrl) {
    return {'Referer': pageUrl.toString()};
  }
}
