import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

enum FlickrAlbumType { user, photoset }

class FlickrAlbum {
  final FlickrAlbumType type;
  final String id;

  const FlickrAlbum(this.type, this.id);
}

class FlickrRipper extends AbstractHTMLRipper {
  static const String fallbackApiKey = '935649baf09b2cc50628e2b306e4da5d';

  static final RegExp _photosetPattern = RegExp(
    r'^https?://[wm.]*flickr\.com/photos/[a-zA-Z0-9@_-]+/(sets|albums)/([0-9]+)/?.*$',
    caseSensitive: false,
  );
  static final RegExp _userPattern = RegExp(
    r'^https?://[wm.]*flickr\.com/photos/([a-zA-Z0-9@_-]+)/?$',
    caseSensitive: false,
  );
  static final RegExp _gidSetPattern = RegExp(
    r'^https?://[wm.]*flickr\.com/photos/([a-zA-Z0-9@_-]+)/sets/([0-9]+)/?.*$',
    caseSensitive: false,
  );
  static final RegExp _gidUserPattern = RegExp(
    r'^https?://[wm.]*flickr\.com/photos/([a-zA-Z0-9@_-]+).*$',
    caseSensitive: false,
  );
  static final RegExp _gidGroupPattern = RegExp(
    r'^https?://[wm.]*flickr\.com/groups/([a-zA-Z0-9@_-]+).*$',
    caseSensitive: false,
  );

  FlickrRipper(super.url);

  @override
  String getHost() => 'flickr';

  @override
  bool canRip(Uri url) => url.host.endsWith('flickr.com');

  @override
  Future<String> getGID(Uri url) async {
    final text = url.toString();
    final setMatch = _gidSetPattern.firstMatch(text);
    if (setMatch != null) {
      return '${setMatch.group(1)}_${setMatch.group(2)}';
    }

    final userMatch = _gidUserPattern.firstMatch(text);
    if (userMatch != null) return userMatch.group(1)!;

    final groupMatch = _gidGroupPattern.firstMatch(text);
    if (groupMatch != null) return 'groups-${groupMatch.group(1)}';

    throw FormatException(
      'Expected flickr.com URL formats: flickr.com/photos/username or flickr.com/photos/username/sets/albumid Got: $url',
    );
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    if (!url.toString().contains('/sets/')) {
      return super.getAlbumTitle(url);
    }

    try {
      final page = await Http.get(sanitizeUrl(url));
      final title = albumTitleFromDocument(url, page);
      if (title != null) return title;
    } catch (_) {
      // Fall through to Java's default album naming convention.
    }
    return super.getAlbumTitle(url);
  }

  @override
  Future<void> rip() async {
    final sourceUrl = sanitizeUrl(url);
    sendUpdate(RipStatus.loadingResource, sourceUrl.toString());

    Document page;
    try {
      page = await Http.get(sourceUrl);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final album = classifyUrl(sourceUrl);
    final apiKey = apiKeyFromDocument(page);
    if (apiKey == fallbackApiKey) {
      sendUpdate(
          RipStatus.downloadWarn, 'Unable to extract api key from flickr');
      sendUpdate(RipStatus.downloadWarn, 'Using hardcoded api key');
    }

    final downloads = <RipperDownload>[];
    var pageNumber = 1;
    var downloadIndex = 0;

    while (!isStopped) {
      final json = await _fetchListing(album, pageNumber, apiKey);
      if (json == null || json['stat'] == 'fail') break;

      final listing = photoIdsFromListJson(json);
      if (listing == null) break;

      for (final photoId in listing.photoIds) {
        if (isStopped) break;

        final imageUrl = await _largestImageUrl(photoId, apiKey);
        if (imageUrl == null) continue;

        downloadIndex++;
        downloads.add(RipperDownload(
          url: imageUrl,
          saveAs: File(p.join(
            workingDir.path,
            fileNameForUrl(imageUrl, prefix: _prefix(downloadIndex)),
          )),
        ));
      }

      if (pageNumber >= listing.totalPages) break;
      pageNumber++;
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async => const [];

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  Future<Map<String, dynamic>?> _fetchListing(
    FlickrAlbum album,
    int pageNumber,
    String apiKey,
  ) async {
    final uri = Uri.parse(apiUrl(album, pageNumber.toString(), apiKey));
    try {
      final json = await Http.getJSON(uri);
      if (json is Map<String, dynamic>) return json;
    } catch (e) {
      sendUpdate(RipStatus.downloadWarn, 'Unable to fetch Flickr API page: $e');
    }
    return null;
  }

  Future<Uri?> _largestImageUrl(String photoId, String apiKey) async {
    final uri = Uri.parse(
      'https://www.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=$apiKey&photo_id=$photoId&format=json&nojsoncallback=1',
    );
    try {
      final json = await Http.getJSON(uri);
      if (json is Map<String, dynamic>) {
        return largestImageUrlFromSizesJson(json);
      }
    } catch (e) {
      sendUpdate(
        RipStatus.downloadWarn,
        'IOException while looking at image sizes: $e',
      );
    }
    return null;
  }

  static Uri sanitizeUrl(Uri uri) {
    var text = uri.toString().replaceFirst(
          'https://secure.flickr.com',
          'http://www.flickr.com',
        );
    if (text.contains('flickr.com/groups/') && !text.contains('/pool')) {
      if (!text.endsWith('/')) text += '/';
      text += 'pool';
    }
    return Uri.parse(text);
  }

  static FlickrAlbum classifyUrl(Uri uri) {
    final text = uri.toString();
    final setMatch = _photosetPattern.firstMatch(text);
    if (setMatch != null) {
      return FlickrAlbum(FlickrAlbumType.photoset, setMatch.group(2)!);
    }

    final userMatch = _userPattern.firstMatch(text);
    if (userMatch != null) {
      return FlickrAlbum(FlickrAlbumType.user, userMatch.group(1)!);
    }

    throw FormatException('Failed to extract photoset ID from url: $uri');
  }

  static String apiKeyFromDocument(Document page) {
    final pattern = RegExp(
      r'root\.YUI_config\.flickr\.api\.site_key = "([a-zA-Z0-9]*)";',
    );
    for (final script in page.querySelectorAll('script')) {
      final match = pattern.firstMatch(script.innerHtml);
      if (match != null) return match.group(1)!;
    }
    return fallbackApiKey;
  }

  static String apiUrl(FlickrAlbum album, String pageNumber, String apiKey) {
    final method = switch (album.type) {
      FlickrAlbumType.photoset => 'flickr.photosets.getPhotos',
      FlickrAlbumType.user => 'flickr.people.getPhotos',
    };
    final idField = switch (album.type) {
      FlickrAlbumType.photoset => 'photoset_id=${album.id}',
      FlickrAlbumType.user => 'user_id=${album.id}',
    };

    return 'https://api.flickr.com/services/rest?extras=can_addmeta,'
        'can_comment,can_download,can_share,contact,count_comments,count_faves,count_views,date_taken,'
        'date_upload,icon_urls_deep,isfavorite,ispro,license,media,needs_interstitial,owner_name,'
        'owner_datecreate,path_alias,realname,rotation,safety_level,secret_k,secret_h,url_c,url_f,url_h,url_k,'
        'url_l,url_m,url_n,url_o,url_q,url_s,url_sq,url_t,url_z,visibility,visibility_source,o_dims,'
        'is_marketplace_printable,is_marketplace_licensable,publiceditability&per_page=100&page=$pageNumber&'
        'get_user_info=1&primary_photo_extras=url_c,%20url_h,%20url_k,%20url_l,%20url_m,%20url_n,%20url_o'
        ',%20url_q,%20url_s,%20url_sq,%20url_t,%20url_z,%20needs_interstitial,%20can_share&jump_to=&'
        '$idField&viewerNSID=&method=$method&csrf=&'
        'api_key=$apiKey&format=json&hermes=1&hermesClient=1&reqId=358ed6a0&nojsoncallback=1';
  }

  static FlickrPhotoListing? photoIdsFromListJson(Map<String, dynamic> json) {
    final root = json['photoset'] ?? json['photos'];
    if (root is! Map<String, dynamic>) return null;

    final pages = root['pages'];
    final photos = root['photo'];
    if (photos is! List) return null;

    return FlickrPhotoListing(
      totalPages: pages is int ? pages : int.tryParse('$pages') ?? 0,
      photoIds: [
        for (final photo in photos)
          if (photo is Map && photo['id'] != null) photo['id'].toString(),
      ],
    );
  }

  static Uri? largestImageUrlFromSizesJson(Map<String, dynamic> json) {
    final sizes = json['sizes'];
    if (sizes is! Map) return null;

    final sizeList = sizes['size'];
    if (sizeList is! List || sizeList.isEmpty) return null;

    Map? largest;
    var largestArea = -1;
    for (final size in sizeList) {
      if (size is! Map) continue;

      final width = _intValue(size['width']);
      final height = _intValue(size['height']);
      final source = size['source'];
      if (width == null || height == null || source == null) continue;

      final area = width * height;
      if (area > largestArea) {
        largestArea = area;
        largest = size;
      }
    }

    final source = largest?['source'];
    return source == null ? null : Uri.parse(source.toString());
  }

  static String? albumTitleFromDocument(Uri uri, Document page) {
    if (!uri.toString().contains('/sets/')) return null;

    final user = userFromPhotosUrl(uri);
    if (user == null) return null;

    final title =
        page.querySelector('meta[name=description]')?.attributes['content'];
    if (title == null || title.isEmpty) return null;

    return 'flickr_${user}_$title';
  }

  static String? userFromPhotosUrl(Uri uri) {
    final text = uri.toString();
    const marker = '/photos/';
    final start = text.indexOf(marker);
    if (start < 0) return null;

    final after = text.substring(start + marker.length);
    final slash = after.indexOf('/');
    if (slash < 0) return null;
    return after.substring(0, slash);
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  static String _prefix(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class FlickrPhotoListing {
  final int totalPages;
  final List<String> photoIds;

  const FlickrPhotoListing({
    required this.totalPages,
    required this.photoIds,
  });
}
