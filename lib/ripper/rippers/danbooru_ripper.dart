import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';
import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';

class DanbooruRipper extends AbstractJSONRipper {
  DanbooruRipper(super.url);

  static const String domain = 'danbooru.donmai.us';
  static const Map<String, String> requestHeaders = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
    'Accept': 'application/json,text/javascript,*/*;q=0.01',
    'Accept-Language': 'en-US,en;q=0.9',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'Referer': 'https://danbooru.donmai.us/',
    'X-Requested-With': 'XMLHttpRequest',
    'Connection': 'keep-alive',
  };

  static final RegExp _gidPattern = RegExp(
    r'^https?://danbooru\.donmai\.us/(posts)?.*([?&]tags=([^&]*)(?:&z=([0-9]+))?$)',
  );

  int _currentPageNum = 1;

  @override
  String getHost() => 'danbooru';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  @override
  Future<String> getGID(Uri url) async {
    try {
      return Utils.filesystemSafe(Uri.parse(getTag(url)).path);
    } catch (_) {
      throw FormatException(
        'Expected booru URL format: $domain/posts?tags=searchterm - got $url instead',
      );
    }
  }

  @override
  Future<void> parseJSON(Uri url) async {
    var index = 0;
    var json = await getCurrentPage();

    while (json != null && !isStopped) {
      final urls = urlsFromJson(json);
      if (urls.isEmpty) {
        throw StateError('No images found at $url');
      }

      final downloads = <RipperDownload>[];
      for (final urlText in urls) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(urlText);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, downloadFileName(uri, index))),
          ),
        );
      }
      await downloadFiles(downloads);

      if (isStopped) break;
      sendUpdate(RipStatus.loadingResource, 'next page');
      json = await getCurrentPage();
    }
  }

  Future<Map<String, dynamic>?> getCurrentPage() async {
    final response = await Http.getResponse(
      getPage(_currentPageNum),
      headers: requestHeaders,
      defaultTimeoutMs: 60000,
    );
    _currentPageNum++;
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body);
    if (json is List && json.isNotEmpty) {
      return {'resources': json};
    }
    return null;
  }

  Uri getPage(int num) {
    return Uri.parse(
        'https://$domain/posts.json?page=$num&tags=${getTag(url)}');
  }

  static String getTag(Uri url) {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(3)!;

    throw FormatException(
      'Expected danbooru URL format: $domain/posts?tags=searchterm - got $url instead',
    );
  }

  static List<String> urlsFromJson(Map<String, dynamic> json) {
    final resources = json['resources'];
    if (resources is! List) return const [];

    final urls = <String>[];
    for (final resource in resources) {
      if (resource is! Map) continue;
      final fileUrl = resource['file_url'];
      if (fileUrl is String) urls.add(fileUrl);
    }
    return urls;
  }

  static String downloadFileName(Uri uri, int index) {
    var fileName =
        uri.toString().substring(uri.toString().lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) {
        fileName = fileName.substring(0, separatorIndex);
      }
    }
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
