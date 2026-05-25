import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class BooruRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r"^https?://(www\.)?(x|gel)booru\.com/(index\.php)?.*([?&]tags=([a-zA-Z0-9$_.+!*'(),%-]+))(&|(#.*)?$)",
  );

  BooruRipper(super.url);

  @override
  bool canRip(Uri url) {
    final text = url.toString();
    return text.contains('xbooru') || text.contains('gelbooru');
  }

  @override
  String getHost() => url.host.split('.').first;

  String getDomain() => url.host;

  @override
  Future<String> getGID(Uri url) async {
    try {
      return Utils.filesystemSafe(getTerm(url).replaceAll('&tags=', ''));
    } catch (_) {
      throw FormatException(
        'Expected xbooru.com URL format: ${getHost()}.com/index.php?tags=searchterm - got $url instead',
      );
    }
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, getPage(0).toString());

    Document page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final booruUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        final uri = Uri.parse(booruUrl);
        final downloadUri = uri.removeFragment();
        downloads.add(
          RipperDownload(
            url: downloadUri,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForUrl(
                  downloadUri,
                  prefix: prefixForPostId(uri.fragment),
                ),
              ),
            ),
          ),
        );
      }

      await downloadFiles(downloads);
      if (isStopped) break;

      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await Http.get(nextUri);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() => Http.get(getPage(0));

  @override
  Future<Uri?> getNextPage(Document page) async {
    final posts = page.querySelectorAll('posts');
    if (posts.isEmpty) return null;

    final offset = int.tryParse(posts.first.attributes['offset'] ?? '') ?? 0;
    final count = int.tryParse(posts.first.attributes['count'] ?? '') ?? 0;
    if (offset + 100 > count) return null;

    return getPage(offset ~/ 100 + 1);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final urls = <String>[];
    final base = getPage(0);
    for (final post in page.querySelectorAll('post')) {
      final fileUrl = post.attributes['file_url'];
      if (fileUrl == null || fileUrl.isEmpty) continue;
      final id = post.attributes['id'] ?? '';
      urls.add('${absoluteFileUrl(fileUrl, base: base)}#$id');
    }
    return urls;
  }

  Uri getPage(int num) {
    return Uri.parse(
      'http://${getHost()}.com/index.php?page=dapi&s=post&q=index&pid=$num&tags=${getTerm(url)}',
    );
  }

  static String getTerm(Uri url) {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(4)!;

    throw FormatException('Expected xbooru.com URL format: $url');
  }

  static Uri absoluteFileUrl(String fileUrl, {required Uri base}) {
    if (fileUrl.startsWith('//')) {
      return Uri.parse('${base.scheme}:$fileUrl');
    }
    return base.resolve(fileUrl);
  }

  static String prefixForPostId(String postId) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    if (postId.isEmpty) return '';
    return '$postId-';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
