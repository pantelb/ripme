import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/zizki_ripper.dart';

void main() {
  test('matches Java Zizki host and GID parsing', () async {
    final uri = Uri.parse('http://zizki.com/dee-chorde/we-got-spirit');
    final ripper = ZizkiRipper(uri);

    expect(ripper.getHost(), 'zizki');
    expect(ripper.getDomain(), 'zizki.com');
    expect(ripper.canRip(uri), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.zizki.com/dee-chorde/gallery')),
      isTrue,
    );
    expect(ripper.canRip(Uri.parse('https://cdn.zizki.com/dee')), isFalse);
    expect(await ripper.getGID(uri), 'dee-chorde');
  });

  test('extracts Java album title from title and creator elements', () {
    final page = parse('''
      <h1 class="title">We Got Spirit</h1>
      <span class="creator"><a>Dee Chorde</a></span>
    ''');

    expect(
      ZizkiRipper.albumTitleFromDocument(page),
      'zizki_Dee Chorde_We Got Spirit',
    );
  });

  test('extracts colorbox foaf images and rewrites medium to large', () {
    final page = parse('''
      <a class="colorbox gallery"
         href="https://zizki.com/sites/default/files/styles/medium/public/one.jpg">
        <img typeof="foaf:Image" src="/thumb/one.jpg">
      </a>
      <a class="colorbox"
         href="https://cdn.example.com/sites/default/files/styles/medium/public/two.jpg">
        <img typeof="foaf:Image" src="/thumb/two.jpg">
      </a>
      <a class="other"
         href="https://zizki.com/sites/default/files/styles/medium/public/three.jpg">
        <img typeof="foaf:Image" src="/thumb/three.jpg">
      </a>
      <a class="colorbox"
         href="https://zizki.com/sites/default/files/styles/medium/public/four.jpg">
        <img src="/thumb/four.jpg">
      </a>
    ''');

    expect(ZizkiRipper.imageUrlsFromDocument(page), [
      'https://zizki.com/sites/default/files/styles/large/public/one.jpg',
    ]);
  });

  test('uses Java forced ordered filenames and response cookie parsing', () {
    expect(
      ZizkiRipper.fileNameForUrl(
        Uri.parse('https://zizki.com/sites/default/files/full.jpg'),
        prefix: ZizkiRipper.prefix(7),
      ),
      '007_full.jpg',
    );
    expect(
      ZizkiRipper.cookiesFromSetCookieHeader(
        'session=abc; Path=/; HttpOnly, pref=dark; Secure',
      ),
      {'session': 'abc', 'pref': 'dark'},
    );
  });
}
