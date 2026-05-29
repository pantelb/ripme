import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class SpankbangRipper extends AbstractHTMLRipper {
  static final RegExp _urlPattern =
      RegExp(r'^https?://.*spankbang\.com/(.*)/video/.*$');
  static final RegExp _gidPattern =
      RegExp(r'^https?://.*spankbang\.com/(.*)/video/(.*)$');

  SpankbangRipper(super.url);

  @override
  String getHost() => 'spankbang';

  String getDomain() => 'spankbang.com';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(2)!;

    throw FormatException(
      'Expected spankbang format:'
      'spankbang.com/####/video/'
      ' Got: $url',
    );
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

    final urls = videoUrlsFromDocument(page);
    if (urls == null) {
      sendUpdate(
        RipStatus.ripErrored,
        'Could not find Embed code at $url',
      );
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final videoUrl in urls) {
      if (isStopped) break;
      index++;
      final videoUri = Uri.parse(videoUrl);
      downloads.add(
        RipperDownload(
          url: videoUri,
          saveAs:
              File(p.join(workingDir.path, fileNameForUrl(videoUri, index))),
        ),
      );
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return videoUrlsFromDocument(page) ?? const [];
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String>? videoUrlsFromDocument(Document page) {
    final videos = page.querySelectorAll('.video-js > source');
    if (videos.isEmpty) return null;
    return [videos.first.attributes['src'] ?? ''];
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${prefix(index)}$fileName');
  }

  static String prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
