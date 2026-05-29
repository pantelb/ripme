import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/viewcomic_ripper.dart';

void main() {
  test('ViewcomicRipper matches Java URL detection, host, domain, and GID',
      () async {
    final url = Uri.parse('https://view-comic.com/batman-no-mans-land-vol-1/');
    final ripper = ViewcomicRipper(url);

    expect(ripper.getHost(), 'view-comic');
    expect(ripper.getDomain(), 'view-comic.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://view-comic.com/batman-no-mans-land')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://view-comic.com/batman/issue-1')),
      isFalse,
    );
    expect(await ripper.getGID(url), 'batman-no-mans-land-vol-1');
  });

  test('ViewcomicRipper extracts separator image sources like Java', () {
    final page = html.parse('''
      <div class="separator"><a><img src="https://cdn.example.com/001.jpg"></a></div>
      <div class="pinbin-copy"><a><img src="https://cdn.example.com/readcomic.jpg"></a></div>
    ''');

    expect(ViewcomicRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/001.jpg',
    ]);
  });

  test('ViewcomicRipper applies Java title cleanup', () {
    final page = html.parse(
      '<title>Example_Title | Viewcomic reading comics online for free….</title>',
    );

    expect(ViewcomicRipper.titleFromDocument(page), 'ExampleTitle');
  });

  test('ViewcomicRipper uses Java-style ordered filenames', () {
    expect(
      ViewcomicRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page.jpg'),
        prefix: ViewcomicRipper.prefixForIndex(3),
      ),
      '003_page.jpg',
    );
  });
}
