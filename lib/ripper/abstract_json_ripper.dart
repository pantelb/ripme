import 'dart:io';
import 'package:path/path.dart' as p;
import 'abstract_ripper.dart';
import '../utils/http_utils.dart';
import '../ui/rip_status_message.dart';

abstract class AbstractJSONRipper extends AbstractRipper {
  AbstractJSONRipper(Uri url) : super(url);

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      await parseJSON(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<void> parseJSON(Uri url);
}
