import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class PornhubRipper extends AbstractHTMLRipper {
  static const String domain = 'pornhub.com';
  static const int imageSleepMilliseconds = 1000;
  static final RegExp _gidPattern =
      RegExp(r'^.*pornhub\.com/album/([0-9]+).*$');

  PornhubRipper(Uri url) : super(sanitizeUrl(url));

  @override
  String getHost() => 'Pornhub';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) =>
      url.host.toLowerCase().endsWith(domain) && url.path.startsWith('/album');

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected pornhub.com album format: '
      'http://www.pornhub.com/album/#### Got: $url',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await Http.get(url, headers: referrerHeaders(url));
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    while (!isStopped) {
      for (final imagePageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        await _queueImageFromPage(Uri.parse(imagePageUrl), index);
        if (!isStopped) {
          await Http.delay(
            const Duration(milliseconds: imageSleepMilliseconds),
          );
        }
      }

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

  Future<void> _queueImageFromPage(Uri imagePageUrl, int index) async {
    try {
      final imagePage = await Http.get(
        imagePageUrl,
        headers: referrerHeaders(imagePageUrl),
      );
      final imageUrl = directImageUrlFromDocument(imagePage, imagePageUrl);
      if (imageUrl == null) return;
      await downloadFiles([
        RipperDownload(
          url: imageUrl,
          saveAs: File(
            p.join(
              workingDir.path,
              fileNameForUrl(imageUrl, prefix: prefixForIndex(index)),
            ),
          ),
        ),
      ]);
    } catch (_) {
      return;
    }
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imagePageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => nextPageUrl(page, url);

  static Uri sanitizeUrl(Uri url) {
    final external = url.toString();
    final queryStart = external.indexOf('?');
    if (queryStart < 0) return url;
    return Uri.parse(external.substring(0, queryStart));
  }

  static List<String> imagePageUrlsFromDocument(Document page) {
    final pageUrls = <String>[];
    for (final thumb in page.querySelectorAll('.photoBlockBox li')) {
      final anchor = thumb.querySelector('.photoAlbumListBlock > a');
      if (anchor == null) continue;
      final imagePage = anchor.attributes['href'] ?? '';
      pageUrls.add('https://pornhub.com$imagePage');
    }
    return pageUrls;
  }

  static Uri? nextPageUrl(Document page, Uri albumUrl) {
    final nextPageLink = page.querySelector('li.page_next > a');
    if (nextPageLink == null) return null;
    return albumUrl.resolve(nextPageLink.attributes['href'] ?? '');
  }

  static Uri? directImageUrlFromDocument(Document page, Uri imagePageUrl) {
    final image = page.querySelector('#photoImageSection img');
    final source = image?.attributes['src'] ?? '';
    if (source.isEmpty) return null;
    return imagePageUrl.resolve(source);
  }

  static Map<String, String> referrerHeaders(Uri pageUrl) {
    return {'Referer': pageUrl.toString()};
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
