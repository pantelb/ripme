import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' show parse;
import 'package:ripme/ripper/rippers/erofus_ripper.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java Erofus host support and strict GID parsing', () async {
    final uri = Uri.parse(
      'https://www.erofus.com/comics/be-story-club-comics/a-kiss/issue-1',
    );
    final ripper = ErofusRipper(uri);

    expect(ripper.getHost(), 'erofus');
    expect(ripper.getDomain(), 'erofus.com');
    expect(ripper.canRip(uri), isTrue);
    expect(ripper.canRip(Uri.parse('https://erofus.com/comics/a')), isTrue);
    expect(await ripper.getGID(uri), 'be-story-club-comics');
    expect(
      () => ripper.getGID(Uri.parse('https://erofus.com/comics/a')),
      throwsFormatException,
    );
  });

  test('detects album pages and rewrites thumbnail sources like Java', () {
    final page = parse('''
      <a class="a-click" href="/pic/1">
        <div class="thumbnail"><img src="/uploads/thumbs/thumb-one.jpg"></div>
      </a>
      <a class="a-click" href="/pic/2">
        <div class="thumbnail"><img src="/thumb/two-thumb.jpg"></div>
      </a>
    ''');

    expect(ErofusRipper.pageContainsImages(page), isTrue);
    expect(ErofusRipper.imageUrlsFromAlbumPage(page), [
      'https://www.erofus.com/uploads/mediums/medium-one.jpg',
      'https://www.erofus.com/medium/two-medium.jpg',
    ]);
  });

  test('builds subalbum URLs and title subdirectories with Java strings', () {
    final page = parse('''
      <a class="a-click" href="/comics/one"></a>
      <a class="a-click" href="/pic/ignored"></a>
      <a class="a-click" href="https://www.erofus.com/comics/absolute"></a>
    ''');

    expect(ErofusRipper.subalbumUrlsFromDocument(page), [
      'https://erofus.com/comics/one',
      'https://erofus.comhttps://www.erofus.com/comics/absolute',
    ]);
    expect(
      ErofusRipper.subdirectoryFromTitle(
        'A Kiss Issue 1 | Erofus - Sex and Porn Comics',
      ),
      'A_Kiss_Issue_1',
    );
  });

  test('creates Java-style subdirectory downloads recursively', () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();

    final ripper = ErofusRipper(
      Uri.parse(
        'https://www.erofus.com/comics/be-story-club-comics/a-kiss/issue-1',
      ),
    );
    final tempDir = await Directory.systemTemp.createTemp('erofus_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    ripper.workingDir = tempDir;

    final rootPage = parse('''
      <a class="a-click" href="/comics/be-story-club-comics/a-kiss/issue-1"></a>
    ''');
    final albumPage = parse('''
      <html>
        <head><title>A Kiss Issue 1 | Erofus - Sex and Porn Comics</title></head>
        <body>
          <a class="a-click" href="/pic/1">
            <div class="thumbnail"><img src="/media/thumb/one.jpg"></div>
          </a>
        </body>
      </html>
    ''');

    final downloads = await ripper.downloadsFromPage(
      rootPage,
      pageFetcher: (_) async => albumPage,
    );

    expect(downloads, hasLength(1));
    expect(
      downloads.single.url.toString(),
      'https://www.erofus.com/media/medium/one.jpg',
    );
    expect(
      downloads.single.saveAs.path,
      contains('${Platform.pathSeparator}A_Kiss_Issue_1'
          '${Platform.pathSeparator}001_one.jpg'),
    );
  });
}
