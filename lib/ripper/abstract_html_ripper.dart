import 'dart:io';
import 'package:html/dom.dart';
import 'package:path/path.dart' as p;
import 'abstract_ripper.dart';
import '../utils/http_utils.dart';
import '../ui/rip_status_message.dart';

abstract class AbstractHTMLRipper extends AbstractRipper {
  AbstractHTMLRipper(super.url);

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    Document doc;
    try {
      doc = await Http.get(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    if (hasQueueSupport() && pageContainsAlbums(url)) {
      final childUrls = await getAlbumsToQueue(doc);
      for (final childUrl in childUrls) {
        if (isStopped) break;
        sendUpdate(RipStatus.queueAdd, childUrl);
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    int index = 0;
    while (true) {
      List<String> imageURLs = await getURLsFromPage(doc);
      final downloads = <RipperDownload>[];

      for (String imageURL in imageURLs) {
        if (isStopped) break;
        index++;
        Uri imageUri = Uri.parse(imageURL);
        String fileName = _getFileName(imageUri, index);
        File saveAs = File(p.join(workingDir.path, fileName));
        downloads.add(RipperDownload(url: imageUri, saveAs: saveAs));
      }
      await downloadFiles(downloads);

      if (isStopped) break;

      Uri? nextUri = await getNextPage(doc);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        doc = await Http.get(nextUri);
      } catch (e) {
        break;
      }
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<List<String>> getURLsFromPage(Document page);
  Future<Uri?> getNextPage(Document page);
  bool hasQueueSupport() => false;
  bool pageContainsAlbums(Uri url) => false;
  Future<List<String>> getAlbumsToQueue(Document page) async => const [];

  String _getFileName(Uri url, int index) {
    String fileName =
        url.pathSegments.isNotEmpty ? url.pathSegments.last : "file";
    if (fileName.contains('?')) {
      fileName = fileName.substring(0, fileName.indexOf('?'));
    }
    return "${index.toString().padLeft(3, '0')}_$fileName";
  }
}
