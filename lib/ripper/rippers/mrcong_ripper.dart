import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class MrCongRipper extends AbstractHTMLRipper {
  static final RegExp _galleryPattern = RegExp(
    r'^https?://(?:[a-z]+\.)?misskon\.com/([-0-9a-zA-Z]+)(?:/?|/[0-9]+/?)?$',
  );
  static final RegExp _tagPattern =
      RegExp(r'^https?://misskon\.com/tag/(\S*)/$');

  MrCongRipper(super.url);

  bool _tagPage = false;
  int _lastPageNum = 1;
  int _currPageNum = 1;
  late Uri _currentUrl = url;

  @override
  String getHost() => 'misskon';

  String getDomain() => 'misskon.com';

  @override
  bool canRip(Uri url) {
    if (!url.host.endsWith(getDomain())) return false;
    return _galleryPattern.hasMatch(url.toString()) ||
        _tagPattern.hasMatch(url.toString());
  }

  @override
  Future<String> getGID(Uri url) async {
    final galleryMatch = _galleryPattern.firstMatch(url.toString());
    if (galleryMatch != null) {
      _tagPage = false;
      return galleryMatch.group(1)!;
    }

    final tagMatch = _tagPattern.firstMatch(url.toString());
    if (tagMatch != null) {
      _tagPage = true;
      return tagMatch.group(1)!;
    }

    throw FormatException(
      'Expected misskon.com URL format: '
      'misskon.com/GALLERY_NAME (or /PAGE_NUMBER/) - got $url instead',
    );
  }

  Future<Document> getFirstPage() async {
    final rootUrl = _tagPage ? rootTagUrl(url) : rootGalleryUrl(url);
    _currentUrl = rootUrl;
    _currPageNum = 1;
    final page = await Http.get(rootUrl);
    _lastPageNum = maxPageNumber(page, tagPage: _tagPage);
    return page;
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      await getGID(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    Document page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    if (_tagPage) {
      final childUrls = <String>[];
      while (!isStopped) {
        childUrls.addAll(await getURLsFromPage(page));
        final nextUri = await getNextPage(page);
        if (nextUri == null) break;
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await Http.get(nextUri);
      }
      for (final childUrl in childUrls) {
        if (isStopped) break;
        sendUpdate(RipStatus.queueAdd, childUrl);
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    var index = 0;
    while (!isStopped) {
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
      if (isStopped) break;

      final nextUri = await getNextPage(page);
      if (nextUri == null) break;
      sendUpdate(RipStatus.loadingResource, nextUri.toString());
      page = await Http.get(nextUri);
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return _tagPage
        ? tagGalleryUrlsFromDocument(page)
        : imageUrlsFromDocument(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final next = nextPageUrl(
      _currentUrl,
      currPageNum: _currPageNum,
      lastPageNum: _lastPageNum,
      tagPage: _tagPage,
    );
    if (next == null) return null;
    _currentUrl = next;
    _currPageNum++;
    return next;
  }

  static Uri rootGalleryUrl(Uri url) {
    var text = url.toString();
    text = text.replaceFirst(RegExp(r'/[0-9]+/?$'), '');
    text = text.replaceFirst(RegExp(r'/*$'), '');
    return Uri.parse('$text/');
  }

  static Uri rootTagUrl(Uri url) {
    return Uri.parse(
      url.toString().replaceFirst(RegExp(r'(page/[0-9]+/)$'), 'page/1/'),
    );
  }

  static int maxPageNumber(Document page, {required bool tagPage}) {
    final selector = tagPage ? 'div.pagination > a' : 'div.page-link > a';
    final links = page.querySelectorAll(selector);
    if (links.isEmpty) return 1;
    return int.tryParse(links.last.text) ?? 1;
  }

  static Uri? nextPageUrl(
    Uri currentUrl, {
    required int currPageNum,
    required int lastPageNum,
    required bool tagPage,
  }) {
    if (currPageNum >= lastPageNum) return null;
    if (tagPage) {
      if (currPageNum == 1) {
        return Uri.parse('${currentUrl}page/${currPageNum + 1}');
      }
      return Uri.parse(
        currentUrl.toString().replaceFirst(
            RegExp(r'(page/([0-9]*)/?)$'), 'page/${currPageNum + 1}/'),
      );
    }

    if (currPageNum == 1) {
      return Uri.parse('$currentUrl${currPageNum + 1}');
    }
    return Uri.parse(
      currentUrl
          .toString()
          .replaceFirst(RegExp(r'(/([0-9]*)/?)$'), '/${currPageNum + 1}/'),
    );
  }

  static List<String> imageUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final image in page.querySelectorAll('p > img')) {
      var imageSource = image.attributes['data-src'] ?? '';
      if (imageSource.isEmpty) {
        imageSource = image.attributes['src'] ?? '';
      }
      result.add(imageSource);
    }
    return result;
  }

  static List<String> tagGalleryUrlsFromDocument(Document page) {
    final result = <String>[];
    for (final link in page.querySelectorAll('h2 > a')) {
      final href = link.attributes['href'] ?? '';
      if (href != 'https://misskon.com/') {
        result.add(href);
      }
    }
    return result;
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  bool get tagPageForTesting => _tagPage;
  int get lastPageNumForTesting => _lastPageNum;
}
