import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:ripme/ripper/rippers/eightmuses_ripper.dart';

void main() {
  test('EightmusesRipper matches Java album URLs and GIDs', () async {
    final comics =
        Uri.parse('https://www.8muses.com/comics/album/Album_123-extra');
    final comix = Uri.parse('http://8muses.com/comix/album/another-album');
    final picture = Uri.parse('https://www.8muses.com/comics/picture/a/1');
    final ripper = EightmusesRipper(comics);

    expect(ripper.canRip(comics), isTrue);
    expect(ripper.canRip(comix), isTrue);
    expect(ripper.canRip(picture), isFalse);
    expect(await ripper.getGID(comics), 'Album_123-extra');
    expect(await ripper.getGID(comix), 'another-album');
    await expectLater(ripper.getGID(picture), throwsA(isA<FormatException>()));
  });

  test('EightmusesRipper derives album title from Java meta description', () {
    final page = html.parse('''
      <html><head>
        <meta name="description" content="A huge collection of free porn comics for adults. Read Example Album online for free at 8muses.com">
      </head></html>
    ''');

    expect(
        EightmusesRipper.albumTitleFromDocument(page), '8muses_Example Album');
  });

  test('EightmusesRipper normalizes title text into Java subdirectory names',
      () {
    expect(
      EightmusesRipper.subdirFromTitle(
          '8muses - Sex and Porn Comics | Parent - Child Name'),
      '-Parent-Child-Name',
    );
  });

  test('EightmusesRipper extracts Java-compatible picture image URLs', () {
    final page = html.parse('''
      <html><body>
        <a class="c-tile" href="/comics/picture/example/1">
          <img data-src="/pictures/th/example/1.jpg">
        </a>
        <a class="c-tile" href="/comics/picture/example/2" data-cfsrc="https://comics.8muses.com/pictures/fl/example/2.png">
        </a>
        <a class="c-tile" href="/comics/picture/example/3" data-cfsrc="https://cdn.example.com/3.jpg">
        </a>
      </body></html>
    ''');

    expect(EightmusesRipper.imageUrlsFromPage(page), [
      'https://comics.8muses.com/pictures/fl/example/1.jpg',
      'https://comics.8muses.com/pictures/fl/example/2.png',
    ]);
  });

  test('EightmusesRipper creates ASAP-style download metadata', () async {
    final ripper = EightmusesRipper(
        Uri.parse('https://www.8muses.com/comics/album/example'));
    final tempDir = await Directory.systemTemp.createTemp('eightmuses_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    ripper.workingDir = tempDir;

    final page = html.parse('''
      <html><head><title>8muses - Sex and Porn Comics | Parent - Child</title></head>
      <body>
        <a class="c-tile" href="/comics/picture/example/1">
          <img data-src="/pictures/th/example/1.jpg">
        </a>
      </body></html>
    ''');

    final downloads = await ripper.downloadsFromPage(page);

    expect(downloads, hasLength(1));
    expect(downloads.single.url.toString(),
        'https://comics.8muses.com/pictures/fl/example/1.jpg');
    expect(
        downloads.single.saveAs.path,
        endsWith(
            '${Platform.pathSeparator}-Parent-Child${Platform.pathSeparator}0001.jpg'));
    expect(downloads.single.headers,
        {'Referer': 'https://www.8muses.com/comics/album/example'});
    expect(downloads.single.allowDuplicate, isTrue);
  });

  test('EightmusesRipper parses response cookies for follow-up downloads', () {
    expect(
      EightmusesRipper.cookiesFromSetCookieHeader(
          'session=abc; Path=/; HttpOnly, pref=dark; Secure'),
      {'session': 'abc', 'pref': 'dark'},
    );
  });
}
