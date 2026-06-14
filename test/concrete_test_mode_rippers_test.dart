import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ripper/rippers/chan_ripper.dart';
import 'package:ripme/ripper/rippers/eightmuses_ripper.dart';
import 'package:ripme/ripper/rippers/erofus_ripper.dart';
import 'package:ripme/ripper/rippers/fivehundredpx_ripper.dart';
import 'package:ripme/ripper/rippers/imagefap_ripper.dart';
import 'package:ripme/ripper/rippers/motherless_ripper.dart';
import 'package:ripme/ripper/rippers/natalie_mu_ripper.dart';
import 'package:ripme/ripper/rippers/reddit_ripper.dart';
import 'package:ripme/ripper/rippers/tapastic_ripper.dart';
import 'package:ripme/ripper/rippers/xhamster_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    AbstractRipper.resetTestMode();
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
  });

  tearDown(AbstractRipper.resetTestMode);

  test('Chan test mode stops after the first self-hosted media URL', () async {
    final ripper = ChanRipper(
      Uri.parse('https://boards.4chan.org/hr/thread/3015701'),
    )..markAsTest();
    final page = html.parse('''
      <a href="//i.4cdn.org/hr/one.jpg"></a>
      <a href="//i.4cdn.org/hr/two.jpg"></a>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'http://i.4cdn.org/hr/one.jpg',
    ]);
  });

  test('Eightmuses test mode keeps one hosted picture per page', () async {
    final ripper = EightmusesRipper(
      Uri.parse('https://www.8muses.com/comics/album/example'),
    )..markAsTest();
    final directory =
        await Directory.systemTemp.createTemp('ripme_8muses_test_mode_');
    addTearDown(() => directory.delete(recursive: true));
    ripper.workingDir = directory;
    final page = html.parse('''
      <title>8muses - Sex and Porn Comics | Example</title>
      <a class="c-tile" href="/comics/picture/example/1">
        <img data-src="/pictures/th/example/1.jpg">
      </a>
      <a class="c-tile" href="/comics/picture/example/2">
        <img data-src="/pictures/th/example/2.jpg">
      </a>
    ''');

    expect(await ripper.getURLsFromPage(page), hasLength(1));
    expect(await ripper.downloadsFromPage(page), hasLength(1));
  });

  test('Erofus test mode examines only the first page link', () async {
    final ripper = ErofusRipper(
      Uri.parse('https://www.erofus.com/comics/example'),
    )..markAsTest();
    final directory =
        await Directory.systemTemp.createTemp('ripme_erofus_test_mode_');
    addTearDown(() => directory.delete(recursive: true));
    ripper.workingDir = directory;
    final page = html.parse('''
      <a class="a-click" href="/pic/not-a-subalbum"></a>
      <a class="a-click" href="/comics/should-not-load"></a>
    ''');
    var fetches = 0;

    final downloads = await ripper.downloadsFromPage(
      page,
      pageFetcher: (_) async {
        fetches++;
        return html.parse('<html></html>');
      },
    );

    expect(downloads, isEmpty);
    expect(fetches, 0);
  });

  test('500px test mode limits extraction and bypasses next-page parsing',
      () async {
    final ripper = _FivehundredpxHarness(
      Uri.parse('https://500px.com/example'),
    )..markAsTest();

    expect(
      await ripper.getURLsFromJSON({
        'photos': [
          {'url': '/one'},
          {'url': '/two'},
        ],
      }),
      ['https://cdn.example/one.jpg'],
    );
    expect(ripper.photoCalls, 1);
    expect(await ripper.getNextPage(const {}), isNull);
  });

  test('Imagefap test mode resolves only the first gallery thumbnail',
      () async {
    final ripper = _ImagefapHarness(
      Uri.parse('https://www.imagefap.com/gallery/abcdef12'),
    )..markAsTest();
    final page = html.parse('''
      <div id="gallery">
        <a href="/photo/1"><img src="one.jpg" width="100"></a>
        <a href="/photo/2"><img src="two.jpg" width="100"></a>
      </div>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'https://cdn.example/1.jpg',
    ]);
    expect(ripper.requestedPages, ['https://www.imagefap.com/photo/1']);
  });

  test('Motherless limits page URLs and preserves queued test tasks on stop',
      () async {
    final page = html.parse('''
      <div class="thumb-container">
        <a class="img-container" href="/ONE"></a>
      </div>
      <div class="thumb-container">
        <a class="img-container" href="/TWO"></a>
      </div>
    ''');
    final normal =
        MotherlessRipper(Uri.parse('https://motherless.com/GABCDEF1'));
    normal.stop();
    expect(await normal.getURLsFromPage(page), isEmpty);
    expect(normal.shouldRunImageTask, isFalse);

    final testRipper =
        MotherlessRipper(Uri.parse('https://motherless.com/GABCDEF1'))
          ..markAsTest();
    expect(await testRipper.getURLsFromPage(page), hasLength(1));
    testRipper.stop();
    expect(testRipper.shouldRunImageTask, isTrue);
  });

  test('Natalie.mu test mode keeps the first unique gallery image', () async {
    final ripper = NatalieMuRipper(
      Uri.parse('http://cdn2.natalie.mu/music/news/140411'),
    )..markAsTest();
    final page = html.parse('''
      <div class="NA_articleGallery">
        <span style="background-image: url(/list_thumb_inbox/one.jpg);"></span>
        <span style="background-image: url(/list_thumb_inbox/two.jpg);"></span>
      </div>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'http://cdn2.natalie.mu/xlarge/one.jpg',
    ]);
  });

  test('Reddit test mode ignores history cutoff and stops after one page',
      () async {
    SharedPreferences.setMockInitialValues({
      'history.end_rip_after_already_seen': 1,
    });
    await Utils.init();
    final ripper = RedditRipper(Uri.parse('https://www.reddit.com/r/example'));
    ripper.alreadyDownloadedUrls = 1;
    expect(ripper.shouldEndForHistory, isTrue);

    ripper.markAsTest();
    expect(ripper.shouldEndForHistory, isFalse);
    expect(ripper.shouldStopAfterCurrentPage, isTrue);
  });

  test('Tapastic test mode keeps one image from the selected episode',
      () async {
    final ripper = TapasticRipper(Uri.parse('https://tapas.io/series/example'))
      ..markAsTest();
    final directory =
        await Directory.systemTemp.createTemp('ripme_tapastic_test_mode_');
    addTearDown(() => directory.delete(recursive: true));
    final page = html.parse('''
      <article class="ep-contents">
        <img src="https://cdn.example/one.jpg">
        <img src="https://cdn.example/two.jpg">
      </article>
    ''');

    expect(
      ripper.downloadsFromEpisodePageForCurrentMode(
        page,
        TapasticEpisode(id: 1, title: 'Example'),
        episodeIndex: 1,
        episodeDigitCount: 1,
        workingDirectory: directory,
      ),
      hasLength(1),
    );
  });

  test('Xhamster test mode limits queues and only old-gallery extraction',
      () async {
    final ripper = XhamsterRipper(
      Uri.parse('https://xhamster.com/photos/gallery/example-1'),
    )..markAsTest();
    final queuePage = html.parse('''
      <div class="item-container"><a class="item" href="/one"></a></div>
      <div class="item-container"><a class="item" href="/two"></a></div>
    ''');
    expect(await ripper.getAlbumsToQueue(queuePage), ['/one']);

    final oldPage = html.parse('''
      <div class="picture_view"><div class="pictures_block"><div class="items">
        <div class="item-container"><a class="item"></a></div>
      </div></div></div>
      <div class="clearfix">
        <div><a class="slided" href="https://xhamster.com/view/1"></a></div>
        <div><a class="slided" href="https://xhamster.com/view/2"></a></div>
      </div>
    ''');
    var fetches = 0;
    expect(
      await ripper.galleryUrlsFromPage(
        oldPage,
        pageFetcher: (uri) async {
          fetches++;
          return html.parse(
            '<a><img id="photoCurr" src="https://cdn.example/${uri.pathSegments.last}.jpg"></a>',
          );
        },
      ),
      ['https://cdn.example/1.jpg'],
    );
    expect(fetches, 1);

    final newPage = html.parse('''
      <div id="photo-slider"><div id="photo_slider">
        <a href="https://xhamster.com/one.jpg"></a>
        <a href="https://xhamster.com/two.jpg"></a>
      </div></div>
    ''');
    expect(await ripper.galleryUrlsFromPage(newPage), hasLength(2));
  });
}

class _FivehundredpxHarness extends FivehundredpxRipper {
  _FivehundredpxHarness(super.url);

  int photoCalls = 0;

  @override
  Future<String> imageUrlForPhoto(Map photo) async {
    photoCalls++;
    return 'https://cdn.example/${photo['url'].toString().substring(1)}.jpg';
  }
}

class _ImagefapHarness extends ImagefapRipper {
  _ImagefapHarness(super.url);

  final requestedPages = <String>[];

  @override
  Future<String?> getFullSizedImage(Uri pageUrl) async {
    requestedPages.add(pageUrl.toString());
    return 'https://cdn.example/${pageUrl.pathSegments.last}.jpg';
  }
}
