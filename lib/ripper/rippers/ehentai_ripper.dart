import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class EHentaiRipper extends AbstractHTMLRipper {
  EHentaiRipper(super.url);

  static const String domain = 'e-hentai.org';
  static const Duration pageSleepTime = Duration(seconds: 3);
  static const Duration imageSleepTime = Duration(milliseconds: 1500);
  static const Duration ipBlockSleepTime = Duration(seconds: 60);
  static const Map<String, String> ehCookies = {'nw': '1', 'tip': '1'};
  static final RegExp _gidPattern =
      RegExp(r'^https?://e-hentai\.org/g/([0-9]+)/([a-fA-F0-9]+)/?');
  static final RegExp _manualFilePattern =
      RegExp(r'^http://.*/ehg/image\.php.*&n=([^&]+).*$');

  Uri? _lastUrl;
  Document? _albumDoc;

  @override
  String getHost() => 'e-hentai';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return '${match.group(1)}-${match.group(2)}';
    throw FormatException(
      'Expected e-hentai.org gallery format: http://e-hentai.org/g/####/####/ Got: $url',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      _albumDoc ??= await getPageWithRetries(url);
      final title = _albumDoc!.querySelector('#gn')?.text;
      if (title != null && title.isNotEmpty) return '${getHost()}_$title';
    } catch (_) {
      // Fall back to default Java album naming convention.
    }
    return super.getAlbumTitle(url);
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    Document? page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    var index = 0;
    while (page != null && !isStopped) {
      final downloads = <RipperDownload>[];
      for (final pageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        final download = await downloadFromImagePage(Uri.parse(pageUrl), index);
        if (download != null) downloads.add(download);
        await Http.delay(imageSleepTime);
      }

      if (downloads.isEmpty) {
        sendUpdate(RipStatus.ripErrored, 'No images found at $url');
        break;
      }
      await downloadFiles(downloads);
      if (isStopped) break;

      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await getPageWithRetries(nextUri);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document?> getFirstPage() async {
    _albumDoc ??= await getPageWithRetries(url);
    _lastUrl = url;
    final blacklistedTag = checkTags(
        Utils.getConfigStringList('ehentai.blacklist.tags'),
        tagsFromPage(_albumDoc!));
    if (blacklistedTag != null) {
      sendUpdate(
        RipStatus.downloadWarn,
        'Skipping $url as it contains the blacklisted tag "$blacklistedTag"',
      );
      return null;
    }
    return _albumDoc;
  }

  Future<Document> getPageWithRetries(Uri uri) async {
    var retries = 3;
    while (true) {
      sendUpdate(RipStatus.loadingResource, uri.toString());
      final doc = await Http.get(
        uri,
        headers: {'Referer': url.toString()},
        cookies: ehCookies,
      );
      if (!doc.outerHtml.contains('IP address will be automatically banned')) {
        return doc;
      }
      if (retries == 0) {
        throw const HttpException(
          'Hit rate limit and maximum number of retries, giving up',
        );
      }
      retries--;
      await Http.delay(ipBlockSleepTime);
    }
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final links = page.querySelectorAll('.ptt a');
    if (links.isEmpty) return null;

    final href = links.last.attributes['href'];
    if (href == null || href.isEmpty) return null;
    final nextUrl = Uri.parse(href);
    if (_lastUrl != null && nextUrl.toString() == _lastUrl.toString()) {
      return null;
    }

    await Http.delay(pageSleepTime);
    _lastUrl = nextUrl;
    return nextUrl;
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imagePageUrlsFromGallery(page);
  }

  static List<String> imagePageUrlsFromGallery(Document page) {
    return [
      for (final thumb in page.querySelectorAll('#gdt > a'))
        if ((thumb.attributes['href'] ?? '').isNotEmpty)
          thumb.attributes['href']!,
    ];
  }

  Future<RipperDownload?> downloadFromImagePage(
      Uri imagePageUrl, int index) async {
    try {
      final doc = await getPageWithRetries(imagePageUrl);
      final imageUrl = imageUrlFromPage(doc);
      if (imageUrl == null) return null;
      final uri = Uri.parse(imageUrl);
      return RipperDownload(
        url: uri,
        saveAs: File(p.join(workingDir.path, downloadFileName(uri, index))),
      );
    } catch (_) {
      return null;
    }
  }

  static String? imageUrlFromPage(Document page) {
    var image = page.querySelector('.sni > a > img');
    image ??= page.querySelector('img#img');
    final src = image?.attributes['src'];
    if (src == null || src.isEmpty) return null;
    return src;
  }

  static List<String> tagsFromPage(Document page) {
    return [
      for (final tag in page.querySelectorAll('td > div > a')) tag.text,
    ];
  }

  static String? checkTags(List<String> blacklist, List<String> tags) {
    final normalizedTags = tags.map((tag) => tag.toLowerCase()).toSet();
    for (final tag in blacklist) {
      if (normalizedTags.contains(tag.toLowerCase())) return tag;
    }
    return null;
  }

  static String downloadFileName(Uri uri, int index) {
    final manualMatch = _manualFilePattern.firstMatch(uri.toString());
    if (manualMatch != null) {
      return Utils.sanitizeSaveAs('${_prefix(index)}${manualMatch.group(1)!}');
    }

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
