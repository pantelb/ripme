import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class NfsfwRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern =
      RegExp(r'^https?://[wm.]*nfsfw\.com/gallery/v/(.*)$');
  static final RegExp _subalbumPattern =
      RegExp(r'^https?://[wm.]*nfsfw\.com/gallery/v/[^/]+/(.+)$');

  final List<String> _subalbumURLs = <String>[];
  late final Uri sanitizedUrl = sanitizeUri(url);
  String _currentDir = '';
  int _subalbumIndex = 0;

  NfsfwRipper(super.url);

  @override
  String getHost() => 'nfsfw';

  String getDomain() => 'nfsfw.com';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(sanitizeUri(url).toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(sanitizeUri(url).toString());
    if (match != null) {
      var group = match.group(1)!;
      if (group.endsWith('/')) group = group.substring(0, group.length - 1);
      return group.replaceAll('/', '__');
    }

    throw FormatException(
      'Expected nfsfw.com gallery format: nfsfw.com/v/albumname Got: $url',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    return '${getHost()}_${await getGID(sanitizeUri(url))}';
  }

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) => false;

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return subalbumUrlsFromDocument(page);
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, sanitizedUrl.toString());
    Document page;
    try {
      page = await Http.get(sanitizedUrl);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    if (pageContainsOnlySubalbums(page)) {
      for (final childUrl in subalbumUrlsFromDocument(page)) {
        if (isStopped) break;
        sendUpdate(RipStatus.queueAdd, childUrl);
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    var index = 0;
    while (!isStopped) {
      final imagePageUrls = imagePageUrlsFromDocument(page);
      _subalbumURLs.addAll(subalbumUrlsFromDocument(page));

      final downloads = <RipperDownload>[];
      for (final imagePageUrl in imagePageUrls) {
        if (isStopped) break;
        final imagePageUri = Uri.parse(imagePageUrl);
        final downloadIndex = _currentDir.isEmpty ? ++index : ++_subalbumIndex;
        final download = await downloadFromImagePage(
          imagePageUri,
          index: downloadIndex,
          subdirectory: _currentDir,
          imagePageFetcher: (uri) => Http.get(
            uri,
            headers: {'Referer': uri.toString()},
          ),
        );
        if (download != null) downloads.add(download);
      }
      await downloadFiles(downloads);

      final nextUri = await getNextPage(page);
      if (nextUri == null || isStopped) break;
      await Http.delay(const Duration(seconds: 2));
      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await Http.get(nextUri);
      } catch (e) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    _subalbumURLs.addAll(subalbumUrlsFromDocument(page));
    return imagePageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final nextLink = page.querySelector('a.next')?.attributes['href'];
    if (nextLink != null && nextLink.isNotEmpty) {
      return Uri.parse('http://nfsfw.com$nextLink');
    }

    while (_subalbumURLs.isNotEmpty) {
      final nextURL = _subalbumURLs.removeAt(0);
      final match = _subalbumPattern.firstMatch(nextURL);
      if (match == null) continue;
      _currentDir = match.group(1)!;
      _subalbumIndex = 0;
      return Uri.parse(nextURL);
    }

    return null;
  }

  Future<RipperDownload?> downloadFromImagePage(
    Uri imagePageUrl, {
    required int index,
    required String subdirectory,
    required Future<Document> Function(Uri imagePageUrl) imagePageFetcher,
  }) async {
    Document page;
    try {
      page = await imagePageFetcher(imagePageUrl);
    } catch (_) {
      return null;
    }

    final imageUrl = imageUrlFromImagePage(page);
    if (imageUrl == null) return null;

    final imageUri = Uri.parse(imageUrl);
    final fileName = fileNameForUrl(imageUri, prefix: prefixForIndex(index));
    final safeSubdir = Utils.filesystemSafe(subdirectory);
    final saveAs = safeSubdir.trim().isEmpty
        ? File(p.join(workingDir.path, fileName))
        : File(p.join(workingDir.path, safeSubdir, fileName));
    return RipperDownload(
      url: imageUri,
      saveAs: saveAs,
      headers: {'Referer': imagePageUrl.toString()},
    );
  }

  static Uri sanitizeUri(Uri url) {
    final text = url.toString();
    final queryIndex = text.indexOf('?');
    return queryIndex < 0 ? url : Uri.parse(text.substring(0, queryIndex));
  }

  static bool pageContainsOnlySubalbums(Document page) {
    return imagePageUrlsFromDocument(page).isEmpty &&
        subalbumUrlsFromDocument(page).isNotEmpty;
  }

  static List<String> imagePageUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final thumb in page.querySelectorAll('td.giItemCell > div > a')) {
      final href = thumb.attributes['href'] ?? '';
      result.add('http://nfsfw.com$href');
    }
    return result;
  }

  static List<String> subalbumUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final subalbum in page.querySelectorAll('td.IMG > a')) {
      final href = subalbum.attributes['href'] ?? '';
      result.add('http://nfsfw.com$href');
    }
    return result;
  }

  static String? imageUrlFromImagePage(Document page) {
    final src = page.querySelector('.gbBlock img')?.attributes['src'];
    if (src == null || src.isEmpty) return null;
    if (src.startsWith('/')) return 'http://nfsfw.com$src';
    return src;
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
