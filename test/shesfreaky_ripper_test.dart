import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/shesfreaky_ripper.dart';

void main() {
  test('ShesFreakyRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse(
      'http://www.shesfreaky.com/gallery/nicee-snow-bunny-579NbPjUcYa.html',
    );
    final ripper = ShesFreakyRipper(url);

    expect(ripper.getHost(), 'shesfreaky');
    expect(ripper.getDomain(), 'shesfreaky.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://m.shesfreaky.com/gallery/id_123.html')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://shesfreaky.com/galleries/id.html')),
      isFalse,
    );

    expect(await ripper.getGID(url), 'nicee-snow-bunny-579NbPjUcYa');
  });

  test('ShesFreakyRipper keeps Java malformed URL error text', () async {
    final ripper = ShesFreakyRipper(
      Uri.parse('https://shesfreaky.com/galleries/example'),
    );

    expect(
      () => ripper.getGID(ripper.url),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('shesfreaky.com/gallery/...'),
        ),
      ),
    );
  });

  test('ShesFreakyRipper extracts lightbox hrefs with Java https prefix', () {
    final page = html.parse('''
      <a data-lightbox="gallery" href="//img.example.com/one.jpg"></a>
      <a data-lightbox="gallery" href="/relative/two.jpg"></a>
      <a data-lightbox="gallery" href="https://img.example.com/three.jpg"></a>
      <a href="//img.example.com/skip.jpg"></a>
    ''');

    expect(ShesFreakyRipper.imageUrlsFromDocument(page), [
      'https://img.example.com/one.jpg',
      'https:/relative/two.jpg',
      'https:https://img.example.com/three.jpg',
    ]);
  });

  test('ShesFreakyRipper uses Java-style ordered filenames', () {
    expect(
      ShesFreakyRipper.fileNameForUrl(
        Uri.parse('https://img.example.com/path/image.jpg'),
        prefix: ShesFreakyRipper.prefixForIndex(7),
      ),
      '007_image.jpg',
    );
  });
}
