import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/fitnakedgirls_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java URL detection, host, domain, and GID', () async {
    final ripper = FitnakedgirlsRipper(
      Uri.parse('https://fitnakedgirls.com/photos/gallery/erin-ashford-nude/'),
    );
    final subdomain = Uri.parse(
        'https://www.fitnakedgirls.com/photos/gallery/erin-ashford-nude/');

    expect(ripper.canRip(ripper.url), isTrue);
    expect(ripper.canRip(subdomain), isTrue);
    expect(ripper.getHost(), 'fitnakedgirls');
    expect(ripper.getDomain(), 'fitnakedgirls.com');
    expect(await ripper.getGID(ripper.url), 'erin-ashford-nude/');
  });

  test('extracts entry-inner images preferring data-src over src', () {
    final page = parse('''
      <img src="https://cdn.example/outside.jpg">
      <div class="entry-inner">
        <img data-src="https://cdn.example/data.jpg" src="https://cdn.example/src.jpg">
        <img data-src="   " src="https://cdn.example/fallback.jpg">
        <img data-src="   " src="   ">
      </div>
    ''');

    expect(FitnakedgirlsRipper.imageUrlsFromPage(page), [
      'https://cdn.example/data.jpg',
      'https://cdn.example/fallback.jpg',
    ]);
  });

  test('uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      FitnakedgirlsRipper.fileNameForUrl(
        Uri.parse('https://cdn.fitnakedgirls.com/path/image.jpg?size=large'),
        3,
      ),
      '003_image.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      FitnakedgirlsRipper.fileNameForUrl(
        Uri.parse('https://cdn.fitnakedgirls.com/path/image.jpg'),
        3,
      ),
      'image.jpg',
    );
  });
}
