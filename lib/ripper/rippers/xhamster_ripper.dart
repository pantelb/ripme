import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class XhamsterRipper extends AbstractHTMLRipper {
  static const String domain = 'xhamster.com';
  static final RegExp _galleryPattern = RegExp(
    r'^https?://([\w\w]*\.)?xhamster([^<]*)\.(com|desi)/photos/gallery/.*?(\d+)$',
  );
  static final RegExp _userPattern = RegExp(
    r'^https?://[\w\w.]*xhamster([^<]*)\.(com|desi)/users/([a-zA-Z0-9_-]+)/(photos|videos)(/\d+)?',
  );
  static final RegExp _videoPattern = RegExp(
    r'^https?://.*xhamster([^<]*)\.(com|desi)/(movies|videos)/(.*$)',
  );
  static final RegExp _mobileHostPattern =
      RegExp(r'https?://\w?\w?\.?xhamster([^<]*)\.');
  static final RegExp _redirectHostPattern = RegExp(r'://xhamster([^<]*)\.');

  XhamsterRipper(Uri url) : super(sanitizeUrl(url));

  @override
  String getHost() => 'xhamster';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) {
    final text = url.toString();
    return _galleryPattern.hasMatch(text) ||
        _userPattern.hasMatch(text) ||
        _videoPattern.hasMatch(text);
  }

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    final galleryMatch = _galleryPattern.firstMatch(text);
    if (galleryMatch != null) return galleryMatch.group(4)!;

    final userMatch = _userPattern.firstMatch(text);
    if (userMatch != null) return 'user_${userMatch.group(1)!}';

    final videoMatch = _videoPattern.firstMatch(text);
    if (videoMatch != null) return videoMatch.group(4)!;

    throw FormatException(
      'Expected xhamster.com gallery formats: '
      'xhamster.com/photos/gallery/xxxxx-##### Got: $url',
    );
  }

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) => _userPattern.hasMatch(url.toString());

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return albumUrlsFromDocument(page);
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await Http.get(sanitizeUrl(url));
      final title = albumTitleFromDocument(page, sanitizeUrl(url));
      if (title != null) return title;
    } catch (_) {
      // Java falls back to the inherited host_GID name when title lookup fails.
    }
    return super.getAlbumTitle(url);
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
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(imageUrl);
        await downloadFiles([
          RipperDownload(
            url: uri,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForUrl(uri, prefix: prefix(index)),
              ),
            ),
          ),
        ]);
      }

      if (isStopped) break;
      final next = await getNextPage(page);
      if (next == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, next.toString());
        page = await Http.get(next);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    if (isVideoUrl(url)) return videoUrlsFromDocument(page);

    if (usesOldGalleryStructure(page)) {
      final results = <String>[];
      for (final imagePageUrl in oldImagePageUrlsFromDocument(page)) {
        if (isStopped) break;
        try {
          final imagePage = await Http.get(Uri.parse(imagePageUrl));
          final image = imageFromOldImagePage(imagePage);
          if (image != null) results.add(image);
        } catch (_) {
          continue;
        }
      }
      return results;
    }

    return newGalleryUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => nextPageUrl(page);

  static Uri sanitizeUrl(Uri url) {
    if (isVideoUrl(url)) return url;
    return Uri.parse(
      url.toString().replaceAllMapped(
            _mobileHostPattern,
            (match) => 'https://m.xhamster${match.group(1)}.',
          ),
    );
  }

  static bool isVideoUrl(Uri url) => _videoPattern.hasMatch(url.toString());

  static List<String> albumUrlsFromDocument(Document page) {
    return [
      for (final link in page.querySelectorAll('div.item-container > a.item'))
        link.attributes['href'] ?? '',
    ];
  }

  static bool usesOldGalleryStructure(Document page) {
    return page
        .querySelectorAll(
          'div.picture_view > div.pictures_block > div.items > div.item-container > a.item',
        )
        .isNotEmpty;
  }

  static List<String> oldImagePageUrlsFromDocument(Document page) {
    return [
      for (final link in page.querySelectorAll('.clearfix > div > a.slided'))
        mobileRedirectUrl(link.attributes['href'] ?? ''),
    ];
  }

  static String? imageFromOldImagePage(Document page) {
    final source = page.querySelector('a > img#photoCurr')?.attributes['src'];
    return source == null || source.isEmpty ? null : source;
  }

  static List<String> newGalleryUrlsFromDocument(Document page) {
    return [
      for (final link
          in page.querySelectorAll('div#photo-slider > div#photo_slider > a'))
        mobileRedirectUrl(link.attributes['href'] ?? ''),
    ];
  }

  static List<String> videoUrlsFromDocument(Document page) {
    final href =
        page.querySelector('div.player-container > a')?.attributes['href'];
    if (href == null || href.isEmpty) return const [];
    return [href];
  }

  static Uri? nextPageUrl(Document page) {
    if (page.querySelector('a.prev-next-list-link') == null) return null;
    final next = page.querySelector('a.prev-next-list-link--next');
    final href = next?.attributes['href'] ?? '';
    if (!href.startsWith('http')) return null;
    return Uri.parse(
      href.replaceAllMapped(
        _mobileHostPattern,
        (match) => 'https://m.xhamster${match.group(1)}.',
      ),
    );
  }

  static String? albumTitleFromDocument(Document page, Uri url) {
    final username = page.querySelector('a.author')?.text ?? '';
    if (username.isEmpty) return null;
    final match = RegExp(r'^/photos/gallery/(.*)$').firstMatch(url.path);
    if (match == null) return null;
    return 'xhamster_${username}_${match.group(1)!}';
  }

  static String mobileRedirectUrl(String url) {
    return url.replaceAllMapped(
      _redirectHostPattern,
      (match) => '://m.xhamster${match.group(1)}.',
    );
  }

  static String prefix(int index) => '${index.toString().padLeft(3, '0')}_';

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
