import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class DynastyscansRipper extends AbstractHTMLRipper {
  DynastyscansRipper(super.url);

  static const String domain = 'dynasty-scans.com';
  static final RegExp _gidPattern =
      RegExp(r'https?://dynasty-scans.com/chapters/([\S]+)/?$');

  @override
  String getHost() => 'dynasty-scans';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;
    throw FormatException(
      'Expected dynasty-scans URL format: dynasty-scans.com/chapters/ID - got $url instead',
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
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    var index = 0;
    while (!isStopped) {
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(imageUrl);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, downloadFileName(uri, index))),
          ),
        );
      }

      if (downloads.isEmpty) {
        sendUpdate(RipStatus.ripErrored, 'No images found at $url');
        break;
      }
      await downloadFiles(downloads);
      if (isStopped) break;

      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await Http.get(nextUri);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final link = page.querySelector('a[id=next_link]');
    final href = link?.attributes['href'];
    if (href == null || href == '#') return null;
    return Uri.parse('https://dynasty-scans.com$href');
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return urlsFromPage(page);
  }

  static List<String> urlsFromPage(Document page) {
    final jsonText = pagesJsonText(page);
    final imageArray = jsonDecode(jsonText);
    if (imageArray is! List) return const [];

    final urls = <String>[];
    for (final image in imageArray) {
      if (image is! Map) continue;
      final path = image['image'];
      if (path is String) {
        urls.add('https://dynasty-scans.com$path');
      }
    }
    return urls;
  }

  static String pagesJsonText(Document page) {
    String? jsonText;
    for (final script in page.querySelectorAll('script')) {
      final data = script.text;
      if (data.contains('var pages')) {
        jsonText = data
            .replaceAll('var pages = ', '')
            .replaceAll(RegExp(r'//<!\[CDATA\['), '')
            .replaceAll(RegExp(r'//\]\]>'), '');
      }
    }
    if (jsonText == null) {
      throw const FormatException('No Dynasty pages JSON found');
    }
    return jsonText;
  }

  static String downloadFileName(Uri uri, int index) {
    var fileName =
        uri.toString().substring(uri.toString().lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) {
        fileName = fileName.substring(0, separatorIndex);
      }
    }
    return Utils.sanitizeSaveAs('${_prefix(index)}$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
