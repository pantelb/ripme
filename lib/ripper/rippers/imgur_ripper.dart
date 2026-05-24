import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

enum ImgurAlbumType {
  album,
  user,
  userAlbum,
  userImages,
  singleImage,
  subreddit,
}

class ImgurImage {
  final Uri url;
  final String title;

  const ImgurImage(this.url, {this.title = ''});

  String get saveAs {
    var cleanUrl = url.toString();
    final queryIndex = cleanUrl.indexOf('?');
    if (queryIndex >= 0) cleanUrl = cleanUrl.substring(0, queryIndex);

    final slash = cleanUrl.lastIndexOf('/');
    final dot = cleanUrl.lastIndexOf('.');
    final imageId = dot > slash
        ? cleanUrl.substring(slash + 1, dot)
        : url.pathSegments.last;
    final extension = dot > slash ? cleanUrl.substring(dot) : '';
    final baseName = title.isEmpty ? imageId : '${title}_$imageId';
    return '${Utils.filesystemSafe(baseName)}$extension';
  }
}

class ImgurRipper extends AbstractHTMLRipper {
  ImgurRipper(super.url);

  ImgurAlbumType _albumType = ImgurAlbumType.album;
  Document? _albumDoc;
  static const int _sleepBetweenAlbumsSeconds = 1;
  static const String _defaultClientId = '546c25a59c58ad7';

  @override
  String getHost() => 'imgur';

  @override
  bool canRip(Uri url) => classifyUrl(url) != null;

  @override
  Future<String> getGID(Uri url) async {
    final parsed = classifyUrl(url);
    if (parsed == null) {
      throw FormatException('Unsupported imgur URL format: $url');
    }
    _albumType = parsed.type;
    return parsed.gid;
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return (await imgurMediaFromPage(page))
        .map((uri) => uri.toString())
        .toList();
  }

  @override
  Future<void> rip() async {
    try {
      await getGID(url);
      switch (_albumType) {
        case ImgurAlbumType.album:
        case ImgurAlbumType.userAlbum:
          await _ripAlbum(url);
        case ImgurAlbumType.singleImage:
          await _ripSingleImage(url);
        case ImgurAlbumType.user:
          await _ripUserAccount(url);
        case ImgurAlbumType.userImages:
          await _ripUserImages(url);
        case ImgurAlbumType.subreddit:
          await _ripSubreddit(url);
      }
      sendUpdate(RipStatus.ripComplete, workingDir.path);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
  }

  Future<void> _ripSingleImage(Uri url) async {
    final gid = await getGID(url);
    final json = await _getJSON(Uri.parse(
        'https://api.imgur.com/post/v1/media/$gid?include=media,adconfig,account'));
    final media = json is Map ? json['media'] : null;
    if (media is! List || media.isEmpty) {
      throw HttpException('Failed to fetch image for url $url');
    }

    final imageUrl = extractImageUrlFromJson(media.first);
    await downloadFile(
      imageUrl,
      File(p.join(workingDir.path, _fileNameFor(imageUrl))),
    );
  }

  Future<void> _ripAlbum(Uri url, {String subdirectory = ''}) async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    final album = await getImgurAlbum(url);
    final downloads = <RipperDownload>[];

    for (var i = 0; i < album.length; i++) {
      if (isStopped) break;
      final image = album[i];
      var saveDir = workingDir.path;
      if (subdirectory.isNotEmpty) {
        saveDir = p.join(saveDir, subdirectory);
      }
      final prefix = Utils.getConfigBoolean('download.save_order', true)
          ? '${(i + 1).toString().padLeft(3, '0')}_'
          : '';
      downloads.add(RipperDownload(
        url: image.url,
        saveAs: File(p.join(
            saveDir, '$prefix${image.saveAs.replaceAll(RegExp(r'\?\d'), '')}')),
      ));
    }

    await downloadFiles(downloads);
  }

  Future<List<ImgurImage>> getImgurAlbum(Uri url) async {
    final id = await getGID(url);

    try {
      final json =
          await _getJSON(Uri.parse('https://api.imgur.com/3/album/$id/all'));
      final images = albumImagesFromApiJson(json);
      if (images.isNotEmpty) return images;
    } catch (_) {
      // Java falls back to /noscript when JSON parsing fails.
    }

    final doc = await Http.get(Uri.parse('${albumPageUrl(id)}/noscript'));
    return albumImagesFromNoscript(doc);
  }

  Future<void> _ripUserAccount(Uri url) async {
    final username = (await getGID(url)).replaceFirst('user_', '');
    var page = 0;
    var globalIndex = 0;

    while (!isStopped) {
      final json = await _getJSON(Uri.parse(
          'https://api.imgur.com/3/account/$username/submissions/$page/newest?album_previews=1'));
      if (json is! Map ||
          json['success'] != true ||
          (json['status'] as num?)?.toInt() != 200) {
        throw HttpException('Unexpected Imgur response for $url page $page');
      }

      final data = json['data'];
      if (data is! List || data.isEmpty) break;

      for (final item in data.whereType<Map>()) {
        if (isStopped) break;
        globalIndex++;
        var prefixOrSubdir = Utils.getConfigBoolean('download.save_order', true)
            ? '${globalIndex.toString().padLeft(3, '0')}_'
            : '';
        final link = item['link']?.toString();
        if (link == null || link.isEmpty) continue;

        if (item['is_album'] == true) {
          final albumId = item['id']?.toString() ?? '';
          await _ripAlbum(Uri.parse(link),
              subdirectory: '$prefixOrSubdir$albumId');
          await Http.delay(const Duration(seconds: _sleepBetweenAlbumsSeconds));
        } else {
          var mediaLink = link;
          if (item['mp4'] != null &&
              Utils.getConfigBoolean('prefer.mp4', false)) {
            mediaLink = item['mp4'].toString();
          }
          final mediaUri = Uri.parse(mediaLink);
          await downloadFile(
            mediaUri,
            File(p.join(
                workingDir.path, '$prefixOrSubdir${_fileNameFor(mediaUri)}')),
            allowDuplicate: allowDuplicates(),
          );
        }
      }

      page++;
    }
  }

  Future<void> _ripUserImages(Uri url) async {
    var jsonUrl = url.toString().replaceFirst('/all', '/ajax/images');
    final hashIndex = jsonUrl.indexOf('#');
    if (hashIndex >= 0) jsonUrl = jsonUrl.substring(0, hashIndex);

    var page = 0;
    var imagesFound = 0;
    var imagesTotal = 0;
    while (!isStopped) {
      page++;
      final json = await Http.getJSON(
          Uri.parse('$jsonUrl?sort=0&order=1&album=0&page=$page&perPage=60'));
      final parsed = userImagesFromAjaxJson(json);
      if (parsed.total != null) imagesTotal = parsed.total!;
      if (parsed.images.isEmpty) break;

      final downloads = <RipperDownload>[];
      for (final image in parsed.images) {
        imagesFound++;
        final prefix = Utils.getConfigBoolean('download.save_order', true)
            ? '${imagesFound.toString().padLeft(3, '0')}_'
            : '';
        downloads.add(RipperDownload(
          url: image.url,
          saveAs: File(p.join(workingDir.path, '$prefix${image.saveAs}')),
        ));
      }
      await downloadFiles(downloads);
      if (imagesTotal > 0 && imagesFound >= imagesTotal) break;
      await Http.delay(const Duration(seconds: 1));
    }
  }

  Future<void> _ripSubreddit(Uri url) async {
    var page = 0;
    while (!isStopped) {
      final pageUrl = url.toString().endsWith('/')
          ? '${url}page/$page/miss?scrolled'
          : '$url/page/$page/miss?scrolled';
      sendUpdate(RipStatus.loadingResource, pageUrl);
      final doc = await Http.get(Uri.parse(pageUrl));
      final downloads = <RipperDownload>[];
      final images = doc.querySelectorAll('.post img');
      for (final img in images) {
        var src = img.attributes['src'];
        if (src == null || src.isEmpty) continue;
        if (src.startsWith('//')) src = 'http:$src';
        if (src.contains('b.')) src = src.replaceFirst('b.', '.');
        final mediaUri = Uri.parse(src);
        downloads.add(RipperDownload(
          url: mediaUri,
          saveAs: File(p.join(workingDir.path, _fileNameFor(mediaUri))),
        ));
      }
      await downloadFiles(downloads);
      if (images.isEmpty) break;
      page++;
      await Http.delay(const Duration(seconds: 1));
    }
  }

  @override
  Future<String> getAlbumTitle(Uri url) async {
    final parsed = classifyUrl(url);
    if (parsed?.type == ImgurAlbumType.album) {
      try {
        _albumDoc ??= await Http.get(url);
        final gid = await getGID(url);
        final title = albumTitleFromDocument(_albumDoc!);
        return 'imgur_${gid}_$title';
      } catch (_) {
        // Fall through to default.
      }
    }
    return super.getAlbumTitle(url);
  }

  bool allowDuplicates() => _albumType == ImgurAlbumType.user;

  Future<dynamic> _getJSON(Uri uri) {
    return Http.getJSON(uri, headers: {
      'Authorization':
          'Client-ID ${Utils.getConfigString('imgur.client_id', _defaultClientId) ?? _defaultClientId}',
    });
  }

  static ImgurUrlMatch? classifyUrl(Uri url) {
    if (!url.host.endsWith('imgur.com')) return null;
    final urlStr = url.toString();
    if (urlStr == 'https://www.imgur.com' ||
        urlStr == 'http://www.imgur.com' ||
        urlStr == 'https://imgur.com' ||
        urlStr == 'http://imgur.com') {
      return null;
    }

    final patterns = <(RegExp, ImgurAlbumType, String Function(RegExpMatch))>[
      (
        RegExp(
            r'^https?://(?:www\.|m\.)?imgur\.com/gallery/(?:(?:[a-zA-Z0-9]*/)?.*-)?([a-zA-Z0-9]+)$'),
        ImgurAlbumType.album,
        (m) => m.group(m.groupCount)!,
      ),
      (
        RegExp(
            r'^https?://(?:www\.|m\.)?imgur\.com/(?:a|t)/(?:(?:[a-zA-Z0-9]*/)?.*-)?([a-zA-Z0-9]+).*$'),
        ImgurAlbumType.album,
        (m) => m.group(m.groupCount)!,
      ),
      (
        RegExp(r'^https?://([a-zA-Z0-9-]{4,})\.imgur\.com/?$'),
        ImgurAlbumType.user,
        (m) => m.group(1) == 'www' ? '' : 'user_${m.group(1)!}',
      ),
      (
        RegExp(r'^https?://(?:www\.|m\.)?imgur\.com/user/([a-zA-Z0-9]+).*$'),
        ImgurAlbumType.user,
        (m) => 'user_${m.group(1)!}',
      ),
      (
        RegExp(r'^https?://([a-zA-Z0-9-]{3,})\.imgur\.com/all.*$'),
        ImgurAlbumType.userImages,
        (m) => '${m.group(1)!}_images',
      ),
      (
        RegExp(r'^https?://([a-zA-Z0-9-]{3,})\.imgur\.com/([a-zA-Z0-9_-]+).*$'),
        ImgurAlbumType.userAlbum,
        (m) => '${m.group(1)!}-${m.group(2)!}',
      ),
      (
        RegExp(
            r'^https?://(www\.|m\.)?imgur\.com/r/([a-zA-Z0-9_-]{3,})(/top|/new)?(/all|/year|/month|/week|/day)?/?$'),
        ImgurAlbumType.subreddit,
        (m) {
          final id = StringBuffer(m.group(2)!);
          for (var i = 3; i <= m.groupCount; i++) {
            final part = m.group(i);
            if (part != null) id.write('_${part.replaceAll('/', '')}');
          }
          return id.toString();
        },
      ),
      (
        RegExp(
            r'^https?://(i\.|www\.|m\.)?imgur\.com/r/(\w+)/([a-zA-Z0-9,]{5,}).*$'),
        ImgurAlbumType.album,
        (m) => 'r_${m.group(m.groupCount - 1)!}_${m.group(m.groupCount)!}',
      ),
      (
        RegExp(r'^https?://(i\.|www\.|m\.)?imgur\.com/([a-zA-Z0-9]{5,})$'),
        ImgurAlbumType.singleImage,
        (m) => m.group(m.groupCount)!,
      ),
    ];

    for (final entry in patterns) {
      final match = entry.$1.firstMatch(urlStr);
      if (match == null) continue;
      final gid = entry.$3(match);
      if (gid.isEmpty) return null;
      return ImgurUrlMatch(entry.$2, gid);
    }
    return null;
  }

  static List<ImgurImage> albumImagesFromApiJson(dynamic json) {
    final data = json is Map ? json['data'] : null;
    final images = data is Map ? data['images'] : null;
    if (images is! List) return const [];
    return images
        .whereType<Map>()
        .map((image) => image['link']?.toString() ?? '')
        .where((link) => link.isNotEmpty)
        .map((link) => ImgurImage(Uri.parse(_preferMp4(link))))
        .toList();
  }

  static List<ImgurImage> albumImagesFromNoscript(Document doc) {
    final images = <ImgurImage>[];
    for (final thumb in doc.querySelectorAll('div.image')) {
      String? image;
      final zoom = thumb.querySelector('a.zoom');
      if (zoom != null && (zoom.attributes['href'] ?? '').isNotEmpty) {
        image = zoom.attributes['href'];
      } else {
        image = thumb.querySelector('img')?.attributes['src'];
      }
      if (image == null || image.isEmpty) continue;
      if (image.startsWith('//')) image = 'http:$image';
      images.add(ImgurImage(Uri.parse(_preferMp4(image))));
    }
    return images;
  }

  static Uri extractImageUrlFromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Expected Imgur media object');
    }
    final id = json['id']?.toString();
    var ext = json['ext']?.toString();
    if (id == null || id.isEmpty || ext == null || ext.isEmpty) {
      throw const FormatException('Imgur media object missing id or ext');
    }
    if (!ext.startsWith('.')) ext = '.$ext';
    if (ext == '.gif' && Utils.getConfigBoolean('prefer.mp4', false)) {
      ext = '.mp4';
    }
    return Uri.parse('https://i.imgur.com/$id$ext');
  }

  static ImgurUserImages userImagesFromAjaxJson(dynamic json) {
    final data = json is Map ? json['data'] : null;
    if (data is! Map) return const ImgurUserImages([], null);
    final images = data['images'];
    final parsed = images is List
        ? images
            .whereType<Map>()
            .map((image) {
              final hash = image['hash']?.toString();
              final ext = image['ext']?.toString();
              if (hash == null || ext == null) return null;
              return ImgurImage(Uri.parse('https://i.imgur.com/$hash$ext'));
            })
            .whereType<ImgurImage>()
            .toList()
        : <ImgurImage>[];
    return ImgurUserImages(parsed, (data['count'] as num?)?.toInt());
  }

  static String albumTitleFromDocument(Document doc) {
    const defaultTitle1 = 'Imgur: The most awesome images on the Internet';
    const defaultTitle2 = 'Imgur: The magic of the Internet';
    var title =
        doc.querySelector('meta[property="og:title"]')?.attributes['content'] ??
            '';
    if (title.contains(defaultTitle1) || title.contains(defaultTitle2)) {
      final titleText = doc.querySelector('title')?.text ?? '';
      title =
          titleText.contains(defaultTitle1) || titleText.contains(defaultTitle2)
              ? ''
              : titleText;
    }
    return title;
  }

  static Uri albumPageUrl(String gid) {
    if (gid.startsWith('r_')) {
      final parts = gid.split('_');
      if (parts.length >= 3) {
        return Uri.parse(
            'https://imgur.com/r/${parts[1]}/${parts.sublist(2).join('_')}');
      }
    }
    return Uri.parse('https://imgur.com/a/$gid');
  }

  static Future<List<Uri>> imgurMediaFromPage(Document page) async {
    final result = <Uri>[];
    for (final meta in page.querySelectorAll('meta')) {
      final content = meta.attributes['content'];
      if (content == null || content.isEmpty) continue;
      if (meta.attributes['property'] == 'og:video' ||
          meta.attributes['name'] == 'twitter:image:src' ||
          meta.attributes['name'] == 'twitter:image') {
        result.add(
            Uri.parse(content.startsWith('//') ? 'https:$content' : content));
        if (result.isNotEmpty) return result;
      }
    }

    for (final img in page.querySelectorAll('img')) {
      final src = img.attributes['src'];
      if (src != null && src.contains('i.imgur.com')) {
        result.add(Uri.parse(src.startsWith('//') ? 'https:$src' : src));
      }
    }
    return result;
  }

  static String _preferMp4(String url) {
    return url.endsWith('.gif') && Utils.getConfigBoolean('prefer.mp4', false)
        ? url.replaceFirst(RegExp(r'\.gif$'), '.mp4')
        : url;
  }

  static String _fileNameFor(Uri url) {
    return ImgurImage(url).saveAs;
  }
}

class ImgurUrlMatch {
  final ImgurAlbumType type;
  final String gid;

  const ImgurUrlMatch(this.type, this.gid);
}

class ImgurUserImages {
  final List<ImgurImage> images;
  final int? total;

  const ImgurUserImages(this.images, this.total);
}
