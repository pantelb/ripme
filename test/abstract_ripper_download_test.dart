import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:ripme/download_history_provider.dart';
import 'package:ripme/ripper/abstract_html_ripper.dart';
import 'package:ripme/ripper/abstract_json_ripper.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ripper/abstract_single_file_ripper.dart';
import 'package:ripme/ui/rip_status_message.dart';
import 'package:ripme/utils/http_utils.dart';
import 'package:ripme/utils/utils.dart';
import 'package:path/path.dart' as p;
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

class LifecycleTestRipper extends TestRipper {
  LifecycleTestRipper(
    super.url,
    super.directory, {
    this.error,
  });

  final Object? error;

  @override
  Future<void> rip() async {
    if (error != null) throw error!;
  }
}

class NormalizingHistoryTestRipper extends TestRipper {
  NormalizingHistoryTestRipper(
    super.url,
    super.directory,
    this.historyUrl,
  );

  final Uri historyUrl;

  @override
  Uri normalizeUrl(Uri url) => historyUrl;
}

class GaussianSleepTestRipper extends TestRipper {
  GaussianSleepTestRipper(super.url, super.directory, this.sample);

  final double sample;

  @override
  double nextGaussian() => sample;

  Future<bool> sleepForTest(int milliseconds) =>
      sleepWithGaussianJitter(milliseconds);
}

class SingleFileProgressTestRipper extends AbstractSingleFileRipper {
  SingleFileProgressTestRipper(super.url, this.directory);

  final Directory directory;

  @override
  Future<void> setup() async {
    workingDir = directory;
  }

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getGID(Uri url) async => 'single';

  @override
  String getHost() => 'test';

  @override
  Future<List<String>> getURLsFromPage(Document page) async => const [];

  @override
  Future<Uri?> getNextPage(Document page) async => null;
}

class ParallelTestRipper extends TestRipper {
  ParallelTestRipper(super.url, super.directory);

  int activeDownloads = 0;
  int maxActiveDownloads = 0;
  final startedUrls = <Uri>[];

  @override
  Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      bool allowDuplicate = false,
      bool getFileExtFromMIME = false}) async {
    startedUrls.add(url);
    activeDownloads++;
    if (activeDownloads > maxActiveDownloads) {
      maxActiveDownloads = activeDownloads;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    activeDownloads--;
  }
}

class TimedWaitTestRipper extends TestRipper {
  TimedWaitTestRipper(super.url, super.directory);

  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Duration get downloadWorkerWaitTimeout => const Duration(milliseconds: 10);

  @override
  Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      bool allowDuplicate = false,
      bool getFileExtFromMIME = false}) async {
    if (!started.isCompleted) started.complete();
    await release.future;
  }
}

class AuxiliaryPoolTestRipper extends TestRipper {
  AuxiliaryPoolTestRipper(super.url, super.directory);

  int activeTasks = 0;
  int maxActiveTasks = 0;

  Future<int?> task(int value, {bool fail = false}) async {
    activeTasks++;
    if (activeTasks > maxActiveTasks) maxActiveTasks = activeTasks;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    activeTasks--;
    if (fail) throw StateError('task failed');
    return value;
  }
}

class HeaderCookieTestRipper extends TestRipper {
  HeaderCookieTestRipper(super.url, super.directory);

  Map<String, String>? receivedHeaders;
  Map<String, String>? receivedCookies;

  @override
  Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      bool allowDuplicate = false,
      bool getFileExtFromMIME = false}) async {
    receivedHeaders = headers;
    receivedCookies = cookies;
  }
}

class StopAfterFirstDownloadRipper extends TestRipper {
  StopAfterFirstDownloadRipper(super.url, super.directory);

  final startedUrls = <Uri>[];

  @override
  Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      bool allowDuplicate = false,
      bool getFileExtFromMIME = false}) async {
    startedUrls.add(url);
    stop();
  }
}

class WorkingDirectoryTestRipper extends AbstractRipper {
  WorkingDirectoryTestRipper(super.url, this.title);

  final String title;

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getAlbumTitle(Uri url) async => title;

  @override
  Future<String> getGID(Uri url) async => 'gid';

  @override
  String getHost() => 'example';

  @override
  Future<void> rip() async {}
}

class JsonWorkingDirectoryTestRipper extends AbstractJSONRipper {
  JsonWorkingDirectoryTestRipper(super.url, this.title);

  final String title;

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getAlbumTitle(Uri url) async => title;

  @override
  Future<String> getGID(Uri url) async => 'gid';

  @override
  String getHost() => 'json';

  @override
  Future<void> parseJSON(Uri url) async {}
}

class HtmlWorkingDirectoryTestRipper extends AbstractHTMLRipper {
  HtmlWorkingDirectoryTestRipper(super.url, this.title);

  final String title;

  @override
  bool canRip(Uri url) => true;

  @override
  Future<String> getAlbumTitle(Uri url) async => title;

  @override
  Future<String> getGID(Uri url) async => 'gid';

  @override
  String getHost() => 'html';

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  @override
  Future<List<String>> getURLsFromPage(Document page) async => const [];
}

void main() {
  tearDown(() {
    AbstractRipper.folderNameSuffix = null;
  });

  test('setup uses Java-safe truncated working directory names', () async {
    final base =
        await Directory.systemTemp.createTemp('ripme_working_dir_test');
    addTearDown(() => base.delete(recursive: true));
    SharedPreferences.setMockInitialValues({
      'rips.directory': base.path,
    });
    await Utils.init();
    final longName = List.filled(101, 'a').join();
    final ripper = WorkingDirectoryTestRipper(
      Uri.parse('https://example.com/album'),
      ' $longName/?! ',
    );

    await ripper.setup();

    expect(p.basename(ripper.workingDir.path), List.filled(99, 'a').join());
    expect(await ripper.workingDir.exists(), isTrue);
  });

  test('run deletes an empty working directory after a successful rip',
      () async {
    final parent =
        await Directory.systemTemp.createTemp('ripme_cleanup_success_test');
    addTearDown(() => parent.delete(recursive: true));
    final directory = await Directory(p.join(parent.path, 'album')).create();
    final ripper = LifecycleTestRipper(
      Uri.parse('https://example.com/album'),
      directory,
    );
    await ripper.setup();

    await ripper.run();

    expect(await directory.exists(), isFalse);
  });

  test('run deletes an empty working directory after a failed rip', () async {
    final parent =
        await Directory.systemTemp.createTemp('ripme_cleanup_failure_test');
    addTearDown(() => parent.delete(recursive: true));
    final directory = await Directory(p.join(parent.path, 'album')).create();
    final ripper = LifecycleTestRipper(
      Uri.parse('https://example.com/album'),
      directory,
      error: StateError('rip failed'),
    );
    await ripper.setup();

    await expectLater(ripper.run(), throwsStateError);

    expect(await directory.exists(), isFalse);
  });

  test('run preserves a non-empty working directory', () async {
    final parent =
        await Directory.systemTemp.createTemp('ripme_cleanup_nonempty_test');
    addTearDown(() => parent.delete(recursive: true));
    final directory = await Directory(p.join(parent.path, 'album')).create();
    final file = await File(p.join(directory.path, 'image.jpg'))
        .writeAsString('downloaded');
    final ripper = LifecycleTestRipper(
      Uri.parse('https://example.com/album'),
      directory,
    );
    await ripper.setup();

    await ripper.run();

    expect(await directory.exists(), isTrue);
    expect(await file.readAsString(), 'downloaded');
  });

  test('sleep applies Java gaussian jitter and integer truncation', () async {
    final directory =
        await Directory.systemTemp.createTemp('ripme_gaussian_sleep_test');
    addTearDown(() => directory.delete(recursive: true));
    final originalDelay = Http.delay;
    final delays = <Duration>[];
    Http.delay = (duration) async => delays.add(duration);
    addTearDown(() => Http.delay = originalDelay);
    final ripper = GaussianSleepTestRipper(
      Uri.parse('https://example.com/album'),
      directory,
      0.5,
    );

    expect(await ripper.sleepForTest(101), isTrue);

    expect(delays, [const Duration(milliseconds: 116)]);
  });

  test('sleep clamps Java gaussian jitter to 47 percent', () async {
    final directory =
        await Directory.systemTemp.createTemp('ripme_gaussian_clamp_test');
    addTearDown(() => directory.delete(recursive: true));
    final originalDelay = Http.delay;
    final delays = <Duration>[];
    Http.delay = (duration) async => delays.add(duration);
    addTearDown(() => Http.delay = originalDelay);
    final ripper = GaussianSleepTestRipper(
      Uri.parse('https://example.com/album'),
      directory,
      -10,
    );

    expect(await ripper.sleepForTest(1000), isTrue);

    expect(delays, [const Duration(milliseconds: 470)]);
  });

  test('album_titles.save false uses Java JSON fallback directory', () async {
    final base = await Directory.systemTemp.createTemp('ripme_json_title_test');
    addTearDown(() => base.delete(recursive: true));
    SharedPreferences.setMockInitialValues({
      'rips.directory': base.path,
      'album_titles.save': false,
    });
    await Utils.init();

    final ripper = JsonWorkingDirectoryTestRipper(
      Uri.parse('https://example.com/album'),
      'custom title',
    );
    await ripper.setup();

    expect(p.basename(ripper.workingDir.path), 'json_gid');
  });

  test('album_titles.save true keeps Java JSON custom directory', () async {
    final base = await Directory.systemTemp.createTemp('ripme_json_title_test');
    addTearDown(() => base.delete(recursive: true));
    SharedPreferences.setMockInitialValues({
      'rips.directory': base.path,
      'album_titles.save': true,
    });
    await Utils.init();

    final ripper = JsonWorkingDirectoryTestRipper(
      Uri.parse('https://example.com/album'),
      'custom title',
    );
    await ripper.setup();

    expect(p.basename(ripper.workingDir.path), 'custom title');
  });

  test('album_titles.save false does not change Java HTML directory', () async {
    final base = await Directory.systemTemp.createTemp('ripme_html_title_test');
    addTearDown(() => base.delete(recursive: true));
    SharedPreferences.setMockInitialValues({
      'rips.directory': base.path,
      'album_titles.save': false,
    });
    await Utils.init();

    final ripper = HtmlWorkingDirectoryTestRipper(
      Uri.parse('https://example.com/album'),
      'custom title',
    );
    await ripper.setup();

    expect(p.basename(ripper.workingDir.path), 'custom title');
  });

  test('shared filename helper preserves Java extension edge cases', () {
    final objectUrl = Uri.parse(
      'http://www.tsumino.com/Image/Object?name=U1EieteEGwm6N1dGszqCpA%3D%3D',
    );

    expect(
      AbstractRipper.getFileName(
        objectUrl,
        fileName: 'test',
        extension: 'test',
      ),
      'test.test',
    );
    expect(
      AbstractRipper.getFileName(objectUrl, fileName: 'test'),
      'test',
    );
    expect(
      AbstractRipper.getFileName(
        objectUrl,
        fileName: 'test',
        extension: '',
      ),
      'test.',
    );
    expect(AbstractRipper.getFileName(objectUrl), 'Object');
    expect(
      AbstractRipper.getFileName(Uri.parse('http://www.test.com/file.png')),
      'file.png',
    );
    expect(
      AbstractRipper.getFileName(Uri.parse('http://www.test.com/file.')),
      'file.',
    );
  });

  test('append-to-folder redirects file paths to a sibling album root',
      () async {
    final parent = await Directory.systemTemp.createTemp('ripme_append_test');
    addTearDown(() => parent.delete(recursive: true));
    final workingDir = Directory(p.join(parent.path, 'album'));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), workingDir);
    await ripper.setup();
    AbstractRipper.folderNameSuffix = '-extra';

    final resolved = ripper.resolveSavePath(
      File(p.join(workingDir.path, 'subdir', 'image.jpg')),
    );

    expect(
      resolved.path,
      p.join(parent.path, 'album-extra', 'subdir', 'image.jpg'),
    );
    expect(ripper.workingDir.path, workingDir.path);
  });

  test('skips existing files when overwrite is disabled', () async {
    SharedPreferences.setMockInitialValues({
      'file.overwrite': false,
      'remember.url_history': true,
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

    final url = Uri.parse('https://example.com/image.jpg');
    await ripper.downloadFile(url, file);
    await Future<void>.delayed(Duration.zero);

    expect(statuses.single.status, RipStatus.downloadWarn);
    expect(ripper.alreadyDownloadedUrls, 0);
    expect(await DownloadHistoryProvider.hasDownloaded(url), isTrue);
  });

  test('records Java URL history before a failed download', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': true,
      'download.retries': 0,
    });
    await Utils.init();

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });
    final url = Uri.parse(
      'http://${server.address.host}:${server.port}/missing.jpg',
    );
    final directory =
        await Directory.systemTemp.createTemp('ripme_history_failure_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    await ripper.downloadFile(url, File(p.join(directory.path, 'missing.jpg')));

    expect(await DownloadHistoryProvider.hasDownloaded(url), isTrue);
  });

  test('uses ripper URL normalization for history lookup and writes', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': true,
      'download.retries': 0,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_normalized_history_test');
    addTearDown(() => directory.delete(recursive: true));
    final historyUrl = Uri.parse('https://example.com/normalized');
    final rawUrl = Uri.parse('https://example.com/raw.jpg#fragment');
    await DownloadHistoryProvider.markDownloaded(historyUrl);

    final lookupRipper = NormalizingHistoryTestRipper(
      Uri.parse('https://example.com/album'),
      directory,
      historyUrl,
    );
    await lookupRipper.setup();
    await lookupRipper.downloadFile(
      rawUrl,
      File(p.join(directory.path, 'skipped.jpg')),
    );
    expect(lookupRipper.alreadyDownloadedUrls, 1);

    await DownloadHistoryProvider.clear();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });
    final failedUrl = Uri.parse(
      'http://${server.address.host}:${server.port}/missing.jpg',
    );
    final writeRipper = NormalizingHistoryTestRipper(
      Uri.parse('https://example.com/album'),
      directory,
      historyUrl,
    );
    await writeRipper.setup();
    await writeRipper.downloadFile(
      failedUrl,
      File(p.join(directory.path, 'missing.jpg')),
    );

    expect(await DownloadHistoryProvider.hasDownloaded(historyUrl), isTrue);
    expect(await DownloadHistoryProvider.hasDownloaded(failedUrl), isFalse);
  });

  test('skips URLs already present in persisted download history', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': true,
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

    expect(statuses.single.status, RipStatus.downloadWarn);
    expect(ripper.alreadyDownloadedUrls, 1);
  });

  test('stops queued downloads after configured already-seen limit', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': true,
      'history.end_rip_after_already_seen': 2,
      'threads.size': 1,
    });
    await Utils.init();

    final firstUrl = Uri.parse('https://example.com/one.jpg');
    final secondUrl = Uri.parse('https://example.com/two.jpg');
    final thirdUrl = Uri.parse('https://example.com/three.jpg');
    await DownloadHistoryProvider.markDownloaded(firstUrl);
    await DownloadHistoryProvider.markDownloaded(secondUrl);
    await DownloadHistoryProvider.markDownloaded(thirdUrl);

    final directory =
        await Directory.systemTemp.createTemp('ripme_history_limit_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    await ripper.downloadFiles([
      RipperDownload(
        url: firstUrl,
        saveAs: File('${directory.path}/one.jpg'),
      ),
      RipperDownload(
        url: secondUrl,
        saveAs: File('${directory.path}/two.jpg'),
      ),
      RipperDownload(
        url: thirdUrl,
        saveAs: File('${directory.path}/three.jpg'),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(ripper.isStopped, isTrue);
    expect(ripper.alreadyDownloadedUrls, 3);
    expect(
      statuses
          .where((msg) => msg.object.toString().contains('Already downloaded')),
      hasLength(3),
    );
    expect(statuses.last.status, RipStatus.downloadComplete);
    expect(
      statuses.last.object.toString(),
      contains('Already seen the last 3 images ending rip'),
    );
  });

  test('HTML history threshold uses Java completion-history status', () async {
    final base = await Directory.systemTemp.createTemp('ripme_html_limit_test');
    addTearDown(() => base.delete(recursive: true));
    SharedPreferences.setMockInitialValues({
      'rips.directory': base.path,
      'remember.url_history': true,
      'history.end_rip_after_already_seen': 1,
    });
    await Utils.init();
    final url = Uri.parse('https://example.com/seen.jpg');
    await DownloadHistoryProvider.markDownloaded(url);
    final ripper = HtmlWorkingDirectoryTestRipper(
      Uri.parse('https://example.com/album'),
      'album',
    );
    await ripper.setup();
    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    await ripper.downloadFiles([
      RipperDownload(
        url: url,
        saveAs: File(p.join(ripper.workingDir.path, 'seen.jpg')),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(statuses.last.status, RipStatus.downloadCompleteHistory);
  });

  test('limits parallel downloads by threads.size', () async {
    SharedPreferences.setMockInitialValues({
      'threads.size': 2,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_parallel_download_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        ParallelTestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    await ripper.downloadFiles(
      List.generate(
        5,
        (index) => RipperDownload(
          url: Uri.parse('https://example.com/$index.jpg'),
          saveAs: File('${directory.path}/$index.jpg'),
        ),
      ),
    );

    expect(ripper.startedUrls, hasLength(5));
    expect(ripper.maxActiveDownloads, 2);
  });

  test('stops waiting for workers after the Java termination timeout',
      () async {
    SharedPreferences.setMockInitialValues({'threads.size': 1});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_worker_timeout_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TimedWaitTestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final completed = ripper.downloadFiles([
      RipperDownload(
        url: Uri.parse('https://example.com/slow.jpg'),
        saveAs: File(p.join(directory.path, 'slow.jpg')),
      ),
    ]);
    await ripper.started.future;
    await completed;

    expect(ripper.release.isCompleted, isFalse);
    ripper.release.complete();
  });

  test('runs Java auxiliary pool tasks with configured width and isolation',
      () async {
    SharedPreferences.setMockInitialValues({'threads.size': 2});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_aux_pool_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        AuxiliaryPoolTestRipper(Uri.parse('https://example.com'), directory);

    final results = await ripper.runAuxiliaryTasks<int>([
      () => ripper.task(1),
      () => ripper.task(2, fail: true),
      () => ripper.task(3),
      () => ripper.task(4),
    ]);

    expect(results, [1, 3, 4]);
    expect(ripper.maxActiveTasks, 2);
  });

  test('uses Java pending completed and errored progress percentage', () async {
    SharedPreferences.setMockInitialValues({
      'threads.size': 3,
      'remember.url_history': false,
      'download.retries': 0,
      'download.timeout': 1000,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_progress_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final releaseRemaining = Completer<void>();
    final firstCompleted = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path != '/one.jpg') {
        await releaseRemaining.future;
      }
      request.response.write('ok');
      await request.response.close();
    });
    addTearDown(server.close);

    final sub = ripper.statusStream.listen((message) {
      if (message.status == RipStatus.downloadComplete &&
          !firstCompleted.isCompleted) {
        firstCompleted.complete();
      }
    });
    addTearDown(sub.cancel);

    final download = ripper.downloadFiles([
      for (final name in ['one.jpg', 'two.jpg', 'three.jpg'])
        RipperDownload(
          url: Uri.parse('http://127.0.0.1:${server.port}/$name'),
          saveAs: File('${directory.path}/$name'),
        ),
    ]);

    await firstCompleted.future;
    expect(ripper.completionPercentage, 33);
    expect(
      ripper.statusText,
      '33% - Pending: 2, Completed: 1, Errored: 0',
    );

    releaseRemaining.complete();
    await download;
    expect(ripper.completionPercentage, 100);
    expect(
      ripper.statusText,
      '100% - Pending: 0, Completed: 3, Errored: 0',
    );
  });

  test('counts Java download errors as finished progress', () async {
    SharedPreferences.setMockInitialValues({
      'threads.size': 2,
      'remember.url_history': false,
      'download.retries': 0,
      'download.timeout': 1000,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_error_progress_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final releaseSuccess = Completer<void>();
    final firstError = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/error.jpg') {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        await releaseSuccess.future;
        request.response.write('ok');
      }
      await request.response.close();
    });
    addTearDown(server.close);

    final sub = ripper.statusStream.listen((message) {
      if (message.status == RipStatus.downloadErrored &&
          !firstError.isCompleted) {
        firstError.complete();
      }
    });
    addTearDown(sub.cancel);

    final download = ripper.downloadFiles([
      RipperDownload(
        url: Uri.parse('http://127.0.0.1:${server.port}/error.jpg'),
        saveAs: File('${directory.path}/error.jpg'),
      ),
      RipperDownload(
        url: Uri.parse('http://127.0.0.1:${server.port}/success.jpg'),
        saveAs: File('${directory.path}/success.jpg'),
      ),
    ]);

    await firstError.future;
    expect(ripper.completionPercentage, 50);
    expect(
      ripper.statusText,
      '50% - Pending: 1, Completed: 0, Errored: 1',
    );

    releaseSuccess.complete();
    await download;
    expect(ripper.completionPercentage, 100);
  });

  test('single-file rippers emit Java GET byte progress and status text',
      () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.retries': 0,
      'download.timeout': 1000,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_byte_progress_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper = SingleFileProgressTestRipper(
      Uri.parse('https://example.com/video'),
      directory,
    );
    await ripper.setup();

    final releaseSecondChunk = Completer<void>();
    final firstChunkObserved = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response
        ..bufferOutput = false
        ..contentLength = 6
        ..add([1, 2, 3]);
      await request.response.flush();
      await releaseSecondChunk.future;
      request.response.add([4, 5, 6]);
      await request.response.close();
    });
    addTearDown(server.close);

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen((message) {
      statuses.add(message);
      if (message.status == RipStatus.completedBytes &&
          !firstChunkObserved.isCompleted) {
        firstChunkObserved.complete();
      }
    });
    addTearDown(sub.cancel);

    final download = ripper.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/video.mp4'),
      File('${directory.path}/video.mp4'),
    );
    await firstChunkObserved.future;

    expect(ripper.completionPercentage, 50);
    expect(ripper.statusText, '50%  - 3.00iB / 6.00iB');
    expect(
      statuses.map((message) => message.status),
      containsAllInOrder([
        RipStatus.downloadStarted,
        RipStatus.totalBytes,
        RipStatus.completedBytes,
      ]),
    );

    releaseSecondChunk.complete();
    await download;
    expect(ripper.completionPercentage, 100);
    expect(ripper.statusText, '100%  - 6.00iB / 6.00iB');
  });

  test('passes headers and cookies through scheduled downloads', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_download_options_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper = HeaderCookieTestRipper(
        Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    await ripper.downloadFiles([
      RipperDownload(
        url: Uri.parse('https://example.com/image.jpg'),
        saveAs: File('${directory.path}/image.jpg'),
        headers: {'Referer': 'https://example.com/page'},
        cookies: {'session': 'abc'},
      ),
    ]);

    expect(ripper.receivedHeaders, {'Referer': 'https://example.com/page'});
    expect(ripper.receivedCookies, {'session': 'abc'});
  });

  test('does not start queued downloads after stop is requested', () async {
    SharedPreferences.setMockInitialValues({
      'threads.size': 1,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_stop_download_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper = StopAfterFirstDownloadRipper(
        Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    await ripper.downloadFiles([
      RipperDownload(
        url: Uri.parse('https://example.com/one.jpg'),
        saveAs: File('${directory.path}/one.jpg'),
      ),
      RipperDownload(
        url: Uri.parse('https://example.com/two.jpg'),
        saveAs: File('${directory.path}/two.jpg'),
      ),
    ]);

    expect(ripper.startedUrls, [Uri.parse('https://example.com/one.jpg')]);
  });

  test('interrupts an active download and reports Java status text', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
      'download.timeout': 1000,
      'download.retries': 0,
      'download.retry.sleep': 0,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_active_stop_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();
    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    final firstChunkSent = Completer<void>();
    final releaseSecondChunk = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.bufferOutput = false;
      request.response.add([1, 2, 3]);
      await request.response.flush();
      firstChunkSent.complete();
      await releaseSecondChunk.future;
      request.response.add([4, 5, 6]);
      await request.response.close();
    });
    addTearDown(server.close);

    final download = ripper.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/image.jpg'),
      File('${directory.path}/image.jpg'),
    );
    await firstChunkSent.future;
    ripper.stop();
    releaseSecondChunk.complete();
    await download;
    await Future<void>.delayed(Duration.zero);

    expect(statuses.last.status, RipStatus.downloadErrored);
    expect(statuses.last.object, 'Download interrupted');
  });

  test('does not start downloads when already stopped', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_prestopped_download_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper = StopAfterFirstDownloadRipper(
        Uri.parse('https://example.com/album'), directory);
    await ripper.setup();
    ripper.stop();

    await ripper.downloadFiles([
      RipperDownload(
        url: Uri.parse('https://example.com/one.jpg'),
        saveAs: File('${directory.path}/one.jpg'),
      ),
    ]);

    expect(ripper.startedUrls, isEmpty);
  });

  test('skips duplicate download URLs unless explicitly allowed', () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_duplicate_download_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.write('ok');
      await request.response.close();
    });
    addTearDown(server.close);

    final url = Uri.parse('http://127.0.0.1:${server.port}/image.jpg');
    await ripper.downloadFiles([
      RipperDownload(url: url, saveAs: File('${directory.path}/one.jpg')),
      RipperDownload(url: url, saveAs: File('${directory.path}/two.jpg')),
      RipperDownload(
        url: url,
        saveAs: File('${directory.path}/three.jpg'),
        allowDuplicate: true,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(requests, 2);
    expect(statuses.where((msg) => msg.status == RipStatus.downloadSkip),
        isNotEmpty);
  });

  test('rejects Java bare download schemes before history or output', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': true,
      'urls_only.save': true,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_bare_scheme_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();
    final statuses = <RipStatusMessage>[];
    final subscription = ripper.statusStream.listen(statuses.add);
    addTearDown(subscription.cancel);

    for (final scheme in ['http:', 'https:']) {
      await ripper.downloadFile(
        Uri.parse(scheme),
        File(p.join(directory.path, 'invalid')),
      );
    }
    await Future<void>.delayed(Duration.zero);

    expect(statuses, isEmpty);
    expect(await DownloadHistoryProvider.loadDownloadedUrls(), isEmpty);
    expect(await File(p.join(directory.path, 'urls.txt')).exists(), isFalse);
  });

  test('rewrites literal spaces in download URL text like Java', () {
    expect(AbstractRipper.preflightDownloadUrlText('http:'), isNull);
    expect(AbstractRipper.preflightDownloadUrlText('https:'), isNull);
    expect(
      AbstractRipper.preflightDownloadUrlText(
        'https://example.com/image name one.jpg',
      ),
      'https://example.com/image%20name%20one.jpg',
    );
    expect(
      AbstractRipper.preflightDownloadUrl(
        Uri.parse('https://example.com/image%20name.jpg'),
      ).toString(),
      'https://example.com/image%20name.jpg',
    );
  });

  test('matches Java ignored extensions from the final URL path suffix',
      () async {
    SharedPreferences.setMockInitialValues({
      'download.ignore_extensions': ' mp4, GIF ',
      'remember.url_history': false,
      'download.retries': 0,
      'download.timeout': 1000,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_ignore_extension_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.write('ok');
      await request.response.close();
    });
    addTearDown(server.close);

    await ripper.downloadFiles([
      RipperDownload(
        url: Uri.parse(
            'http://127.0.0.1:${server.port}/archive.tar.GIF?token=1'),
        saveAs: File('${directory.path}/archive.gif'),
      ),
      RipperDownload(
        url: Uri.parse('http://127.0.0.1:${server.port}/.MP4#fragment'),
        saveAs: File('${directory.path}/video.mp4'),
      ),
      RipperDownload(
        url: Uri.parse('http://127.0.0.1:${server.port}/video.mp4/segment'),
        saveAs: File('${directory.path}/segment'),
      ),
      RipperDownload(
        url: Uri.parse('http://127.0.0.1:${server.port}/folder.with.dot/file'),
        saveAs: File('${directory.path}/file'),
      ),
      RipperDownload(
        url: Uri.parse('http://127.0.0.1:${server.port}/plain'),
        saveAs: File('${directory.path}/plain'),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    final skipped =
        statuses.where((message) => message.status == RipStatus.downloadSkip);
    expect(skipped, hasLength(2));
    expect(
      skipped.every(
          (message) => message.object.toString().contains('ignored extension')),
      isTrue,
    );
    expect(requests, 3);
  });

  test('saves URLs to urls.txt instead of downloading when configured',
      () async {
    SharedPreferences.setMockInitialValues({
      'urls_only.save': true,
      'remember.url_history': false,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_urls_only_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    await ripper.downloadFiles([
      RipperDownload(
        url: Uri.parse('https://example.com/one.jpg'),
        saveAs: File('${directory.path}/one.jpg'),
      ),
      RipperDownload(
        url: Uri.parse('https://example.com/two.jpg'),
        saveAs: File('${directory.path}/two.jpg'),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    final urlsFile = File('${directory.path}/urls.txt');
    expect(await urlsFile.readAsLines(), [
      'https://example.com/one.jpg',
      'https://example.com/two.jpg',
    ]);
    expect(await File('${directory.path}/one.jpg').exists(), isFalse);
    expect(statuses.map((msg) => msg.status),
        everyElement(RipStatus.downloadComplete));
    expect(
        await DownloadHistoryProvider.hasDownloaded(
            Uri.parse('https://example.com/one.jpg')),
        isFalse);
  });

  test('URL-only mode keeps Java append-to-folder path side effects', () async {
    SharedPreferences.setMockInitialValues({
      'urls_only.save': true,
      'remember.url_history': true,
    });
    await Utils.init();

    final parent =
        await Directory.systemTemp.createTemp('ripme_urls_only_append_test');
    addTearDown(() => parent.delete(recursive: true));
    final workingDir = Directory(p.join(parent.path, 'album'));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), workingDir);
    await ripper.setup();
    AbstractRipper.folderNameSuffix = '-extra';

    final url = Uri.parse('https://example.com/one.jpg');
    await ripper.downloadFile(
      url,
      File(p.join(workingDir.path, 'subdir', 'one.jpg')),
    );

    final urlsFile = File(p.join(workingDir.path, 'urls.txt'));
    expect(await urlsFile.readAsLines(), ['https://example.com/one.jpg']);
    expect(
      await Directory(
        p.join(parent.path, 'album-extra', 'subdir'),
      ).exists(),
      isTrue,
    );
    expect(
      await File(p.join(parent.path, 'album-extra', 'urls.txt')).exists(),
      isFalse,
    );
    expect(await DownloadHistoryProvider.hasDownloaded(url), isFalse);
  });

  test('legacy Flutter history key remains a fallback for URL history',
      () async {
    SharedPreferences.setMockInitialValues({
      'history.skip_downloaded_urls': false,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_history_fallback_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.write('ok');
      await request.response.close();
    });
    addTearDown(server.close);
    final url = Uri.parse('http://127.0.0.1:${server.port}/image.jpg');
    await DownloadHistoryProvider.markDownloaded(url);

    await ripper.downloadFile(url, File('${directory.path}/image.jpg'));
    await Future<void>.delayed(Duration.zero);

    expect(requests, 1);
    expect(
        statuses.any((msg) => msg.status == RipStatus.downloadStarted), isTrue);
  });

  test('sanitizes final save filename in the shared download path', () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_sanitize_filename_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write('ok');
      await request.response.close();
    });
    addTearDown(server.close);

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    await ripper.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/image.jpg'),
      File('${directory.path}/bad:name?.jpg'),
    );
    await Future<void>.delayed(Duration.zero);

    final savedFile = File(p.join(directory.path, 'bad_name_.jpg'));
    expect(await savedFile.readAsString(), 'ok');
    expect(statuses.last.status, RipStatus.downloadComplete);
    expect(statuses.last.object, savedFile.path);
  });

  test('MIME extension detection appends the resolved Java image extension',
      () async {
    SharedPreferences.setMockInitialValues({
      'remember.url_history': false,
    });
    await Utils.init();

    final directory =
        await Directory.systemTemp.createTemp('ripme_mime_extension_test');
    addTearDown(() => directory.delete(recursive: true));
    final ripper =
        TestRipper(Uri.parse('https://example.com/album'), directory);
    await ripper.setup();

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.add(
        [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3],
      );
      await request.response.close();
    });
    addTearDown(server.close);

    final statuses = <RipStatusMessage>[];
    final sub = ripper.statusStream.listen(statuses.add);
    addTearDown(sub.cancel);

    final saveAs = File(p.join(directory.path, 'image'));
    await ripper.downloadFile(
      Uri.parse('http://127.0.0.1:${server.port}/object'),
      saveAs,
      getFileExtFromMIME: true,
    );
    await Future<void>.delayed(Duration.zero);

    final resolved = File('${saveAs.path}.png');
    expect(await saveAs.exists(), isFalse);
    expect(await resolved.readAsBytes(), hasLength(11));
    expect(statuses.last.status, RipStatus.downloadComplete);
    expect(statuses.last.object, resolved.path);
  });
}
