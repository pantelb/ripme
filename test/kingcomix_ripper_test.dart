import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/kingcomix_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, broad URL support, and comic GID', () async {
    final url = Uri.parse('https://kingcomix.com/aunt-cumming-tracy-scops/');
    final ripper = KingcomixRipper(url);

    expect(ripper.getHost(), 'kingcomix');
    expect(ripper.getDomain(), 'kingcomix.com');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(Uri.parse('https://www.kingcomix.com/')), isTrue);
    expect(ripper.canRip(Uri.parse('https://example.com/comic')), isFalse);
    expect(await ripper.getGID(url), 'aunt-cumming-tracy-scops');
    await expectLater(
      ripper
          .getGID(Uri.parse('http://kingcomix.com/aunt-cumming-tracy-scops/')),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(
        Uri.parse('https://kingcomix.com/aunt-cumming-tracy-scops/2'),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://kingcomix.com/aunt-cumming-tracy-0/')),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts entry-content paragraph images like Java', () {
    final page = html.parse('''
      <div class="entry-content">
        <p><img src="https://cdn.example.com/page01.jpg"></p>
        <p><span><img src="https://cdn.example.com/nested.jpg"></span></p>
        <p><img></p>
      </div>
      <section class="entry-content">
        <p><img src="https://cdn.example.com/skip.jpg"></p>
      </section>
    ''');

    expect(KingcomixRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/page01.jpg',
      '',
    ]);
  });

  test('uses Java-style configurable ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(KingcomixRipper.prefixForIndex(9), '009_');
    expect(
      KingcomixRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page01.jpg'),
        prefix: KingcomixRipper.prefixForIndex(9),
      ),
      '009_page01.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(KingcomixRipper.prefixForIndex(9), '');
    expect(
      KingcomixRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/page01.jpg'),
        prefix: KingcomixRipper.prefixForIndex(9),
      ),
      'page01.jpg',
    );
  });
}
