import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/history_provider.dart';
import 'package:ripme/rip_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
}
