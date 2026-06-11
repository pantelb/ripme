import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/download_history_provider.dart';
import 'package:ripme/ripper/abstract_ripper.dart';
import 'package:ripme/ui/rip_status_message.dart';
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

class ParallelTestRipper extends TestRipper {
  ParallelTestRipper(super.url, super.directory);

  int activeDownloads = 0;
  int maxActiveDownloads = 0;
  final startedUrls = <Uri>[];

  @override
  Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      bool allowDuplicate = false}) async {
    startedUrls.add(url);
    activeDownloads++;
    if (activeDownloads > maxActiveDownloads) {
      maxActiveDownloads = activeDownloads;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    activeDownloads--;
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
      bool allowDuplicate = false}) async {
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
      bool allowDuplicate = false}) async {
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

void main() {
  tearDown(() {
    AbstractRipper.folderNameSuffix = null;
  });

  test('setup uses Java-safe truncated working directory names', () async {
    final base = await Directory.systemTemp.createTemp('ripme_working_dir_test');
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
      'remember.url_history': false,
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

    expect(statuses.single.status, RipStatus.downloadSkip);
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
    expect(ripper.alreadyDownloadedUrls, 2);
    expect(
      statuses
          .where((msg) => msg.object.toString().contains('Already downloaded')),
      hasLength(2),
    );
    expect(
      statuses.last.object.toString(),
      contains('Already seen the last 2 files, ending rip'),
    );
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

  test('skips configured ignored file extensions', () async {
    SharedPreferences.setMockInitialValues({
      'download.ignore_extensions': 'mp4, gif',
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

    await ripper.downloadFiles([
      RipperDownload(
        url: Uri.parse('https://example.com/video.MP4?token=1'),
        saveAs: File('${directory.path}/video.mp4'),
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(statuses.single.status, RipStatus.downloadSkip);
    expect(statuses.single.object.toString(), contains('ignored extension'));
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
}
