import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class DeviantartRipper extends AbstractHTMLRipper {
  DeviantartRipper(super.url);

  static const String domain = 'deviantart.com';
  static const String referer = 'https://www.deviantart.com/';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0';
  static const Map<String, String> requestHeaders = {
    'User-Agent': userAgent,
    'Referer': referer,
  };
  static const Map<String, String> daCookies = {'agegate_state': '1'};

  int _offset = 0;
  bool _usingCatPath = false;
  final Set<String> _names = <String>{};

  @override
  String getHost() => 'deviantart';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    if (text.contains('catpath=/')) {
      _usingCatPath = true;
    }

    final artistMatch =
        RegExp(r'^https?://www\.deviantart\.com/([a-zA-Z0-9]+).*$')
            .firstMatch(text);
    if (artistMatch == null) {
      throw FormatException(_expectedUrlMessage(url));
    }

    final what = switch (text) {
      final s when s.contains('/gallery') => 'gallery',
      final s when s.contains('/favourites') => 'favourites',
      _ => throw FormatException(_expectedUrlMessage(url)),
    };

    var albumName = 'unknown';
    final albumMatch = RegExp(
      r'^https?://www\.deviantart\.com/[a-zA-Z0-9]+/[a-zA-Z]+/[0-9]+/([a-zA-Z0-9-]+).*$',
    ).firstMatch(text);
    if (text.endsWith('?catpath=/')) {
      albumName = 'all';
    } else if (text.endsWith('/favourites/') ||
        text.endsWith('/gallery/') ||
        text.endsWith('/gallery') ||
        text.endsWith('/favourites')) {
      albumName = 'featured';
    } else if (albumMatch != null) {
      albumName = albumMatch.group(1)!;
    }

    return '${artistMatch.group(1)}_${what}_$albumName';
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    Document page;
    try {
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      sendUpdate(RipStatus.ripComplete, workingDir.path);
      return;
    }

    while (!isStopped) {
      final pageUrls = await getURLsFromPage(page);
      if (pageUrls.isEmpty) {
        sendUpdate(RipStatus.ripErrored, 'No images found at $url');
        break;
      }

      final downloads = <RipperDownload>[];
      for (final pageUrl in pageUrls) {
        if (isStopped) break;
        sendUpdate(
          RipStatus.loadingResource,
          'Searching max. resolution for $pageUrl',
        );
        final download = await downloadFromDeviationPage(Uri.parse(pageUrl));
        if (download != null) downloads.add(download);
      }
      await downloadFiles(downloads);

      if (isStopped) break;
      final nextUri = await getNextPage(page);
      if (nextUri == null) break;

      try {
        sendUpdate(RipStatus.loadingResource, nextUri.toString());
        page = await _getPage(nextUri);
      } catch (_) {
        break;
      }
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    final response = await Http.getResponse(
      url,
      headers: requestHeaders,
      cookies: daCookies,
      defaultTimeoutMs: 60000,
    );
    if (response.statusCode != 200) {
      throw const HttpException('Account Deactivated');
    }
    return _getPage(urlWithParams(0));
  }

  Future<Document> _getPage(Uri uri) {
    return Http.get(
      uri,
      headers: requestHeaders,
      cookies: daCookies,
    );
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    _offset += 24;
    if (page.getElementsByClassName('message').isNotEmpty) return null;
    return urlWithParams(_offset);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return urlsFromPage(page, usingCatPath: _usingCatPath);
  }

  static List<String> urlsFromPage(
    Document page, {
    required bool usingCatPath,
  }) {
    final Element? container;
    if (usingCatPath) {
      container = page.getElementById('gmi-');
    } else {
      final folder = page.getElementsByClassName('folderview-art').firstOrNull;
      container = folder?.children.firstOrNull;
    }

    if (container == null) return const [];
    return [
      for (final link in container.querySelectorAll('a.torpedo-thumb-link'))
        if ((link.attributes['href'] ?? '').isNotEmpty)
          link.attributes['href']!,
    ];
  }

  Future<RipperDownload?> downloadFromDeviationPage(Uri pageUrl) async {
    try {
      final response = await Http.getResponse(
        pageUrl,
        headers: requestHeaders,
        cookies: daCookies,
        defaultTimeoutMs: 60000,
      );
      if (response.statusCode != 200) return null;
      final page = Document.html(response.body);
      final title = uniqueTitle(titleFromPage(page));
      final downloadLink = page.querySelector('a.dev-page-download');

      if (downloadLink != null) {
        final href = downloadLink.attributes['href'];
        if (href == null || href.isEmpty) return null;
        return downloadFromDownloadButton(Uri.parse(href), title);
      }

      return downloadFromScaledImage(page, title);
    } catch (e) {
      sendUpdate(RipStatus.downloadErrored, '$pageUrl : ${e.toString()}');
      return null;
    }
  }

  Future<RipperDownload?> downloadFromDownloadButton(
    Uri downloadUri,
    String title,
  ) async {
    final response = await Http.getResponse(
      downloadUri,
      headers: requestHeaders,
      cookies: daCookies,
      defaultTimeoutMs: 60000,
    );
    if (response.statusCode != 200) return null;

    final finalUri = response.request?.url ?? downloadUri;
    final extension = extensionFromContentDisposition(
        response.headers['content-disposition']);
    final filename = extension == null ? title : '$title.$extension';
    return RipperDownload(
      url: finalUri,
      saveAs: File(p.join(workingDir.path, Utils.sanitizeSaveAs(filename))),
      headers: requestHeaders,
      cookies: daCookies,
    );
  }

  Future<RipperDownload?> downloadFromScaledImage(
    Document page,
    String title,
  ) async {
    final imageUri = imageUrlFromDeviationPage(page);
    if (imageUri == null) return null;

    var downloadUri = originalImageUrl(imageUri);
    try {
      final response = await Http.getResponse(
        downloadUri,
        headers: requestHeaders,
        cookies: daCookies,
        defaultTimeoutMs: 60000,
      );
      if (response.statusCode == 404) {
        downloadUri = imageUri;
      }
    } catch (_) {
      downloadUri = imageUri;
    }

    final extension = extensionFromUrl(downloadUri);
    return RipperDownload(
      url: downloadUri,
      saveAs: File(
        p.join(workingDir.path, Utils.sanitizeSaveAs('$title.$extension')),
      ),
      headers: requestHeaders,
      cookies: daCookies,
    );
  }

  String uniqueTitle(String title) {
    var candidate = title;
    var counter = 1;
    if (_names.contains(candidate)) {
      while (_names.contains('${title}_$counter')) {
        counter++;
      }
      candidate = '${title}_$counter';
    }
    _names.add(candidate);
    return candidate;
  }

  Uri urlWithParams(int offset) {
    final cleaned = cleanUrl(url);
    if (_usingCatPath) {
      return Uri.parse('$cleaned?catpath=/&offset=$offset');
    }
    return Uri.parse('$cleaned?offset=$offset');
  }

  static String cleanUrl(Uri url) => url.toString().split('?').first;

  static String titleFromPage(Document page) {
    final title = page.querySelector('a.title')?.innerHtml ?? '';
    return title.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_').toLowerCase();
  }

  static Uri? imageUrlFromDeviationPage(Document page) {
    final container = page.querySelector('div.dev-view-deviation');
    final image = container?.querySelector('img');
    if (image == null || image.classes.contains('avatar')) return null;

    final src = image.attributes['src'];
    if (src == null || src.isEmpty) return null;
    return Uri.parse(src.split('?').first);
  }

  static Uri originalImageUrl(Uri scaledImage) {
    final parts = scaledImage.toString().split('/v1/');
    if (parts.length > 2) {
      throw const FormatException('Unexpected URL Format');
    }
    return Uri.parse(parts.first);
  }

  static String extensionFromUrl(Uri uri) {
    final text = uri.toString();
    final dot = text.lastIndexOf('.');
    if (dot < 0 || dot == text.length - 1) return '';
    return text.substring(dot + 1);
  }

  static String? extensionFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) return null;
    final parts = header.split('.');
    if (parts.isEmpty) return null;
    return parts.last.replaceAll('"', '').trim();
  }

  static String _expectedUrlMessage(Uri url) {
    return 'Expected deviantart.com URL format: '
        'www.deviantart.com/<ARTIST>/gallery/<NUMBERS>/<NAME>\nOR\n'
        'www.deviantart.com/<ARTIST>/favourites/<NUMBERS>/<NAME>\n'
        'Or simply the gallery or favorites of some artist - got $url instead';
  }
}
