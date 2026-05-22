import 'dart:io';
import 'dart:async';

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

class BlockingRipper extends AbstractRipper {
  BlockingRipper(super.url, this.directory, this.release);

  final Directory directory;
  final Future<void> release;

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'blocking';

  @override
  String getHost() => 'test';

  @override
  Future<void> rip() async {
    await release;
  }
}

class QueueingRipper extends AbstractRipper {
  QueueingRipper(super.url, this.directory);

  final Directory directory;

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'queueing';

  @override
  String getHost() => 'test';

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.queueAdd, 'https://example.com/child');
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

  test('replaces and removes persisted history entries', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final manager = RipManager(
      ripperResolver: (uri) => null,
      completionSoundPlayer: () async {},
    );
    await manager.init();

    await manager.replaceHistory([
      HistoryEntry(
        url: 'https://example.com/one',
        dir: '/tmp/one',
        date: DateTime(2026),
      ),
      HistoryEntry(
        url: 'https://example.com/two',
        dir: '/tmp/two',
        date: DateTime(2026, 2),
      ),
    ]);

    expect(manager.history.map((entry) => entry.url), [
      'https://example.com/one',
      'https://example.com/two',
    ]);

    await manager.removeHistoryEntry(0);

    expect(manager.history.single.url, 'https://example.com/two');
  });

  test('tracks status counters and queue controls', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_queue_test');
    addTearDown(() => directory.delete(recursive: true));
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });

    final manager = RipManager(
      ripperResolver: (uri) => BlockingRipper(uri, directory, release.future),
      completionSoundPlayer: () async {},
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/one');
    manager.addUrlToQueue('https://example.com/two');
    manager.addUrlToQueue('https://example.com/three');
    await _waitFor(() => manager.queue.length == 2);
    manager.moveQueueItem(1, 0);
    expect(manager.queue, [
      'https://example.com/three',
      'https://example.com/two',
    ]);

    manager.clearQueue();
    expect(manager.queue, isEmpty);

    release.complete();
    manager.stop();
    await _waitFor(() => !manager.isRipping);

    expect(manager.failedDownloads, 0);

    manager.clearLogs();
    expect(manager.logs, isEmpty);
  });

  test('adds child URLs emitted by queue-capable rippers', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_child_queue_test');
    addTearDown(() => directory.delete(recursive: true));

    var childStarted = false;
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final manager = RipManager(
      ripperResolver: (uri) {
        if (uri.toString().endsWith('/child')) {
          childStarted = true;
          return BlockingRipper(uri, directory, release.future);
        }
        return QueueingRipper(uri, directory);
      },
      completionSoundPlayer: () async {},
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/parent');

    await _waitFor(() => childStarted);
    release.complete();
    manager.stop();

    expect(manager.logs.any((msg) => msg.status == RipStatus.queueAdd), isTrue);
  });
}
