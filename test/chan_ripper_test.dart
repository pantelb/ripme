import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/chan_ripper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ripme/utils/utils.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
  });

  test('ChanRipper parses Java chan config strings', () {
    final chans = ChanRipper.getChansFromConfig(
      'site1.com[cnd1.site1.com|cdn2.site2.biz],site2.co.uk[cdn.site2.co.uk]',
    )!;

    expect(chans[0].domains, ['site1.com']);
    expect(chans[0].cdnDomains, ['cnd1.site1.com', 'cdn2.site2.biz']);
    expect(chans[1].domains, ['site2.co.uk']);
    expect(chans[1].cdnDomains, ['cdn.site2.co.uk']);
  });

  test('ChanRipper matches Java baked-in chan URLs, hosts, domains, and GIDs',
      () async {
    final cases = [
      (
        Uri.parse('http://desuchan.net/v/res/7034.html'),
        'desuchan_v',
        'desuchan.net',
        '7034',
      ),
      (
        Uri.parse('https://boards.4chan.org/hr/thread/3015701'),
        '4chan_hr',
        'boards.4chan.org',
        '3015701',
      ),
      (
        Uri.parse('http://7chan.org/gif/res/25873.html'),
        '7chan_gif',
        '7chan.org',
        '25873',
      ),
      (
        Uri.parse('https://rbt.asia/g/thread/70643087/'),
        'rbt_g',
        'rbt.asia',
        '70643087',
      ),
      (
        Uri.parse('https://4archive.org/board/hr/thread/2770629'),
        '4archive_board',
        '4archive.org',
        '2770629',
      ),
    ];

    for (final item in cases) {
      final ripper = ChanRipper(item.$1);
      expect(ripper.canRip(item.$1), isTrue, reason: item.$1.toString());
      expect(ripper.getHost(), item.$2, reason: item.$1.toString());
      expect(ripper.getDomain(), item.$3, reason: item.$1.toString());
      expect(await ripper.getGID(item.$1), item.$4, reason: item.$1.toString());
    }
  });

  test('ChanRipper extracts normal 55chan thread IDs', () async {
    final url = Uri.parse('https://55chan.org/b/res/123.html');
    expect(await ChanRipper(url).getGID(url), '123');
  });

  test('ChanRipper supports user configured explicit domains', () async {
    SharedPreferences.setMockInitialValues({
      'chans.chan_sites': 'examplechan.test[cdn.examplechan.test]',
    });
    await Utils.init();

    final url = Uri.parse('https://examplechan.test/a/res/123.html');
    final ripper = ChanRipper(url);

    expect(ripper.canRip(url), isTrue);
    expect(await ripper.getGID(url), '123');
  });

  test('ChanRipper extracts direct media URLs with Java normalization rules',
      () async {
    final ripper = ChanRipper(
      Uri.parse('https://boards.4chan.org/hr/thread/3015701'),
    );
    final page = html.parse('''
      <html><body>
        <a href="//i.4cdn.org/hr/one.jpg">one</a>
        <a href="/hr/two.PNG">two</a>
        <a href="https://i.4cdn.org/hr/one.jpg">dupe after normalization differs</a>
        <a href="https://iqdb.org/?url=https://i.4cdn.org/hr/skip.jpg">skip</a>
        <a href="https://example.com/not-media.txt">skip</a>
      </body></html>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'http://i.4cdn.org/hr/one.jpg',
      'https://i.4cdn.org/hr/one.jpg',
    ]);
  });

  test('ChanRipper expands non-CDN links on explicit archive sites', () async {
    final ripper = ChanRipper(
      Uri.parse('https://desuarchive.org/wsg/thread/2770629'),
    );
    final page = html.parse('''
      <html><body>
        <a href="https://i.imgur.com/example.gifv">gifv</a>
      </body></html>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://i.imgur.com/example.mp4',
    ]);
  });

  test('ChanRipper uses Java-style ordered filenames and video detection', () {
    expect(ChanRipper.prefixForIndex(12), '012_');
    expect(ChanRipper.isVideo(Uri.parse('https://cdn.example.com/a.webm')),
        isTrue);
    expect(
      ChanRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/path/image.jpg'),
        prefix: '012_',
      ),
      '012_image.jpg',
    );
  });
}
