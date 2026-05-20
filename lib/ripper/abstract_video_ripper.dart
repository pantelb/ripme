import 'dart:io';
import 'abstract_ripper.dart';
import '../utils/http_utils.dart';
import '../ui/rip_status_message.dart';

abstract class AbstractVideoRipper extends AbstractRipper {
  AbstractVideoRipper(super.url);

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      Uri videoUrl = await getVideoURLForRip(url);
      String fileName = await _getFileName(videoUrl);
      File saveAs = File(workingDir.path + Platform.pathSeparator + fileName);

      sendUpdate(RipStatus.downloadStarted, videoUrl.toString());
      await Http.downloadFile(videoUrl, saveAs);
      sendUpdate(RipStatus.downloadComplete, saveAs.path);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Uri> getVideoURLForRip(Uri url);

  Future<String> _getFileName(Uri url) async {
    return url.pathSegments.last;
  }
}
