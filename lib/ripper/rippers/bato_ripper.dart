import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';

class BatoRipper extends AbstractHTMLRipper {
  static final RegExp _chapterPattern =
      RegExp(r'^https?://bato\.to/chapter/([\d]+)/?$');
  static final RegExp _seriesPattern =
      RegExp(r'^https?://bato\.to/series/([\d]+)/?$');

  BatoRipper(super.url);

  @override
  String getHost() => 'bato';

  @override
  bool canRip(Uri url) {
    final text = url.toString();
    return _seriesPattern.hasMatch(text) || _chapterPattern.hasMatch(text);
  }

  @override
  Future<String> getGID(Uri url) async {
    final chapterMatch = _chapterPattern.firstMatch(url.toString());
    if (chapterMatch != null) return chapterMatch.group(1)!;

    if (_seriesPattern.hasMatch(url.toString())) return '';

    throw FormatException(
      'Expected bato.to URL format: bato.to/chapter/ID - got $url instead',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await Http.get(url);
      final title = page.querySelector('title')?.text.replaceAll(' ', '_');
      if (title != null && title.isNotEmpty) {
        return '${getHost()}_${await getGID(url)}_$title';
      }
    } catch (_) {
      // Fall through to the default host_GID album title.
    }
    return super.getAlbumTitle(url);
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

    if (hasQueueSupport() && pageContainsAlbums(url)) {
      for (final childUrl in await getAlbumsToQueue(page)) {
        if (isStopped) break;
        sendUpdate(RipStatus.queueAdd, childUrl);
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    final imageUrls = await getURLsFromPage(page);
    for (var i = 0; i < imageUrls.length; i++) {
      if (isStopped) break;
      await Http.delay(const Duration(milliseconds: 500));

      final imageUri = Uri.parse(imageUrls[i]);
      await downloadFile(
        imageUri,
        File(p.join(
          workingDir.path,
          fileNameForUrl(imageUri, prefix: prefixForIndex(i + 1)),
        )),
      );
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  bool hasQueueSupport() => true;

  @override
  bool pageContainsAlbums(Uri url) => _seriesPattern.hasMatch(url.toString());

  @override
  Future<List<String>> getAlbumsToQueue(Document page) async {
    return [
      for (final elem in page.querySelectorAll('div.main > div > a'))
        'https://bato.to${elem.attributes['href'] ?? ''}',
    ];
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<String> imageUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final script in page.querySelectorAll('script')) {
      final scriptData = script.innerHtml;
      if (!scriptData.contains('imgHttps')) continue;

      final jsonText = scanForImageList(scriptData);
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) continue;
      result.addAll(decoded.map((value) => value.toString()));
    }
    return result;
  }

  static String scanForImageList(String scriptData) {
    final pattern = RegExp(r'.*imgHttps = (\["[^\];]*"\]);.*');
    for (final line in scriptData.split('\n')) {
      final match = pattern.firstMatch(line.trim());
      if (match != null) return match.group(1)!;
    }
    return '[]';
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }
}
