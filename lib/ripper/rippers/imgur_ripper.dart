import 'dart:async';
import 'dart:io';
import 'package:html/dom.dart';
import '../abstract_html_ripper.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../../ui/rip_status_message.dart';

enum ImgurAlbumType {
  album,
  user,
  userAlbum,
  userImages,
  singleImage,
  subreddit
}

class ImgurRipper extends AbstractHTMLRipper {
  ImgurRipper(super.url) {
    _albumType = ImgurAlbumType.album; // Default, will be set in getGID
  }

  @override
  String getHost() => "imgur";

  ImgurAlbumType _albumType = ImgurAlbumType.album;
  final int _sleepBetweenAlbums = 1;
  Document? _albumDoc;

  @override
  Future<String> getGID(Uri url) async {
    final urlStr = url.toString();

    // Pattern 1: gallery URLs
    final galleryPattern = RegExp(
        r'^https?://(?:www\.|m\.)?imgur\.com/gallery/(?:(?:[a-zA-Z0-9]*/)?.*-)?([a-zA-Z0-9]+)$');
    var match = galleryPattern.firstMatch(urlStr);
    if (match != null) {
      _albumType = ImgurAlbumType.album;
      final gid = match.group(match.groupCount)!;
      return gid;
    }

    // Pattern 2: /a/ or /t/ albums
    final albumPattern = RegExp(
        r'^https?://(?:www\.|m\.)?imgur\.com/(?:a|t)/(?:(?:[a-zA-Z0-9]*/)?.*-)?([a-zA-Z0-9]+).*$');
    match = albumPattern.firstMatch(urlStr);
    if (match != null) {
      _albumType = ImgurAlbumType.album;
      final gid = match.group(match.groupCount)!;
      return gid;
    }

    // Pattern 3: root imgur account (username.imgur.com)
    final rootAccountPattern =
        RegExp(r'^https?://([a-zA-Z0-9\-]{4,})\.imgur\.com/?$');
    match = rootAccountPattern.firstMatch(urlStr);
    if (match != null) {
      final gid = match.group(1)!;
      if (gid == 'www') {
        throw const FormatException('Cannot rip the www.imgur.com homepage');
      }
      _albumType = ImgurAlbumType.user;
      return 'user_$gid';
    }

    // Pattern 4: new imgur user URL
    final userPattern =
        RegExp(r'^https?://(?:www\.|m\.)?imgur\.com/user/([a-zA-Z0-9]+).*$');
    match = userPattern.firstMatch(urlStr);
    if (match != null) {
      final gid = match.group(1)!;
      _albumType = ImgurAlbumType.user;
      return 'user_$gid';
    }

    // Pattern 5: user images (username.imgur.com/all)
    final userImagesPattern =
        RegExp(r'^https?://([a-zA-Z0-9\-]{3,})\.imgur\.com/all.*$');
    match = userImagesPattern.firstMatch(urlStr);
    if (match != null) {
      _albumType = ImgurAlbumType.userImages;
      return '${match.group(1)!}_images';
    }

    // Pattern 6: user album (username.imgur.com/albumname)
    final userAlbumPattern = RegExp(
        r'^https?://([a-zA-Z0-9\-]{3,})\.imgur\.com/([a-zA-Z0-9\-_]+).*$');
    match = userAlbumPattern.firstMatch(urlStr);
    if (match != null) {
      _albumType = ImgurAlbumType.userAlbum;
      return '${match.group(1)!}-${match.group(2)!}';
    }

    // Pattern 7: subreddit aggregator
    final subredditPattern = RegExp(
        r'^https?://(www\.|m\.)?imgur\.com/r/([a-zA-Z0-9\-_]{3,})(/top|/new)?(/all|/year|/month|/week|/day)?/?$');
    match = subredditPattern.firstMatch(urlStr);
    if (match != null) {
      _albumType = ImgurAlbumType.subreddit;
      final album = StringBuffer(match.group(2)!);
      for (int i = 3; i <= match.groupCount; i++) {
        final group = match.group(i);
        if (group != null) {
          album.write('_${group.replaceAll('/', '')}');
        }
      }
      return album.toString();
    }

    // Pattern 8: subreddit album or image
    final subredditAlbumPattern = RegExp(
        r'^https?://(i\.|www\.|m\.)?imgur\.com/r/(\w+)/([a-zA-Z0-9,]{5,}).*$');
    match = subredditAlbumPattern.firstMatch(urlStr);
    if (match != null) {
      _albumType = ImgurAlbumType.album;
      final subreddit = match.group(match.groupCount - 1)!;
      final gid = match.group(match.groupCount)!;
      return 'r_${subreddit}_$gid';
    }

    // Pattern 9: single image
    final singleImagePattern =
        RegExp(r'^https?://(i\.|www\.|m\.)?imgur\.com/([a-zA-Z0-9]{5,})$');
    match = singleImagePattern.firstMatch(urlStr);
    if (match != null) {
      _albumType = ImgurAlbumType.singleImage;
      return match.group(match.groupCount)!;
    }

    throw FormatException('Unsupported imgur URL format: $urlStr');
  }

  @override
  bool canRip(Uri url) {
    if (!url.host.endsWith('imgur.com')) {
      return false;
    }
    try {
      // Special case: homepage should return false
      final urlStr = url.toString();
      if (urlStr == 'https://www.imgur.com' ||
          urlStr == 'http://www.imgur.com' ||
          urlStr == 'https://imgur.com' ||
          urlStr == 'http://imgur.com') {
        return false;
      }
      getGID(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    return null; // Imgur uses API pagination
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    final List<String> urls = [];
    final images = page.querySelectorAll('img');

    for (final img in images) {
      var src = img.attributes['src'];
      if (src != null && src.contains('i.imgur.com')) {
        if (src.startsWith('//')) src = 'https:$src';
        urls.add(src);
      }
    }

    return urls;
  }

  @override
  Future<void> rip() async {
    await setup();
    try {
      switch (_albumType) {
        case ImgurAlbumType.album:
        case ImgurAlbumType.userAlbum:
          await _ripAlbum(url);
          break;
        case ImgurAlbumType.singleImage:
          await _ripSingleImage(url);
          break;
        case ImgurAlbumType.user:
          await _ripUserAccount(url);
          break;
        case ImgurAlbumType.userImages:
          await _ripUserImages(url);
          break;
        case ImgurAlbumType.subreddit:
          await _ripSubreddit(url);
          break;
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
  }

  Future<void> _ripAlbum(Uri url) async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    _albumDoc = await Http.get(url);

    // Try to extract from JSON API first
    final albumId = await getGID(url);
    final apiUrl = Uri.parse(
        'https://api.imgur.com/post/v1/albums/$albumId?client_id=546c25a59c58ad7&include=media');

    try {
      final response = await Http.getJSON(apiUrl);
      final items = response['media'] as List?;
      if (items != null && items.isNotEmpty) {
        for (int i = 0; i < items.length; i++) {
          if (isStopped) break;
          final item = items[i] as Map<String, dynamic>;
          final imageUrl = item['url'] as String?;
          if (imageUrl != null) {
            final prefix = Utils.getConfigBoolean('download.save_order', true)
                ? '${(i + 1).toString().padLeft(3, '0')}_'
                : '';
            final uri = Uri.parse(imageUrl);
            final fileName = _getFileName(uri, i + 1, prefix);
            final saveAs =
                File(workingDir.path + Platform.pathSeparator + fileName);
            await downloadFile(uri, saveAs);
          }
        }
        return;
      }
    } catch (e) {
      // Fall back to HTML parsing
    }

    // HTML fallback
    final images = _albumDoc!.querySelectorAll('img');
    for (int i = 0; i < images.length; i++) {
      if (isStopped) break;
      final img = images[i];
      var src = img.attributes['src'];
      if (src != null && src.contains('i.imgur.com')) {
        if (src.startsWith('//')) src = 'https:$src';
        final prefix = Utils.getConfigBoolean('download.save_order', true)
            ? '${(i + 1).toString().padLeft(3, '0')}_'
            : '';
        final uri = Uri.parse(src);
        final fileName = _getFileName(uri, i + 1, prefix);
        final saveAs =
            File(workingDir.path + Platform.pathSeparator + fileName);
        await downloadFile(uri, saveAs);
      }
    }
  }

  Future<void> _ripSingleImage(Uri url) async {
    // Ensure we have the direct image URL
    Uri imageUrl = url;
    if (url.host != 'i.imgur.com') {
      // Extract from page
      final page = await Http.get(url);
      final meta = page.querySelector('meta[property="og:image"]') ??
          page.querySelector('meta[name="twitter:image:src"]') ??
          page.querySelector('meta[name="twitter:image"]');
      final imageSrc = meta?.attributes['content'];
      if (imageSrc != null) {
        imageUrl =
            Uri.parse(imageSrc.startsWith('//') ? 'https:$imageSrc' : imageSrc);
      }
    }

    final fileName = _getFileName(imageUrl, 1, '');
    final saveAs = File(workingDir.path + Platform.pathSeparator + fileName);
    await downloadFile(imageUrl, saveAs);
  }

  Future<void> _ripUserAccount(Uri url) async {
    final gid = await getGID(url);
    final username = gid.replaceFirst('user_', '');
    int page = 0;

    while (!isStopped) {
      final apiUrl = Uri.parse(
          'https://api.imgur.com/3/account/$username/albums/$page?client_id=546c25a59c58ad7');
      try {
        final response = await Http.getJSON(apiUrl);
        final albums = response['data'] as List?;
        if (albums == null || albums.isEmpty) break;

        for (final album in albums) {
          if (isStopped) break;
          final albumId = album['id'] as String?;
          if (albumId != null) {
            final albumUrl = Uri.parse('https://imgur.com/a/$albumId');
            await _ripAlbum(albumUrl);
          }
          await Future.delayed(Duration(seconds: _sleepBetweenAlbums));
        }

        page++;
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        break;
      }
    }
  }

  Future<void> _ripUserImages(Uri url) async {
    final gid = await getGID(url);
    final username = gid.replaceFirst('_images', '');
    int page = 0;

    while (!isStopped) {
      final apiUrl = Uri.parse(
          'https://api.imgur.com/3/account/$username/images/$page?client_id=546c25a59c58ad7');
      try {
        final response = await Http.getJSON(apiUrl);
        final images = response['data'] as List?;
        if (images == null || images.isEmpty) break;

        for (int i = 0; i < images.length; i++) {
          if (isStopped) break;
          final image = images[i] as Map<String, dynamic>;
          final imageUrl = image['link'] as String?;
          if (imageUrl != null) {
            final prefix = Utils.getConfigBoolean('download.save_order', true)
                ? '${(i + 1).toString().padLeft(3, '0')}_'
                : '';
            final uri = Uri.parse(imageUrl);
            final fileName = _getFileName(uri, i + 1, prefix);
            final saveAs =
                File(workingDir.path + Platform.pathSeparator + fileName);
            await downloadFile(uri, saveAs);
          }
        }

        page++;
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        break;
      }
    }
  }

  Future<void> _ripSubreddit(Uri url) async {
    int page = 0;
    while (!isStopped) {
      final pageUrl = url.toString().endsWith('/')
          ? '${url}page/$page/miss?scrolled'
          : '$url/page/$page/miss?scrolled';

      sendUpdate(RipStatus.loadingResource, pageUrl);
      final doc = await Http.get(Uri.parse(pageUrl));
      final images = doc.querySelectorAll('.post img');

      for (final img in images) {
        if (isStopped) break;
        var src = img.attributes['src'];
        if (src != null) {
          if (src.startsWith('//')) src = 'https:$src';
          if (src.contains('b.')) src = src.replaceFirst('b.', '.');
          final uri = Uri.parse(src);
          final fileName = _getFileName(uri, 1, '');
          final saveAs =
              File(workingDir.path + Platform.pathSeparator + fileName);
          await downloadFile(uri, saveAs);
        }
      }

      if (images.isEmpty) break;
      page++;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  String _getFileName(Uri url, int index, String prefix) {
    String fileName =
        url.pathSegments.isNotEmpty ? url.pathSegments.last : 'file';
    if (fileName.contains('?')) {
      fileName = fileName.substring(0, fileName.indexOf('?'));
    }
    final extension = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '.jpg';
    final nameWithoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    final orderPrefix = prefix.isNotEmpty ? prefix : '';
    return '$orderPrefix$nameWithoutExt$extension';
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    if (_albumType == ImgurAlbumType.album ||
        _albumType == ImgurAlbumType.userAlbum) {
      try {
        _albumDoc ??= await Http.get(url);

        const defaultTitle1 = 'Imgur: The most awesome images on the Internet';
        const defaultTitle2 = 'Imgur: The magic of the Internet';

        // Try og:title first
        final ogTitle = _albumDoc!.querySelector('meta[property="og:title"]');
        var title = ogTitle?.attributes['content'] ?? '';

        if (title.contains(defaultTitle1) || title.contains(defaultTitle2)) {
          // Try title tag
          final titleTag = _albumDoc!.querySelector('title');
          final titleText = titleTag?.text ?? '';
          if (!titleText.contains(defaultTitle1) &&
              !titleText.contains(defaultTitle2)) {
            title = titleText;
          } else {
            title = '';
          }
        }

        final gid = await getGID(url);
        final albumTitle = 'imgur_${gid}_$title';
        return Utils.filesystemSafe(albumTitle.trim());
      } catch (e) {
        // Fall through to default
      }
    }
    return super.getAlbumTitle(url);
  }

  bool allowDuplicates() {
    return _albumType == ImgurAlbumType.user;
  }

  // Helper method used by RedditRipper
  static Future<List<Uri>> imgurMediaFromPage(Document page) async {
    final result = <Uri>[];

    // Check meta tags first (for single images)
    for (final meta in page.querySelectorAll('meta')) {
      final content = meta.attributes['content'];
      if (content == null || content.isEmpty) continue;
      if (meta.attributes['property'] == 'og:video' ||
          meta.attributes['name'] == 'twitter:image:src' ||
          meta.attributes['name'] == 'twitter:image') {
        final mediaUri = content.startsWith('//')
            ? Uri.parse('https:$content')
            : Uri.parse(content);
        result.add(mediaUri);
        if (result.isNotEmpty) return result;
      }
    }

    // Fall back to image elements
    for (final img in page.querySelectorAll('img')) {
      final src = img.attributes['src'];
      if (src != null && src.contains('i.imgur.com')) {
        final uri =
            src.startsWith('//') ? Uri.parse('https:$src') : Uri.parse(src);
        result.add(uri);
      }
    }

    return result;
  }
}
