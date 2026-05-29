import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class NudeGalsRipper extends AbstractHTMLRipper {
  static final RegExp _albumPattern = RegExp(
    r'^.*nude-gals\.com/photoshoot\.php\?photoshoot_id=(\d+)$',
  );
  static final RegExp _videoPattern = RegExp(
    r'^.*nude-gals\.com/video\.php\?video_id=(\d+)$',
  );

  NudeGalsRipper(super.url);

  @override
  String getHost() => 'Nude-Gals';

  String getDomain() => 'nude-gals.com';

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    final albumMatch = _albumPattern.firstMatch(text);
    if (albumMatch != null) return 'album_${albumMatch.group(1)}';

    final videoMatch = _videoPattern.firstMatch(text);
    if (videoMatch != null) return 'video_${videoMatch.group(1)}';

    throw FormatException(
      'Expected nude-gals.com gallery format: '
      'nude-gals.com/photoshoot.php?phtoshoot_id=#### Got: $url',
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
    for (final mediaUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final mediaUri = Uri.parse(mediaUrl);
      downloads.add(
        RipperDownload(
          url: mediaUri,
          saveAs: File(
            p.join(workingDir.path, downloadFileName(mediaUri, index)),
          ),
          headers: downloadHeaders(url),
        ),
      );
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    if (_albumPattern.hasMatch(url.toString())) {
      return albumUrlsFromPage(page);
    }
    if (_videoPattern.hasMatch(url.toString())) {
      return videoUrlsFromPage(page);
    }
    return const [];
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> albumUrlsFromPage(Document page) {
    return [
      for (final thumb in page.querySelectorAll('img.thumbnail'))
        _absoluteNudeGalsUrl(
          (thumb.attributes['src'] ?? '').trim().replaceAll('thumbs/th_', ''),
        ),
    ];
  }

  static List<String> videoUrlsFromPage(Document page) {
    return [
      for (final source in page.querySelectorAll('video source'))
        _absoluteNudeGalsUrl((source.attributes['src'] ?? '').trim()),
    ];
  }

  static String _absoluteNudeGalsUrl(String path) {
    return 'http://nude-gals.com/$path'.replaceAll(' ', '%20');
  }

  static Map<String, String> downloadHeaders(Uri sourcePage) {
    return {'Referer': sourcePage.toString()};
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String downloadFileName(Uri uri, int index) {
    final path = uri.toString().split(RegExp(r'[?#]')).first;
    final fileName =
        path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : 'file';
    return Utils.sanitizeSaveAs('${prefixForIndex(index)}$fileName');
  }
}
