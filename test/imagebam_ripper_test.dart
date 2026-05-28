import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/imagebam_ripper.dart';

void main() {
  test('matches Java host, domain, broad URL support, and GID quirk', () async {
    final galleryUrl = Uri.parse(
      'http://www.imagebam.com/gallery/488cc796sllyf7o5srds8kpaz1t4m78i',
    );
    final viewUrl = Uri.parse('https://m.imagebam.com/view/ME123ABC');
    final ripper = ImagebamRipper(galleryUrl);

    expect(ripper.getHost(), 'imagebam');
    expect(ripper.getDomain(), 'imagebam.com');
    expect(ripper.canRip(galleryUrl), isTrue);
    expect(ripper.canRip(Uri.parse('https://imagebam.com/anything')), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://example.com/gallery/abc')), isFalse);
    expect(await ripper.getGID(galleryUrl), 'gallery');
    expect(await ripper.getGID(viewUrl), 'view');
    await expectLater(
      ripper.getGID(Uri.parse('https://imagebam.com/not-supported/abc')),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts gallery title like Java', () {
    expect(
      ImagebamRipper.albumTitleFromDocument(
        html.parse('<div id="gallery-name"> Example Gallery </div>'),
      ),
      'Example Gallery',
    );
    expect(
      ImagebamRipper.albumTitleFromDocument(
        html.parse('<div id="gallery-name">   </div>'),
      ),
      isNull,
    );
  });

  test('extracts thumbnail image page links while skipping footera links', () {
    final page = html.parse('''
      <div><a class="thumbnail" href="https://www.imagebam.com/view/ME1">one</a></div>
      <div><a class="thumbnail footera" href="https://www.imagebam.com/view/skip">skip</a></div>
      <section><a class="thumbnail" href="https://www.imagebam.com/view/not-direct-child">skip</a></section>
      <div><a class="other" href="https://www.imagebam.com/view/ME2">skip</a></div>
    ''');

    expect(ImagebamRipper.imagePageUrlsFromDocument(page), [
      'https://www.imagebam.com/view/ME1',
    ]);
  });

  test('finds next page using adjacent pagination links', () async {
    final ripper = ImagebamRipper(
      Uri.parse(
          'http://www.imagebam.com/gallery/488cc796sllyf7o5srds8kpaz1t4m78i'),
    );
    final page = html.parse('''
      <a class="pagination_current" href="/gallery/example/1">1</a>
      <a class="pagination_link" href="/gallery/example/2">2</a>
    ''');

    expect(
      await ripper.getNextPage(page),
      Uri.parse('http://www.imagebam.com/gallery/example/2'),
    );
    expect(await ripper.getNextPage(html.parse('<html></html>')), isNull);
  });

  test('extracts main-image URLs and uses Java-style ordered filenames', () {
    expect(
      ImagebamRipper.directImageUrlFromDocument(
        html.parse(
            '<img class="main-image large" src="https://images.example/full.jpg">'),
      ),
      'https://images.example/full.jpg',
    );
    expect(
      ImagebamRipper.directImageUrlFromDocument(
        html.parse('<img class="main-image" src="//images.example/full.jpg">'),
      ),
      'https://images.example/full.jpg',
    );
    expect(
        ImagebamRipper.directImageUrlFromDocument(html.parse('<html></html>')),
        isNull);
    expect(ImagebamRipper.prefixForIndex(7), '007_');
    expect(
      ImagebamRipper.fileNameForUrl(
        Uri.parse('https://images.example/path/full.jpg'),
        prefix: '007_',
      ),
      '007_full.jpg',
    );
  });
}
