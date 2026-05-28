import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/imagevenue_ripper.dart';

void main() {
  test('matches Java host, domain, broad URL support, and gallery GID',
      () async {
    final url = Uri.parse(
      'http://img120.imagevenue.com/galshow.php?gal=gallery_1373818527696_191lo',
    );
    final ripper = ImagevenueRipper(url);

    expect(ripper.getHost(), 'imagevenue');
    expect(ripper.getDomain(), 'imagevenue.com');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://imagevenue.com/anything')), isTrue);
    expect(ripper.canRip(Uri.parse('https://example.com/galshow.php?gal=x')),
        isFalse);
    expect(await ripper.getGID(url), 'gallery_1373818527696_191lo');
    await expectLater(
      ripper.getGID(Uri.parse('https://imagevenue.com/not-gallery')),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts target-blank image page links like Java', () {
    final page = html.parse('''
      <a target="_blank" href="http://img120.imagevenue.com/img.php?image=one">one</a>
      <a target="_self" href="http://img120.imagevenue.com/img.php?image=skip">skip</a>
      <a target="_blank">missing</a>
    ''');

    expect(ImagevenueRipper.imagePageUrlsFromDocument(page), [
      'http://img120.imagevenue.com/img.php?image=one',
    ]);
  });

  test('builds direct image URL from image page host and nested image src', () {
    final imagePageUrl = Uri.parse(
      'http://img120.imagevenue.com/img.php?image=sample',
    );

    expect(
      ImagevenueRipper.directImageUrlFromDocument(
        html.parse('<a><img src="loc123/image.jpg"></a>'),
        imagePageUrl,
      ),
      'http://img120.imagevenue.com/loc123/image.jpg',
    );
    expect(
      ImagevenueRipper.directImageUrlFromDocument(
        html.parse('<a><img src="/loc123/image.jpg"></a>'),
        imagePageUrl,
      ),
      'http://img120.imagevenue.com//loc123/image.jpg',
    );
    expect(
      ImagevenueRipper.directImageUrlFromDocument(
        html.parse('<img src="not-nested.jpg">'),
        imagePageUrl,
      ),
      isNull,
    );
  });

  test('uses Java-style ordered filenames', () {
    expect(ImagevenueRipper.prefixForIndex(7), '007_');
    expect(
      ImagevenueRipper.fileNameForUrl(
        Uri.parse('http://img120.imagevenue.com/loc123/image.jpg'),
        prefix: '007_',
      ),
      '007_image.jpg',
    );
  });
}
