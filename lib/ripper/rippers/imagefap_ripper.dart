import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class ImagefapRipper extends AbstractHTMLRipper {
  static const int retryLimit = 10;
  static const int httpRetryLimit = 3;
  static const int rateLimitHour = 1000;
  static const Duration pageSleepTime =
      Duration(milliseconds: 60 * 60 * 1000 ~/ rateLimitHour);
  static const Duration imageSleepTime =
      Duration(milliseconds: 60 * 60 * 1000 ~/ rateLimitHour);
  static const Duration ipBlockSleepTime =
      Duration(milliseconds: 60 * 60 * 1000 ~/ (retryLimit - 1));
  static const String rateLimitMessage =
      'Your IP made too many requests to our servers and we need to check that you are a real human being';

  static final List<RegExp> _gidPatterns = [
    RegExp(r'^.*imagefap\.com/gallery\.php\?pgid=([a-f0-9]+).*$'),
    RegExp(r'^.*imagefap\.com/gallery\.php\?gid=([0-9]+).*$'),
    RegExp(r'^.*imagefap\.com/gallery/([a-f0-9]+).*$'),
    RegExp(r'^.*imagefap\.com/pictures/([a-f0-9]+).*$'),
  ];

  int _callsMade = 0;
  final DateTime _startTime = DateTime.now().toUtc();
  Document? _firstPage;

  ImagefapRipper(super.url);

  @override
  String getHost() => 'imagefap';

  @override
  bool canRip(Uri url) => url.host.endsWith('imagefap.com');

  @override
  Future<String> getGID(Uri url) async => gidFromUrl(url);

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final title =
          (await _cachedFirstPage()).head?.querySelector('title')?.text ??
              (await _cachedFirstPage()).querySelector('title')?.text ??
              '';
      if (title.isNotEmpty) {
        return albumTitleFromPageTitle(title, await getGID(url));
      }
    } catch (_) {
      // Fall back to the default host_GID album title.
    }
    return super.getAlbumTitle(url);
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, 'Loading first page...');

    Document page;
    try {
      page = await _cachedFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;

    while (!isStopped) {
      final urls = await getURLsFromPage(page);
      for (final imageUrl in urls) {
        if (isStopped) break;
        index++;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(RipperDownload(
          url: imageUri,
          saveAs: File(p.join(
            workingDir.path,
            fileNameForUrl(imageUri, prefix: prefixForIndex(index)),
          )),
          headers: {'Referer': url.toString()},
        ));
      }

      if (isStopped) break;

      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        await Http.delay(pageSleepTime);
        sendUpdate(
            RipStatus.loadingResource, 'Loading next page URL: $nextUri');
        page = await getPageWithRetries(nextUri);
      } catch (_) {
        break;
      }
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final imageUrls = <String>[];

    for (final thumb in page.querySelectorAll('#gallery img')) {
      if (isStopped) break;
      if (!thumb.attributes.containsKey('src') ||
          !thumb.attributes.containsKey('width')) {
        continue;
      }

      final href = thumb.parent?.attributes['href'];
      if (href == null || href.isEmpty) continue;

      final pageUrl = Uri.parse('https://www.imagefap.com$href');
      var image = await getFullSizedImage(pageUrl);
      if (image == null) {
        for (var i = 0; i < httpRetryLimit; i++) {
          image = await getFullSizedImage(pageUrl);
          if (image != null) break;
          await Http.delay(pageSleepTime);
        }
        if (image == null) {
          throw StateError(
            'Unable to extract image URL from single image page! Unable to continue',
          );
        }
      }

      imageUrls.add(image);
    }

    return imageUrls;
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    for (final link in page.querySelectorAll('a.link3')) {
      if (!link.text.contains('next')) continue;

      final href = link.attributes['href'];
      if (href == null || href.isEmpty) return null;
      return Uri.parse('${sanitizeUrl(url)}$href');
    }
    return null;
  }

  Future<String?> getFullSizedImage(Uri pageUrl) async {
    try {
      await Http.delay(imageSleepTime);
      final doc = await getPageWithRetries(pageUrl);
      return fullSizedImageFromDocument(doc);
    } catch (e) {
      return null;
    }
  }

  Future<Document> _cachedFirstPage() async {
    return _firstPage ??= await getPageWithRetries(sanitizeUrl(url));
  }

  Future<Document> getPageWithRetries(Uri uri) async {
    var retries = retryLimit;

    while (true) {
      sendUpdate(RipStatus.loadingResource, uri.toString());
      _callsMade++;
      checkRateLimit();

      Document? doc;
      var httpCallThrottled = false;
      var httpAttempts = 0;

      while (true) {
        httpAttempts++;
        try {
          doc = await Http.get(uri);
        } catch (e) {
          if (e.toString().contains('404')) {
            throw const HttpException('Gallery/Page not found!');
          }

          if (httpAttempts < httpRetryLimit) {
            sendUpdate(
              RipStatus.downloadWarn,
              'HTTP call failed: $e retrying $httpAttempts / $httpRetryLimit',
            );
            await Http.delay(pageSleepTime);
            continue;
          }

          sendUpdate(
            RipStatus.downloadWarn,
            'HTTP call failed too many times: $e treating this as a throttle',
          );
          httpCallThrottled = true;
        }
        break;
      }

      if (httpCallThrottled ||
          (doc != null && doc.outerHtml.contains(rateLimitMessage))) {
        if (retries == 0) {
          throw const HttpException(
            'Hit rate limit and maximum number of retries, giving up',
          );
        }
        final message =
            'Probably hit rate limit while loading $uri, sleeping for ${ipBlockSleepTime.inMilliseconds}ms, $retries retries remaining';
        sendUpdate(RipStatus.downloadWarn, message);
        retries--;
        await Http.delay(ipBlockSleepTime);
      } else if (doc != null) {
        return doc;
      }
    }
  }

  int checkRateLimit() {
    final duration = DateTime.now().toUtc().difference(_startTime);
    if (duration.inSeconds < 60) {
      return 100 - _callsMade;
    }
    if (duration.inSeconds < 300) {
      return 200 - _callsMade;
    }
    if (duration.inSeconds < 3600) {
      return rateLimitHour - _callsMade;
    }
    return 0;
  }

  static String gidFromUrl(Uri url) {
    for (final pattern in _gidPatterns) {
      final match = pattern.firstMatch(url.toString());
      if (match != null) return match.group(1)!;
    }
    throw FormatException(
      'Expected imagefap.com gallery formats: imagefap.com/gallery.php?gid=####... or imagefap.com/pictures/####... Got: $url',
    );
  }

  static Uri sanitizeUrl(Uri url) {
    final gid = gidFromUrl(url);
    return Uri.parse('https://www.imagefap.com/pictures/$gid/random-string');
  }

  static String? fullSizedImageFromDocument(Document doc) {
    final framedPhotoUrl =
        doc.querySelector('img#mainPhoto')?.attributes['data-src'];
    if (framedPhotoUrl == null || framedPhotoUrl.isEmpty) return null;

    final noQueryPhotoUrl = framedPhotoUrl.split('?').first;
    for (final link in doc.querySelectorAll('ul.thumbs > li > a')) {
      final framed = link.attributes['framed'] ?? '';
      if (framed.startsWith(noQueryPhotoUrl)) {
        final href = link.attributes['href'];
        if (href != null && href.isNotEmpty) return href;
      }
    }
    return null;
  }

  static String albumTitleFromPageTitle(String title, String gid) {
    final normalized =
        title.replaceAll('Porn Pics & Porn GIFs', '').replaceAll(' ', '_');
    return 'imagefap_${normalized}_$gid'.replaceAll(RegExp(r'__+'), '_');
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
