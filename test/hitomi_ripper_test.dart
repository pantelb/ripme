import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/hitomi_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, URL support, and GID behavior', () async {
    final ripper = HitomiRipper(
      Uri.parse('https://hitomi.la/manga/example-gallery-123.html'),
    );

    expect(ripper.canRip(ripper.url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://hitomi.la/galleries/975973.html')),
      isFalse,
    );
    expect(
      ripper.canRip(Uri.parse('http://hitomi.la/manga/example.html')),
      isFalse,
    );
    expect(ripper.getHost(), 'hitomi');
    expect(ripper.getDomain(), 'hitomi.la');
    expect(await ripper.getGID(ripper.url), 'manga');
  });

  test('constructs ltn.hitomi JavaScript page URLs like Java', () {
    expect(
      HitomiRipper.firstPageUrl(
        Uri.parse('https://hitomi.la/cg/example-gallery-123.html'),
      ),
      Uri.parse('https://ltn.hitomi.la/cg/example-gallery-123.js'),
    );
  });

  test('strips the Java title suffix only', () {
    final page = parse('''
      <html><head><title>Example Title - Read Online - hentai artistcg | Hitomi.la</title></head></html>
    ''');

    expect(HitomiRipper.albumTitleFromPage(page), 'Example Title');
  });

  test('extracts galleryinfo image names using Java CDN path behavior', () {
    const galleryInfo = '''
      var galleryinfo = [
        {"name":"001.jpg"},
        {"name":"002.png"}
      ]
    ''';

    expect(HitomiRipper.imageUrlsFromGalleryInfo(galleryInfo, 'manga'), [
      'https://ba.hitomi.la/galleries/manga/001.jpg',
      'https://ba.hitomi.la/galleries/manga/002.png',
    ]);
  });

  test('uses Java-style ordered filename prefixes', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      HitomiRipper.fileNameForUrl(
        Uri.parse('https://ba.hitomi.la/galleries/manga/001.jpg'),
        prefix: HitomiRipper.prefixForIndex(12),
      ),
      '012_001.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      HitomiRipper.fileNameForUrl(
        Uri.parse('https://ba.hitomi.la/galleries/manga/001.jpg'),
        prefix: HitomiRipper.prefixForIndex(12),
      ),
      '001.jpg',
    );
  });
}
