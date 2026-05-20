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
}
