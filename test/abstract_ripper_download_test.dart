import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/download_history_provider.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestRipper extends AbstractRipper {
  TestRipper(super.url, this.directory);

  final Directory directory;

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'test';

  @override
  String getHost() => 'test';

  @override
  Future<void> rip() async {}
}

void main() {
  test('skips existing files when overwrite is disabled', () async {
    SharedPreferences.setMockInitialValues({
      'file.overwrite': false,
      'history.skip_downloaded_urls': false,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_download_test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/image.jpg');
    await file.writeAsString('existing');

    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    await ripper.downloadFile(Uri.parse('https://example.com/image.jpg'), file);
    await Future<void>.delayed(Duration.zero);

    expect(statuses.single.status, RipStatus.downloadSkip);
    expect(ripper.alreadyDownloadedUrls, 1);
  });

  test('skips URLs already present in persisted download history', () async {
    SharedPreferences.setMockInitialValues({
      'history.skip_downloaded_urls': true,
    });
    await Utils.init();

    final url = Uri.parse('https://example.com/image.jpg');
    await DownloadHistoryProvider.markDownloaded(url);

    final directory =
        await Directory.systemTemp.createTemp('ripme_download_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    await ripper.downloadFile(url, File('${directory.path}/image.jpg'));
    await Future<void>.delayed(Duration.zero);

    expect(statuses.single.status, RipStatus.downloadSkip);
    expect(ripper.alreadyDownloadedUrls, 1);
  });
}
