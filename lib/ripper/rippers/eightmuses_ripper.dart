import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class EightmusesRipper extends AbstractHTMLRipper {
  static final RegExp _albumPattern = RegExp(
    r'^https?://(www\.)?8muses\.com/(comix|comics)/album/([a-zA-Z0-9\-_]+).*$',
    caseSensitive: false,
  );

  final Map<String, String> _cookies = <String, String>{};

  EightmusesRipper(super.url);

  @override
  String getHost() => '8muses';

  @override
  bool canRip(Uri url) => _albumPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _albumPattern.firstMatch(url.toString());
    if (match == null) {
      throw FormatException(
        'Expected URL format: http://www.8muses.com/index/category/albumname, got: $url',
      );
    }
    return match.group(3)!;
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    try {
      final page = await _getFirstPage(url);
      return albumTitleFromDocument(page) ??
          '${getHost()}_${await getGID(url)}';
    } catch (_) {
      return '${getHost()}_${await getGID(url)}';
    }
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await _getFirstPage(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = await downloadsFromPage(page);
    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return imageUrlsFromPage(page);
  }

  static List<String> imageUrlsFromPage(Document page) {
    final urls = <String>[];
    for (final tile in page.querySelectorAll('.c-tile')) {
      final href = tile.attributes['href'] ?? '';
      if (!href.contains('/comics/picture/')) continue;

      final imageUrl = imageUrlFromTile(tile);
      if (imageUrl != null && imageUrl.contains('8muses.com')) {
        urls.add(imageUrl);
      }
    }
    return urls;
  }

  Future<List<RipperDownload>> downloadsFromPage(Document page) async {
    return _downloadsFromPage(page);
  }

  Future<List<RipperDownload>> _downloadsFromPage(Document page) async {
    final downloads = <RipperDownload>[];
    final tiles = page.querySelectorAll('.c-tile');

    for (var index = 0; index < tiles.length; index++) {
      if (isStopped) break;

      final tile = tiles[index];
      final href = tile.attributes['href'] ?? '';
      if (href.contains('/comics/album/')) {
        final subUrl = Uri.parse('https://www.8muses.com$href');
        try {
          sendUpdate(RipStatus.loadingResource, subUrl.toString());
          final subPage = await _getPage(subUrl);
          downloads.addAll(await _downloadsFromPage(subPage));
        } catch (e) {
          sendUpdate(RipStatus.downloadWarn, 'Error loading $subUrl: $e');
        }
        continue;
      }

      if (!href.contains('/comics/picture/')) continue;

      final imageUrl = imageUrlFromTile(tile);
      if (imageUrl == null || !imageUrl.contains('8muses.com')) continue;

      downloads.add(_downloadForImage(
        Uri.parse(imageUrl),
        subdirectory: subdirFromTitle(page.querySelector('title')?.text ?? ''),
        prefix: getPrefixShort(index),
        allowDuplicate: true,
      ));
    }

    return downloads;
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  Future<Document> _getFirstPage(Uri uri) async {
    final response = await Http.getResponse(uri);
    _cookies.addAll(cookiesFromSetCookieHeader(response.headers['set-cookie']));
    if (response.statusCode != 200) {
      throw HttpException('Failed to load $uri: Status ${response.statusCode}');
    }
    return html.parse(response.body, sourceUrl: uri.toString());
  }

  Future<Document> _getPage(Uri uri) async {
    final response = await Http.getResponse(uri, cookies: _cookies);
    _cookies.addAll(cookiesFromSetCookieHeader(response.headers['set-cookie']));
    if (response.statusCode != 200) {
      throw HttpException('Failed to load $uri: Status ${response.statusCode}');
    }
    return html.parse(response.body, sourceUrl: uri.toString());
  }

  RipperDownload _downloadForImage(
    Uri imageUri, {
    required String subdirectory,
    required String prefix,
    required bool allowDuplicate,
  }) {
    final fileName = fileNameForUrl(imageUri, prefix: prefix);
    final safeSubdir = Utils.filesystemSafe(subdirectory);
    final saveAs = safeSubdir.trim().isEmpty
        ? File(p.join(workingDir.path, fileName))
        : File(p.join(workingDir.path, safeSubdir, fileName));
    return RipperDownload(
      url: imageUri,
      saveAs: saveAs,
      headers: {'Referer': url.toString()},
      cookies: _cookies,
      allowDuplicate: allowDuplicate,
    );
  }

  static String? imageUrlFromTile(Element tile) {
    if (tile.attributes.containsKey('data-cfsrc')) {
      return tile.attributes['data-cfsrc'];
    }

    final src = tile.querySelector('img')?.attributes['data-src'];
    if (src == null || src.isEmpty) return null;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return src.replaceFirst('/th/', '/fl/');
    }
    return 'https://comics.8muses.com${src.replaceFirst('/th/', '/fl/')}';
  }

  static String? albumTitleFromDocument(Document page) {
    final description =
        page.querySelector('meta[name=description]')?.attributes['content'];
    if (description == null || description.trim().isEmpty) return null;

    final title = description
        .replaceAll(
            'A huge collection of free porn comics for adults. Read', '')
        .replaceAll('online for free at 8muses.com', '')
        .trim();
    if (title.isEmpty) return null;
    return '8muses_$title';
  }

  static String subdirFromTitle(String rawTitle) {
    return rawTitle
        .replaceAll('8muses - Sex and Porn Comics', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\n', '')
        .replaceAll(RegExp(r'\| '), '')
        .replaceAll(' - ', '-')
        .replaceAll(' ', '-');
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  static String getPrefixShort(int index) => index.toString().padLeft(3, '0');

  static String getPrefixLong(int index) =>
      '${index.toString().padLeft(3, '0')}_';

  static Map<String, String> cookiesFromSetCookieHeader(String? header) {
    if (header == null || header.trim().isEmpty) return const {};

    final cookies = <String, String>{};
    final parts = header.split(RegExp(r',\s*(?=[^;,]+=)'));
    for (final rawCookie in parts) {
      final firstPart = rawCookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator <= 0) continue;

      final name = firstPart.substring(0, separator).trim();
      final value = firstPart.substring(separator + 1).trim();
      if (name.isNotEmpty) cookies[name] = value;
    }
    return cookies;
  }
}
