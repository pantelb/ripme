import 'abstract_ripper.dart';
import '../ui/rip_status_message.dart';

abstract class AbstractJSONRipper extends AbstractRipper {
  AbstractJSONRipper(super.url);

  bool get usesJavaSharedTestMode => true;

  bool get shouldStopJsonPagination =>
      isStopped || (usesJavaSharedTestMode && isThisATest);

  List<T> limitJsonMediaForTest<T>(Iterable<T> media) {
    if (!usesJavaSharedTestMode || !isThisATest) {
      return media.toList(growable: false);
    }
    return media.take(1).toList(growable: false);
  }

  @override
  Future<void> downloadFiles(Iterable<RipperDownload> downloads) {
    final effectiveDownloads =
        usesJavaSharedTestMode && isThisATest ? downloads.take(1) : downloads;
    return super.downloadFiles(effectiveDownloads);
  }

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
