import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class HypnohubRipper extends AbstractHTMLRipper {
  HypnohubRipper(super.url);

  static const String baseUrl = 'https://hypnohub.net';

  @override
  String getHost() => 'hypnohub';

  String getDomain() => 'hypnohub.net';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final query = url.query;
    if (query.isEmpty) {
      throw FormatException('URL missing query: $url');
    }

    if (query.contains('page=pool')) {
      for (final param in query.split('&')) {
        if (param.startsWith('id=')) {
          return param.substring('id='.length);
        }
      }
      throw FormatException('Pool URL missing id: $url');
    }

    if (query.startsWith('page=post')) {
      return query.substring('page='.length);
    }

    throw FormatException('Unexpected URL format for GID: $url');
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
    final downloads = <RipperDownload>[];
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
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

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final pageUrl = url.toString();
    if (pageUrl.contains('page=pool')) {
      return imageUrlsFromPoolDocument(page, fetchPost: ripPostFromUrl);
    }

    if (pageUrl.contains('page=post')) {
      final imageUrl = imageUrlFromPostDocument(page);
      return imageUrl == null ? const [] : [imageUrl];
    }

    return const [];
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static Future<String?> ripPostFromUrl(String postUrl) async {
    final doc = await Http.get(Uri.parse(postUrl));
    return imageUrlFromPostDocument(doc);
  }

  static Future<List<String>> imageUrlsFromPoolDocument(
    Document page, {
    required Future<String?> Function(String postUrl) fetchPost,
  }) async {
    final result = <String>[];
    for (final link in page.querySelectorAll(
      'span.thumb > a[href*="page=post"]',
    )) {
      final href = link.attributes['href'] ?? '';
      if (href.isEmpty) continue;
      final fullPostUrl = href.startsWith('http') ? href : '$baseUrl/$href';
      try {
        final imageUrl = await fetchPost(fullPostUrl);
        if (imageUrl != null) result.add(imageUrl);
      } catch (_) {
        // Java logs and continues when an individual post cannot be fetched.
      }
    }
    return result;
  }

  static String? imageUrlFromPostDocument(Document page) {
    final imageSource = page.querySelector('img#image')?.attributes['src'];
    if (imageSource != null && imageSource.isNotEmpty) {
      return normalizeHypnohubUrl(imageSource);
    }

    for (final link in page.querySelectorAll('a[href]')) {
      if (link.text.trim() != 'Original image') continue;
      final href = link.attributes['href'] ?? '';
      if (href.isNotEmpty) return normalizeHypnohubUrl(href);
    }

    final metaImage =
        page.querySelector('meta[property="og:image"]')?.attributes['content'];
    if (metaImage != null && metaImage.isNotEmpty) {
      return normalizeHypnohubUrl(metaImage);
    }

    return null;
  }

  static String normalizeHypnohubUrl(String source) {
    if (source.startsWith('//')) return 'https:$source';
    if (source.startsWith('/')) return '$baseUrl$source';
    return source;
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
