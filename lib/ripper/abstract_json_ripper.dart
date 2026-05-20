import 'abstract_ripper.dart';
import '../ui/rip_status_message.dart';

abstract class AbstractJSONRipper extends AbstractRipper {
  AbstractJSONRipper(super.url);

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
