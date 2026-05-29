import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class XvideosRipper extends AbstractHTMLRipper {
  static final RegExp _videoPattern =
      RegExp(r'^https?://[wm.]*xvideos\.com/video\.([^/]*)(.*)$');
  static final RegExp _albumPattern = RegExp(
    r'^https?://[wm.]*xvideos\.com/(profiles|amateurs)/([a-zA-Z0-9_-]+)/photos/(\d+)/([a-zA-Z0-9_-]+)$',
  );

  XvideosRipper(super.url);

  @override
  String getHost() => 'xvideos';

  String getDomain() => 'xvideos.com';

  @override
  bool canRip(Uri url) {
    final text = url.toString();
    return _videoPattern.hasMatch(text) || _albumPattern.hasMatch(text);
  }

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    final videoMatch = _videoPattern.firstMatch(text);
    if (videoMatch != null) return videoMatch.group(1)!;

    final albumMatch = _albumPattern.firstMatch(text);
    if (albumMatch != null) return albumMatch.group(3)!;

    throw FormatException(
      'Expected xvideo format:xvideos.com/video#### Got: $url',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    final text = url.toString();
    final videoMatch = _videoPattern.firstMatch(text);
    if (videoMatch != null) {
      return 'xvideos_${videoMatch.group(1)!}_${videoMatch.group(2)!}';
    }

    final albumMatch = _albumPattern.firstMatch(text);
    if (albumMatch != null) {
      return 'xvideos_${albumMatch.group(1)!}_${albumMatch.group(2)!}_'
          '${albumMatch.group(4)!}_${albumMatch.group(3)!}';
    }

    return super.getAlbumTitle(url);
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    final Document page;
    try {
      page = await Http.get(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final source in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final sourceUri = Uri.parse(source);
      downloads.add(
        RipperDownload(
          url: sourceUri,
          saveAs: File(
            p.join(
              workingDir.path,
              fileNameForUrl(sourceUri, prefix: prefix(index)),
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
    if (_videoPattern.hasMatch(url.toString())) {
      return videoUrlsFromDocument(page);
    }
    return albumUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> videoUrlsFromDocument(Document page) {
    final results = <String>[];
    for (final script in page.querySelectorAll('script')) {
      final html = script.innerHtml;
      if (!html.contains('html5player.setVideoUrlHigh')) continue;
      final lines = html.split('\n');
      for (final line in lines) {
        if (!line.contains('html5player.setVideoUrlHigh')) continue;
        final videoUrl = line
            .trim()
            .replaceAll('\t', '')
            .replaceAll(RegExp(r'html5player\.setVideoUrlHigh\('), '')
            .replaceAll("'", '')
            .replaceAll(RegExp(r'\);'), '');
        results.add(videoUrl);
      }
    }
    return results;
  }

  static List<String> albumUrlsFromDocument(Document page) {
    return [
      for (final link in page.querySelectorAll('div.thumb > a'))
        link.attributes['href'] ?? '',
    ];
  }

  static String prefix(int index) => '${index.toString().padLeft(3, '0')}_';

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
