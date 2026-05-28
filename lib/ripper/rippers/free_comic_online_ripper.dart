import 'package:html/dom.dart';

import '../../utils/http_utils.dart';
import '../abstract_html_ripper.dart';

class FreeComicOnlineRipper extends AbstractHTMLRipper {
  FreeComicOnlineRipper(super.url);

  static const String domain = 'freecomiconline.me';
  static const Duration pageDelay = Duration(milliseconds: 500);
  static final RegExp _chapterPattern = RegExp(
      r'https://freecomiconline\.me/comic/([a-zA-Z0-9_\-]+)/([a-zA-Z0-9_\-]+)/?$');
  static final RegExp _comicPattern =
      RegExp(r'^https://freecomiconline\.me/comic/([a-zA-Z0-9_\-]+)/?$');

  @override
  String getHost() => 'freecomiconline';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) {
    final text = url.toString();
    return _chapterPattern.hasMatch(text) || _comicPattern.hasMatch(text);
  }

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    final chapter = _chapterPattern.firstMatch(text);
    if (chapter != null) return '${chapter.group(1)}_${chapter.group(2)}';

    final comic = _comicPattern.firstMatch(text);
    if (comic != null) return comic.group(1)!;

    throw FormatException(
      'Expected freecomiconline URL format: freecomiconline.me/TITLE/CHAPTER - got $url instead',
    );
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final links = page.querySelectorAll('div.select-pagination a');
    if (links.length <= 1) return null;

    final href = links[1].attributes['href'] ?? '';
    final match = _chapterPattern.firstMatch(href);
    if (match == null) return null;

    await Http.delay(pageDelay);
    return Uri.parse(match.group(0)!);
  }

  static List<String> imageUrlsFromPage(Document page) {
    return [
      for (final image in page.querySelectorAll('.wp-manga-chapter-img'))
        image.attributes['src'] ?? '',
    ];
  }
}
