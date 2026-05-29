import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/tapastic_ripper.dart';

void main() {
  test('TapasticRipper matches Java host, domain, support, and GIDs', () async {
    final url = Uri.parse('https://tapas.io/series/TPIAG');
    final ripper = TapasticRipper(url);

    expect(ripper.getHost(), 'tapas');
    expect(ripper.getDomain(), 'tapas.io');
    expect(ripper.canRip(url), isTrue);
    expect(
        ripper.canRip(Uri.parse('https://www.tapas.io/series/TPIAG')), isFalse);

    expect(await ripper.getGID(url), 'series_ TPIAG');
    expect(
      await ripper.getGID(Uri.parse('https://tapas.io/series/TPIAG/info')),
      'series_ TPIAG',
    );
    expect(
      await ripper.getGID(Uri.parse('https://tapas.io/episode/123?x=1')),
      'ep_123',
    );
    await expectLater(
      ripper.getGID(Uri.parse('https://tapastic.com/series/TPIAG')),
      throwsA(isA<FormatException>()),
    );
  });

  test('TapasticRipper extracts episodeList JSON like Java', () async {
    final ripper = TapasticRipper(Uri.parse('https://tapas.io/series/TPIAG'));
    final page = html.parse('''
      <script>
        var series = {
          episodeList : [{"id":101,"title":"One: bad?"},{"id":202,"title":"Two Three"}],
          other: true
        };
      </script>
    ''');

    expect(await ripper.getURLsFromPage(page), [
      'http://tapastic.com/episode/101',
      'http://tapastic.com/episode/202',
    ]);
    expect(ripper.episodes.map((episode) => episode.filename), [
      'One bad',
      'Two Three',
    ]);
    expect(TapasticRipper.episodesFromDocument(html.parse('<html></html>')),
        isEmpty);
  });

  test('TapasticRipper extracts episode images and Java filename prefixes', () {
    final episode = TapasticEpisode(id: 101, title: 'One: Bad? Title');
    final directory = Directory.systemTemp.createTempSync('ripme_tapastic_');
    addTearDown(() => directory.deleteSync(recursive: true));

    final page = html.parse('''
      <article class="ep-contents">
        <img src="https://cdn.example.com/one.jpg">
        <span><img src="https://cdn.example.com/two.png?ignored=1"></span>
        <img>
      </article>
      <img src="https://cdn.example.com/outside.jpg">
    ''');

    final downloads = TapasticRipper.downloadsFromEpisodePage(
      page,
      episode,
      episodeIndex: 3,
      episodeDigitCount: 2,
      workingDirectory: directory,
    );

    expect(downloads.map((download) => download.url.toString()), [
      'https://cdn.example.com/one.jpg',
      'https://cdn.example.com/two.png?ignored=1',
    ]);
    expect(downloads.map((download) => download.saveAs.path.split('/').last), [
      'ep03-1of3-One-Bad-Title-one.jpg',
      'ep03-2of3-One-Bad-Title-two.png',
    ]);
  });

  test('TapasticRipper matches Java digit and prefix behavior', () {
    final episode = TapasticEpisode(id: 7, title: 'A Title!');

    expect(TapasticRipper.digitCount(0), 1);
    expect(TapasticRipper.digitCount(9), 1);
    expect(TapasticRipper.digitCount(10), 2);
    expect(
      TapasticRipper.filenamePrefix(
        episode,
        episodeIndex: 12,
        episodeDigitCount: 3,
        imageIndex: 4,
        imageCount: 10,
        imageDigitCount: 2,
      ),
      'ep012-04of10-A-Title-',
    );
    expect(
      TapasticRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/a:b.jpg'),
        prefix: 'ep1-1of1-A-',
      ),
      'ep1-1of1-A-a_b.jpg',
    );
  });
}
