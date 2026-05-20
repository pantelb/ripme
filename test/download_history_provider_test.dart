import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/download_history_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores normalized downloaded URLs', () async {
    SharedPreferences.setMockInitialValues({});

    final url = Uri.parse('https://example.com/image.jpg#fragment');
    await DownloadHistoryProvider.markDownloaded(url);

    expect(
      await DownloadHistoryProvider.hasDownloaded(
          Uri.parse('https://example.com/image.jpg')),
      isTrue,
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
}
