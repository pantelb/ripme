import '../../utils/http_utils.dart';
import '../abstract_video_ripper.dart';
import 'vk_ripper.dart';

class VkVideoRipper extends AbstractVideoRipper {
  static final RegExp _urlPattern =
      RegExp(r'^https?://[wm.]*vk\.com/video[0-9]+.*$');
  static final RegExp _gidPattern =
      RegExp(r'^https?://[wm.]*vk\.com/video([0-9]+).*$');

  VkVideoRipper(super.url);

  @override
  String getHost() => 'vk';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected vk video URL format:vk.com/videos#### Got: $url',
    );
  }

  @override
  Future<Uri> getVideoURLForRip(Uri url) async {
    final html = await Http.getText(
      url,
      headers: {'User-Agent': Http.userAgent},
    );
    return VkRipper.videoURLFromHtml(html, url);
  }

  @override
  Future<VideoDownloadRequest> getVideoDownloadForRip(Uri url) async {
    final videoUrl = await getVideoURLForRip(url);
    return VideoDownloadRequest(
      url: videoUrl,
      fileName: javaDownloadFileName(videoUrl, await getGID(url)),
    );
  }

  static String javaDownloadFileName(Uri videoUrl, String gid) {
    return 'vk_$gid${VkRipper.javaUrlFileName(videoUrl.toString())}';
  }
}
