import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class FemjoyhunterRipper extends AbstractHTMLRipper {
  FemjoyhunterRipper(super.url);

  static const String domain = 'femjoyhunter.com';
  static const String downloadReferer = 'https://a2h6m3w6.ssl.hwcdn.net/';
  static final RegExp _gidPattern =
      RegExp(r'https?://www\.femjoyhunter\.com/([a-zA-Z0-9_-]+)/?');

  @override
  String getHost() => 'femjoyhunter';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => _gidPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected femjoyhunter URL format: femjoyhunter.com/ID - got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await Http.get(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final uri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: uri,
          saveAs: File(p.join(workingDir.path, fileNameForUrl(uri, index))),
          headers: const {'Referer': downloadReferer},
        ),
      );
    }
    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromPage(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> imageUrlsFromPage(Document page) {
    return [
      for (final image in page.querySelectorAll('img'))
        image.attributes['src'] ?? '',
    ];
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
