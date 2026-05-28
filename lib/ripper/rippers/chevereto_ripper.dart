import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class CheveretoRipper extends AbstractHTMLRipper {
  static const Map<String, String> consentCookie = {'AGREE_CONSENT': '1'};
  static const List<String> explicitDomains = ['kenzato.uk'];

  static final RegExp _gidPattern = RegExp(
    r'^(?:https?://)?(?:www\.)?[a-z1-9-]*\.[a-z1-9]*(?:[a-zA-Z1-9]*)/album/([a-zA-Z1-9]*)/?$',
  );

  CheveretoRipper(super.url);

  @override
  String getHost() => url.host;

  String getDomain() => url.host;

  @override
  bool canRip(Uri url) => explicitDomains.contains(url.host);

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await getFirstPage();
      final title = albumTitleFromDocument(page);
      if (title != null) return '${getHost()}_$title';
    } catch (_) {
      // Fall through to the default Java host_GID album title.
    }
    return super.getAlbumTitle(url);
  }

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected chevereto URL format: site.domain/album/albumName or site.domain/username/albums- got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await getFirstPage();
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
        page = await Http.get(nextUri, cookies: consentCookie);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() => Http.get(url, cookies: consentCookie);

  @override
  Future<Uri?> getNextPage(Document page) async {
    final nextPage =
        page.querySelector('li.pagination-next > a')?.attributes['href'] ?? '';
    if (nextPage.isEmpty) return null;
    return Uri.parse(nextPage);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  static List<String> imageUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final image in page.querySelectorAll('a.image-container > img')) {
      final source = image.attributes['src'];
      if (source == null || source.isEmpty) continue;
      result.add(source.replaceAll('.md', ''));
    }
    return result;
  }

  static String? albumTitleFromDocument(Document page) {
    final content =
        page.querySelector('meta[property="og:title"]')?.attributes['content'];
    if (content == null) return null;
    final title = content.substring(content.lastIndexOf('/') + 1).trim();
    return title.isEmpty ? null : title;
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
