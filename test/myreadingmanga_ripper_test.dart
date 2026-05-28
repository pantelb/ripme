import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/myreadingmanga_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('MyreadingmangaRipper matches Java host, domain, support, and GID',
      () async {
    final url = Uri.parse(
      'https://myreadingmanga.info/zelo-lee-brave-lover-dj-slave-market-jp/',
    );
    final ripper = MyreadingmangaRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.myreadingmanga.info/title/')),
      isTrue,
    );
    expect(ripper.getHost(), 'myreadingmanga');
    expect(ripper.getDomain(), 'myreadingmanga.info');
    expect(await ripper.getGID(url), 'zelo-lee-brave-lover-dj-slave-market-jp');
    expect(
      await ripper.getGID(
        Uri.parse('https://myreadingmanga.info/title_with_underscores/'),
      ),
      'title_with_underscores',
    );
    await expectLater(
      ripper.getGID(
        Uri.parse('http://myreadingmanga.info/zelo-lee-brave-lover/'),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(
        Uri.parse('https://myreadingmanga.info/title/extra/'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('MyreadingmangaRipper extracts data-lazy-src images like Java', () {
    final page = html.parse('''
      <div>
        <p>
          <img data-lazy-src="https://cdn.example/one.jpg" src="thumb.jpg">
        </p>
      </div>
      <section>
        <img data-lazy-src="https://cdn.example/ignored.jpg">
      </section>
      <div>
        <span>
          <img data-lazy-src="https://cdn.example/two.png">
        </span>
      </div>
      <div>
        <img src="https://cdn.example/no-lazy.jpg">
      </div>
    ''');

    expect(MyreadingmangaRipper.imageUrlsFromDocument(page), [
      'https://cdn.example/one.jpg',
      'https://cdn.example/two.png',
    ]);
  });

  test('MyreadingmangaRipper uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(MyreadingmangaRipper.prefixForIndex(7), '007_');
    expect(
      MyreadingmangaRipper.fileNameForUrl(
        Uri.parse('https://cdn.example/pages/001.jpg?size=large'),
        prefix: MyreadingmangaRipper.prefixForIndex(7),
      ),
      '007_001.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(MyreadingmangaRipper.prefixForIndex(7), '');
  });
}
