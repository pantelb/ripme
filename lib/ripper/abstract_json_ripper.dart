import 'abstract_ripper.dart';
import '../ui/rip_status_message.dart';

abstract class AbstractJSONRipper extends AbstractRipper {
  AbstractJSONRipper(super.url);

  @override
  bool get usesAlbumTitleSetting => true;

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    await parseJSON(url);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<void> parseJSON(Uri url);
}
