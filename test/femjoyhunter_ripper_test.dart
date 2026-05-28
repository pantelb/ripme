import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/femjoyhunter_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java URL detection, host, domain, and GID', () async {
    final ripper = FemjoyhunterRipper(Uri.parse(
        'https://www.femjoyhunter.com/alisa-i-got-nice-big-breasts-and-fine-ass-so-she-seems-to-be-a-hottest-brunette-5936/'));

    expect(ripper.canRip(ripper.url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://femjoyhunter.com/no-www/')),
      isFalse,
    );
    expect(ripper.getHost(), 'femjoyhunter');
    expect(ripper.getDomain(), 'femjoyhunter.com');
    expect(
      await ripper.getGID(ripper.url),
      'alisa-i-got-nice-big-breasts-and-fine-ass-so-she-seems-to-be-a-hottest-brunette-5936',
    );
  });

  test('extracts all image src attributes like Java', () {
    final page = parse('''
      <main>
        <img src="https://cdn.femjoyhunter.com/one.jpg">
        <picture><img src="https://cdn.femjoyhunter.com/two.jpg"></picture>
        <img data-src="https://cdn.femjoyhunter.com/ignored.jpg">
      </main>
    ''');

    expect(FemjoyhunterRipper.imageUrlsFromPage(page), [
      'https://cdn.femjoyhunter.com/one.jpg',
      'https://cdn.femjoyhunter.com/two.jpg',
      '',
    ]);
  });

  test('uses Java download referer and ordered filenames', () async {
    expect(
      FemjoyhunterRipper.downloadReferer,
      'https://a2h6m3w6.ssl.hwcdn.net/',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      FemjoyhunterRipper.fileNameForUrl(
        Uri.parse('https://cdn.femjoyhunter.com/path/image.jpg?size=large'),
        2,
      ),
      '002_image.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      FemjoyhunterRipper.fileNameForUrl(
        Uri.parse('https://cdn.femjoyhunter.com/path/image.jpg'),
        2,
      ),
      'image.jpg',
    );
  });
}
