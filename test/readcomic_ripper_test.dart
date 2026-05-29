import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/readcomic_ripper.dart';

void main() {
  test('ReadcomicRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse('https://read-comic.com/comic-name/');
    final ripper = ReadcomicRipper(url);

    expect(ripper.getHost(), 'read-comic');
    expect(ripper.getDomain(), 'read-comic.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://read-comic.com/comic-name')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://www.read-comic.com/comic-name/')),
      isFalse,
    );
    expect(
      ripper.canRip(Uri.parse('https://read-comic.com/comic0/')),
      isFalse,
    );

    expect(await ripper.getGID(url), 'comic-name');
  });

  test('ReadcomicRipper extracts pinbin-copy image sources like Java', () {
    final page = html.parse('''
      <div class="pinbin-copy">
        <a><img src="https://cdn.example.com/001.jpg"></a>
        <a><img src="https://cdn.example.com/002.jpg"></a>
      </div>
      <div class="separator"><a><img src="https://cdn.example.com/view.jpg"></a></div>
    ''');

    expect(ReadcomicRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/001.jpg',
      'https://cdn.example.com/002.jpg',
    ]);
  });

  test('ReadcomicRipper applies inherited Viewcomic title cleanup', () {
    final page = html.parse(
      '<title>Example_Title | Viewcomic reading comics online for free….</title>',
    );

    expect(ReadcomicRipper.titleFromDocument(page), 'ExampleTitle');
  });

  test('ReadcomicRipper uses Java-style ordered filenames', () {
    expect(
      ReadcomicRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page-001.jpg'),
        prefix: ReadcomicRipper.prefixForIndex(4),
      ),
      '004_page-001.jpg',
    );
  });
}
