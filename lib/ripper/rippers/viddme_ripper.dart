import 'dart:io';

import 'package:html/dom.dart';

import '../../utils/http_utils.dart';
import '../abstract_video_ripper.dart';

class ViddmeRipper extends AbstractVideoRipper {
  static final RegExp _urlPattern =
      RegExp(r'^https?://[wm.]*vid\.me/[a-zA-Z0-9]+.*$');
  static final RegExp _gidPattern =
      RegExp(r'^https?://[wm.]*vid\.me/([a-zA-Z0-9]+).*$');

  ViddmeRipper(super.url);

  @override
  String getHost() => 'vid';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException('Expected vid.me format:vid.me/id Got: $url');
  }

  @override
  Future<Uri> getVideoURLForRip(Uri url) async {
    final page = await getPage(url);
    return videoUrlFromDocument(page, url);
  }

  @override
  Future<VideoDownloadRequest> getVideoDownloadForRip(Uri url) async {
    final videoUrl = await getVideoURLForRip(url);
    return VideoDownloadRequest(
      url: videoUrl,
      fileName: javaDownloadFileName(videoUrl, await getGID(url)),
    );
  }

  Future<Document> getPage(Uri uri) => Http.get(uri);

  static Uri videoUrlFromDocument(Document page, Uri pageUrl) {
    final stream = page.querySelector('meta[name="twitter:player:stream"]');
    if (stream == null) {
      throw HttpException('Could not find twitter:player:stream at $pageUrl');
    }
    final content = stream.attributes['content'] ?? '';
    return Uri.parse(content.replaceAll('&amp;', '&'));
  }

  static String javaDownloadFileName(Uri videoUrl, String gid) {
    var fileName = videoUrl.toString();
    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return 'vid_$gid$fileName';
  }
}
