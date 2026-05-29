import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';
import 'fuskator_ripper.dart';

class PhotobucketAlbumMetadata {
  final String baseUrl;
  final String location;
  final int sortOrder;
  Map<String, String> cookies;
  Document? currentPage;
  String? currentPageLocation;
  int numPages;
  int pageIndex;

  PhotobucketAlbumMetadata({
    required this.baseUrl,
    required this.location,
    required this.sortOrder,
    this.cookies = const {},
    this.currentPage,
    this.currentPageLocation,
    this.numPages = 0,
    this.pageIndex = 1,
  });

  factory PhotobucketAlbumMetadata.fromJson(Map<String, dynamic> data) {
    return PhotobucketAlbumMetadata(
      baseUrl: data['url'].toString(),
      location: data['location'].toString().replaceAll(' ', '_'),
      sortOrder: data['sortOrder'] as int,
    );
  }

  Uri currentPageUrl() => Uri.parse(
        '$baseUrl?sort=$sortOrder&page=$pageIndex',
      );
}

class PhotobucketRipper extends AbstractHTMLRipper {
  static const int itemsPerPage = 24;
  static const Duration waitBeforeNextPage = Duration(seconds: 2);
  static final RegExp _urlPattern = RegExp(
    r'^https?://([a-zA-Z0-9]+)\.photobucket\.com/user/'
    r'([a-zA-Z0-9_\-]+)/library/([^?]*).*$',
  );
  static final RegExp _collectionDataPattern = RegExp(
    r'^.*collectionData: (\{.*\}).*$',
    dotAll: true,
  );

  List<PhotobucketAlbumMetadata>? _albums;
  PhotobucketAlbumMetadata? _currentAlbum;
  int _index = 0;

  PhotobucketRipper(Uri url) : super(sanitizeUri(url));

  @override
  String getHost() => 'photobucket';

  String getDomain() => 'photobucket.com';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(sanitizeUri(url).toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _urlPattern.firstMatch(sanitizeUri(url).toString());
    if (match != null) return match.group(2)!;
    throw FormatException(
      'Expected photobucket.com gallery formats: '
      'http://x###.photobucket.com/username/library/... Got: $url',
    );
  }

  @override
  Future<void> rip() async {
    Document page;
    try {
      sendUpdate(RipStatus.loadingResource, url.toString());
      page = await getFirstPage();
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    while (!isStopped) {
      final album = _currentAlbum;
      final downloads = <RipperDownload>[];
      for (final imageUrl in await getURLsFromPage(page)) {
        if (isStopped || album == null) break;
        _index++;
        final imageUri = Uri.parse(imageUrl);
        downloads.add(
          downloadForMedia(
            imageUri,
            index: _index,
            albumLocation: album.location,
            pageUrl:
                album.currentPageLocation ?? album.currentPageUrl().toString(),
            cookies: album.cookies,
            workingDir: workingDir,
          ),
        );
      }
      await downloadFiles(downloads);

      if (isStopped) break;
      final nextPage = await getNextDocument(page);
      if (nextPage == null) break;
      page = nextPage;
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<Document> getFirstPage() async {
    final albums = _albums ??= await getAlbumMetadata(url.toString());
    _currentAlbum = albums.removeAt(0);
    final album = _currentAlbum!;
    final page = await loadAlbumPage(album.currentPageUrl());
    album.currentPage = page;

    final collectionData = collectionDataFromDocument(page);
    final totalNumItems = collectionData?['total'];
    album.numPages = totalNumItems is int ? numPagesForTotal(totalNumItems) : 0;
    _index = 0;
    return page;
  }

  Future<Document?> getNextDocument(Document page) async {
    final album = _currentAlbum;
    final albums = _albums;
    if (album == null || albums == null) return null;

    album.pageIndex++;
    final endOfAlbum = album.pageIndex > album.numPages;
    final noMoreSubalbums = albums.isEmpty;
    if (endOfAlbum && noMoreSubalbums) return null;

    await Http.delay(waitBeforeNextPage);
    if (endOfAlbum) {
      return getFirstPage();
    }

    final nextPage = await loadAlbumPage(album.currentPageUrl());
    album.currentPage = nextPage;
    return nextPage;
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final collectionData = collectionDataFromDocument(page);
    if (collectionData == null) return const [];
    return imageUrlsFromCollectionData(collectionData);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final album = _currentAlbum;
    if (album == null) return null;
    final nextPageIndex = album.pageIndex + 1;
    if (nextPageIndex > album.numPages) return null;
    return Uri.parse(
      '${album.baseUrl}?sort=${album.sortOrder}&page=$nextPageIndex',
    );
  }

  Future<Document> loadAlbumPage(Uri uri) async {
    final response = await Http.getResponse(uri);
    final album = _currentAlbum;
    if (album != null) {
      album.currentPageLocation = uri.toString();
      album.cookies = FuskatorRipper.cookiesFromSetCookieHeader(
        response.headers['set-cookie'],
      );
    }
    if (response.statusCode != 200) {
      throw HttpException('Failed to load $uri: Status ${response.statusCode}');
    }
    return html.parse(response.body, sourceUrl: uri.toString());
  }

  Future<List<PhotobucketAlbumMetadata>> getAlbumMetadata(
      String albumUrl) async {
    final data = await getAlbumMetadataJson(albumUrl);
    final metadata = <PhotobucketAlbumMetadata>[
      PhotobucketAlbumMetadata.fromJson(data),
    ];

    if (data['location'].toString() != '') {
      for (final subalbum in subAlbumJsons(data)) {
        metadata.add(PhotobucketAlbumMetadata.fromJson(subalbum));
      }
    }
    return metadata;
  }

  Future<Map<String, dynamic>> getAlbumMetadataJson(String albumUrl) async {
    final apiUrl = albumMetadataApiUrl(albumUrl, subAlbums: itemsPerPage);
    var data = await _loadMetadataData(apiUrl);
    if (data.containsKey('subAlbums')) {
      final count = data['subAlbumCount'];
      if (count is int && count > itemsPerPage) {
        data = await _loadMetadataData(
          albumMetadataApiUrl(albumUrl, subAlbums: count),
        );
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> _loadMetadataData(Uri apiUrl) async {
    final json = await Http.getJSON(apiUrl);
    if (json is Map && json['data'] is Map) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
    throw const FormatException('Invalid Photobucket metadata JSON');
  }

  static Uri sanitizeUri(Uri url) {
    var text = url.toString();
    final queryIndex = text.indexOf('?');
    if (queryIndex >= 0) text = text.substring(0, queryIndex);
    if (!text.endsWith('/')) text = '$text/';
    return Uri.parse(text);
  }

  static Uri albumMetadataApiUrl(String albumUrl, {required int subAlbums}) {
    final match = _urlPattern.firstMatch(albumUrl);
    if (match == null) throw FormatException('invalid URL $albumUrl');

    final subdomain = match.group(1)!;
    final user = match.group(2)!;
    var albumTitle = match.group(3)!;
    if (albumTitle.endsWith('/')) {
      albumTitle = albumTitle.substring(0, albumTitle.length - 1);
    }

    return Uri.parse(
      'http://$subdomain.photobucket.com/api/user/'
      '$user/album/$albumTitle/get?subAlbums=$subAlbums&json=1',
    );
  }

  static List<Map<String, dynamic>> subAlbumJsons(Map<String, dynamic> data) {
    final subAlbums = data['subAlbums'];
    if (subAlbums is! List) return const [];
    return [
      for (final subAlbum in subAlbums)
        if (subAlbum is Map) Map<String, dynamic>.from(subAlbum),
    ];
  }

  static Map<String, dynamic>? collectionDataFromDocument(Document page) {
    for (final script
        in page.querySelectorAll('script[type="text/javascript"]')) {
      final data = script.text;
      if (!data.contains('libraryAlbumsPageCollectionData')) continue;

      final match = _collectionDataPattern.firstMatch(data);
      if (match == null) continue;

      final decoded = jsonDecode(match.group(1)!);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  static List<String> imageUrlsFromCollectionData(Map<String, dynamic> data) {
    final items = data['items'];
    if (items is! Map) return const [];
    final objects = items['objects'];
    if (objects is! List) return const [];

    return [
      for (final object in objects)
        if (object is Map && object['fullsizeUrl'] is String)
          object['fullsizeUrl'] as String,
    ];
  }

  static int numPagesForTotal(int totalNumItems) {
    return (totalNumItems / itemsPerPage).ceil();
  }

  static RipperDownload downloadForMedia(
    Uri uri, {
    required int index,
    required String albumLocation,
    required String pageUrl,
    required Map<String, String> cookies,
    required Directory workingDir,
  }) {
    final segments = <String>[
      workingDir.path,
      if (albumLocation.isNotEmpty) ...p.split(albumLocation),
      fileNameForUrl(uri, index),
    ];

    return RipperDownload(
      url: uri,
      saveAs: File(p.joinAll(segments)),
      headers: {'Referer': pageUrl},
      cookies: cookies,
    );
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
