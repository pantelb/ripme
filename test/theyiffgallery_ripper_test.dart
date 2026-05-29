import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/theyiffgallery_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('TheyiffgalleryRipper matches Java host, domain, support, and GID',
      () async {
    final url = Uri.parse('https://theyiffgallery.com/index?/category/4303');
    final ripper = TheyiffgalleryRipper(url);

    expect(ripper.getHost(), 'theyiffgallery');
    expect(ripper.getDomain(), 'theyiffgallery.com');
    expect(ripper.canRip(url), isTrue);
    expect(
      ripper.canRip(Uri.parse('http://theyiffgallery.com/index?/category/1')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('https://theyiffgallery.com/index?/category/a')),
      isFalse,
    );
    expect(
      ripper.canRip(
          Uri.parse('https://www.theyiffgallery.com/index?/category/1')),
      isFalse,
    );

    expect(await ripper.getGID(url), '4303');
    await expectLater(
      ripper.getGID(Uri.parse('https://theyiffgallery.com/index?/category/a')),
      throwsA(isA<FormatException>()),
    );
  });

  test('TheyiffgalleryRipper rewrites thumbnail paths like Java', () {
    final page = html.parse('''
      <img class="thumbnail" src="/_data/i/galleries/4303/photo-aa_a1x2.jpg">
      <img class="thumbnail" src="/_data/i/galleries/4303/photo-bb_z12x34.png">
      <img class="thumbnail" src="/galleries/4303/full.jpg">
      <img src="/_data/i/galleries/outside-cc_a1x2.jpg">
    ''');

    expect(TheyiffgalleryRipper.imageUrlsFromDocument(page), [
      'https://theyiffgallery.com//galleries/4303/photo.jpg',
      'https://theyiffgallery.com//galleries/4303/photo.png',
      'https://theyiffgallery.com/galleries/4303/full.jpg',
    ]);
  });

  test('TheyiffgalleryRipper follows Java next page span rules', () {
    final withNext = html.parse('''
      <span class="navPrevNext">
        <a href="index?/category/4303/start-15">Next</a>
      </span>
    ''');
    final withoutStart = html.parse('''
      <span class="navPrevNext">
        <a href="index?/category/4303">Current</a>
      </span>
    ''');
    final withoutLink = html.parse('<span class="navPrevNext"></span>');

    expect(
      TheyiffgalleryRipper.nextPageFromDocument(withNext).toString(),
      'https://theyiffgallery.com/index?/category/4303/start-15',
    );
    expect(TheyiffgalleryRipper.nextPageFromDocument(withoutStart), isNull);
    expect(TheyiffgalleryRipper.nextPageFromDocument(withoutLink), isNull);
  });

  test('TheyiffgalleryRipper uses Java-style configurable ordered filenames',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    expect(
      TheyiffgalleryRipper.fileNameForUrl(
        Uri.parse('https://theyiffgallery.com/galleries/4303/photo.jpg'),
        7,
      ),
      '007_photo.jpg',
    );

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      TheyiffgalleryRipper.fileNameForUrl(
        Uri.parse('https://theyiffgallery.com/galleries/4303/photo.jpg'),
        7,
      ),
      'photo.jpg',
    );
  });
}
