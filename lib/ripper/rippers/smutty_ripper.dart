import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class SmuttyRipper extends AbstractHTMLRipper {
  static final RegExp _tagGidPattern = RegExp(
    r'^https?://smutty\.com/h/([a-zA-Z0-9\-_]+).*$',
  );
  static final RegExp _searchGidPattern = RegExp(
    r'^https?://[wm.]*smutty\.com/search/\?q=([a-zA-Z0-9\-_%]+).*$',
  );
  static final RegExp _userGidPattern = RegExp(
    r'^https?://smutty\.com/user/([a-zA-Z0-9\-_]+)/?$',
  );

  SmuttyRipper(super.url);

  @override
  String getHost() => 'smutty';

  String getDomain() => 'smutty.com';

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    var match = _tagGidPattern.firstMatch(text);
    if (match != null) return match.group(1)!;

    match = _searchGidPattern.firstMatch(text);
    if (match != null) return match.group(1)!.replaceAll('%23', '');

    match = _userGidPattern.firstMatch(text);
    if (match != null) return match.group(1)!;

    throw FormatException('Expected tag in URL (smutty.com/h/tag and not $url');
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await Http.get(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: imageUri,
            saveAs: File(
              p.join(workingDir.path, fileNameForUrl(imageUri, index)),
            ),
          ),
        );
      }

      await downloadFiles(downloads);
      if (isStopped) break;

      Uri? nextUri;
      try {
        nextUri = await getNextPage(page);
      } catch (_) {
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
    return nextPageUrlFromDocument(page);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  static Uri nextPageUrlFromDocument(Document page) {
    final elem = page.querySelector('a.next');
    if (elem == null) throw const HttpException('No more pages');

    final nextPage = elem.attributes['href'] ?? '';
    if (nextPage.isEmpty) throw const HttpException('No more pages');

    return Uri.parse('https://smutty.com$nextPage');
  }

  static List<String> imageUrlsFromDocument(Document page) {
    final results = <String>[];
    for (final image in page.querySelectorAll('a.l > img')) {
      final fields = (image.attributes['src'] ?? '').split('/');
      for (var i = 0; i < fields.length; i++) {
        if (i == fields.length - 2 && fields[i] == 'm') {
          fields[i] = 'b';
        }
      }
      results.add('http:${fields.join('/')}');
    }
    return results;
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${prefix(index)}$fileName');
  }

  static String prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
