import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/download_history_provider.dart';
import 'package:ripme/history_provider.dart';
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

class StopAwareRipper extends AbstractRipper {
  StopAwareRipper(super.url, this.directory, this.onStarted) {
    onStarted(url.toString());
  }

  final Directory directory;
  final void Function(String url) onStarted;
  final Completer<void> _stopped = Completer<void>();

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'stoppable';

  @override
  String getHost() => 'test';

  @override
  Future<void> rip() => _stopped.future;

  @override
  void stop() {
    super.stop();
    if (!_stopped.isCompleted) {
      _stopped.complete();
    }
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

class ProgressRipper extends AbstractRipper {
  ProgressRipper(super.url, this.directory, this.release);

  final Directory directory;
  final Future<void> release;
  int _completionPercentage = 0;

  @override
  int get completionPercentage => _completionPercentage;

  @override
  String get statusText => '$completionPercentage% progress';

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'progress';

  @override
  String getHost() => 'test';

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    sendUpdate(RipStatus.downloadStarted, 'https://example.com/one.jpg');
    sendUpdate(RipStatus.downloadStarted, 'https://example.com/two.jpg');
    _completionPercentage = 50;
    sendUpdate(RipStatus.downloadComplete, '/tmp/one.jpg');
    await release;
    _completionPercentage = 100;
    sendUpdate(RipStatus.downloadComplete, '/tmp/two.jpg');
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

Future<void> _deleteIfExists(Directory directory) async {
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}

void main() {
  test('plays completion sound when enabled', () async {
    SharedPreferences.setMockInitialValues({'play.sound': true});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_test');
    addTearDown(() => _deleteIfExists(directory));

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
    addTearDown(() => _deleteIfExists(directory));

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

  test('preserves Java history fields and updates repeat rip metadata',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_metadata_test');
    addTearDown(() => _deleteIfExists(directory));
    final manager = RipManager(
      ripperResolver: (uri) => ProgressRipper(
        uri,
        directory,
        Future<void>.value(),
      ),
      completionSoundPlayer: () async {},
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/metadata');
    await _waitFor(
      () => manager.history.length == 1 && manager.history.single.title != '',
    );
    final first = manager.history.single;

    expect(first.url, 'https://example.com/metadata');
    expect(first.dir, directory.path);
    expect(first.title, 'test_progress');
    expect(first.count, 2);
    expect(first.startDate, first.date);
    expect(first.modifiedDate, first.startDate);
    expect(first.selected, isFalse);

    final created = first.startDate;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    manager.addUrlToQueue('https://example.com/metadata');
    await _waitFor(() => first.modifiedDate.isAfter(created));

    expect(manager.history, hasLength(1));
    expect(first.startDate, created);
    expect(first.count, 2);
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

    await manager.setHistoryEntrySelected(1, true);
    final restoredManager = RipManager(
      ripperResolver: (uri) => null,
      completionSoundPlayer: () async {},
    );
    await restoredManager.init();
    expect(restoredManager.history[1].selected, isTrue);

    await manager.removeHistoryEntry(0);

    expect(manager.history.single.url, 'https://example.com/two');
  });

  test('clears album and downloaded URL history together like Java', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager(
      ripperResolver: (uri) => null,
      completionSoundPlayer: () async {},
    );
    await manager.init();
    await manager.replaceHistory([
      HistoryEntry(
        url: 'https://example.com/album',
        dir: '/tmp/album',
        date: DateTime(2026),
      ),
    ]);
    final downloaded = Uri.parse('https://example.com/image.jpg');
    await DownloadHistoryProvider.markDownloaded(downloaded);

    await manager.clearHistory();

    expect(manager.history, isEmpty);
    expect(await HistoryProvider.loadHistory(), isEmpty);
    expect(await DownloadHistoryProvider.hasDownloaded(downloaded), isFalse);
  });

  test('re-rips every selected history row in order including duplicates',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final directory =
        await Directory.systemTemp.createTemp('ripme_selected_history_test');
    addTearDown(() => _deleteIfExists(directory));
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final manager = RipManager(
      ripperResolver: (uri) => BlockingRipper(uri, directory, release.future),
      completionSoundPlayer: () async {},
    );
    await manager.init();
    await manager.replaceHistory([
      HistoryEntry(
        url: 'https://example.com/selected',
        dir: '/tmp/one',
        date: DateTime(2026),
        selected: true,
      ),
      HistoryEntry(
        url: 'https://example.com/skipped',
        dir: '/tmp/two',
        date: DateTime(2026),
      ),
      HistoryEntry(
        url: 'https://example.com/selected',
        dir: '/tmp/three',
        date: DateTime(2026),
        selected: true,
      ),
    ]);

    expect(manager.reripSelectedHistory(), HistoryReripResult.queued);
    await _waitFor(() => manager.isRipping);

    expect(manager.queue, ['https://example.com/selected']);
    manager.stop();
  });

  test('selected history re-rip distinguishes empty and unchecked history',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager(ripperResolver: (uri) => null);
    await manager.init();

    expect(
      manager.reripSelectedHistory(),
      HistoryReripResult.emptyHistory,
    );
    await manager.replaceHistory([
      HistoryEntry(
        url: 'https://example.com/unchecked',
        dir: '/tmp/unchecked',
        date: DateTime(2026),
      ),
    ]);
    expect(
      manager.reripSelectedHistory(),
      HistoryReripResult.noneSelected,
    );
  });

  test('tracks status counters and queue controls', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_queue_test');
    addTearDown(() => _deleteIfExists(directory));
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

  test('stop leaves pending queue entries until a new submission resumes it',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_stop_test');
    addTearDown(() => _deleteIfExists(directory));
    final started = <String>[];
    final manager = RipManager(
      ripperResolver: (uri) => StopAwareRipper(uri, directory, started.add),
      completionSoundPlayer: () async {},
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/current');
    manager.addUrlToQueue('https://example.com/two');
    manager.addUrlToQueue('https://example.com/three');
    await _waitFor(() => manager.isRipping && manager.queue.length == 2);

    manager.stop();
    await _waitFor(() => !manager.isRipping);
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(started, ['https://example.com/current']);
    expect(manager.queue, [
      'https://example.com/two',
      'https://example.com/three',
    ]);
    expect(manager.statusText, 'Download interrupted');
    expect(
      manager.logs.last.object,
      'Download interrupted',
    );

    manager.addUrlToQueue('https://example.com/four');
    await _waitFor(() => started.length == 2);
    expect(started.last, 'https://example.com/two');
    expect(manager.queue, [
      'https://example.com/three',
      'https://example.com/four',
    ]);
    manager.stop();
  });

  test('ignores status events emitted after the active ripper is stopped',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_late_event_test');
    addTearDown(() => _deleteIfExists(directory));
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    BlockingRipper? activeRipper;
    final manager = RipManager(
      ripperResolver: (uri) {
        activeRipper = BlockingRipper(uri, directory, release.future);
        return activeRipper;
      },
      completionSoundPlayer: () async {},
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/late-event');
    await _waitFor(() => manager.isRipping && activeRipper != null);
    manager.stop();
    activeRipper!.sendUpdate(RipStatus.downloadComplete, '/tmp/late.jpg');
    await Future<void>.delayed(Duration.zero);

    expect(
      manager.logs.any((message) => message.object == '/tmp/late.jpg'),
      isFalse,
    );
    expect(manager.statusText, 'Download interrupted');
    release.complete();
  });

  test('restores the persisted queue without starting it', () async {
    SharedPreferences.setMockInitialValues({
      'queue': <String>[
        'https://example.com/one',
        'https://example.com/two',
      ],
    });
    await Utils.init();
    var resolvedRippers = 0;
    final manager = RipManager(
      ripperResolver: (uri) {
        resolvedRippers++;
        return null;
      },
      completionSoundPlayer: () async {},
    );

    await manager.init();

    expect(manager.queue, [
      'https://example.com/one',
      'https://example.com/two',
    ]);
    expect(manager.isRipping, isFalse);
    expect(resolvedRippers, 0);
  });

  test('persists pending queue updates in order like Java', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_persist_test');
    addTearDown(() => _deleteIfExists(directory));
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final manager = RipManager(
      ripperResolver: (uri) => BlockingRipper(uri, directory, release.future),
      completionSoundPlayer: () async {},
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/current');
    manager.addUrlToQueue('https://example.com/two');
    manager.addUrlToQueue('https://example.com/three');
    await _waitFor(() => manager.queue.length == 2);
    await _waitFor(
      () => Utils.getConfigList('queue').length == 2,
    );
    expect(Utils.getConfigList('queue'), [
      'https://example.com/two',
      'https://example.com/three',
    ]);

    manager.moveQueueItem(1, 0);
    await _waitFor(
      () => Utils.getConfigList('queue').first == 'https://example.com/three',
    );
    expect(Utils.getConfigList('queue'), [
      'https://example.com/three',
      'https://example.com/two',
    ]);

    manager.removeFromQueue(1);
    await _waitFor(() => Utils.getConfigList('queue').length == 1);
    expect(Utils.getConfigList('queue'), ['https://example.com/three']);
  });

  test('matches Java non-empty update behavior when clearing a queue',
      () async {
    SharedPreferences.setMockInitialValues({
      'queue': <String>['https://example.com/persisted'],
    });
    await Utils.init();
    final manager = RipManager(
      ripperResolver: (uri) => null,
      completionSoundPlayer: () async {},
    );
    await manager.init();

    manager.clearQueue();

    expect(manager.queue, isEmpty);
    expect(
      Utils.getConfigList('queue'),
      ['https://example.com/persisted'],
    );
  });

  test('rejects exact duplicate URLs already in the pending queue', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_duplicate_test');
    addTearDown(() => _deleteIfExists(directory));
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final manager = RipManager(
      ripperResolver: (uri) => BlockingRipper(uri, directory, release.future),
      completionSoundPlayer: () async {},
    );
    await manager.init();

    expect(manager.addUrlToQueue('https://example.com/current'), isTrue);
    await _waitFor(() => manager.isRipping);
    expect(manager.addUrlToQueue('https://example.com/duplicate'), isTrue);
    expect(manager.addUrlToQueue('https://example.com/duplicate'), isFalse);

    expect(manager.queue, ['https://example.com/duplicate']);
    expect(
      manager.statusText,
      'This URL is already in queue: https://example.com/duplicate',
    );
  });

  test('expands inclusive manual URL ranges before queueing', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_range_test');
    addTearDown(() => _deleteIfExists(directory));
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final manager = RipManager(
      ripperResolver: (uri) => BlockingRipper(uri, directory, release.future),
      completionSoundPlayer: () async {},
    );
    await manager.init();

    final result = manager.submitManualUrl(
      'https://example.com/album/{2-4}/page/{ignored}',
    );
    await _waitFor(() => manager.isRipping);

    expect(result.accepted, 3);
    expect(result.errors, isEmpty);
    expect(manager.queue, [
      'https://example.com/album/3/page/3',
      'https://example.com/album/4/page/4',
    ]);
  });

  test('invalid manual URL ranges report errors without queueing', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager(
      ripperResolver: (uri) => null,
      completionSoundPlayer: () async {},
    );
    await manager.init();

    for (final url in const [
      'https://example.com/{1-x}',
      'https://example.com/{4-2}',
      'https://example.com/{1-3',
    ]) {
      final result = manager.submitManualUrl(url);
      expect(result.accepted, 0);
      expect(result.errors.single, 'Invalid URL range: $url');
    }

    expect(manager.queue, isEmpty);
  });

  test('URL input validation detects bare hosts through the resolved ripper',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final resolvedUris = <Uri>[];
    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_validate_test');
    addTearDown(() => _deleteIfExists(directory));
    final manager = RipManager(
      ripperResolver: (uri) {
        resolvedUris.add(uri);
        return BlockingRipper(uri, directory, Future<void>.value());
      },
      completionSoundPlayer: () async {},
    );
    await manager.init();

    expect(manager.validateUrlInput(' example.com/album '), isTrue);
    expect(resolvedUris, [Uri.parse('http://example.com/album')]);
    expect(manager.statusText, 'test album detected');
  });

  test('URL input validation reports malformed and unsupported URLs', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();
    final manager = RipManager(
      ripperResolver: (uri) => null,
      completionSoundPlayer: () async {},
    );
    await manager.init();

    expect(
        manager.validateUrlInput('https://unsupported.example/album'), isFalse);
    expect(manager.statusText, "Can't rip this URL: No ripper found");

    expect(manager.validateUrlInput('http://'), isFalse);
    expect(manager.statusText, "Can't rip this URL: Invalid URL");
  });

  test('adds child URLs emitted by queue-capable rippers', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_child_queue_test');
    addTearDown(() => _deleteIfExists(directory));

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

  test('tracks current rip status text and determinate progress', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_manager_progress_test');
    addTearDown(() => _deleteIfExists(directory));
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });

    final manager = RipManager(
      ripperResolver: (uri) => ProgressRipper(uri, directory, release.future),
      completionSoundPlayer: () async {},
    );
    await manager.init();

    manager.addUrlToQueue('https://example.com/progress');

    await _waitFor(() => manager.progressPercent == 50);
    expect(manager.statusText, '50% progress');
    expect(manager.isRipping, isTrue);

    release.complete();
    await _waitFor(() => manager.history.length == 1);

    expect(manager.statusText, '100% progress');
    expect(manager.progressValue, 0);
  });
}
