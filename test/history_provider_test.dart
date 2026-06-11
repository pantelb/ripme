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
}
