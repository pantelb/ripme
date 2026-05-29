import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class SoundgasmRipper extends AbstractHTMLRipper {
  static final RegExp _gidPattern = RegExp(
    r'^/u/([a-zA-Z0-9_-]+)/([a-zA-Z0-9_-]+).*$',
  );
  static final RegExp _m4aPattern = RegExp(r'm4a\:\s"(https?:.*)"');

  SoundgasmRipper(super.url);

  @override
  String getHost() => 'soundgasm';

  String getDomain() => 'soundgasm.net';

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern
        .firstMatch(url.hasQuery ? '${url.path}?${url.query}' : url.path);
    if (match != null) return match.group(match.groupCount)!;

    throw FormatException(
      'Expected soundgasm.net format: '
      'soundgasm.net/u/username/id or  Got: $url',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    final Document page;
    try {
      page = await Http.get(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    var index = 0;
    for (final audioUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final audioUri = Uri.parse(audioUrl);
      downloads.add(
        RipperDownload(
          url: audioUri,
          saveAs:
              File(p.join(workingDir.path, fileNameForUrl(audioUri, index))),
        ),
      );
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return audioUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> audioUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final script in page.querySelectorAll('script')) {
      final match = _m4aPattern.firstMatch(script.text);
      if (match != null) result.add(match.group(1)!);
    }
    return result;
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${prefix(index)}$fileName');
  }

  static String prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
