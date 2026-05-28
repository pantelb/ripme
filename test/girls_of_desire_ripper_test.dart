import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/girls_of_desire_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final ripper = GirlsOfDesireRipper(
      Uri.parse('http://www.girlsofdesire.org/galleries/krillia/'),
    );

    expect(ripper.canRip(ripper.url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://www.girlsofdesire.org/models/krillia/')),
      isFalse,
    );
    expect(ripper.getHost(), 'GirlsOfDesire');
    expect(ripper.getDomain(), 'girlsofdesire.org');
    expect(await ripper.getGID(ripper.url), 'krillia');
  });

  test('extracts album title from albumName like Java', () {
    final page = parse('<div class="albumName"> Krillia Gallery </div>');

    expect(
      GirlsOfDesireRipper.albumTitleFromPage(page),
      'Krillia Gallery',
    );
    expect(
        GirlsOfDesireRipper.albumTitleFromPage(parse('<main></main>')), isNull);
  });

  test('normalizes thumbnail image URLs like Java', () {
    final page = parse('''
      <table><tr>
        <td class="vtop"><a><img src="/media/krillia/001_thumb.jpg"></a></td>
        <td class="vtop"><a><img src="http://cdn.example/002_thumb.png"></a></td>
      </tr></table>
      <img src="/media/ignored_thumb.jpg">
    ''');

    expect(GirlsOfDesireRipper.imageUrlsFromPage(page), [
      'http://www.girlsofdesire.org/media/krillia/001.jpg',
      'http://cdn.example/002.png',
    ]);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      GirlsOfDesireRipper.fileNameForUrl(
        Uri.parse('http://www.girlsofdesire.org/media/image:name.jpg'),
        3,
      ),
      '003_image',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      GirlsOfDesireRipper.fileNameForUrl(
        Uri.parse('http://www.girlsofdesire.org/media/image.jpg'),
        3,
      ),
      'image.jpg',
    );
  });
}
