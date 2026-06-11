import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/history_provider.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
  });

  test('clears persisted rip history', () async {
    SharedPreferences.setMockInitialValues({});

    await HistoryProvider.saveHistory([
      HistoryEntry(
        url: 'https://example.com/album',
        dir: '/tmp/album',
        date: DateTime(2026),
      ),
    ]);

    expect(await HistoryProvider.loadHistory(), hasLength(1));

    await HistoryProvider.clearHistory();

    expect(await HistoryProvider.loadHistory(), isEmpty);
  });

  test('exports and imports Flutter rip history JSON', () async {
    final history = [
      HistoryEntry(
        url: 'https://example.com/album',
        dir: '/tmp/album',
        date: DateTime(2026, 5, 20),
      ),
    ];

    final exported = HistoryProvider.exportHistory(history);
    final imported = HistoryProvider.importHistory(exported);

    expect(imported, hasLength(1));
    expect(imported.single.url, history.single.url);
    expect(imported.single.dir, history.single.dir);
    expect(imported.single.date, history.single.date);
  });

  test('imports Java history export JSON', () {
    final imported = HistoryProvider.importHistory('''
      [
        {
          "url": "https://example.com/java",
          "startDate": 1779235200000,
          "modifiedDate": 1779321600000,
          "title": "Java",
          "count": 3,
          "selected": false
        }
      ]
    ''');

    expect(imported.single.url, 'https://example.com/java');
    expect(imported.single.dir, isEmpty);
    expect(imported.single.date,
        DateTime.fromMillisecondsSinceEpoch(1779321600000));
    expect(imported.single.startDate,
        DateTime.fromMillisecondsSinceEpoch(1779235200000));
    expect(imported.single.modifiedDate,
        DateTime.fromMillisecondsSinceEpoch(1779321600000));
    expect(imported.single.title, 'Java');
    expect(imported.single.count, 3);
    expect(imported.single.selected, isFalse);
  });

  test('imports every Java history field without data loss', () {
    final imported = HistoryProvider.importHistory('''
      [
        {
          "url": "https://example.com/full-java-entry",
          "startDate": 1779235200123,
          "modifiedDate": 1779321600456,
          "title": "Full Java entry",
          "count": 9,
          "dir": "/tmp/full-java-entry",
          "selected": true
        }
      ]
    ''').single;

    expect(imported.url, 'https://example.com/full-java-entry');
    expect(imported.startDate.millisecondsSinceEpoch, 1779235200123);
    expect(imported.modifiedDate.millisecondsSinceEpoch, 1779321600456);
    expect(imported.title, 'Full Java entry');
    expect(imported.count, 9);
    expect(imported.dir, '/tmp/full-java-entry');
    expect(imported.selected, isTrue);
  });

  test('rejects malformed Java history entries like Java fromFile', () {
    for (final json in const [
      '[null]',
      '[{"startDate": 1, "modifiedDate": 2}]',
      '[{"url": "x", "modifiedDate": 2}]',
      '[{"url": "x", "startDate": 1}]',
      '[{"url": "x", "startDate": "1", "modifiedDate": 2}]',
    ]) {
      expect(
        () => HistoryProvider.importHistory(json),
        throwsA(isA<FormatException>()),
        reason: json,
      );
    }
  });

  test('keeps tolerant loading for legacy Flutter preference history',
      () async {
    SharedPreferences.setMockInitialValues({
      'rip_history':
          '[{"url":"https://example.com/legacy","dir":"/tmp/legacy",'
              '"date":"2026-06-11T00:00:00.000Z"}]',
    });

    final loaded = await HistoryProvider.loadHistory();

    expect(loaded.single.url, 'https://example.com/legacy');
    expect(loaded.single.date, DateTime.utc(2026, 6, 11));
  });

  test('preserves Java selected state and metadata through export', () {
    final entry = HistoryEntry(
      url: 'https://example.com/selected',
      dir: '/tmp/selected',
      date: DateTime(2026, 5, 20),
      title: 'Selected album',
      count: 7,
      startDate: DateTime(2026, 5, 19),
      modifiedDate: DateTime(2026, 5, 20),
      selected: true,
    );

    final imported =
        HistoryProvider.importHistory(HistoryProvider.exportHistory([entry]));

    expect(imported.single.title, entry.title);
    expect(imported.single.count, entry.count);
    expect(imported.single.startDate, entry.startDate);
    expect(imported.single.modifiedDate, entry.modifiedDate);
    expect(imported.single.selected, isTrue);
  });

  test('writes Java history timestamps as epoch milliseconds', () {
    final startDate = DateTime.fromMillisecondsSinceEpoch(1779235200123);
    final modifiedDate = DateTime.fromMillisecondsSinceEpoch(1779321600456);
    final exported = HistoryProvider.exportHistory([
      HistoryEntry(
        url: 'https://example.com/timestamps',
        dir: '/tmp/timestamps',
        date: modifiedDate,
        startDate: startDate,
        modifiedDate: modifiedDate,
      ),
    ]);
    final entry = (jsonDecode(exported) as List).single as Map<String, dynamic>;

    expect(entry['startDate'], 1779235200123);
    expect(entry['modifiedDate'], 1779321600456);
    expect(entry['startDate'], isA<int>());
    expect(entry['modifiedDate'], isA<int>());
  });

  test('documents the Java-compatible Flutter history format extension', () {
    final exported = HistoryProvider.exportHistory([
      HistoryEntry(
        url: 'https://example.com/extended',
        dir: '/tmp/extended',
        date: DateTime.utc(2026, 6, 11),
        title: 'Extended',
        count: 4,
        selected: true,
      ),
    ]);
    final entry = (jsonDecode(exported) as List).single as Map<String, dynamic>;

    expect(entry.keys, containsAll([
      'url',
      'startDate',
      'modifiedDate',
      'title',
      'count',
      'selected',
    ]));
    expect(entry['dir'], '/tmp/extended');
    expect(entry['date'], '2026-06-11T00:00:00.000Z');
  });

  test('exports indented Java-style history JSON', () {
    final exported = HistoryProvider.exportHistory([
      HistoryEntry(
        url: 'https://example.com/pretty',
        dir: '/tmp/pretty',
        date: DateTime.utc(2026, 6, 11),
      ),
    ]);

    expect(exported, startsWith('[\n  {\n'));
    expect(exported, contains('\n    "url": "https://example.com/pretty",'));
    expect(exported, endsWith('\n  }\n]'));
  });

  test('reconstructs Java URLs from supported bare directory names', () {
    const cases = {
      'imgur_abcde': 'http://imgur.com/a/abcde',
      'imgur_one-two': 'http://imgur.com/one,two',
      'imgur_username_favorites': 'http://username.imgur.com/favorites',
      'imagefap_123': 'http://www.imagefap.com/gallery.php?gid=123',
      'imagefap_slug': 'http://www.imagefap.com/gallery.php?pgid=slug',
      'deviantart_artist': 'http://artist.deviantart.com/',
      'deviantart_artist_42':
          'http://artist.deviantart.com/gallery/42',
      'bfcakes_actor': 'http://www.bcfakes.com/celebritylist/actor',
      'drawcrowd_artist': 'http://drawcrowd.com/artist',
      'ehentai_123-abc': 'http://g.e-hentai.org/g/123/abc',
      'vinebox_user': 'http://finebox.co/u/user',
      'imgbox_gallery': 'http://imgbox.com/g/gallery',
      'modelmayhem_123': 'http://www.modelmayhem.com/123',
    };

    for (final entry in cases.entries) {
      expect(
        HistoryDirectoryGuesser.urlFromDirectoryName(entry.key),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('preserves Java full-path and Reddit fallback limitations', () {
    expect(
      HistoryDirectoryGuesser.urlFromDirectoryName('/rips/imgur_abcde'),
      isNull,
    );
    expect(
      HistoryDirectoryGuesser.urlFromDirectoryName(r'C:\rips\imgur_abcde'),
      isNull,
    );
    expect(
      HistoryDirectoryGuesser.urlFromDirectoryName('reddit_sub_flutter'),
      isNull,
    );
  });

  test('loads legacy download.history before guessing directories', () async {
    SharedPreferences.setMockInitialValues({
      'download.history': ['https://example.com/legacy'],
    });
    await Utils.init();
    final directory = await Directory.systemTemp.createTemp('ripme-history-');
    addTearDown(() => directory.delete(recursive: true));
    await Directory('${directory.path}/imgur_abcde').create();

    final history =
        await HistoryProvider.loadHistory(workingDirectory: directory);

    expect(history.map((entry) => entry.url), [
      'https://example.com/legacy',
    ]);
  });

  test('does not guess when persisted album history exists', () async {
    SharedPreferences.setMockInitialValues({'rip_history': '[]'});
    await Utils.init();
    final directory = await Directory.systemTemp.createTemp('ripme-history-');
    addTearDown(() => directory.delete(recursive: true));
    await Directory('${directory.path}/imgur_abcde').create();

    expect(
      await HistoryProvider.loadHistory(workingDirectory: directory),
      isEmpty,
    );
  });

  test('ignores malformed Java fallback candidates without crashing', () {
    expect(
      () => HistoryDirectoryGuesser.urlFromDirectoryName('imgur_'),
      throwsRangeError,
    );
    expect(
      () => HistoryDirectoryGuesser.urlFromDirectoryName(
        'imgur_flutter_top_week',
      ),
      throwsUnsupportedError,
    );
    expect(
      () => HistoryDirectoryGuesser.urlFromDirectoryName('deviantart'),
      throwsRangeError,
    );
  });
}
