import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/free_comic_online_ripper.dart';

void main() {
  test('matches Java URL detection, host, domain, and GIDs', () async {
    final chapter = FreeComicOnlineRipper(Uri.parse(
        'https://freecomiconline.me/comic/perfect-half-hentai0003/chapter-01/'));
    final comic = FreeComicOnlineRipper(
        Uri.parse('https://freecomiconline.me/comic/perfect-half-hentai0003/'));

    expect(chapter.canRip(chapter.url), isTrue);
    expect(
      chapter.canRip(Uri.parse('http://freecomiconline.me/comic/title/')),
      isFalse,
    );
    expect(chapter.getHost(), 'freecomiconline');
    expect(chapter.getDomain(), 'freecomiconline.me');
    expect(
      await chapter.getGID(chapter.url),
      'perfect-half-hentai0003_chapter-01',
    );
    expect(await comic.getGID(comic.url), 'perfect-half-hentai0003');
  });

  test('extracts chapter image sources like Java', () {
    final page = parse('''
      <img class="wp-manga-chapter-img" src="https://cdn.example/001.jpg">
      <img class="wp-manga-chapter-img" data-src="https://cdn.example/ignored.jpg">
    ''');

    expect(FreeComicOnlineRipper.imageUrlsFromPage(page), [
      'https://cdn.example/001.jpg',
      '',
    ]);
  });

  test('uses the second select-pagination link for next chapter', () async {
    final ripper = FreeComicOnlineRipper(Uri.parse(
        'https://freecomiconline.me/comic/perfect-half-hentai0003/chapter-01/'));
    final page = parse('''
      <div class="select-pagination">
        <a href="https://freecomiconline.me/comic/perfect-half-hentai0003/chapter-01/">prev</a>
        <a href="https://freecomiconline.me/comic/perfect-half-hentai0003/chapter-02/">next</a>
      </div>
    ''');

    expect(
      (await ripper.getNextPage(page)).toString(),
      'https://freecomiconline.me/comic/perfect-half-hentai0003/chapter-02/',
    );
    expect(await ripper.getNextPage(parse('<main></main>')), isNull);
  });
}
