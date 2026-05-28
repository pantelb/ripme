import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ripme/ripper/rippers/mangadex_ripper.dart';
import 'package:ripme/utils/http_utils.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('matches Java host, domain, broad support, and legacy numeric GIDs',
      () async {
    final chapter = Uri.parse('https://mangadex.org/chapter/467904/');
    final title = Uri.parse(
      'https://mangadex.org/title/44625/this-croc-will-die-in-100-days',
    );
    final ripper = MangadexRipper(chapter);

    expect(ripper.getHost(), 'mangadex');
    expect(ripper.getDomain(), 'mangadex.org');
    expect(ripper.canRip(chapter), isTrue);
    expect(
      ripper.canRip(Uri.parse('https://uploads.mangadex.org/file.jpg')),
      isTrue,
    );
    expect(await ripper.getGID(chapter), '467904');
    expect(ripper.isSingleChapterForTesting, isTrue);
    expect(await ripper.getGID(title), '44625');
    expect(ripper.isSingleChapterForTesting, isFalse);

    await expectLater(
      ripper.getGID(Uri.parse('https://mangadex.org/chapter/467904')),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      ripper.getGID(
        Uri.parse(
          'https://mangadex.org/chapter/01234567-89ab-cdef-0123-456789abcdef',
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('extracts Java chapter and manga IDs only from old URL shapes', () {
    expect(
      MangadexRipper.getChapterID('https://mangadex.org/chapter/467904/'),
      '467904',
    );
    expect(
      MangadexRipper.getChapterID('https://mangadex.org/chapter/467904/1'),
      '467904',
    );
    expect(
      MangadexRipper.getChapterID('https://mangadex.org/chapter/467904/12'),
      isNull,
    );
    expect(
      MangadexRipper.getMangaID(
        'https://mangadex.org/title/44625/this-croc-will-die-in-100-days',
      ),
      '44625',
    );
  });

  test('builds image URLs from chapter hash, page array, and server like Java',
      () {
    expect(
      MangadexRipper.imageUrl(
        'hash123',
        'page01.jpg',
        'https://server.example/data/',
      ),
      'https://server.example/data/hash123/page01.jpg',
    );
    expect(
      MangadexRipper.urlsFromChapterJson({
        'hash': 'hash123',
        'server': 'https://server.example/data/',
        'page_array': ['page01.jpg', 'page02.png'],
      }),
      [
        'https://server.example/data/hash123/page01.jpg',
        'https://server.example/data/hash123/page02.png',
      ],
    );
  });

  test('keeps only English manga chapters and sorts by chapter number', () {
    expect(
      MangadexRipper.englishChapterIdsByNumber({
        'chapter': {
          'later': {'lang_name': 'English', 'chapter': 2},
          'spanish': {'lang_name': 'Spanish', 'chapter': 1},
          'first': {'lang_name': 'English', 'chapter': '1'},
          'half': {'lang_name': 'English', 'chapter': 1.5},
        },
      }),
      {
        1.0: 'first',
        1.5: 'half',
        2.0: 'later',
      },
    );
  });

  test('fetches manga chapters from the Java API endpoints in sorted order',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final requestedPaths = <String>[];
    server.listen((request) async {
      requestedPaths.add(request.uri.path);
      request.response.headers.contentType = ContentType.json;
      switch (request.uri.path) {
        case '/api/chapter/first':
          request.response.write(jsonEncode({
            'hash': 'hash-first',
            'server': 'https://cdn.example.com/data/',
            'page_array': ['001.jpg'],
          }));
          break;
        case '/api/chapter/second':
          request.response.write(jsonEncode({
            'hash': 'hash-second',
            'server': 'https://cdn.example.com/data/',
            'page_array': ['002.jpg'],
          }));
          break;
        default:
          request.response.statusCode = 404;
      }
      await request.response.close();
    });

    final base = 'http://127.0.0.1:${server.port}/api/chapter/';
    final ripper = MangadexRipper(
      Uri.parse('https://mangadex.org/title/44625/example'),
      chapterApiEndPoint: base,
    );

    expect(
      await ripper.urlsFromMangaJson({
        'chapter': {
          'second': {'lang_name': 'English', 'chapter': 2},
          'first': {'lang_name': 'English', 'chapter': 1},
          'skip': {'lang_name': 'French', 'chapter': 0},
        },
      }),
      [
        'https://cdn.example.com/data/hash-first/001.jpg',
        'https://cdn.example.com/data/hash-second/002.jpg',
      ],
    );
    expect(requestedPaths, ['/api/chapter/first', '/api/chapter/second']);
  });

  test('waits one second per download and uses Java-style ordered filenames',
      () async {
    SharedPreferences.setMockInitialValues({'download.save_order': true});
    await Utils.init();
    final delays = <Duration>[];
    final oldDelay = Http.delay;
    Http.delay = (duration) async => delays.add(duration);
    addTearDown(() => Http.delay = oldDelay);

    final ripper = _DownloadRecordingMangadexRipper(
      Uri.parse('https://mangadex.org/chapter/467904/'),
    );
    final tempDir = await Directory.systemTemp.createTemp('mangadex_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    ripper.workingDir = tempDir;

    await ripper.parseJSON(ripper.url);

    expect(delays, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    expect(ripper.downloaded.map((entry) => p.basename(entry.path)).toList(), [
      '001_001.jpg',
      '002_002.png',
    ]);

    SharedPreferences.setMockInitialValues({'download.save_order': false});
    await Utils.init();
    expect(
      MangadexRipper.fileNameForUrl(
        Uri.parse('https://cdn.example.com/hash/page.jpg'),
        9,
      ),
      'page.jpg',
    );
  });
}

class _DownloadRecordingMangadexRipper extends MangadexRipper {
  _DownloadRecordingMangadexRipper(super.url);

  final downloaded = <File>[];

  @override
  Future<Map<String, dynamic>> getFirstPage() async {
    return {
      'hash': 'hash',
      'server': 'https://cdn.example.com/data/',
      'page_array': ['001.jpg', '002.png'],
    };
  }

  @override
  Future<void> downloadFile(
    Uri url,
    File saveAs, {
    Map<String, String>? headers,
    Map<String, String>? cookies,
    bool allowDuplicate = false,
  }) async {
    downloaded.add(saveAs);
  }
}
