import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/allporncomic_ripper.dart';

void main() {
  test('matches Java host and GID behavior', () async {
    final ripper = AllporncomicRipper(Uri.parse(
        'https://allporncomic.com/porncomic/example-title/chapter-1/'));

    expect(
      ripper.canRip(Uri.parse('https://allporncomic.com/porncomic/title/')),
      isTrue,
    );
    expect(ripper.canRip(Uri.parse('https://example.com/porncomic/title/')),
        isFalse);
    expect(ripper.getHost(), 'allporncomic');
    expect(
      await ripper.getGID(Uri.parse(
          'https://allporncomic.com/porncomic/example-title/chapter-1/')),
      'example-title_chapter-1',
    );
    expect(
      await ripper
          .getGID(Uri.parse('https://allporncomic.com/porncomic/title_1/')),
      'title_1',
    );
  });

  test('extracts chapter images from wp-manga data-src attributes', () async {
    final ripper = AllporncomicRipper(Uri.parse(
        'https://allporncomic.com/porncomic/example-title/chapter-1/'));
    final page = html.parse('''
      <html><body>
        <img class="wp-manga-chapter-img" data-src="https://cdn.example/1.jpg">
        <img class="wp-manga-chapter-img" data-src="https://cdn.example/2.jpg">
        <img class="wp-manga-chapter-img">
      </body></html>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://cdn.example/1.jpg',
      'https://cdn.example/2.jpg',
    ]);
  });

  test('queues chapters from comic album pages', () async {
    final ripper = AllporncomicRipper(
        Uri.parse('https://allporncomic.com/porncomic/example-title/'));
    final page = html.parse('''
      <html><body>
        <li class="wp-manga-chapter">
          <a href="https://allporncomic.com/porncomic/example-title/one/">one</a>
        </li>
        <li class="wp-manga-chapter">
          <a href="https://allporncomic.com/porncomic/example-title/two/">two</a>
        </li>
      </body></html>
    ''');

    expect(ripper.hasQueueSupport(), isTrue);
    expect(ripper.pageContainsAlbums(ripper.url), isTrue);
    expect(await ripper.getAlbumsToQueue(page), [
      'https://allporncomic.com/porncomic/example-title/one/',
      'https://allporncomic.com/porncomic/example-title/two/',
    ]);
  });
}
