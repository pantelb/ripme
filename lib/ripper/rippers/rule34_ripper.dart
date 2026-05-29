import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class Rule34Ripper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^https?://rule34\.xxx/index\.php\?page=post&s=list&tags=([\S]+)$',
  );

  String? _apiUrl;
  int _pageNumber = 0;

  Rule34Ripper(super.url);

  @override
  String getHost() => 'rule34';

  String getDomain() => 'rule34.xxx';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected rule34.xxx URL format: '
      'rule34.xxx/index.php?page=post&s=list&tags=TAG - got $url instead',
    );
  }

  Future<Uri> getAPIUrl() async {
    return Uri.parse(
      'https://rule34.xxx/index.php?page=dapi&s=post&q=index&limit=100&tags=${await getGID(url)}',
    );
  }

  Future<Document> getFirstPage() async {
    final api = await getAPIUrl();
    _apiUrl = api.toString();
    _pageNumber = 0;
    return Http.get(api);
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, (await getAPIUrl()).toString());

    Document page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        if (imageUrl.isEmpty) continue;
        index++;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForUrl(imageUri, prefix: prefixForIndex(index)),
              ),
            ),
          ),
        );
      }

      if (downloads.isEmpty) {
        sendUpdate(
            RipStatus.ripErrored, 'No images found at ${_apiUrl ?? url}');
        break;
      }
      await downloadFiles(downloads);
      if (isStopped) break;

      Uri? nextUri;
      try {
        nextUri = await getNextPage(page);
      } on IOException {
        break;
      }
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

  @override
  Future<Uri?> getNextPage(Document page) async {
    if (page.outerHtml.contains('Search error: API limited due to abuse')) {
      throw const HttpException('No more pages');
    }
    _pageNumber += 1;
    return Uri.parse('${_apiUrl ?? await getAPIUrl()}&pid=$_pageNumber');
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return fileUrlsFromDocument(page);
  }

  static List<String> fileUrlsFromDocument(Document page) {
    return [
      for (final post in page.querySelectorAll('posts > post'))
        post.attributes['file_url'] ?? '',
    ];
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
