import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';

class FivehundredpxRipper extends AbstractJSONRipper {
  FivehundredpxRipper(super.url);

  static const String domain = '500px.com';
  static const String consumerKey = 'XPm2br2zGBq6TOfd2xbDIHYoLnt3cLxr1HYryGCv';
  static const Duration pageDelay = Duration(milliseconds: 500);
  static const Duration sizeProbeDelay = Duration(milliseconds: 10);

  int _page = 1;
  String _baseUrl = 'https://api.500px.com/v1';

  @override
  String getHost() => '500px';

  String getDomain() => domain;

  @override
  bool canRip(Uri url) => url.host.toLowerCase().endsWith(domain);

  @override
  Future<String> getGID(Uri url) async {
    final configured = await configureUrl(url, userIdFetcher: getUserID);
    _baseUrl = configured.baseUrl;
    return configured.gid;
  }

  @override
  Future<void> parseJSON(Uri url) async {
    await getGID(url);
    Map<String, dynamic>? json = await getFirstPage();
    var index = 0;

    while (json != null && !isStopped) {
      final urls = await getURLsFromJSON(json);
      final downloads = <RipperDownload>[];
      for (final urlText in urls) {
        if (isStopped) break;
        index++;
        final uri = Uri.parse(urlText);
        downloads.add(
          RipperDownload(
            url: uri,
            saveAs: File(p.join(workingDir.path, downloadFileName(uri, index))),
          ),
        );
      }
      await downloadFiles(downloads);
      if (isStopped) break;
      json = await getNextPage(json);
    }
  }

  Future<String> getUserID(String username) async {
    final json = await Http.getJSON(Uri.parse(
        'https://api.500px.com/v1/users/show?username=$username&consumer_key=$consumerKey'));
    if (json is Map && json['user'] is Map) {
      return (json['user']['id'] as num).toInt().toString();
    }
    throw const FormatException('Unable to parse 500px user id');
  }

  Future<Map<String, dynamic>> getFirstPage() async {
    final json =
        await Http.getJSON(Uri.parse('$_baseUrl&consumer_key=$consumerKey'));
    if (json is! Map<String, dynamic>) return <String, dynamic>{};

    if (_baseUrl.contains('/galleries?')) {
      final result = <String, dynamic>{'photos': <dynamic>[]};
      final galleries = json['galleries'];
      if (galleries is List) {
        for (var i = 0; i < galleries.length; i++) {
          if (i > 0) await Http.delay(pageDelay);
          final gallery = galleries[i];
          if (gallery is! Map) continue;
          final galleryId = gallery['id'];
          final userId = gallery['user_id'];
          final galleryUrl =
              'https://api.500px.com/v1/users/$userId/galleries/$galleryId/items'
              '?rpp=100&image_size=5&consumer_key=$consumerKey';
          sendUpdate(RipStatus.loadingResource,
              'Gallery ID $galleryId for userID $userId');
          final galleryJson = await Http.getJSON(Uri.parse(galleryUrl));
          final photos = galleryJson is Map ? galleryJson['photos'] : null;
          if (photos is List) result['photos'].addAll(photos);
        }
      }
      return result;
    }

    if (_baseUrl.contains('/blogs?')) {
      final result = <String, dynamic>{'photos': <dynamic>[]};
      final blogs = json['blog_posts'];
      if (blogs is List) {
        for (var i = 0; i < blogs.length; i++) {
          if (i > 0) await Http.delay(pageDelay);
          final blog = blogs[i];
          if (blog is! Map) continue;
          final blogId = blog['id'];
          final user = blog['user'];
          final username = user is Map ? user['username'] : null;
          final blogUrl = 'https://api.500px.com/v1/blogs/$blogId'
              '?feature=user&username=$username&rpp=100&image_size=5'
              '&consumer_key=$consumerKey';
          sendUpdate(
              RipStatus.loadingResource, 'Story ID $blogId for user $username');
          final blogJson = await Http.getJSON(Uri.parse(blogUrl));
          final photos = blogJson is Map ? blogJson['photos'] : null;
          if (photos is List) result['photos'].addAll(photos);
        }
      }
      return result;
    }

    return json;
  }

  Future<Map<String, dynamic>?> getNextPage(Map<String, dynamic> json) async {
    final currentPage = json['current_page'];
    final totalPages = json['total_pages'];
    if (currentPage is! int || totalPages is! int) return null;
    if (currentPage == totalPages) return null;

    await Http.delay(pageDelay);
    _page++;
    final nextJson = await Http.getJSON(
        Uri.parse('$_baseUrl&page=$_page&consumer_key=$consumerKey'));
    return nextJson is Map<String, dynamic> ? nextJson : null;
  }

  Future<List<String>> getURLsFromJSON(Map<String, dynamic> json) async {
    final photos = json['photos'];
    if (photos is! List) return const [];

    final urls = <String>[];
    for (final photo in photos) {
      if (isStopped) break;
      if (photo is! Map) continue;
      urls.add(await imageUrlForPhoto(photo));
    }
    return urls;
  }

  Future<String> imageUrlForPhoto(Map photo) async {
    final rawUrl = 'https://500px.com${photo['url']}';
    try {
      sendUpdate(RipStatus.loadingResource, rawUrl);
      final doc = await Http.get(Uri.parse(rawUrl));
      final preload = preloadImageUrl(doc);
      if (preload != null) return preload;
    } catch (_) {
      // Fall through to the API image_url path, like the Java ripper.
    }

    var imageUrl =
        (photo['image_url'] ?? '').toString().replaceAll('/4.', '/5.');
    final larger = imageUrl.replaceAll('/5.', '/2048.');
    await Http.delay(sizeProbeDelay);
    if (await urlExists(larger)) return larger;
    return imageUrl;
  }

  static String? preloadImageUrl(Document doc) {
    final src = doc.querySelector('div#preload img')?.attributes['src'];
    return src == null || src.isEmpty ? null : src;
  }

  static Future<bool> urlExists(String url) async {
    final client = HttpClient();
    try {
      final request = await client.headUrl(Uri.parse(url));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  static String downloadFileName(Uri uri, int index) {
    final segments = uri.pathSegments;
    final id = segments.length >= 3 ? segments[segments.length - 3] : 'file';
    return '$id.jpg';
  }

  static Future<FivehundredpxConfig> configureUrl(
    Uri url, {
    required Future<String> Function(String username) userIdFetcher,
  }) async {
    final text = url.toString();
    RegExpMatch? match;
    var baseUrl = 'https://api.500px.com/v1';

    match = RegExp(r'^.*500px\.com/([a-zA-Z0-9\-_]+)/stories/([0-9]+).*$')
        .firstMatch(text);
    if (match != null) {
      final username = match.group(1)!;
      final blogId = match.group(2)!;
      baseUrl +=
          '/blogs/$blogId?feature=user&username=$username&image_size=5&rpp=100';
      return FivehundredpxConfig('${username}_stories_$blogId', baseUrl);
    }

    match =
        RegExp(r'^.*500px\.com/([a-zA-Z0-9\-_]+)/stories/?$').firstMatch(text);
    if (match != null) {
      final username = match.group(1)!;
      baseUrl += '/blogs?feature=user&username=$username&rpp=100';
      return FivehundredpxConfig('${username}_stories', baseUrl);
    }

    match = RegExp(r'^.*500px\.com/([a-zA-Z0-9\-_]+)/favorites/?$')
        .firstMatch(text);
    if (match != null) {
      final username = match.group(1)!;
      baseUrl +=
          '/photos?feature=user_favorites&username=$username&rpp=100&image_size=5';
      return FivehundredpxConfig('${username}_faves', baseUrl);
    }

    match = RegExp(r'^.*500px\.com/([a-zA-Z0-9\-_]+)/galleries/?$')
        .firstMatch(text);
    if (match != null) {
      final username = match.group(1)!;
      final userId = await userIdFetcher(username);
      baseUrl += '/users/$userId/galleries?rpp=100';
      return FivehundredpxConfig('${username}_galleries', baseUrl);
    }

    match = RegExp(
            r'^.*500px\.com/([a-zA-Z0-9\-_]+)/galleries/([a-zA-Z0-9\-_]+)/?$')
        .firstMatch(text);
    if (match != null) {
      final username = match.group(1)!;
      final subgallery = match.group(2)!;
      final userId = await userIdFetcher(username);
      baseUrl +=
          '/users/$userId/galleries/$subgallery/items?rpp=100&image_size=5';
      return FivehundredpxConfig('${username}_galleries_$subgallery', baseUrl);
    }

    match = RegExp(r'^.*500px\.com/([a-zA-Z0-9\-_]+)/?$').firstMatch(text);
    if (match != null) {
      final username = match.group(1)!;
      baseUrl += '/photos?feature=user&username=$username&rpp=100&image_size=5';
      return FivehundredpxConfig(username, baseUrl);
    }

    throw FormatException(
      'Expected 500px.com gallery formats: /stories/###  /stories  /favorites  / Got: $url',
    );
  }
}

class FivehundredpxConfig {
  final String gid;
  final String baseUrl;

  const FivehundredpxConfig(this.gid, this.baseUrl);
}
