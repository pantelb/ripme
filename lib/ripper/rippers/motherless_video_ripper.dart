import 'dart:io';

import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_video_ripper.dart';

class MotherlessVideoRipper extends AbstractVideoRipper {
  static final RegExp _urlPattern =
      RegExp(r'^https?://[wm.]*motherless\.com/[A-Z0-9]+.*$');
  static final RegExp _gidPattern =
      RegExp(r'^https?://[wm.]*motherless\.com/([A-Z0-9]+).*$');

  MotherlessVideoRipper(super.url);

  @override
  String getHost() => 'motherless';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected motherless format:motherless.com/#### Got: $url',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      final videoUrl = await getVideoURLForRip(url);
      final fileName = javaDownloadFileName(videoUrl, await getGID(url));
      await downloadFile(
        videoUrl,
        File(p.join(workingDir.path, Utils.sanitizeSaveAs(fileName))),
      );
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<Uri> getVideoURLForRip(Uri url) async {
    final html = await Http.getText(url);
    return videoUrlFromHtml(html, url);
  }

  static Uri videoUrlFromHtml(String html, Uri pageUrl) {
    final urls = between(html, "__fileurl = '", "';");
    if (urls.isEmpty) {
      throw HttpException('Could not find video URL at $pageUrl');
    }
    return Uri.parse(urls.first);
  }

  static List<String> between(String value, String start, String end) {
    final results = <String>[];
    var searchFrom = 0;
    while (searchFrom < value.length) {
      final startIndex = value.indexOf(start, searchFrom);
      if (startIndex < 0) break;
      final contentStart = startIndex + start.length;
      final endIndex = value.indexOf(end, contentStart);
      if (endIndex < 0) break;
      results.add(value.substring(contentStart, endIndex));
      searchFrom = endIndex + end.length;
    }
    return results;
  }

  static String javaDownloadFileName(Uri videoUrl, String gid) {
    var fileName = videoUrl.toString();
    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return 'motherless_$gid$fileName';
  }
}
