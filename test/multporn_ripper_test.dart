import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/multporn_ripper.dart';

void main() {
  test('MultpornRipper matches Java node URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse('https://multporn.net/node/12345/example-comic');
    final ripper = MultpornRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://www.multporn.net/comics/a')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://example.com/node/12345/a')), isFalse);
    expect(ripper.getHost(), 'multporn');
    expect(ripper.getDomain(), 'multporn.net');
    expect(await ripper.getGID(url), '12345');
  });

  test('MultpornRipper resolves simple-mode comic links like Java fallback',
      () {
    final page = html.parse('''
      <html><body>
        <a class="simple-mode-switcher" href="/node/98765/example-comic?mode=simple">
          Simple
        </a>
      </body></html>
    ''');

    final href = MultpornRipper.simpleModeHrefFromDocument(page);
    expect(href, '/node/98765/example-comic?mode=simple');
    expect(MultpornRipper.gidFromNodeHref(href), '98765');
    expect(
      MultpornRipper.canonicalNodeUrlFromHref(href).toString(),
      'https://multporn.net/node/98765/example-comic?mode=simple',
    );
  });

  test('MultpornRipper extracts gallery item hrefs without filtering', () {
    final page = html.parse('''
      <html><body>
        <div class="mfp-gallery-image">
          <a class="mfp-item" href="https://img.multporn.net/one.jpg"></a>
          <a class="mfp-item" href="https://img.multporn.net/two.png?x=1"></a>
          <a class="mfp-item"></a>
        </div>
      </body></html>
    ''');

    expect(MultpornRipper.imageUrlsFromDocument(page), [
      'https://img.multporn.net/one.jpg',
      'https://img.multporn.net/two.png?x=1',
      '',
    ]);
  });

  test('MultpornRipper uses Java-style ordered filenames', () {
    expect(MultpornRipper.prefixForIndex(7), '007_');
    expect(
      MultpornRipper.fileNameForUrl(
        Uri.parse('https://img.multporn.net/path/page.jpg?token=abc#fragment'),
        prefix: '007_',
      ),
      '007_page.jpg',
    );
    expect(
      MultpornRipper.fileNameForUrl(
        Uri.parse('https://img.multporn.net/path/page.jpg&download=1'),
        prefix: '',
      ),
      'page.jpg',
    );
  });
}
