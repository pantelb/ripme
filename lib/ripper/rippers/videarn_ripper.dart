import 'dart:io';

import '../../utils/http_utils.dart';
import '../abstract_video_ripper.dart';

class VidearnRipper extends AbstractVideoRipper {
  static final RegExp _urlPattern =
      RegExp(r'^https?://[wm.]*videarn\.com/[a-zA-Z0-9\-]+/([0-9]+).*$');

  VidearnRipper(super.url);

  @override
  String getHost() => 'videarn';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _urlPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected videarn format:videarn.com/.../####-... Got: $url',
    );
  }

  @override
  Future<Uri> getVideoURLForRip(Uri url) async {
    final html = await Http.getText(url);
    return videoUrlFromHtml(html, url);
  }

  @override
  Future<VideoDownloadRequest> getVideoDownloadForRip(Uri url) async {
    final videoUrl = await getVideoURLForRip(url);
    return VideoDownloadRequest(
      url: videoUrl,
      fileName: javaDownloadFileName(videoUrl, await getGID(url)),
    );
  }

  static Uri videoUrlFromHtml(String html, Uri pageUrl) {
    final urls = between(html, 'file:"', '"');
    if (urls.isEmpty) {
      throw HttpException('Could not find files at $pageUrl');
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
    return 'videarn_$gid$fileName';
  }
}
