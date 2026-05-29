import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class RulePornRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(r'^https://.*ruleporn\.com/(.*)/$');

  RulePornRipper(super.url);

  @override
  String getHost() => 'ruleporn';

  String getDomain() => 'ruleporn.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected ruleporn.com URL format: '
      'ruleporn.com/NAME - got $url instead',
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
              fileNameForUrl(videoUri, prefix: prefixForIndex(index)),
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
    return videoUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> videoUrlsFromDocument(Document page) {
    final source = page.querySelector('source[type="video/mp4"]');
    return [source?.attributes['src'] ?? ''];
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
