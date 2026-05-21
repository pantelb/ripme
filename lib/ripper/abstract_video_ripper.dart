import 'dart:io';
import 'package:html/dom.dart' show Document;

import 'abstract_ripper.dart';
import '../ui/rip_status_message.dart';
import '../utils/http_utils.dart';
import '../utils/utils.dart';

class VideoDownloadRequest {
  final Uri url;
  final String? fileName;
  final Map<String, String>? headers;
  final Map<String, String>? cookies;

  const VideoDownloadRequest({
    required this.url,
    this.fileName,
    this.headers,
    this.cookies,
  });
}

abstract class AbstractVideoRipper extends AbstractRipper {
  AbstractVideoRipper(super.url);

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      final request = await getVideoDownloadForRip(url);
      String fileName = await _getFileName(request);
      File saveAs = File(workingDir.path + Platform.pathSeparator + fileName);

      await downloadFile(
        request.url,
        saveAs,
        headers: request.headers,
        cookies: request.cookies,
      );
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<String> getAlbumTitle(Uri url) async => 'videos';

  Future<Uri> getVideoURLForRip(Uri url);

  Future<VideoDownloadRequest> getVideoDownloadForRip(Uri url) async {
    final videoUrl = await getVideoURLForRip(url);
    return VideoDownloadRequest(
      url: videoUrl,
      headers: {'Referer': url.toString()},
    );
  }

  Future<String> _getFileName(VideoDownloadRequest request) async {
    final explicit = request.fileName;
    if (explicit != null && explicit.trim().isNotEmpty) {
      return Utils.sanitizeSaveAs(_ensureVideoExtension(explicit));
    }
    final sourceName = request.url.pathSegments.isNotEmpty
        ? request.url.pathSegments.last
        : '';
    final name = sourceName.isEmpty ? await getGID(url) : sourceName;
    return Utils.sanitizeSaveAs(_ensureVideoExtension(name));
  }

  String _ensureVideoExtension(String fileName) {
    if (fileName.contains('.') && !fileName.endsWith('.')) return fileName;
    return '$fileName.mp4';
  }

  static Uri? bestDashVideoUrl(Document manifest, Uri manifestUrl) {
    var bestHeight = -1;
    Uri? bestUrl;
    for (final representation in manifest
        .querySelectorAll('MPD > Period > AdaptationSet > Representation')) {
      final baseUrl = representation.querySelector('BaseURL')?.text.trim();
      if (baseUrl == null || baseUrl.isEmpty) continue;
      final height = int.tryParse(representation.attributes['height'] ?? '');
      final bandwidth =
          int.tryParse(representation.attributes['bandwidth'] ?? '');
      final score = height ?? bandwidth ?? 0;
      if (score > bestHeight) {
        bestHeight = score;
        bestUrl = manifestUrl.resolve(baseUrl);
      }
    }
    return bestUrl;
  }

  static Uri? bestHlsVideoUrl(String manifest, Uri manifestUrl) {
    Uri? bestUrl;
    var bestScore = -1;
    final lines = manifest
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;
      if (i + 1 >= lines.length) continue;
      final next = lines[i + 1];
      if (next.startsWith('#')) continue;

      final score = _hlsScore(line);
      if (score > bestScore) {
        bestScore = score;
        bestUrl = manifestUrl.resolve(next);
      }
    }

    return bestUrl;
  }

  static Future<Uri?> bestVideoUrlFromManifest(Uri manifestUrl,
      {Map<String, String>? headers, Map<String, String>? cookies}) async {
    final path = manifestUrl.path.toLowerCase();
    if (path.endsWith('.mpd')) {
      final manifest =
          await Http.get(manifestUrl, headers: headers, cookies: cookies);
      return bestDashVideoUrl(manifest, manifestUrl);
    }
    if (path.endsWith('.m3u8')) {
      final manifest =
          await Http.getText(manifestUrl, headers: headers, cookies: cookies);
      return bestHlsVideoUrl(manifest, manifestUrl);
    }
    return null;
  }

  static int _hlsScore(String streamInf) {
    final resolution = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(streamInf);
    if (resolution != null) {
      return int.tryParse(resolution.group(2) ?? '') ?? 0;
    }
    final bandwidth = RegExp(r'BANDWIDTH=(\d+)').firstMatch(streamInf);
    return int.tryParse(bandwidth?.group(1) ?? '') ?? 0;
  }
}
