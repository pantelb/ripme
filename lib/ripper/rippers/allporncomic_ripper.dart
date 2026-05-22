import 'package:html/dom.dart';

import '../abstract_html_ripper.dart';

class AllporncomicRipper extends AbstractHTMLRipper {
  AllporncomicRipper(super.url);

  static final RegExp _chapterUrl = RegExp(
      r'^https?://allporncomic\.com/porncomic/([a-zA-Z0-9_-]+)/([a-zA-Z0-9_-]+)/?$');
  static final RegExp _comicUrl =
      RegExp(r'^https?://allporncomic\.com/porncomic/([a-zA-Z0-9_-]+)/?$');

  @override
  String getHost() => 'allporncomic';

  @override
  bool canRip(Uri url) => url.host.endsWith('allporncomic.com');

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    final chapter = _chapterUrl.firstMatch(text);
    if (chapter != null) {
      return '${chapter.group(1)}_${chapter.group(2)}';
    }

    final comic = _comicUrl.firstMatch(text);
    if (comic != null) {
      return comic.group(1)!;
    }

    throw FormatException(
        'Expected allporncomic URL format: allporncomic.com/TITLE/CHAPTER - got $url instead');
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return page
        .querySelectorAll('.wp-manga-chapter-img')
        .map((element) => element.attributes['data-src'] ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) => _comicUrl.hasMatch(url.toString());

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return page
        .querySelectorAll('.wp-manga-chapter > a')
        .map((element) => element.attributes['href'] ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
