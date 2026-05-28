import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class MyhentaicomicsRipper extends AbstractHTMLRipper {
  static final RegExp _comicPattern =
      RegExp(r'^https?://myhentaicomics\.com/index\.php/([a-zA-Z0-9-]*)/?$');
  static final RegExp _searchPattern = RegExp(
    r'^https?://myhentaicomics\.com/index\.php/search\?q=([a-zA-Z0-9-]*)([a-zA-Z0-9=&]*)?$',
  );
  static final RegExp _tagPattern = RegExp(
    r'^https?://myhentaicomics\.com/index\.php/tag/([0-9]*)/?([a-zA-Z%0-9+?=:]*)?$',
  );
  static final RegExp _nextPagePattern =
      RegExp(r'^/index\.php/[a-zA-Z0-9_-]*\?page=\d$');

  MyhentaicomicsRipper(super.url);

  @override
  String getHost() => 'myhentaicomics';

  String getDomain() => 'myhentaicomics.com';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final comicMatch = _comicPattern.firstMatch(url.toString());
    if (comicMatch != null) return comicMatch.group(1)!;

    final searchMatch = _searchPattern.firstMatch(url.toString());
    if (searchMatch != null) return searchMatch.group(1)!;

    final tagMatch = _tagPattern.firstMatch(url.toString());
    if (tagMatch != null) return tagMatch.group(1)!;

    throw FormatException(
      'Expected myhentaicomics.com URL format: '
      'myhentaicomics.com/index.php/albumName - got $url instead',
    );
  }

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) => isQueuePage(url);

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return albumUrlsFromDocument(page);
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

    if (hasQueueSupport() && pageContainsAlbums(url)) {
      for (final childUrl in await getAlbumsToQueue(page)) {
        if (isStopped) break;
        sendUpdate(RipStatus.queueAdd, childUrl);
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
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
              p.join(
                workingDir.path,
                fileNameForUrl(imageUri, prefix: prefixForIndex(index)),
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

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final next = nextPageUrlFromDocument(page);
    if (next == null) return null;
    await Http.delay(const Duration(milliseconds: 500));
    return next;
  }

  static bool isQueuePage(Uri url) {
    final text = url.toString();
    return _searchPattern.hasMatch(text) || _tagPattern.hasMatch(text);
  }

  static List<String> albumUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final link in page.querySelectorAll('.g-album > a')) {
      final href = link.attributes['href'] ?? '';
      result.add('https://myhentaicomics.com$href');
    }
    return result;
  }

  static List<String> imageUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final image in page.querySelectorAll('img')) {
      var imageSource = image.attributes['src'] ?? '';
      if (!imageSource.startsWith('http://') &&
          !imageSource.startsWith('https://')) {
        imageSource = imageSource.replaceAll('thumbs', 'resizes');
        result.add('https://myhentaicomics.com$imageSource');
      }
    }
    return result;
  }

  static Uri? nextPageUrlFromDocument(Document page) {
    final href = page.querySelector('a.ui-icon-right')?.attributes['href'];
    if (href == null) return null;
    if (!_nextPagePattern.hasMatch(href)) return null;
    return Uri.parse('https://myhentaicomics.com$href');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    var fileName = uri.toString();
    if (fileName.endsWith('/')) {
      fileName = fileName.substring(0, fileName.length - 1);
    }
    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
    final question = fileName.indexOf('?');
    if (question >= 0) fileName = fileName.substring(0, question);
    final hash = fileName.indexOf('#');
    if (hash >= 0) fileName = fileName.substring(0, hash);
    final ampersand = fileName.indexOf('&');
    if (ampersand >= 0) fileName = fileName.substring(0, ampersand);
    if (fileName.isEmpty) fileName = 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
