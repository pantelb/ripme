import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/myhentaigallery_ripper.dart';

void main() {
  test('MyhentaigalleryRipper matches Java host, domain, support, and GID',
      () async {
    final url = Uri.parse(
      'https://myhentaigallery.com/gallery/thumbnails/9201',
    );
    final ripper = MyhentaigalleryRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://www.myhentaigallery.com/')), isTrue);
    expect(ripper.getHost(), 'myhentaigallery');
    expect(ripper.getDomain(), 'myhentaigallery.com');
    expect(await ripper.getGID(url), '9201');
    await expectLater(
      ripper.getGID(
        Uri.parse('http://myhentaigallery.com/gallery/thumbnails/9201'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('MyhentaigalleryRipper rewrites comic thumbnails to originals', () {
    final page = html.parse('''
      <div class="comic-thumb">
        <img src="https://static.myhentaigallery.com/gallery/9201/thumbnail_001.jpg">
      </div>
      <div class="comic-thumb">
        <img src="https://static.myhentaigallery.com/gallery/9201/page_002.jpg">
      </div>
      <img src="https://static.myhentaigallery.com/gallery/9201/thumbnail_ignored.jpg">
    ''');

    expect(MyhentaigalleryRipper.imageUrlsFromDocument(page), [
      'https://static.myhentaigallery.com/gallery/9201/original_001.jpg',
      'https://static.myhentaigallery.com/gallery/9201/page_002.jpg',
    ]);
  });

  test('MyhentaigalleryRipper uses Java-style ordered filenames', () {
    expect(MyhentaigalleryRipper.prefixForIndex(7), '007_');
    expect(
      MyhentaigalleryRipper.fileNameForUrl(
        Uri.parse(
          'https://static.myhentaigallery.com/gallery/9201/original_001.jpg?x=1',
        ),
        prefix: '007_',
      ),
      '007_original_001.jpg',
    );
  });
}
