import 'dart:io';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import '../utils/utils.dart';
import '../utils/http_utils.dart';
import '../ui/rip_status_message.dart';

abstract class AbstractRipper {
  static final Logger logger = Logger();
  final Uri url;
  late Directory workingDir;
  bool _shouldStop = false;

  final StreamController<RipStatusMessage> _statusController = StreamController<RipStatusMessage>.broadcast();
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

  Future<void> downloadFile(Uri url, File saveAs, {Map<String, String>? headers}) async {
    if (isStopped) return;
    try {
      sendUpdate(RipStatus.downloadStarted, url.toString());
      await Http.downloadFile(url, saveAs, headers: headers);
      sendUpdate(RipStatus.downloadComplete, saveAs.path);
    } catch (e) {
      sendUpdate(RipStatus.downloadErrored, "$url : \${e.toString()}");
    }
  }

  void dispose() {
    _statusController.close();
  }
}
