import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';

class FapDungeonRipper extends AbstractHTMLRipper {
  FapDungeonRipper(super.url);

  static const String hostName = 'fapdungeon';
  static const Duration downloadDelay = Duration(seconds: 1);
  static final RegExp _pagePattern =
      RegExp(r'^https?://[wm.]*fapdungeon\.com/([a-zA-Z0-9_-]+)/(.+)/?$');

  @override
  String getHost() => hostName;

  String getDomain() => '$hostName.com';

  @override
  bool canRip(Uri url) => _pagePattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _pagePattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected fapdungeon format:fapdungeon.com/category/albumname/ Got: $url',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    final match = _pagePattern.firstMatch(url.toString());
    if (match != null) {
      return '${getHost()}_${match.group(1)}_${match.group(2)}';
    }
    return super.getAlbumTitle(url);
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
    for (final mediaUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      await Http.delay(downloadDelay);
      final uri = Uri.parse(mediaUrl);
      await downloadFile(
        uri,
        File(p.join(workingDir.path, fileNameForUrl(uri, index))),
      );
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return mediaFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> mediaFromPage(Document page) {
    final content = page.querySelector('div.entry-content');
    if (content == null) return const [];

    final results = <String>[];
    for (final image in content.querySelectorAll('img')) {
      results.add(largestImageUrlFromSrcset(
        image.attributes['src'] ?? '',
        image.attributes['srcset'] ?? '',
      ));
    }
    for (final video in content.querySelectorAll('video source')) {
      results.add(video.attributes['src'] ?? '');
    }
    return results;
  }

  static String largestImageUrlFromSrcset(String src, String sourceSet) {
    String? largestImgUrl;
    var maxWidth = 0;

    for (final part in sourceSet.split(',')) {
      final subParts = part.trim().split(RegExp(r'\s+'));
      if (subParts.length != 2) continue;

      final widthText = subParts[1].trim();
      final width = int.tryParse(widthText.substring(0, widthText.length - 1));
      if (width == null) continue;

      if (width > maxWidth) {
        largestImgUrl = subParts[0].trim();
        maxWidth = width;
      }
    }

    return largestImgUrl ?? src;
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
