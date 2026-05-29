import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/xcartx_ripper.dart';
import 'package:ripme/ripper/rippers/xlecx_ripper.dart';

void main() {
  test('matches Java Xlecx host support and GID parsing', () async {
    final uri =
        Uri.parse('http://xlecx.org/4274-black-canary-ravished-prey.html');
    final ripper = XlecxRipper(uri);

    expect(ripper.getHost(), 'xlecx');
    expect(ripper.getDomain(), 'xlecx.org');
    expect(ripper.canRip(uri), isTrue);
    expect(
      ripper.canRip(
        Uri.parse('http://xlecx.com/4274-black-canary-ravished-prey.html'),
      ),
      isFalse,
    );
    expect(await ripper.getGID(uri), '4274-black-canary-ravished-prey');

    await expectLater(
      ripper.getGID(
        Uri.parse('http://xlecx.com/4274-black-canary-ravished-prey.html'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('inherits Xcartx image extraction and filenames like Java', () async {
    final ripper = XlecxRipper(
      Uri.parse('http://xlecx.org/4274-black-canary-ravished-prey.html'),
    );
    final page = parse('''
      <div class="f-desc">
        <img data-src="/uploads/001.jpg">
      </div>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://xcartx.com/uploads/001.jpg',
    ]);
    expect(
      XcartxRipper.fileNameForUrl(
        Uri.parse('https://xlecx.org/uploads/001.jpg'),
        1,
      ),
      '001_001.jpg',
    );
  });
}
