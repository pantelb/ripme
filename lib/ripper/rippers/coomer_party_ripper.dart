import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';
import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';

class CoomerPartyRipper extends AbstractJSONRipper {
  CoomerPartyRipper(super.url)
      : service = _pathElement(url, 0),
        user = _pathElement(url, 2) {
    if (service.trim().isEmpty || user.trim().isEmpty) {
      throw FormatException('Invalid coomer.party URL: $url');
    }
  }

  static const String imageUrlBase = 'https://c3.coomer.su/data';
  static const String videoUrlBase = 'https://c1.coomer.su/data';
  static const int postCount = 50;
  static const Duration downloadDelay = Duration(seconds: 5);

  static final RegExp _imagePattern = RegExp(
    r'^.*\.(jpg|jpeg|png|gif|apng|webp|tif|tiff)$',
    caseSensitive: false,
  );
  static final RegExp _videoPattern = RegExp(
    r'^.*\.(webm|mp4|m4v)$',
    caseSensitive: false,
  );

  final String service;
  final String user;

  @override
  String getHost() => 'coomer.party';

  String getDomain() => 'coomer.party';

  @override
  bool canRip(Uri url) {
    final host = url.host.toLowerCase();
    return host.endsWith('coomer.party') || host.endsWith('coomer.su');
  }

  @override
  Future<String> getGID(Uri url) async =>
      Utils.filesystemSafe('${service}_$user');

  @override
  Future<void> parseJSON(Uri url) async {
    var offset = 0;
    var index = 0;

    while (!isStopped) {
      final posts = await getJsonPostsForOffset(offset);
      final urls = urlsFromPosts(posts);
      if (urls.isEmpty && offset == 0) {
        throw StateError('No images found at $url');
      }

      final downloads = <RipperDownload>[];
      for (final urlText in urls) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(urlText);
        await Http.delay(downloadDelay);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, downloadFileName(uri, index))),
          ),
        );
      }
      await downloadFiles(downloads);

      if (isStopped || posts.length < postCount) break;
      offset += postCount;
      sendUpdate(RipStatus.loadingResource, 'next page');
    }
  }

  Future<List<dynamic>> getJsonPostsForOffset(int offset) async {
    final response = await Http.getText(Uri.parse(postsApiUrl(offset)));
    final json = jsonDecode(response);
    if (json is List) return json;
    throw FormatException('Expected Coomer posts array from offset $offset');
  }

  String postsApiUrl(int offset) =>
      'https://coomer.su/api/v1/$service/user/$user?o=$offset';

  static List<String> urlsFromPosts(List<dynamic> posts) {
    final urls = <String>[];
    for (final post in posts) {
      if (post is! Map) continue;
      _pullFileUrl(post, urls);
      _pullAttachmentUrls(post, urls);
    }
    return urls;
  }

  static String downloadFileName(Uri url, int index) {
    var fileName =
        url.toString().substring(url.toString().lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) {
        fileName = fileName.substring(0, separatorIndex);
      }
    }
    return '${_prefix(index)}$fileName';
  }

  static void _pullAttachmentUrls(
      Map<dynamic, dynamic> post, List<String> urls) {
    final attachments = post['attachments'];
    if (attachments is! List) return;
    for (final attachment in attachments) {
      if (attachment is Map) _pullFileUrl(attachment, urls);
    }
  }

  static void _pullFileUrl(Map<dynamic, dynamic> post, List<String> urls) {
    final file = post['file'];
    if (file is! Map) return;
    final path = file['path'];
    if (path is! String) return;

    if (_imagePattern.hasMatch(path)) {
      urls.add('$imageUrlBase$path');
    } else if (_videoPattern.hasMatch(path)) {
      urls.add('$videoUrlBase$path');
    }
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String _pathElement(Uri url, int index) {
    final parts = url.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    if (index >= parts.length) {
      throw FormatException('Invalid coomer.party URL: $url');
    }
    return parts[index];
  }
}
