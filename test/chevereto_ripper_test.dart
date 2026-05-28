import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/chevereto_ripper.dart';

void main() {
  test('CheveretoRipper matches Java host, domain, canRip, and GID behavior',
      () async {
    final url = Uri.parse('https://kenzato.uk/album/TnEc');
    final subdirUrl = Uri.parse('https://kenzato.uk/booru/album/TnEc');
    final ripper = CheveretoRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(subdirUrl), isTrue);
    expect(ripper.canRip(Uri.parse('https://example.com/album/TnEc')), isFalse);
    expect(ripper.getHost(), 'kenzato.uk');
    expect(ripper.getDomain(), 'kenzato.uk');
    expect(await ripper.getGID(url), 'TnEc');
    await expectLater(
      ripper.getGID(subdirUrl),
      throwsA(isA<FormatException>()),
    );
  });

  test('CheveretoRipper derives Java album title from og:title content', () {
    final page = html.parse('''
      <html><head>
        <meta property="og:title" content="Kenzato / Albums / TnEc">
      </head></html>
    ''');

    expect(CheveretoRipper.albumTitleFromDocument(page), 'TnEc');
    expect(
      CheveretoRipper.albumTitleFromDocument(html.parse('<html></html>')),
      isNull,
    );
  });

  test('CheveretoRipper extracts full-size image URLs from medium thumbnails',
      () {
    final page = html.parse('''
      <html><body>
        <a class="image-container"><img src="https://cdn.example.com/one.md.jpg"></a>
        <a class="image-container"><img src="https://cdn.example.com/two.md.png"></a>
      </body></html>
    ''');

    expect(CheveretoRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/one.jpg',
      'https://cdn.example.com/two.png',
    ]);
  });

  test('CheveretoRipper follows Java pagination selector', () async {
    final ripper = CheveretoRipper(Uri.parse('https://kenzato.uk/album/TnEc'));
    final page = html.parse('''
      <html><body>
        <li class="pagination-next"><a href="https://kenzato.uk/album/TnEc/?page=2">next</a></li>
      </body></html>
    ''');

    expect(
      (await ripper.getNextPage(page)).toString(),
      'https://kenzato.uk/album/TnEc/?page=2',
    );
    expect(await ripper.getNextPage(html.parse('<html></html>')), isNull);
  });

  test('CheveretoRipper uses Java-style ordered filenames', () {
    expect(CheveretoRipper.prefixForIndex(5), '005_');
    expect(
      CheveretoRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/image.jpg'),
        prefix: '005_',
      ),
      '005_image.jpg',
    );
  });
}
