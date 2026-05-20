import 'dart:io';
import 'abstract_ripper.dart';
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

      await downloadFile(videoUrl, saveAs);
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
