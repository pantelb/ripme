import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/hqporner_ripper.dart';

void main() {
  test('matches Java host, domain, URL support, and GIDs', () async {
    final ripper = HqpornerRipper(
      Uri.parse(
        'https://hqporner.com/hdporn/84636-pool_lesson_with_a_cheating_husband.html',
      ),
    );

    expect(ripper.canRip(ripper.url), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://hqporner.com/actress/kali-roses')),
      isTrue,
    );
    expect(
      ripper.canRip(Uri.parse('http://hqporner.com/actress/kali-roses')),
      isFalse,
    );
    expect(ripper.getHost(), 'hqporner');
    expect(ripper.getDomain(), 'hqporner.com');
    expect(
      await ripper.getGID(ripper.url),
      '84636-pool_lesson_with_a_cheating_husband',
    );
    expect(
      await ripper.getGID(Uri.parse('https://hqporner.com/actress/kali-roses')),
      'actress',
    );
    expect(await ripper.getGID(Uri.parse('https://hqporner.com/top')), 'top');
  });

  test('extracts listing video URLs and subdirectories like Java', () {
    final page = parse('''
      <div class="6u"><h3><a class="click-trigger" href="/hdporn/one.html">One</a></h3></div>
      <div class="6u"><h3><a class="click-trigger" href="/hdporn/two.html">Two</a></h3></div>
    ''');

    expect(HqpornerRipper.getAllVideoUrls(page), [
      'https://hqporner.com/hdporn/one.html',
      'https://hqporner.com/hdporn/two.html',
    ]);
    expect(
      HqpornerRipper.subdirectoryForListing(
        Uri.parse('https://hqporner.com/category/tattooed'),
      ),
      'tattooed',
    );
    expect(
      HqpornerRipper.subdirectoryForListing(
        Uri.parse('https://hqporner.com/top'),
      ),
      '',
    );
  });

  test('finds next pagination link only when last page link says Next',
      () async {
    final ripper = HqpornerRipper(
      Uri.parse('https://hqporner.com/category/tattooed'),
    );
    final page = parse('''
      <ul class="pagination">
        <li><a href="/category/tattooed/2">2</a></li>
        <li><a href="/category/tattooed/2">Next</a></li>
      </ul>
    ''');

    expect(
      await ripper.getNextPage(page),
      Uri.parse('https://hqporner.com/category/tattooed/2'),
    );
    expect(
      await ripper
          .getNextPage(parse('<ul class="pagination"><a href="/1">1</a></ul>')),
      isNull,
    );
  });

  test('normalizes embed URLs and picks Java best quality order', () {
    expect(
      HqpornerRipper.normalizeProtocolRelative('//flyflv.example/embed'),
      Uri.parse('https://flyflv.example/embed'),
    );
    expect(
      HqpornerRipper.bestQualityLink([
        'https://cdn.example/video_720.mp4',
        'https://cdn.example/video_1080.mp4',
        'https://cdn.example/video_2160.mp4',
      ]),
      'https://cdn.example/video_2160.mp4',
    );
    expect(
      HqpornerRipper.bestQualityLink(['https://cdn.example/video.mp4']),
      'https://cdn.example/video.mp4',
    );
  });
}
