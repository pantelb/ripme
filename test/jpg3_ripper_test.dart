import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/jpg3_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, broad URL support, and split GID', () async {
    final url = Uri.parse('https://jpg3.su/a/abcdef');
    final ripper = Jpg3Ripper(url);

    expect(ripper.getHost(), 'jpg3');
    expect(ripper.getDomain(), 'jpg3.su');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.jpg3.su/a/abcdef')), isTrue);
    expect(ripper.canRip(Uri.parse('https://example.com/a/abcdef')), isFalse);
    expect(await ripper.getGID(url), 'abcdef');
    expect(
        await ripper.getGID(Uri.parse('https://jpg3.su/a/abcdef/')), 'abcdef');
    expect(
      await ripper.getGID(Uri.parse('https://jpg3.su/a/abcdef?sort=1')),
      'abcdef?sort=1',
    );
  });

  test('sanitizes album URLs like Java constructor sanitizeURL', () {
    expect(
      Jpg3Ripper.sanitizeUrl(
        Uri.parse('http://jpg3.su/a/abcdef/extra?ignored=true'),
      ),
      Uri.parse('https://jpg3.su/a/abcdef'),
    );
    expect(
      Jpg3Ripper.sanitizeUrl(Uri.parse('https://jpg3.su/a/abcdef/')),
      Uri.parse('https://jpg3.su/a/abcdef'),
    );
    expect(
      Jpg3Ripper.sanitizeUrl(Uri.parse('https://www.jpg3.su/a/abcdef/')),
      Uri.parse('https://www.jpg3.su/a/abcdef/'),
    );
  });

  test('extracts image-container sources and removes literal .md like Java',
      () {
    final page = html.parse('''
      <div class="image-container">
        <img src="https://i.jpg3.su/images/page01.md.jpg">
        <img src="https://i.jpg3.su/images/.md/page02.md.png">
        <span><img src="https://i.jpg3.su/images/nested.md.jpg"></span>
        <img>
      </div>
      <section class="image-container">
        <img src="https://i.jpg3.su/images/skip.md.jpg">
      </section>
    ''');

    expect(Jpg3Ripper.imageUrlsFromDocument(page), [
      'https://i.jpg3.su/images/page01.jpg',
      'https://i.jpg3.su/images//page02.png',
      '',
      'https://i.jpg3.su/images/skip.jpg',
    ]);
  });

  test('finds data-pagination next href exactly like Java', () async {
    final ripper = Jpg3Ripper(Uri.parse('https://jpg3.su/a/abcdef'));

    expect(
      await ripper.getNextPage(
        html.parse(
            '<a data-pagination="next" href="https://jpg3.su/a/abcdef/2">'),
      ),
      Uri.parse('https://jpg3.su/a/abcdef/2'),
    );
    expect(
      await ripper
          .getNextPage(html.parse('<a data-pagination="prev" href="x">')),
      isNull,
    );
  });

  test('uses Java-style configurable ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(Jpg3Ripper.prefixForIndex(8), '008_');
    expect(
      Jpg3Ripper.fileNameForUrl(
        Uri.parse('https://i.jpg3.su/images/page01.jpg'),
        prefix: Jpg3Ripper.prefixForIndex(8),
      ),
      '008_page01.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(Jpg3Ripper.prefixForIndex(8), '');
    expect(
      Jpg3Ripper.fileNameForUrl(
        Uri.parse('https://i.jpg3.su/images/page01.jpg'),
        prefix: Jpg3Ripper.prefixForIndex(8),
      ),
      'page01.jpg',
    );
  });
}
