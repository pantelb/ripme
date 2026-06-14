import 'dart:io';
import 'package:html/dom.dart';
import 'package:path/path.dart' as p;
import 'abstract_ripper.dart';
import '../utils/http_utils.dart';
import '../ui/rip_status_message.dart';

abstract class AbstractHTMLRipper extends AbstractRipper {
  AbstractHTMLRipper(super.url);

  Document? _cachedFirstPage;

  @override
  RipStatus get historyLimitStatus => RipStatus.downloadCompleteHistory;

  Future<Document> fetchPage(Uri uri) => Http.get(uri);

  Future<Document?> getFirstPage() => fetchPage(url);

  Future<Document> getCachedFirstPage() async {
    final cached = _cachedFirstPage;
    if (cached != null) return cached;

    final page = await getFirstPage();
    if (page == null) {
      throw StateError('Unable to load first page: $url');
    }
    _cachedFirstPage = page;
    return page;
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    Document doc;
    try {
      doc = await getCachedFirstPage();
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
    final processedLocations = <String>{};
    while (true) {
      final location = Http.documentLocation(doc)?.toString() ?? url.toString();
      if (!processedLocations.add(location)) break;

      List<String> imageURLs = await getURLsFromPage(doc);
      if (isThisATest && imageURLs.length > 1) {
        imageURLs = imageURLs.take(1).toList(growable: false);
      }
      requireMediaFound(imageURLs, url);
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

      if (isStopped || isThisATest) break;

      Uri? nextUri = await getNextPage(doc);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        doc = await fetchPage(nextUri);
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
