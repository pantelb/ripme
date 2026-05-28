import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';

class FapwizRipper extends AbstractHTMLRipper {
  FapwizRipper(super.url);

  static const Duration downloadDelay = Duration(seconds: 2);
  static final RegExp _categoryPattern =
      RegExp(r'https?://fapwiz\.com/category/([a-zA-Z0-9_-]+)/?$');
  static final RegExp _userPattern =
      RegExp(r'https?://fapwiz\.com/([a-zA-Z0-9_-]+)/?$');
  static final RegExp _postPattern =
      RegExp(r'https?://fapwiz\.com/([a-zA-Z0-9_-]+)/([a-zA-Z0-9_%-]+)/?$');

  @override
  String getHost() => 'fapwiz';

  String getDomain() => 'fapwiz.com';

  @override
  bool canRip(Uri url) {
    final text = url.toString();
    return _categoryPattern.hasMatch(text) ||
        _userPattern.hasMatch(text) ||
        _postPattern.hasMatch(text);
  }

  @override
  Future<String> getGID(Uri url) async {
    final text = _lowercasePercentEscapes(url.toString());
    var match = _categoryPattern.firstMatch(text);
    if (match != null) return 'category_${match.group(1)}';

    match = _userPattern.firstMatch(text);
    if (match != null) return 'user_${match.group(1)}';

    match = _postPattern.firstMatch(text);
    if (match != null) return 'post_${match.group(1)}_${match.group(2)}';

    throw FormatException(
      'Expected fapwiz URL format: fapwiz.com/USER or fapwiz.com/USER/POST or fapwiz.com/CATEGORY - got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await Http.get(url, headers: {'User-Agent': Http.userAgent});
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    var index = 0;
    while (!isStopped) {
      for (final mediaUrl in await getURLsFromPage(page)) {
        if (isStopped) break;
        index++;
        await Http.delay(downloadDelay);
        final uri = Uri.parse(mediaUrl);
        await downloadFile(
          uri,
          File(p.join(workingDir.path, fileNameForUrl(uri, index))),
        );
      }

      if (isStopped) break;
      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await Http.get(nextUri, headers: {'User-Agent': Http.userAgent});
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return mediaFromPage(url, page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final href = page.querySelector('a.next')?.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return Uri.parse(href);
  }

  static List<String> mediaFromPage(Uri url, Document page) {
    final results = <String>[];
    final text = url.toString();

    if (_categoryPattern.hasMatch(text)) {
      processUserOrCategoryPage(page, results);
    }
    if (_userPattern.hasMatch(text)) {
      processUserOrCategoryPage(page, results);
    }
    if (_postPattern.hasMatch(text)) {
      processPostPage(page, results);
    }

    return results;
  }

  static void processUserOrCategoryPage(Document page, List<String> results) {
    for (final image in page.querySelectorAll('.post-items-holder img')) {
      final src = image.attributes['src'] ?? '';
      if (src.endsWith('-thumbnail-icon.jpg')) continue;
      results.add(src.replaceAll('-thumbnail.jpg', '.mp4'));
    }
  }

  static void processPostPage(Document page, List<String> results) {
    for (final video in page.querySelectorAll('video source')) {
      results.add(video.attributes['src'] ?? '');
    }
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

  static String _lowercasePercentEscapes(String text) {
    return text.replaceAllMapped(
      RegExp(r'%[0-9A-Fa-f]{2}'),
      (match) => match.group(0)!.toLowerCase(),
    );
  }
}
