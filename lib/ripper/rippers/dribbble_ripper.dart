import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class DribbbleRipper extends AbstractHTMLRipper {
  DribbbleRipper(super.url);

  static const String domain = 'dribbble.com';
  static final RegExp _gidPattern =
      RegExp(r'^https?://[wm.]*dribbble\.com/([a-zA-Z0-9]+).*$');

  @override
  String getHost() => 'dribbble';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected dribbble.com URL format: dribbble.com/albumid - got ${url}instead',
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
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    var index = 0;
    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, downloadFileName(uri, index))),
          ),
        );
      }

      if (downloads.isEmpty) {
        sendUpdate(RipStatus.ripErrored, 'No images found at $url');
        break;
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
  Future<Uri?> getNextPage(Document page) async {
    final next = page.querySelector('a.next_page');
    if (next == null) return null;

    await Http.delay(const Duration(milliseconds: 500));
    return Uri.parse('https://www.dribbble.com${next.attributes['href']}');
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return urlsFromPage(page);
  }

  static List<String> urlsFromPage(Document page) {
    final urls = <String>[];
    for (final thumb
        in page.querySelectorAll('div.shot-thumbnail-base > figure > img')) {
      final imageUrl = largestImageUrl(thumb.attributes['data-srcset'] ?? '');
      if (imageUrl != null) urls.add(imageUrl);
    }
    return urls;
  }

  static String? largestImageUrl(String srcset) {
    var maxWidth = 0;
    String? largestUrl;

    for (final imageUrl in srcset.split(', ')) {
      final parts = imageUrl.trim().split(' ');
      if (parts.length <= 1) continue;

      final width = int.tryParse(parts[1].replaceAll('w', ''));
      if (width == null) continue;

      if (width > maxWidth) {
        maxWidth = width;
        largestUrl = parts[0];
      }
    }

    return largestUrl;
  }

  static String downloadFileName(Uri uri, int index) {
    var fileName =
        uri.toString().substring(uri.toString().lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) {
        fileName = fileName.substring(0, separatorIndex);
      }
    }
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
