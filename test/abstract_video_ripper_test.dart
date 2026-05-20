import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/ripper/abstract_video_ripper.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestVideoRipper extends AbstractVideoRipper {
  TestVideoRipper(super.url, this.directory, this.videoUrl);

  final Directory directory;
  final Uri videoUrl;

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'video';

  @override
  String getHost() => 'test';

  @override
  Future<Uri> getVideoURLForRip(Uri url) async => videoUrl;
}

void main() {
  test('uses shared download path for video rips', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.ignore_extensions': 'mp4',
    });
    await Utils.init();

    final directory = await Directory.systemTemp.createTemp('ripme_video_test');
    addTearDown(() => directory.delete(recursive: true));

    final ripper = TestVideoRipper(
      Uri.parse('https://example.com/video-page'),
      directory,
      Uri.parse('https://example.com/video.mp4'),
    );
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    await ripper.rip();
    await Future<void>.delayed(Duration.zero);

    expect(
      statuses.map((status) => status.status),
      containsAllInOrder([
        RipStatus.loadingResource,
        RipStatus.downloadSkip,
        RipStatus.ripComplete,
      ]),
    );
    expect(statuses[1].object.toString(), contains('ignored extension'));
    expect(await File('${directory.path}/video.mp4').exists(), isFalse);
  });
}
