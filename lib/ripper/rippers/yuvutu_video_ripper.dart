import 'dart:io';

import 'package:html/dom.dart';

import '../../utils/http_utils.dart';
import '../abstract_video_ripper.dart';

class YuvutuVideoRipper extends AbstractVideoRipper {
  static final RegExp _urlPattern =
      RegExp(r'^http://www\.yuvutu\.com/video/[0-9]+/(.*)$');

  YuvutuVideoRipper(super.url);

  @override
  String getHost() => 'yuvutu';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _urlPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected yuvutu format:yuvutu.com/video/#### Got: $url',
    );
  }

  @override
  Future<Uri> getVideoURLForRip(Uri url) async {
    final page = await Http.get(url);
    final iframeSrc = iframeSrcFromDocument(page, url);
    final iframePage =
        await Http.get(Uri.parse('http://www.yuvutu.com$iframeSrc'));
    return videoUrlFromDocument(iframePage, url);
  }

  @override
  Future<VideoDownloadRequest> getVideoDownloadForRip(Uri url) async {
    final videoUrl = await getVideoURLForRip(url);
    return VideoDownloadRequest(
      url: videoUrl,
      fileName: javaDownloadFileName(videoUrl, await getGID(url)),
    );
  }

  static String iframeSrcFromDocument(Document page, Uri pageUrl) {
    final iframe = page.querySelector('iframe');
    if (iframe == null) {
      throw HttpException('Could not find iframe code at $pageUrl');
    }
    return iframe.attributes['src'] ?? '';
  }

  static Uri videoUrlFromDocument(Document page, Uri pageUrl) {
    final scripts = page.querySelectorAll('script');
    if (scripts.isEmpty) {
      throw HttpException('Could not find script code at $pageUrl');
    }

    final pattern = RegExp(r'file: "(.*?)"');
    for (final script in scripts) {
      final match = pattern.firstMatch(script.text);
      if (match != null) return Uri.parse(match.group(1)!);
    }

    throw HttpException('Could not find file URL at $pageUrl');
  }

  static String javaDownloadFileName(Uri videoUrl, String gid) {
    var fileName = videoUrl.toString();
    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return 'yuvutu_$gid$fileName';
  }
}
