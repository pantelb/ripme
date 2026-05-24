import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/motherless_ripper.dart';

void main() {
  test('MotherlessRipper matches Java GID URL patterns and canRip', () async {
    final cases = {
      'https://motherless.com/GABCDEF1': 'ABCDEF1',
      'https://motherless.com/GMABCDEF1': 'MABCDEF1',
      'https://motherless.com/GIABCDEF1': 'IABCDEF1',
      'https://motherless.com/GVABCDEF1': 'VABCDEF1',
      'https://motherless.com/term/images/search%20term': 'search%20term',
      'https://motherless.com/gi/example-tag_1': 'example-tag_1',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key);
      final ripper = MotherlessRipper(uri);
      expect(ripper.canRip(uri), isTrue, reason: entry.key);
      expect(await ripper.getGID(uri), entry.value, reason: entry.key);
    }

    final invalid = Uri.parse('https://motherless.com/foo');
    expect(MotherlessRipper(invalid).canRip(invalid), isFalse);
  });

  test('MotherlessRipper rewrites gallery home to all uploads', () {
    expect(
      MotherlessRipper.firstPageUrl(
              Uri.parse('https://motherless.com/GABCDEF1'))
          .toString(),
      'https://motherless.com/GMABCDEF1',
    );
    expect(
      MotherlessRipper.firstPageUrl(
              Uri.parse('https://motherless.com/GIABCDEF1'))
          .toString(),
      'https://motherless.com/GIABCDEF1',
    );
  });

  test('MotherlessRipper extracts intermediate image page URLs like Java', () {
    final page = html.parse('''
      <html><body>
        <div class="thumb-container"><a class="img-container" href="/ABCDEF1"></a></div>
        <div class="thumb-container"><a class="img-container" href="https://motherless.com/ABCDEF2"></a></div>
        <div class="thumb-container"><a class="img-container" href="https://pornmd.com/ignored"></a></div>
      </body></html>
    ''');

    expect(MotherlessRipper.pageUrlsFromDocument(page), [
      'https://motherless.com/ABCDEF1',
      'https://motherless.com/ABCDEF2',
    ]);
  });

  test('MotherlessRipper extracts file URLs and pagination metadata', () async {
    final ripper =
        MotherlessRipper(Uri.parse('https://motherless.com/GABCDEF1'));
    final page = html.parse(r'''
      <html><head>
        <link rel="canonical" href="https://motherless.com/GMABCDEF1">
        <link rel="next" href="/GMABCDEF1?page=2">
      </head><body>
        <script>var __fileurl = 'https://cdn.motherlessmedia.com/file.jpg';</script>
      </body></html>
    ''');

    expect(MotherlessRipper.extractFileUrl(page).toString(),
        'https://cdn.motherlessmedia.com/file.jpg');
    expect(MotherlessRipper.canonicalUrl(page),
        'https://motherless.com/GMABCDEF1');
    expect((await ripper.getNextPage(page)).toString(),
        'https://motherless.com/GMABCDEF1?page=2');
  });
}
