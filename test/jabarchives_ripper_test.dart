import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/jabarchives_ripper.dart';

void main() {
  test('matches Java host, domain, broad URL support, and view GID', () async {
    final url = Uri.parse('https://jabarchives.com/main/view/example_album');
    final ripper = JabArchivesRipper(url);

    expect(ripper.getHost(), 'jabarchives');
    expect(ripper.getDomain(), 'jabarchives.com');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.jabarchives.com/')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://example.com/main/view/id')), isFalse);
    expect(await ripper.getGID(url), 'example_album');
    expect(
      await ripper.getGID(
        Uri.parse('http://www.jabarchives.com/main/view/ABC_123?page=2'),
      ),
      'ABC_123',
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://foo.jabarchives.com/main/view/ABC_123')),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts content images, rewrites thumbs, and stores title prefixes',
      () {
    final prefixes = <String, String>{};
    final page = html.parse('''
      <main id="contentMain">
        <a title="Café Hero 01!"><img src="/media/thumb/page01.jpg"></a>
        <a title="Two  Spaces"><span><img src="/thumbs/thumb_page02.png"></span></a>
      </main>
      <img src="/media/thumb/outside.jpg">
    ''');

    final urls = JabArchivesRipper.imageUrlsFromDocument(page, prefixes);

    expect(urls, [
      'https://jabarchives.com/media/large/page01.jpg',
      'https://jabarchives.com/larges/large_page02.png',
    ]);
    expect(prefixes, {
      'https://jabarchives.com/media/large/page01.jpg': 'cafe-hero-01_',
      'https://jabarchives.com/larges/large_page02.png': '_',
    });
  });

  test('builds Java-style slug strings', () {
    expect(JabArchivesRipper.getSlug('Café Hero 01!'), 'cafe-hero-01');
    expect(JabArchivesRipper.getSlug('Hello\tWorld_2'), 'hello-world_2');
    expect(JabArchivesRipper.getSlug('A/B (C)'), 'ab-c');
  });

  test('constructs next page URL with Java hardcoded host prefix', () async {
    final ripper = JabArchivesRipper(
      Uri.parse('https://jabarchives.com/main/view/example_album'),
    );

    expect(
      await ripper.getNextPage(
        html.parse('<a title="Next page" href="/main/view/example_album/2">'),
      ),
      Uri.parse('https://jabarchives.com/main/view/example_album/2'),
    );
    expect(
      await ripper.getNextPage(
        html.parse('<a title="Previous page" href="/main/view/example_album">'),
      ),
      isNull,
    );
    expect(
      await ripper.getNextPage(
        html.parse('<a title="Next page" href="https://example.com/next">'),
      ),
      Uri.parse('https://jabarchives.comhttps://example.com/next'),
    );
  });

  test('uses title slug prefixes for filenames', () {
    expect(
      JabArchivesRipper.fileNameForUrl(
        Uri.parse('https://jabarchives.com/media/large/page01.jpg'),
        prefix: 'cafe-hero-01_',
      ),
      'cafe-hero-01_page01.jpg',
    );
  });
}
