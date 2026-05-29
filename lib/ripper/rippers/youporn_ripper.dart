import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class YoupornRipper extends AbstractHTMLRipper {
  static final RegExp _urlPattern =
      RegExp(r'^https?://[wm.]*youporn\.com/watch/[0-9]+.*$');
  static final RegExp _gidPattern =
      RegExp(r'^https?://[wm.]*youporn\.com/watch/([0-9]+).*$');

  YoupornRipper(super.url);

  @override
  String getHost() => 'youporn';

  String getDomain() => 'youporn.com';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected youporn format:youporn.com/watch/#### Got: $url',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    try {
      final page = await Http.get(url);
      final downloads = <RipperDownload>[];
      var index = 0;
      for (final videoUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        final videoUri = Uri.parse(videoUrl);
        downloads.add(
          RipperDownload(
            url: videoUri,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForUrl(videoUri, prefix: prefix(index)),
              ),
            ),
          ),
        );
      }
      await downloadFiles(downloads);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return videoUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> videoUrlsFromDocument(Document page) {
    final videos = page.querySelectorAll('video');
    return [videos.first.attributes['src'] ?? ''];
  }

  static String prefix(int index) => '${index.toString().padLeft(3, '0')}_';

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
