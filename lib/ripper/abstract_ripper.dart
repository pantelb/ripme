import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import '../download_history_provider.dart';
import '../utils/utils.dart';
import '../utils/http_utils.dart';
import '../ui/rip_status_message.dart';

class RipperDownload {
  final Uri url;
  final File saveAs;
  final Map<String, String>? headers;
  final Map<String, String>? cookies;
  final bool allowDuplicate;

  const RipperDownload({
    required this.url,
    required this.saveAs,
    this.headers,
    this.cookies,
    this.allowDuplicate = false,
  });
}

abstract class AbstractRipper {
  static final Logger logger = Logger();
  final Uri url;
  late Directory workingDir;
  bool _shouldStop = false;
  int alreadyDownloadedUrls = 0;
  final Set<String> _attemptedDownloadUrls = <String>{};
  Future<void> _urlOnlyWrite = Future<void>.value();

  final StreamController<RipStatusMessage> _statusController =
      StreamController<RipStatusMessage>.broadcast();
  Stream<RipStatusMessage> get statusStream => _statusController.stream;

  AbstractRipper(this.url);

  void stop() {
    _shouldStop = true;
  }

  bool get isStopped => _shouldStop;

  Future<void> setup() async {
    workingDir = await _getWorkingDir(url);
    if (!await workingDir.exists()) {
      await workingDir.create(recursive: true);
    }
  }

  Future<Directory> _getWorkingDir(Uri url) async {
    Directory baseDir = await Utils.getWorkingDirectory();
    String title = await getAlbumTitle(url);
    title = Utils.filesystemSafe(title);
    return Directory(p.join(baseDir.path, title));
  }

  Future<void> rip();

  String getHost();

  Future<String> getGID(Uri url);

  Future<String> getAlbumTitle(Uri url) async {
    return "${getHost()}_${await getGID(url)}";
  }

  void sendUpdate(RipStatus status, dynamic message) {
    _statusController.add(RipStatusMessage(status, message));
  }

  bool canRip(Uri url);

  Future<void> downloadFiles(Iterable<RipperDownload> downloads) async {
    final queue = Queue<RipperDownload>.of(downloads);
    if (queue.isEmpty || isStopped) return;

    final configuredThreads = Utils.getConfigInteger('threads.size', 5);
    final workerCount = configuredThreads.clamp(1, queue.length);

    Future<void> worker() async {
      while (!isStopped && queue.isNotEmpty) {
        final item = queue.removeFirst();
        await downloadFile(
          item.url,
          item.saveAs,
          headers: item.headers,
          cookies: item.cookies,
          allowDuplicate: item.allowDuplicate,
        );
      }
    }

    await Future.wait(List.generate(workerCount, (_) => worker()));
  }

  Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      bool allowDuplicate = false}) async {
    if (isStopped) return;
    try {
      if (_shouldIgnoreUrl(url)) {
        sendUpdate(RipStatus.downloadSkip, 'Skipping $url - ignored extension');
        return;
      }

      if (!allowDuplicate && !_attemptedDownloadUrls.add(url.toString())) {
        sendUpdate(RipStatus.downloadSkip, 'Already attempted: $url');
        return;
      }

      if (Utils.getConfigBoolean('history.skip_downloaded_urls', true) &&
          await DownloadHistoryProvider.hasDownloaded(url)) {
        alreadyDownloadedUrls++;
        sendUpdate(RipStatus.downloadSkip, 'Already downloaded: $url');
        _stopIfHistoryLimitReached();
        return;
      }

      if (Utils.getConfigBoolean('urls_only.save', false)) {
        await _saveUrlOnly(url);
        alreadyDownloadedUrls = 0;
        return;
      }

      if (!Utils.getConfigBoolean('file.overwrite', false) &&
          await saveAs.exists()) {
        alreadyDownloadedUrls++;
        sendUpdate(
            RipStatus.downloadSkip, 'File already exists: ${saveAs.path}');
        _stopIfHistoryLimitReached();
        return;
      }

      sendUpdate(RipStatus.downloadStarted, url.toString());
      await Http.downloadFile(url, saveAs, headers: headers, cookies: cookies);
      await DownloadHistoryProvider.markDownloaded(url);
      alreadyDownloadedUrls = 0;
      sendUpdate(RipStatus.downloadComplete, saveAs.path);
    } catch (e) {
      sendUpdate(RipStatus.downloadErrored, "$url : ${e.toString()}");
    }
  }

  Future<void> _saveUrlOnly(Uri url) async {
    final previousWrite = _urlOnlyWrite;
    final urlFile = File(p.join(workingDir.path, 'urls.txt'));
    _urlOnlyWrite = previousWrite.then((_) async {
      if (!await urlFile.parent.exists()) {
        await urlFile.parent.create(recursive: true);
      }
      await urlFile.writeAsString('$url${Platform.lineTerminator}',
          mode: FileMode.append);
    });
    await _urlOnlyWrite;
    sendUpdate(RipStatus.downloadComplete, urlFile.path);
  }

  bool _shouldIgnoreUrl(Uri url) {
    final ignoredExtensions =
        Utils.getConfigStringList('download.ignore_extensions');
    if (ignoredExtensions.isEmpty) return false;

    final path = url.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot < 0 || lastDot == path.length - 1) return false;

    final extension = path.substring(lastDot + 1).toLowerCase();
    return ignoredExtensions
        .any((ignored) => ignored.toLowerCase() == extension);
  }

  void _stopIfHistoryLimitReached() {
    final limit = Utils.getConfigInteger(
        'history.end_rip_after_already_seen', 1000000000);
    if (alreadyDownloadedUrls >= limit) {
      sendUpdate(
        RipStatus.downloadSkip,
        'Already seen the last $alreadyDownloadedUrls files, ending rip',
      );
      stop();
    }
  }

  void dispose() {
    _statusController.close();
  }
}
