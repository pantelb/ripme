import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/xcartx_ripper.dart';

void main() {
  test('matches Java Xcartx host support and GID parsing', () async {
    final uri = Uri.parse('http://xcartx.com/4937-tokimeki-nioi.html');
    final ripper = XcartxRipper(uri);

    expect(ripper.getHost(), 'xcartx');
    expect(ripper.getDomain(), 'xcartx.com');
    expect(ripper.canRip(uri), isTrue);
    expect(await ripper.getGID(uri), '4937-tokimeki-nioi');

    final invalid = Uri.parse('http://xcartx.com/4937-tokimeki-nioi');
    expect(ripper.canRip(invalid), isTrue);
    await expectLater(
      ripper.getGID(invalid),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts f-desc data-src image URLs like Java', () {
    final page = parse('''
      <div class="f-desc">
        <img data-src="/uploads/001.jpg">
        <img data-src="/uploads/002.jpg">
        <img src="/ignored.jpg">
      </div>
    ''');

    expect(XcartxRipper.imageUrlsFromDocument(page), [
      'https://xcartx.com/uploads/001.jpg',
      'https://xcartx.com/uploads/002.jpg',
      'https://xcartx.com',
    ]);
  });

  test('always uses Java forced ordered filename prefixes', () {
    expect(
      XcartxRipper.fileNameForUrl(
        Uri.parse('https://xcartx.com/uploads/001.jpg'),
        3,
      ),
      '003_001.jpg',
    );
  });
}
