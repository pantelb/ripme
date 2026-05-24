import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class NhentaiRipper extends AbstractHTMLRipper {
  static final RegExp _galleryPattern =
      RegExp(r'^https?://nhentai\.net/g/(\d+).*$');
  static final RegExp _tagPattern =
      RegExp(r'^https?://nhentai\.net/tag/([a-zA-Z0-9_\-]+)/?');

  Document? _firstPage;

  NhentaiRipper(super.url);

  @override
  String getHost() => 'nhentai';

  @override
  bool canRip(Uri url) => url.host.endsWith('nhentai.net');

  @override
  Future<String> getGID(Uri url) async {
    final match = _galleryPattern.firstMatch(url.toString());
    if (match == null) {
      throw FormatException(
        'Expected nhentai.net URL format: nhentai.net/g/albumid - got $url instead',
      );
    }
    return match.group(1)!;
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await _cachedFirstPage(url);
      final title = albumTitleFromDocument(page);
      if (title != null) return title;
    } catch (_) {
      // Fall back to the default Java-style host_GID name.
    }
    return super.getAlbumTitle(url);
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await _cachedFirstPage(url);
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

    final blacklistedTag = firstBlacklistedTag(
      Utils.getConfigStringList('nhentai.blacklist.tags'),
      getTags(page),
    );
    if (blacklistedTag != null) {
      sendUpdate(
        RipStatus.downloadWarn,
        'Skipping $url as it contains the blacklisted tag "$blacklistedTag"',
      );
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    final imageUrls = await getURLsFromPage(page);
    final downloads = <RipperDownload>[];
    for (var i = 0; i < imageUrls.length; i++) {
      if (isStopped) break;
      final imageUri = Uri.parse(imageUrls[i]);
      downloads.add(RipperDownload(
        url: imageUri,
        saveAs: File(p.join(
          workingDir.path,
          fileNameForUrl(imageUri, prefix: prefixForIndex(i + 1)),
        )),
        headers: {'Referer': url.toString()},
      ));
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) => _tagPattern.hasMatch(url.toString());

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return [
      for (final elem in page.querySelectorAll('a.cover'))
        if ((elem.attributes['href'] ?? '').isNotEmpty)
          'https://nhentai.net${elem.attributes['href']}',
    ];
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  Future<Document> _cachedFirstPage(Uri uri) async {
    return _firstPage ??= await Http.get(uri);
  }

  static String? albumTitleFromDocument(Document page) {
    final title = page.querySelector('#info > h1')?.text;
    if (title == null || title.isEmpty) return null;
    return 'nhentai$title';
  }

  static List<String> getTags(Document page) {
    return [
      for (final tag in page.querySelectorAll('a.tag'))
        (tag.attributes['href'] ?? '')
            .replaceAll('/tag/', '')
            .replaceAll('/', ''),
    ];
  }

  static String? firstBlacklistedTag(
    List<String> blacklistedTags,
    List<String> tags,
  ) {
    for (final tag in tags) {
      if (blacklistedTags.contains(tag)) return tag;
    }
    return null;
  }

  static List<String> imageUrlsFromDocument(Document page) {
    return [
      for (final img in page.querySelectorAll('a.gallerythumb > img'))
        if ((img.attributes['data-src'] ?? '').isNotEmpty)
          thumbnailToImageUrl(img.attributes['data-src']!),
    ];
  }

  static String thumbnailToImageUrl(String thumbnail) {
    return thumbnail.replaceAll('://t', '://i').replaceAll(RegExp(r't\.'), '.');
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
