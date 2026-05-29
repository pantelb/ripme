import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/porncomix_ripper.dart';

void main() {
  test('PorncomixRipper matches Java URL detection, host, domain, and GID',
      () async {
    final ripper = PorncomixRipper(
      Uri.parse('http://www.porncomix.info/lust-unleashed-desire-to-submit/'),
    );

    expect(ripper.getHost(), 'porncomix');
    expect(ripper.getDomain(), 'porncomix.info');
    expect(
      ripper.canRip(
        Uri.parse('http://www.porncomix.info/lust-unleashed-desire-to-submit/'),
      ),
      isTrue,
    );
    expect(ripper.canRip(Uri.parse('https://www.porncomix.info/')), isTrue);
    expect(
      ripper.canRip(
        Uri.parse('https://porncomix.info/lust-unleashed-desire-to-submit/'),
      ),
      isFalse,
    );
    expect(
      ripper.canRip(Uri.parse('https://www.porncomix.info/comic/page/2/')),
      isFalse,
    );

    expect(
      await ripper.getGID(
        Uri.parse('http://www.porncomix.info/lust-unleashed-desire-to-submit/'),
      ),
      'lust-unleashed-desire-to-submit',
    );
  });

  test('PorncomixRipper extracts lazy gallery images like Java', () {
    final page = html.parse('''
      <html><body>
        <div class="single-post">
          <div class="gallery">
            <dl><dt><a><img data-lazy-src="https://cdn.example.com/page-001-150x200.jpg"></a></dt></dl>
            <dl><dt><a><img data-lazy-src="https://cdn.example.com/page-002-999x888.png"></a></dt></dl>
          </div>
        </div>
        <img data-lazy-src="https://cdn.example.com/outside-150x200.jpg">
      </body></html>
    ''');

    expect(PorncomixRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/page-001.jpg',
      'https://cdn.example.com/page-002.png',
    ]);
  });

  test('PorncomixRipper only removes Java three-digit thumbnail sizes', () {
    expect(
      PorncomixRipper.stripThumbnailSize(
        'https://cdn.example.com/page-001-150x200.jpg',
      ),
      'https://cdn.example.com/page-001.jpg',
    );
    expect(
      PorncomixRipper.stripThumbnailSize(
        'https://cdn.example.com/page-001-50x200.jpg',
      ),
      'https://cdn.example.com/page-001-50x200.jpg',
    );
  });

  test('PorncomixRipper uses Java-style ordered filenames', () {
    expect(
      PorncomixRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page-001.jpg'),
        prefix: PorncomixRipper.prefixForIndex(3),
      ),
      '003_page-001.jpg',
    );
  });
}
