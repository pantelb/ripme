import 'dart:io';

import '../../utils/http_utils.dart';
import '../abstract_video_ripper.dart';

class PornhubVideoRipper extends AbstractVideoRipper {
  static final RegExp _urlPattern = RegExp(
    r'^https?://[wm.]*pornhub\.com/view_video\.php\?viewkey=[a-z0-9]+$',
  );
  static final RegExp _gidPattern = RegExp(
    r'^https?://[wm.]*pornhub\.com/view_video\.php\?viewkey=([a-z0-9]+)$',
  );

  PornhubVideoRipper(super.url);

  @override
  String getHost() => 'pornhub';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected pornhub format:pornhub.com/view_video.php?viewkey=#### Got: $url',
    );
  }

  @override
  Future<Uri> getVideoURLForRip(Uri url) async {
    final html = await Http.getText(url);
    final video = bestVideoFromHtml(html, url);
    return video.url;
  }

  @override
  Future<VideoDownloadRequest> getVideoDownloadForRip(Uri url) async {
    final html = await Http.getText(url);
    final video = bestVideoFromHtml(html, url);
    return VideoDownloadRequest(
      url: video.url,
      fileName:
          javaDownloadFileName(video.url, await getGID(url), video.quality),
    );
  }

  static PornhubVideoSource bestVideoFromHtml(String html, Uri pageUrl) {
    var script = _unescapeJavaScript(html);
    final varStart = script.indexOf('var ra');
    if (varStart < 0) {
      throw HttpException('Unable to find encrypted video URL at $pageUrl');
    }
    script = script.substring(varStart);
    final lineEnd = script.indexOf('\n');
    if (lineEnd >= 0) script = script.substring(0, lineEnd);
    script = script.replaceAll(RegExp(r'/\*([\S\s]+?)\*/'), '');

    final vars = <String, String>{};
    for (final match
        in RegExp(r'var\s+(ra\w+)\s*=\s*([^;]+);').allMatches(script)) {
      vars[match.group(1)!] = _joinJavaScriptStringParts(match.group(2)!);
    }

    final qualityMap = <int, Uri>{};
    for (final match
        in RegExp(r'var\s+quality_(\d+)\s*=\s*([^;]+);').allMatches(script)) {
      final quality = int.parse(match.group(1)!);
      final names =
          RegExp(r'ra\w+').allMatches(match.group(2)!).map((m) => m.group(0)!);
      final videoUrl = names.map((name) => vars[name] ?? '').join();
      if (videoUrl.isNotEmpty) qualityMap[quality] = Uri.parse(videoUrl);
    }

    if (qualityMap.isEmpty) {
      throw HttpException('Unable to find encrypted video URL at $pageUrl');
    }

    final bestQuality = qualityMap.keys.reduce((a, b) => a > b ? a : b);
    final bestUrl = qualityMap[bestQuality]!;
    if (bestUrl.toString().isEmpty) {
      throw HttpException('Unable to find encrypted video URL at $pageUrl');
    }
    return PornhubVideoSource(bestUrl, bestQuality);
  }

  static String _joinJavaScriptStringParts(String expression) {
    return expression
        .replaceAll('"', '')
        .replaceAll(RegExp(r'\s*\+\s*'), '')
        .trim();
  }

  static String _unescapeJavaScript(String value) {
    return value
        .replaceAll(r'\/', '/')
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'");
  }

  static String javaDownloadFileName(Uri videoUrl, String gid, int quality) {
    var fileName = videoUrl.toString();
    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return 'pornhub_${quality}p_$gid$fileName';
  }
}

class PornhubVideoSource {
  final Uri url;
  final int quality;

  const PornhubVideoSource(this.url, this.quality);
}
