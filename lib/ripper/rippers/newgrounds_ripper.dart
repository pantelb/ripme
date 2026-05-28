import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class NewgroundsRipper extends AbstractHTMLRipper {
  static const List<String> allowedExtensions = ['png', 'gif', 'jpeg', 'jpg'];
  static const Map<String, String> ajaxHeaders = {
    'X-Requested-With': 'XMLHttpRequest',
  };
  static final RegExp _gidPattern =
      RegExp(r'^https?://(.+).newgrounds.com/?.*');
  static final RegExp _thumbnailPattern =
      RegExp(r'(.*?)" class.*/thumbnails/(.*?)/(.*?)\.');

  late final String username;
  int pageNumber = 1;
  int count = 0;

  NewgroundsRipper(super.url) {
    username = _usernameFromUrl(url);
  }

  @override
  String getHost() => 'newgrounds';

  String getDomain() => 'newgrounds.com';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected newgrounds.com URL format: username.newgrounds.com/art '
      '- got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, firstPageUrl().toString());
    Document doc;
    try {
      final response =
          await Http.getResponse(firstPageUrl(), defaultTimeoutMs: 10000);
      doc = html.parse(response.body);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    while (true) {
      final imageURLs = await getURLsFromPage(doc);
      final downloads = <RipperDownload>[];
      for (final imageURL in imageURLs) {
        if (isStopped) break;
        index++;
        final imageUri = Uri.parse(imageURL);
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

      if (isStopped || count < 60) break;
      count = 0;
      final nextUri = nextPageUrl();
      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        doc = await Http.get(nextUri, headers: ajaxHeaders);
      } catch (e) {
        break;
      }
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) {
    return imageUrlsFromDocument(
      page,
      username: username,
      detailPageFetcher: (detailUrl) => Http.get(detailUrl),
      onMatch: () => count++,
    ).then((imageUrls) {
      pageNumber++;
      return imageUrls;
    });
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    if (count < 60) return null;
    return nextPageUrl();
  }

  Uri firstPageUrl() => Uri.https('$username.newgrounds.com', '/art');

  Uri nextPageUrl() => Uri.https(
        '$username.newgrounds.com',
        '/art/page/$pageNumber',
      );

  static Future<List<String>> imageUrlsFromDocument(
    Document page, {
    required String username,
    required Future<Document> Function(Uri detailUrl) detailPageFetcher,
    void Function()? onMatch,
  }) async {
    final imageURLs = <String>[];
    final documentHTMLString = page.outerHtml.replaceAll('&quot;', '');
    final findStr = 'newgrounds.com/art/view/$username';
    var lastIndex = 0;
    final indices = <int>[];

    while (lastIndex != -1) {
      lastIndex = documentHTMLString.indexOf(findStr, lastIndex);
      if (lastIndex != -1) {
        onMatch?.call();
        lastIndex += findStr.length;
        indices.add(lastIndex);
      }
    }

    for (var i = 0; i < indices.length; i++) {
      final s = _metadataSlice(documentHTMLString, indices, i)
          .replaceAll('\n', '')
          .replaceAll('\t', '')
          .replaceAll('\\', '');
      final match = _thumbnailPattern.matchAsPrefix(s);
      if (match == null) continue;

      final slug = match.group(1)!.replaceFirst(RegExp(r'^/+'), '');
      final thumbnailDirectory = match.group(2)!;
      final thumbnailId = match.group(3)!;
      final testURL =
          '${thumbnailId}_${username}_$slug'.replaceAll('_full', '');
      final detailUrl = Uri.https(
        'www.newgrounds.com',
        '/art/view/$username/$slug',
      );

      try {
        final imagePage = await detailPageFetcher(detailUrl);
        final imagePageHtml = imagePage.outerHtml;
        for (final extension in allowedExtensions) {
          if (!imagePageHtml.contains('$testURL.$extension')) continue;
          imageURLs.add(
            'https://art.ngfiles.com/images/$thumbnailDirectory/'
            '${thumbnailId.replaceAll('_full', '')}_${username}_$slug.'
            '$extension',
          );
          break;
        }
      } on IOException {
        // Java logs and skips detail pages that fail while checking extensions.
      }
    }

    return imageURLs;
  }

  static String _metadataSlice(String html, List<int> indices, int index) {
    if (index == indices.length - 1) {
      return html.substring(indices[index] + 2);
    }
    return html.substring(indices[index] + 1, indices[index + 1]);
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

  static String _usernameFromUrl(Uri url) {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected newgrounds.com URL format: username.newgrounds.com/art '
      '- got $url instead',
    );
  }
}
