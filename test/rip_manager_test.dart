import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompletingRipper extends AbstractRipper {
  CompletingRipper(super.url, this.directory);

  final Directory directory;

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'complete';

  @override
  String getHost() => 'test';

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test('plays completion sound when enabled', () async {
    SharedPreferences.setMockInitialValues({'play.sound': true});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_test');
    addTearDown(() => directory.delete(recursive: true));

    var soundCount = 0;
    final manager = RipManager(
      ripperResolver: (uri) => CompletingRipper(uri, directory),
      completionSoundPlayer: () async {
        soundCount++;
      },
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/album');

    await _waitFor(() => soundCount == 1);
    expect(manager.history, hasLength(1));
  });

  test('does not play completion sound when disabled', () async {
    SharedPreferences.setMockInitialValues({'play.sound': false});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_test');
    addTearDown(() => directory.delete(recursive: true));

    var soundCount = 0;
    final manager = RipManager(
      ripperResolver: (uri) => CompletingRipper(uri, directory),
      completionSoundPlayer: () async {
        soundCount++;
      },
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/album');

    await _waitFor(() => manager.history.length == 1);
    expect(soundCount, 0);
  });
}
