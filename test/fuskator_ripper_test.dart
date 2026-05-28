import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/rippers/fuskator_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java URL sanitization, host, domain, and GIDs', () async {
    final thumbs = FuskatorRipper(Uri.parse(
      'https://fuskator.com/thumbs/hqt6pPXAf9z/Shaved-Blonde-Babe.html',
    ));
    final expanded = FuskatorRipper(Uri.parse(
      'https://fuskator.com/expanded/hsrzk~UIFmJ/Blonde-Babe.html',
    ));

    expect(
      FuskatorRipper.sanitizeUri(Uri.parse(
        'https://fuskator.com/thumbs/hqt6pPXAf9z/Shaved-Blonde-Babe.html',
      )).toString(),
      'https://fuskator.com/full/hqt6pPXAf9z/Shaved-Blonde-Babe.html',
    );
    expect(
      FuskatorRipper.sanitizeUri(Uri.parse(
        'https://fuskator.com/expanded/hsrzk~UIFmJ/Blonde-Babe.html',
      )).toString(),
      'https://fuskator.com/full/hsrzk~UIFmJ/Blonde-Babe.html',
    );
    expect(thumbs.canRip(thumbs.url), isTrue);
    expect(expanded.canRip(expanded.url), isTrue);
    expect(thumbs.getHost(), 'fuskator');
    expect(thumbs.getDomain(), 'fuskator.com');
    expect(await thumbs.getGID(thumbs.url), 'hqt6pPXAf9z');
    expect(await expanded.getGID(expanded.url), 'hsrzk~UIFmJ');
  });

  test('extracts protocol-relative image URLs from gallery JSON', () {
    expect(
        FuskatorRipper.imageUrlsFromJson({
          'images': [
            {'imageUrl': '//static.fuskator.com/1.jpg'},
            {'imageUrl': '//static.fuskator.com/2.png'},
            {'ignored': true},
          ],
        }),
        [
          'https://static.fuskator.com/1.jpg',
          'https://static.fuskator.com/2.png',
        ]);
  });

  test('parses response cookies and builds Java-style cookie headers', () {
    final cookies = FuskatorRipper.cookiesFromSetCookieHeader(
      'sid=abc; Path=/; HttpOnly, pref=light; Expires=Wed, 21 Oct 2030 07:28:00 GMT; Path=/',
    );

    expect(cookies, {'sid': 'abc', 'pref': 'light'});
    expect(FuskatorRipper.cookieHeader(cookies), 'sid=abc; pref=light');
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      FuskatorRipper.fileNameForUrl(
        Uri.parse('https://static.fuskator.com/full/image:name.jpg?download'),
        12,
      ),
      '012_image',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      FuskatorRipper.fileNameForUrl(
        Uri.parse('https://static.fuskator.com/full/image.jpg'),
        12,
      ),
      'image.jpg',
    );
  });
}
