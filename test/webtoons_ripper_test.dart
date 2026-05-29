import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/webtoons_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java Webtoons URL detection and album titles', () async {
    final url = Uri.parse(
      'https://www.webtoons.com/en/drama/lookism/ep-145/viewer?title_no=1049&episode_no=145',
    );
    final superHero = Uri.parse(
      'https://www.webtoons.com/en/super-hero/unordinary/episode-103/viewer?title_no=679&episode_no=109',
    );
    final ripper = WebtoonsRipper(url);

    expect(ripper.getHost(), 'webtoons');
    expect(ripper.getDomain(), 'www.webtoons.com');
    expect(ripper.canRip(url), isTrue);
    expect(ripper.canRip(superHero), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://www.webtoons.com/en/drama/lookism')),
      isFalse,
    );
    expect(await ripper.getAlbumTitle(url), 'webtoons_lookism');
    expect(await WebtoonsRipper(superHero).getAlbumTitle(superHero),
        'webtoons_unordinary');
  });

  test('keeps Java stricter GID regex separate from album title regex',
      () async {
    final drama = Uri.parse(
      'https://www.webtoons.com/en/drama/lookism/ep-145/viewer?title_no=1049&episode_no=145',
    );
    final superHero = Uri.parse(
      'https://www.webtoons.com/en/super-hero/unordinary/episode-103/viewer?title_no=679&episode_no=109',
    );

    expect(await WebtoonsRipper(drama).getGID(drama), 'lookism');
    await expectLater(
      WebtoonsRipper(superHero).getGID(superHero),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts viewer images and strips ?type like Java', () {
    final page = parse('''
      <div class="viewer_img">
        <img data-url="https://cdn.example.com/001.jpg?type=q90">
      </div>
      <div class="viewer_img">
        <img data-url="https://cdn.example.com/002.jpg">
      </div>
      <img data-url="https://cdn.example.com/ignored.jpg?type=q90">
    ''');

    expect(WebtoonsRipper.imageUrlsFromDocument(page), [
      'https://cdn.example.com/001.jpg',
      'https://cdn.example.com/002.jpg',
    ]);
  });

  test('finds next episode link like Java', () async {
    final ripper = WebtoonsRipper(Uri.parse(
      'https://www.webtoons.com/en/drama/lookism/ep-145/viewer?title_no=1049&episode_no=145',
    ));

    expect(
      await ripper.getNextPage(parse(
        '<a class="pg_next" href="https://www.webtoons.com/en/drama/lookism/ep-146/viewer?title_no=1049&episode_no=146">Next</a>',
      )),
      Uri.parse(
        'https://www.webtoons.com/en/drama/lookism/ep-146/viewer?title_no=1049&episode_no=146',
      ),
    );
    expect(await ripper.getNextPage(parse('<a class="pg_next" href="#">')),
        isNull);
    expect(await ripper.getNextPage(parse('<html></html>')), isNull);
  });

  test('uses Java-style ordered filenames', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      WebtoonsRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/001.jpg'),
        WebtoonsRipper.prefixForIndex(3),
      ),
      '003_001.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      WebtoonsRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/001.jpg'),
        WebtoonsRipper.prefixForIndex(3),
      ),
      '001.jpg',
    );
  });
}
