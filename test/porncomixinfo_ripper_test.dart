import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/porncomixinfo_ripper.dart';

void main() {
  test('PorncomixinfoRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse(
      'https://porncomixinfo.net/chapter/comic-title/chapter-title/',
    );
    final ripper = PorncomixinfoRipper(url);

    expect(ripper.getHost(), 'porncomixinfo');
    expect(ripper.getDomain(), 'porncomixinfo.net');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(
        Uri.parse(
            'http://porncomixinfo.net/chapter/comic-title/chapter-title/'),
      ),
      isFalse,
    );
    expect(
      ripper.canRip(
        Uri.parse('https://www.porncomixinfo.net/chapter/comic/chapter/'),
      ),
      isFalse,
    );
    expect(
      ripper.canRip(
        Uri.parse('https://porncomixinfo.net/chapter/comic0/chapter/'),
      ),
      isFalse,
    );

    expect(await ripper.getGID(url), 'comic-title');
  });

  test('PorncomixinfoRipper extracts chapter images like Java', () {
    final page = html.parse('''
      <html><body>
        <img class="wp-manga-chapter-img" src="https://cdn.example.com/001.jpg">
        <img class="wp-manga-chapter-img" src="https://cdn.example.com/002.jpg">
        <img src="https://cdn.example.com/outside.jpg">
      </body></html>
    ''');

    expect(PorncomixinfoRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/001.jpg',
      'https://cdn.example.com/002.jpg',
    ]);
  });

  test('PorncomixinfoRipper follows Java next-page behavior', () {
    final page = html.parse(
      '<a class="next_page" href="https://porncomixinfo.net/chapter/comic/2/">Next</a>',
    );
    final emptyHrefPage = html.parse('<a class="next_page" href="">Next</a>');
    final noNextPage = html.parse('<html><body></body></html>');

    expect(
      PorncomixinfoRipper.nextPageUrl(page).toString(),
      'https://porncomixinfo.net/chapter/comic/2/',
    );
    expect(PorncomixinfoRipper.nextPageUrl(emptyHrefPage), isNull);
    expect(PorncomixinfoRipper.nextPageUrl(noNextPage), isNull);
  });

  test('PorncomixinfoRipper uses Java-style ordered filenames', () {
    expect(
      PorncomixinfoRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page-001.jpg'),
        prefix: PorncomixinfoRipper.prefixForIndex(8),
      ),
      '008_page-001.jpg',
    );
  });
}
