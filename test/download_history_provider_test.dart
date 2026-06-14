import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/download_history_provider.dart';
import 'package:ripme/history_provider.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('preserves URL fragments like Java base normalization', () async {
    SharedPreferences.setMockInitialValues({});

    final url = Uri.parse('https://example.com/image.jpg#fragment');
    await DownloadHistoryProvider.markDownloaded(url);

    expect(await DownloadHistoryProvider.hasDownloaded(url), isTrue);
    expect(
      await DownloadHistoryProvider.hasDownloaded(
          Uri.parse('https://example.com/image.jpg')),
      isFalse,
    );
  });

  test('exports and imports downloaded URL history JSON', () async {
    SharedPreferences.setMockInitialValues({});

    await DownloadHistoryProvider.saveDownloadedUrls({
      'https://example.com/two.jpg',
      'https://example.com/one.jpg',
    });

    final exported = DownloadHistoryProvider.exportDownloadedUrls(
        await DownloadHistoryProvider.loadDownloadedUrls());

    await DownloadHistoryProvider.clear();
    expect(await DownloadHistoryProvider.loadDownloadedUrls(), isEmpty);

    await DownloadHistoryProvider.saveDownloadedUrls(
      DownloadHistoryProvider.importDownloadedUrls(exported),
    );

    expect(await DownloadHistoryProvider.loadDownloadedUrls(), {
      'https://example.com/one.jpg',
      'https://example.com/two.jpg',
    });
  });

  test('uses Java append behavior when history.location is configured',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('ripme-history');
    addTearDown(() => tempDirectory.delete(recursive: true));
    final historyFile = File('${tempDirectory.path}/nested/url_history.txt');
    await historyFile.parent.create();
    SharedPreferences.setMockInitialValues({
      'history.location': historyFile.path,
    });
    await Utils.init();

    await DownloadHistoryProvider.markDownloaded(
      Uri.parse('https://example.com/two.jpg#fragment'),
    );
    expect(
      await DownloadHistoryProvider.hasDownloaded(
        Uri.parse('https://example.com/two.jpg#fragment'),
      ),
      isTrue,
    );
    await DownloadHistoryProvider.markDownloaded(
      Uri.parse('https://example.com/one.jpg'),
    );

    expect(
      await historyFile.readAsString(),
      'https://example.com/two.jpg#fragmenthttps://example.com/one.jpg',
    );
    expect(
      await DownloadHistoryProvider.hasDownloaded(
        Uri.parse('https://example.com/two.jpg'),
      ),
      isFalse,
    );

    await DownloadHistoryProvider.clear();
    expect(await historyFile.exists(), isFalse);
  });

  test('configured downloaded URL history stays distinct from album history',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('ripme-history');
    addTearDown(() => tempDirectory.delete(recursive: true));
    final historyFile = File('${tempDirectory.path}/url_history.txt');
    SharedPreferences.setMockInitialValues({
      'history.location': historyFile.path,
    });
    await Utils.init();

    await HistoryProvider.saveHistory([
      HistoryEntry(
        url: 'https://example.com/album',
        dir: tempDirectory.path,
        date: DateTime.utc(2026, 6, 11),
      ),
    ]);
    await DownloadHistoryProvider.markDownloaded(
      Uri.parse('https://example.com/image.jpg'),
    );

    expect((await HistoryProvider.loadHistory()).single.url,
        'https://example.com/album');
    expect(await historyFile.readAsString(), 'https://example.com/image.jpg');

    await DownloadHistoryProvider.clear();
    expect(await HistoryProvider.loadHistory(), hasLength(1));
  });
}
