import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class HitomiRipper extends AbstractHTMLRipper {
  HitomiRipper(super.url);

  static final RegExp _gidPattern =
      RegExp(r'^https://hitomi\.la/(cg|doujinshi|gamecg|manga)/(.+).html$');

  String _galleryId = '';

  @override
  String getHost() => 'hitomi';

  String getDomain() => 'hitomi.la';

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) {
      _galleryId = match.group(1)!;
      return match.group(1)!;
    }
    throw FormatException(
      'Expected hitomi URL format: https://hitomi.la/(cg|doujinshi|gamecg|manga)/ID.html - got $url instead',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await Http.get(url);
      return '${getHost()}_${await getGID(url)}_${albumTitleFromPage(page)}';
    } catch (_) {
      return super.getAlbumTitle(url);
    }
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      await getGID(url);
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
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

  Future<Document> getFirstPage() => Http.get(firstPageUrl(url));

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromGalleryInfo(page.text ?? '', _galleryId);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static Uri firstPageUrl(Uri url) {
    return Uri.parse(
      url.toString().replaceAll('hitomi', 'ltn.hitomi').replaceAll(
            '.html',
            '.js',
          ),
    );
  }

  static String albumTitleFromPage(Document page) {
    return page
        .querySelectorAll('title')
        .map((element) => element.text)
        .join(' ')
        .replaceAll(
          RegExp(r' - Read Online - hentai artistcg \| Hitomi\.la'),
          '',
        );
  }

  static List<String> imageUrlsFromGalleryInfo(String text, String galleryId) {
    final jsonText = text.replaceAll('var galleryinfo =', '').trim();
    final data = jsonDecode(jsonText) as List<dynamic>;
    return [
      for (final item in data.cast<Map<String, dynamic>>())
        'https://ba.hitomi.la/galleries/$galleryId/${item['name']}',
    ];
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
