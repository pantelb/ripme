import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/chan_ripper.dart';
import 'package:ripme/ripper/rippers/redgifs_ripper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ripme/utils/utils.dart';

void main() {
  setUp(() async {
    ChanRipper.resetExplicitDomainsForTesting();
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
  });

  tearDown(() {
    RedgifsRipper.getJsonForTesting = null;
    RedgifsRipper.resetAuthTokenForTesting();
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

  test('ChanSite keeps Java malformed config exceptions', () {
    expect(
      () => ChanSite([]),
      throwsA(isA<ArgumentError>().having(
        (error) => error.message,
        'message',
        'Domains',
      )),
    );
    expect(
      () => ChanSite(['site.example'], []),
      throwsA(isA<ArgumentError>().having(
        (error) => error.message,
        'message',
        'CdnDomains',
      )),
    );
    expect(
      () => ChanRipper.getChansFromConfig(''),
      throwsA(isA<ArgumentError>().having(
        (error) => error.message,
        'message',
        'Domains',
      )),
    );
    expect(
      () => ChanRipper.getChansFromConfig('[]'),
      throwsA(isA<ArgumentError>().having(
        (error) => error.message,
        'message',
        'Domains',
      )),
    );

    final emptyCdn = ChanRipper.getChansFromConfig('site.example[]')!.single;
    expect(emptyCdn.domains, ['site.example']);
    expect(emptyCdn.cdnDomains, ['']);
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

  test('ChanRipper getHost keeps Java split-index board behavior', () {
    expect(
      ChanRipper(Uri.parse('https://boards.4chan.org/hr/thread/3015701'))
          .getHost(),
      '4chan_hr',
    );

    expect(
      () => ChanRipper(Uri.parse('https://boards.4chan.org')).getHost(),
      throwsRangeError,
    );
    expect(
      () => ChanRipper(Uri.parse('https://boards.4chan.org/')).getHost(),
      throwsRangeError,
    );
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

  test('ChanRipper freezes configured domains like Java class load', () async {
    SharedPreferences.setMockInitialValues({
      'chans.chan_sites': 'firstchan.test[cdn.firstchan.test]',
    });
    await Utils.init();
    ChanRipper.resetExplicitDomainsForTesting();

    final firstUrl = Uri.parse('https://firstchan.test/a/res/123.html');
    final secondUrl = Uri.parse('https://secondchan.test/a/res/123.html');

    expect(ChanRipper(firstUrl).canRip(firstUrl), isTrue);

    SharedPreferences.setMockInitialValues({
      'chans.chan_sites': 'secondchan.test[cdn.secondchan.test]',
    });
    await Utils.init();

    expect(ChanRipper(firstUrl).canRip(firstUrl), isTrue);
    expect(ChanRipper(secondUrl).canRip(secondUrl), isFalse);
  });

  test('ChanRipper keeps Java shared explicit domain list mutation', () async {
    SharedPreferences.setMockInitialValues({
      'chans.chan_sites': 'examplechan.test[cdn.examplechan.test]',
    });
    await Utils.init();
    ChanRipper.resetExplicitDomainsForTesting();

    final firstLength = ChanRipper.explicitDomains().length;
    final secondLength = ChanRipper.explicitDomains().length;

    expect(firstLength, ChanRipper.bakedInExplicitDomains.length + 1);
    expect(
      secondLength,
      firstLength + ChanRipper.bakedInExplicitDomains.length + 1,
    );
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
    RedgifsRipper.getJsonForTesting = (url, {headers}) async {
      if (url.toString() == 'https://api.redgifs.com/v2/auth/temporary') {
        return {'token': 'test-token'};
      }
      if (url.toString() == 'https://api.redgifs.com/v2/gifs/exampleid') {
        return {
          'gif': {
            'gallery': null,
            'urls': {'hd': 'https://media.redgifs.com/exampleid.mp4'},
          },
        };
      }
      fail('Unexpected Redgifs request: $url');
    };

    final ripper = ChanRipper(
      Uri.parse('https://desuarchive.org/wsg/thread/2770629'),
    );
    final page = html.parse('''
      <html><body>
        <a href="https://i.imgur.com/example.gifv">gifv</a>
        <a href="https://v.redd.it/abc123/DASH_720.mp4">v.redd.it</a>
        <a href="https://i.reddituploads.com/uploadid?fit=max&amp;s=token">upload</a>
        <a href="https://cdn.example.com/path/image.jpg?size=large">direct</a>
        <a href="https://www.redgifs.com/watch/exampleid-extra">redgifs</a>
        <a href="https://www.gifdeliverynetwork.com/exampleid">gifdeliverynetwork</a>
      </body></html>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://i.imgur.com/example.mp4',
      'https://v.redd.it/abc123/DASH_720.mp4',
      'https://i.reddituploads.com/uploadid?fit=max&s=token',
      'https://cdn.example.com/path/image.jpg?size=large',
      'https://media.redgifs.com/exampleid.mp4',
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
