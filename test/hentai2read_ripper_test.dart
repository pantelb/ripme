import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/hentai2read_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, queue support, and GIDs', () async {
    final chapter = Hentai2readRipper(
      Uri.parse('https://hentai2read.com/sm_school_memorial/1/'),
    );
    final root = Hentai2readRipper(
      Uri.parse('https://hentai2read.com/sm_school_memorial/'),
    );

    expect(chapter.canRip(chapter.url), isTrue);
    expect(root.canRip(root.url), isTrue);
    expect(chapter.getHost(), 'hentai2read');
    expect(chapter.getDomain(), 'hentai2read.com');
    expect(chapter.hasQueueSupport(), isTrue);
    expect(chapter.pageContainsAlbums(chapter.url), isFalse);
    expect(root.pageContainsAlbums(root.url), isTrue);
    expect(await chapter.getGID(chapter.url), 'sm_school_memorial_1');
  });

  test('extracts chapter queue URLs like Java', () async {
    final page = parse('''
      <ul class="nav-chapters">
        <li><div class="media"><a href="https://hentai2read.com/title/1/">one</a></div></li>
        <li><div class="media"><a href="https://hentai2read.com/title/2/">two</a></div></li>
      </ul>
    ''');

    expect(Hentai2readRipper.chapterUrlsFromPage(page), [
      'https://hentai2read.com/title/1/',
      'https://hentai2read.com/title/2/',
    ]);
  });

  test('discovers thumbnail page links from reader controls', () {
    final primary = parse('''
      <div class="col-xs-12"><div class="reader-controls"><div class="controls-block">
        <button><a href="https://hentai2read.com/title/1/thumbnails/">thumbs</a></button>
      </div></div></div>
    ''');
    final fallback = parse('''
      <a data-original-title="Thumbnails" href="https://hentai2read.com/title/2/thumbnails/">thumbs</a>
    ''');

    expect(
      Hentai2readRipper.thumbnailPageUrlFromReader(primary),
      'https://hentai2read.com/title/1/thumbnails/',
    );
    expect(
      Hentai2readRipper.thumbnailPageUrlFromReader(fallback),
      'https://hentai2read.com/title/2/thumbnails/',
    );
  });

  test('normalizes thumbnail image URLs like Java', () {
    final page = parse('''
      <div class="block-content"><div><div class="img-container"><a>
        <img class="img-responsive" src="//hentaicdn.com/hentai/title/thumbnails/tmb001.jpg">
      </a></div></div></div>
    ''');

    expect(Hentai2readRipper.imageUrlsFromPage(page), [
      'https://static.hentaicdn.com/hentai/title/001.jpg',
    ]);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      Hentai2readRipper.fileNameForUrl(
        Uri.parse('https://static.hentaicdn.com/hentai/title/image:name.jpg'),
        4,
      ),
      '004_image',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      Hentai2readRipper.fileNameForUrl(
        Uri.parse('https://static.hentaicdn.com/hentai/title/image.jpg'),
        4,
      ),
      'image.jpg',
    );
  });
}
