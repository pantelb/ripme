import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class MotherlessRipper extends AbstractHTMLRipper {
  static const String domain = 'motherless.com';
  static const Duration imageSleepTime = Duration(milliseconds: 1000);

  static final List<RegExp> _gidPatterns = [
    RegExp(r'^https?://(www\.)?motherless\.com/G([MVI]?[A-F0-9]{6,8}).*$'),
    RegExp(
        r'^https?://(www\.)?motherless\.com/term/(images/|videos/)([a-zA-Z0-9%]+)$'),
    RegExp(r'^https?://(www\.)?motherless\.com/g[iv]/([a-zA-Z0-9%\-_]+)$'),
  ];

  MotherlessRipper(super.url);

  @override
  String getHost() => 'motherless';

  @override
  bool canRip(Uri url) {
    if (!url.host.endsWith(domain)) return false;
    try {
      gidFromUrl(url);
      return true;
    } on FormatException {
      return false;
    }
  }

  @override
  Future<String> getGID(Uri url) async => gidFromUrl(url);

  @override
  Future<void> rip() async {
    final firstUrl = firstPageUrl(url);
    sendUpdate(RipStatus.loadingResource, firstUrl.toString());

    Document? page;
    try {
      page = await Http.get(
        firstUrl,
        headers: const {'Referer': 'https://motherless.com'},
      );
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;

    while (page != null && !isStopped) {
      for (final pageUrlText in await getURLsFromPage(page)) {
        if (isStopped) break;

        index++;
        final pageUri = Uri.parse(pageUrlText);
        final fileUri = await fileUrlFromImagePage(pageUri);
        await Http.delay(imageSleepTime);
        if (fileUri == null) continue;

        downloads.add(RipperDownload(
          url: fileUri,
          saveAs: File(p.join(
            workingDir.path,
            fileNameForUrl(fileUri, prefix: prefixForIndex(index)),
          )),
        ));
      }

      if (isStopped) break;

      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await Http.get(
          nextUri,
          headers: {'Referer': canonicalUrl(page) ?? url.toString()},
        );
      } catch (_) {
        break;
      }
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return pageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final href = page.querySelector('link[rel="next"]')?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return url.resolve(href);
  }

  Future<Uri?> fileUrlFromImagePage(Uri pageUri) async {
    try {
      final doc = await Http.get(
        pageUri,
        headers: {'Referer': pageUri.toString()},
      );
      return extractFileUrl(doc);
    } catch (e) {
      sendUpdate(
        RipStatus.downloadWarn,
        '[!] Exception while loading/parsing $pageUri: $e',
      );
      return null;
    }
  }

  static String gidFromUrl(Uri url) {
    for (final pattern in _gidPatterns) {
      final match = pattern.firstMatch(url.toString());
      if (match != null) return match.group(match.groupCount)!;
    }
    throw FormatException(
        'Expected URL format: https://motherless.com/GIXXXXXXX, got: $url');
  }

  static Uri firstPageUrl(Uri url) {
    final path = url.path;
    if (path.length > 2 && path.startsWith('/G')) {
      final section = path[2];
      if (!RegExp(r'[MIV]').hasMatch(section)) {
        final newPath = '${path.substring(0, 2)}M${path.substring(2)}';
        return url.replace(scheme: 'https', host: domain, path: newPath);
      }
    }
    return url;
  }

  static List<String> pageUrlsFromDocument(Document page) {
    final urls = <String>[];
    for (final thumb
        in page.querySelectorAll('div.thumb-container a.img-container')) {
      final href = thumb.attributes['href'] ?? '';
      if (href.isEmpty || href.contains('pornmd.com')) continue;

      urls.add(href.startsWith('http') ? href : 'https://$domain$href');
    }
    return urls;
  }

  static Uri? extractFileUrl(Document page) {
    final match = RegExp(r"__fileurl = '([^']+)';", dotAll: true)
        .firstMatch(page.outerHtml);
    final file = match?.group(1);
    return file == null ? null : Uri.parse(file);
  }

  static String? canonicalUrl(Document page) {
    return page.querySelector('link[rel="canonical"]')?.attributes['href'];
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
