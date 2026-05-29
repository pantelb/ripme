import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' show Element;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';

enum VkRipType { video, image }

class VkRipper extends AbstractJSONRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?:\/\/(?:www\.)?vk\.com\/((?:photos|album|videos)-?(?:[a-zA-Z0-9_]+).*$)',
  );

  VkRipper(super.url);

  int _offset = 0;
  VkRipType _ripType = VkRipType.image;
  String? _oid;

  @override
  String getHost() => 'vk';

  @override
  bool canRip(Uri url) {
    if (!url.host.toLowerCase().endsWith('vk.com')) return false;
    final text = url.toString();
    return !text.contains('/video') || text.contains('videos');
  }

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw const FormatException(
      'Expected format: http://vk.com/album#### or vk.com/photos####',
    );
  }

  @override
  Future<void> parseJSON(Uri url) async {
    _ripType = this.url.toString().contains('/videos')
        ? VkRipType.video
        : VkRipType.image;
    if (_ripType == VkRipType.video) {
      await _ripVideos();
    } else {
      await _ripImages();
    }
  }

  Future<void> _ripImages() async {
    while (!isStopped) {
      final page = await getImagePage();
      if (page == null) break;
      final urls = imageUrlsFromJson(page);
      if (urls.isEmpty) {
        throw HttpException('No images found at $url');
      }

      final downloads = <RipperDownload>[];
      for (final imageUrl in urls) {
        downloads.add(
          RipperDownload(
            url: Uri.parse(imageUrl),
            saveAs: File(p.join(workingDir.path, javaUrlFileName(imageUrl))),
          ),
        );
      }
      await downloadFiles(downloads);
    }
  }

  Future<void> _ripVideos() async {
    final gid = await getGID(url);
    _oid = gid.replaceFirst('videos', '');
    final page = await getFirstVideoPage(_oid!);
    final videoUrls = await videoUrlsFromJsonPage(page, _oid!);
    final downloads = <RipperDownload>[];
    for (var i = 0; i < videoUrls.length; i++) {
      final videoUrl = videoUrls[i];
      final prefix = Utils.getConfigBoolean('download.save_order', true)
          ? '${(i + 1).toString().padLeft(3, '0')}_'
          : '';
      downloads.add(
        RipperDownload(
          url: videoUrl,
          saveAs: File(
            p.join(
              workingDir.path,
              '$prefix${javaUrlFileName(videoUrl.toString())}',
            ),
          ),
        ),
      );
      await Http.delay(const Duration(milliseconds: 500));
    }
    await downloadFiles(downloads);
  }

  Future<Map<String, dynamic>> getFirstVideoPage(String oid) async {
    final response = await http.post(
      Uri.parse('http://vk.com/al_video.php'),
      headers: {
        'User-Agent': Http.userAgent,
        'Referer': url.toString(),
      },
      body: {
        'al': '1',
        'act': 'load_videos_silent',
        'offset': '0',
        'oid': oid,
      },
    );
    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to load VK videos: Status ${response.statusCode}',
      );
    }
    final parts = response.body.split('<!>');
    final json = jsonDecode(parts.last);
    if (json is Map<String, dynamic>) return json;
    throw const FormatException('VK video response was not a JSON object');
  }

  Future<List<Uri>> videoUrlsFromJsonPage(
    Map<String, dynamic> page,
    String oid,
  ) async {
    final all = page['all'];
    if (all is! List) return const [];

    final urls = <Uri>[];
    for (final video in all) {
      if (video is! List || video.length <= 1) continue;
      final vidid = video[1];
      final videoUrl =
          await getVideoURLAtPage('http://vk.com/video${oid}_$vidid');
      urls.add(videoUrl);
    }
    return urls;
  }

  Future<Map<String, String>?> getImagePage() async {
    final response = await http.post(
      url,
      headers: {
        'User-Agent': Http.userAgent,
        'Referer': url.toString(),
      },
      body: {
        'al': '1',
        'offset': _offset.toString(),
        'part': '1',
      },
    );
    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to load VK image page: Status ${response.statusCode}',
      );
    }

    var body = response.body;
    final divIndex = body.indexOf('<div');
    if (divIndex < 0) return null;
    body = unescapeJavaScript(body.substring(divIndex));

    final document = html_parser.parseFragment(body);
    final anchors = document.querySelectorAll('a');
    final photoIds = photoIdsFromAnchors(anchors);
    final photoIdsToUrls = <String, String>{};
    for (final photoId in photoIds) {
      try {
        photoIdsToUrls.addAll(await getPhotoIDsToURLs(photoId));
      } catch (_) {
        continue;
      }
      if (isStopped) break;
    }
    _offset += anchors.length;
    return photoIdsToUrls;
  }

  Future<Map<String, String>> getPhotoIDsToURLs(String photoID) async {
    final response = await http.post(
      Uri.parse('https://vk.com/al_photos.php'),
      headers: {
        'Referer': url.toString(),
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.5',
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest',
        'User-Agent': Http.userAgent,
      },
      body: {
        'list': await getGID(url),
        'act': 'show',
        'al': '1',
        'module': 'photos',
        'photo': photoID,
      },
    );
    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to load VK photo $photoID: Status ${response.statusCode}',
      );
    }
    final json = jsonDecode(response.body);
    final photoObject = findJSONObjectContainingPhotoId(photoID, json);
    final bestSourceUrl =
        photoObject == null ? null : getBestSourceUrl(photoObject);
    return bestSourceUrl == null ? const {} : {photoID: bestSourceUrl};
  }

  static Map<String, dynamic>? findJSONObjectContainingPhotoId(
    String photoID,
    Object? json,
  ) {
    if (json is Map) {
      if (json['id']?.toString() == photoID) {
        return Map<String, dynamic>.from(json);
      }
      for (final value in json.values) {
        final found = findJSONObjectContainingPhotoId(photoID, value);
        if (found != null) return found;
      }
    }

    if (json is List) {
      for (final value in json) {
        if (value is Map || value is List) {
          final found = findJSONObjectContainingPhotoId(photoID, value);
          if (found != null) return found;
        }
      }
    }
    return null;
  }

  static String? getBestSourceUrl(Map<String, dynamic> json) {
    String? bestSourceKey;
    var bestSourceResolution = 0;

    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is List &&
          value.length == 3 &&
          value[0].toString() != '' &&
          _toInt(value[1]) != 0 &&
          _toInt(value[2]) != 0 &&
          json.containsKey('${key}src')) {
        final resolution = _toInt(value[1]) * _toInt(value[2]);
        if (resolution >= bestSourceResolution) {
          bestSourceResolution = resolution;
          bestSourceKey = key;
        }
      }
    }

    if (bestSourceKey == null) {
      for (final key in const ['z_src', 'y_src', 'x_src', 'w_src']) {
        final value = json[key];
        if (value != null) return value.toString();
      }
      return null;
    }
    return json['${bestSourceKey}src']?.toString();
  }

  static List<String> photoIdsFromAnchors(List<Element> anchors) {
    final ids = <String>{};
    for (final anchor in anchors) {
      final onclick = anchor.attributes['onclick'] ?? '';
      const marker = "showPhoto('";
      final markerIndex = onclick.indexOf(marker);
      if (markerIndex < 0) continue;
      var photoId = onclick.substring(markerIndex + marker.length);
      final endIndex = photoId.indexOf("'");
      if (endIndex < 0) continue;
      photoId = photoId.substring(0, endIndex);
      ids.add(photoId);
    }
    return ids.toList(growable: false);
  }

  static List<String> imageUrlsFromJson(Map<String, String> page) {
    return page.values.toList(growable: false);
  }

  static List<int> videoIdsFromJsonPage(Map<String, dynamic> page) {
    final all = page['all'];
    if (all is! List) return const [];
    return all
        .whereType<List>()
        .where((video) => video.length > 1)
        .map((video) => _toInt(video[1]))
        .toList(growable: false);
  }

  static Future<Uri> getVideoURLAtPage(String url) async {
    final html = await Http.getText(
      Uri.parse(url),
      headers: {'User-Agent': Http.userAgent},
    );
    return videoURLFromHtml(html, Uri.parse(url));
  }

  static Uri videoURLFromHtml(String html, Uri pageUrl) {
    for (final quality in const ['1080', '720', '480', '240']) {
      final marker = 'url$quality\\":\\"';
      if (!html.contains(marker)) continue;
      var videoUrl = html.substring(html.indexOf(marker) + marker.length);
      videoUrl = videoUrl.substring(0, videoUrl.indexOf('"'));
      videoUrl = videoUrl.replaceAll('\\', '');
      return Uri.parse(videoUrl);
    }
    throw HttpException('Could not find video URL at $pageUrl');
  }

  static String javaUrlFileName(String url) {
    var fileName = url.substring(url.lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return fileName;
  }

  static String unescapeJavaScript(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char != '\\') {
        buffer.write(char);
        continue;
      }
      if (i + 1 >= value.length) {
        buffer.write(char);
        continue;
      }
      final next = value[++i];
      switch (next) {
        case 'b':
          buffer.write('\b');
          break;
        case 'f':
          buffer.write('\f');
          break;
        case 'n':
          buffer.write('\n');
          break;
        case 'r':
          buffer.write('\r');
          break;
        case 't':
          buffer.write('\t');
          break;
        case 'u':
          if (i + 4 < value.length) {
            final code = int.tryParse(
              value.substring(i + 1, i + 5),
              radix: 16,
            );
            if (code != null) {
              buffer.writeCharCode(code);
              i += 4;
              break;
            }
          }
          buffer.write(r'\u');
          break;
        default:
          buffer.write(next);
          break;
      }
    }
    return buffer.toString();
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
