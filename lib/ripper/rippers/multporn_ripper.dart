import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class MultpornRipper extends AbstractHTMLRipper {
  static final RegExp _nodePattern =
      RegExp(r'^https?://multporn\.net/node/(\d+)/.*$');
  static final RegExp _nodeHrefPattern = RegExp(r'/node/(\d+)/.*');

  MultpornRipper(super.url);

  Uri? _canonicalNodeUrl;

  @override
  String getHost() => 'multporn';

  String getDomain() => 'multporn.net';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final nodeMatch = _nodePattern.firstMatch(url.toString());
    if (nodeMatch != null) {
      _canonicalNodeUrl = url;
      return nodeMatch.group(1)!;
    }

    try {
      final page = await Http.get(url);
      final nodeHref = simpleModeHrefFromDocument(page);
      final hrefMatch = _nodeHrefPattern.firstMatch(nodeHref);
      if (hrefMatch != null) {
        _canonicalNodeUrl = Uri.parse('https://multporn.net$nodeHref');
        return hrefMatch.group(1)!;
      }
    } catch (_) {
      // Java ignores lookup failures here and falls through to the format error.
    }

    throw FormatException(
      'Expected multporn.net URL format: '
      'multporn.net/comics/comicid / multporn.net/node/id/* - got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    Uri sourceUrl;
    try {
      await getGID(url);
      sourceUrl = _canonicalNodeUrl ?? url;
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    sendUpdate(RipStatus.loadingResource, sourceUrl.toString());
    Document page;
    try {
      page = await Http.get(sourceUrl);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    final downloads = <RipperDownload>[];
    for (final imageUrl in await getURLsFromPage(page)) {
      if (isStopped) break;
      index++;
      final imageUri = Uri.parse(imageUrl);
      downloads.add(
        RipperDownload(
          url: imageUri,
          saveAs: File(
            p.join(
              workingDir.path,
              fileNameForUrl(imageUri, prefix: prefixForIndex(index)),
            ),
          ),
        ),
      );
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static String simpleModeHrefFromDocument(Document page) {
    return page.querySelector('.simple-mode-switcher')?.attributes['href'] ??
        '';
  }

  static Uri? canonicalNodeUrlFromHref(String href) {
    final match = _nodeHrefPattern.firstMatch(href);
    if (match == null) return null;
    return Uri.parse('https://multporn.net$href');
  }

  static String? gidFromNodeUrl(Uri url) {
    return _nodePattern.firstMatch(url.toString())?.group(1);
  }

  static String? gidFromNodeHref(String href) {
    return _nodeHrefPattern.firstMatch(href)?.group(1);
  }

  static List<String> imageUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final item in page.querySelectorAll('.mfp-gallery-image .mfp-item')) {
      result.add(item.attributes['href'] ?? '');
    }
    return result;
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    var fileName = uri.toString();
    if (fileName.endsWith('/')) {
      fileName = fileName.substring(0, fileName.length - 1);
    }
    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
    final question = fileName.indexOf('?');
    if (question >= 0) fileName = fileName.substring(0, question);
    final hash = fileName.indexOf('#');
    if (hash >= 0) fileName = fileName.substring(0, hash);
    final ampersand = fileName.indexOf('&');
    if (ampersand >= 0) fileName = fileName.substring(0, ampersand);
    if (fileName.isEmpty) fileName = 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
