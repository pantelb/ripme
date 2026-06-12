import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:math';
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
  static final Random _randomGenerator = Random();
  static String? folderNameSuffix;
  final Uri url;
  late Directory workingDir;
  bool _shouldStop = false;
  int alreadyDownloadedUrls = 0;
  final Set<String> _attemptedDownloadUrls = <String>{};
  final Map<String, int> _preRegisteredDownloads = <String, int>{};
  final Set<String> _pendingDownloads = <String>{};
  final Set<String> _completedDownloads = <String>{};
  final Set<String> _erroredDownloads = <String>{};
  int _bytesTotal = 1;
  int _bytesCompleted = 1;
  Future<void> _urlOnlyWrite = Future<void>.value();
  Future<void> _historyWrite = Future<void>.value();

  final StreamController<RipStatusMessage> _statusController =
      StreamController<RipStatusMessage>.broadcast();
  Stream<RipStatusMessage> get statusStream => _statusController.stream;

  AbstractRipper(this.url);

  void stop() {
    _shouldStop = true;
  }

  bool get isStopped => _shouldStop;

  int get completionPercentage {
    if (usesByteProgress) {
      if (_bytesTotal == 0) {
        return _bytesCompleted == 0 ? 0 : 2147483647;
      }
      return (100 * (_bytesCompleted / _bytesTotal)).truncate();
    }
    final total = _pendingDownloads.length +
        _completedDownloads.length +
        _erroredDownloads.length;
    if (total == 0) return 0;
    return (100 *
            (_completedDownloads.length + _erroredDownloads.length) /
            total)
        .truncate();
  }

  String get statusText {
    if (usesByteProgress) {
      return Utils.getByteStatusText(
        completionPercentage,
        _bytesCompleted,
        _bytesTotal,
      );
    }
    return '$completionPercentage% - Pending: ${_pendingDownloads.length}, '
        'Completed: ${_completedDownloads.length}, '
        'Errored: ${_erroredDownloads.length}';
  }

  bool get usesByteProgress => false;

  bool get fetchesByteTotalBeforeDownload => false;

  bool get includesDownloadCookieHeader => true;

  Map<String, String>? resolveDownloadHeaders(
    Uri url,
    Map<String, String>? requestedHeaders,
  ) =>
      requestedHeaders;

  Map<String, String>? resolveDownloadCookies(
    Map<String, String>? requestedCookies,
  ) =>
      requestedCookies;

  Future<void> setup() async {
    workingDir = await _getWorkingDir(url);
    if (!await workingDir.exists()) {
      await workingDir.create(recursive: true);
    }
  }

  Future<Directory> _getWorkingDir(Uri url) async {
    Directory baseDir = await Utils.getWorkingDirectory();
    final saveAlbumTitles = Utils.getConfigBoolean('album_titles.save', true);
    String title = usesAlbumTitleSetting && !saveAlbumTitles
        ? await _getDefaultAlbumTitle(url)
        : await getAlbumTitle(url);
    title = Utils.filesystemSafe(title);
    final path = await Utils.getOriginalDirectory(p.join(baseDir.path, title));
    return Directory(path);
  }

  bool get usesAlbumTitleSetting => false;

  Future<void> rip();

  Future<void> run() async {
    try {
      await rip();
    } finally {
      await _cleanup();
    }
  }

  Future<void> _cleanup() async {
    if (!await workingDir.exists()) return;
    if (await workingDir.list().isEmpty) {
      await workingDir.delete();
    }
  }

  double nextGaussian() {
    var first = 0.0;
    while (first == 0) {
      first = _randomGenerator.nextDouble();
    }
    final second = _randomGenerator.nextDouble();
    return sqrt(-2 * log(first)) * cos(2 * pi * second);
  }

  Future<bool> sleepWithGaussianJitter(int milliseconds) async {
    final adjusted =
        (milliseconds + nextGaussian() * milliseconds * 0.3).toInt();
    final minimum = (milliseconds * 0.47).toInt();
    await Http.delay(Duration(milliseconds: max(adjusted, minimum)));
    return true;
  }

  String getHost();

  Future<String> getGID(Uri url);

  Future<String> getAlbumTitle(Uri url) async {
    return _getDefaultAlbumTitle(url);
  }

  Future<String> _getDefaultAlbumTitle(Uri url) async {
    return "${getHost()}_${await getGID(url)}";
  }

  static String getFileName(
    Uri url, {
    String? prefix,
    String? fileName,
    String? extension,
  }) {
    var resolvedName = fileName ?? '';
    if (resolvedName.trim().isEmpty) {
      final external = url.toString();
      resolvedName = external.substring(external.lastIndexOf('/') + 1);
    }

    for (final delimiter in ['?', '#', '&', ':']) {
      final index = resolvedName.indexOf(delimiter);
      if (index >= 0) {
        resolvedName = resolvedName.substring(0, index);
      }
    }

    if (prefix != null && prefix.trim().isNotEmpty) {
      resolvedName = '$prefix$resolvedName';
    }

    // Java uses String.split(".") here. Since "." is a regex wildcard, the
    // shipped implementation never derives an extension from the URL.
    if (extension != null) {
      resolvedName = '$resolvedName.$extension';
    }

    return Utils.sanitizeSaveAs(resolvedName);
  }

  void sendUpdate(RipStatus status, dynamic message) {
    _statusController.add(RipStatusMessage(status, message));
  }

  bool canRip(Uri url);

  Future<void> downloadFiles(Iterable<RipperDownload> downloads) async {
    final queue = Queue<RipperDownload>.of(downloads);
    if (queue.isEmpty || isStopped) return;

    _preRegisterDownloads(queue);
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
    _stopIfHistoryLimitReached();
  }

  Future<void> downloadFile(Uri url, File saveAs,
      {Map<String, String>? headers,
      Map<String, String>? cookies,
      bool allowDuplicate = false}) async {
    if (isStopped) return;
    try {
      if (_shouldIgnoreUrl(url)) {
        _discardPreRegisteredDownload(url);
        sendUpdate(RipStatus.downloadSkip, 'Skipping $url - ignored extension');
        return;
      }

      if (!allowDuplicate && !_attemptedDownloadUrls.add(url.toString())) {
        _discardPreRegisteredDownload(url);
        sendUpdate(RipStatus.downloadSkip, 'Already attempted: $url');
        return;
      }

      if (_shouldRememberUrlHistory() &&
          await DownloadHistoryProvider.hasDownloaded(url)) {
        _discardPreRegisteredDownload(url);
        alreadyDownloadedUrls++;
        sendUpdate(RipStatus.downloadWarn, 'Already downloaded $url');
        return;
      }

      _consumeOrRegisterPendingDownload(url);
      if (Utils.getConfigBoolean('urls_only.save', false)) {
        final resolvedSaveAs = _sanitizeSaveAs(resolveSavePath(saveAs));
        if (!await resolvedSaveAs.parent.exists()) {
          await resolvedSaveAs.parent.create(recursive: true);
        }
        final urlFile = await _saveUrlOnly(url);
        _completeDownload(url);
        sendUpdate(RipStatus.downloadComplete, urlFile.path);
        return;
      }

      saveAs = _sanitizeSaveAs(resolveSavePath(saveAs));
      if (Platform.isWindows && saveAs.absolute.path.length > 259) {
        saveAs = File(
          Utils.shortenSaveAsWindows(
            p.dirname(saveAs.path),
            p.basename(saveAs.path),
          ),
        );
      }

      if (_shouldRememberUrlHistory()) {
        await _rememberDownloadUrl(url);
      }

      if (!Utils.getConfigBoolean('file.overwrite', false) &&
          await saveAs.exists()) {
        _completeDownload(url);
        sendUpdate(
          RipStatus.downloadWarn,
          '$url already saved as ${saveAs.path}',
        );
        return;
      }

      void updateTotalBytes(int bytes) {
        _bytesTotal = bytes;
        sendUpdate(RipStatus.totalBytes, bytes);
      }

      void updateCompletedBytes(int bytes) {
        _bytesCompleted = bytes;
        sendUpdate(RipStatus.completedBytes, bytes);
      }

      final effectiveHeaders = resolveDownloadHeaders(url, headers);
      final effectiveCookies = resolveDownloadCookies(cookies);
      if (usesByteProgress && fetchesByteTotalBeforeDownload) {
        final totalBytes = await Http.getDownloadContentLength(
          url,
          headers: effectiveHeaders,
          cookies: effectiveCookies,
          includeCookieHeader: includesDownloadCookieHeader,
        );
        updateTotalBytes(totalBytes);
      }
      sendUpdate(RipStatus.downloadStarted, url.toString());
      await Http.downloadFile(
        url,
        saveAs,
        headers: effectiveHeaders,
        cookies: effectiveCookies,
        shouldStop: () => isStopped,
        onTotalBytes: usesByteProgress && !fetchesByteTotalBeforeDownload
            ? updateTotalBytes
            : null,
        onBytesCompleted: usesByteProgress ? updateCompletedBytes : null,
        includeCookieHeader: includesDownloadCookieHeader,
      );
      _completeDownload(url);
      sendUpdate(RipStatus.downloadComplete, saveAs.path);
    } on DownloadInterruptedException {
      _errorDownload(url);
      sendUpdate(RipStatus.downloadErrored, 'Download interrupted');
    } catch (e) {
      _errorDownload(url);
      sendUpdate(RipStatus.downloadErrored, "$url : ${e.toString()}");
    }
  }

  void _preRegisterDownloads(Iterable<RipperDownload> downloads) {
    final seen = <String>{..._attemptedDownloadUrls};
    for (final download in downloads) {
      final key = download.url.toString();
      if (_shouldIgnoreUrl(download.url)) continue;
      if (!download.allowDuplicate && !seen.add(key)) continue;
      _pendingDownloads.add(key);
      _preRegisteredDownloads.update(key, (count) => count + 1,
          ifAbsent: () => 1);
    }
  }

  void _consumeOrRegisterPendingDownload(Uri url) {
    final key = url.toString();
    final count = _preRegisteredDownloads[key] ?? 0;
    if (count > 1) {
      _preRegisteredDownloads[key] = count - 1;
    } else if (count == 1) {
      _preRegisteredDownloads.remove(key);
    } else {
      _pendingDownloads.add(key);
    }
  }

  void _discardPreRegisteredDownload(Uri url) {
    final key = url.toString();
    final count = _preRegisteredDownloads[key] ?? 0;
    if (count == 0) return;
    if (count > 1) {
      _preRegisteredDownloads[key] = count - 1;
    } else {
      _preRegisteredDownloads.remove(key);
    }
    _pendingDownloads.remove(key);
  }

  void _completeDownload(Uri url) {
    final key = url.toString();
    _pendingDownloads.remove(key);
    _completedDownloads.add(key);
  }

  void _errorDownload(Uri url) {
    final key = url.toString();
    _pendingDownloads.remove(key);
    _erroredDownloads.add(key);
  }

  File _sanitizeSaveAs(File saveAs) {
    final sanitizedName = Utils.sanitizeSaveAs(p.basename(saveAs.path));
    if (sanitizedName == p.basename(saveAs.path)) return saveAs;
    return File(p.join(p.dirname(saveAs.path), sanitizedName));
  }

  File resolveSavePath(File saveAs) {
    final suffix = folderNameSuffix;
    if (suffix == null || suffix.isEmpty) return saveAs;
    if (!p.isWithin(workingDir.path, saveAs.path)) return saveAs;

    final siblingRoot = p.join(
      p.dirname(workingDir.path),
      '${p.basename(workingDir.path)}$suffix',
    );
    return File(p.join(
      siblingRoot,
      p.relative(saveAs.path, from: workingDir.path),
    ));
  }

  bool _shouldRememberUrlHistory() {
    return Utils.getConfigBooleanWithFallback(
      'remember.url_history',
      'history.skip_downloaded_urls',
      true,
    );
  }

  Future<File> _saveUrlOnly(Uri url) async {
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
    return urlFile;
  }

  Future<void> _rememberDownloadUrl(Uri url) async {
    final previousWrite = _historyWrite;
    _historyWrite = previousWrite.then(
      (_) => DownloadHistoryProvider.markDownloaded(url),
    );
    await _historyWrite;
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
        historyLimitStatus,
        'Already seen the last $alreadyDownloadedUrls images ending rip',
      );
      stop();
    }
  }

  RipStatus get historyLimitStatus => RipStatus.downloadComplete;

  void dispose() {
    _statusController.close();
  }
}
