import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class MastodonMedia {
  final Uri url;
  final String id;

  const MastodonMedia({required this.url, required this.id});
}

class MastodonRipper extends AbstractHTMLRipper {
  MastodonRipper(super.url);

  @override
  String getHost() => 'mastodon';

  String getDomain() => 'mastodon.social';

  @override
  bool canRip(Uri url) {
    try {
      gidFromUrl(url, getDomain());
      return true;
    } on FormatException {
      return false;
    }
  }

  @override
  Future<String> getGID(Uri url) async => gidFromUrl(url, getDomain());

  @override
  Future<void> rip() async {
    var pageUrl = firstPageUrl(url, getDomain());
    sendUpdate(RipStatus.loadingResource, pageUrl.toString());

    Document page;
    try {
      page = await Http.get(pageUrl);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final downloads = <RipperDownload>[];
    while (!isStopped) {
      for (final media in mediaFromDocument(page)) {
        if (isStopped) break;
        downloads.add(
          RipperDownload(
            url: media.url,
            saveAs: File(
              p.join(
                workingDir.path,
                fileNameForUrl(media.url, prefix: '${media.id}_'),
              ),
            ),
          ),
        );
      }

      final nextUrl = nextPageUrl(page);
      if (nextUrl == null || isStopped) break;
      await Http.delay(const Duration(milliseconds: 500));

      try {
        sendUpdate(RipStatus.loadingResource, nextUrl.toString());
        pageUrl = nextUrl;
        page = await Http.get(pageUrl);
      } catch (_) {
        break;
      }
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    return mediaFromDocument(
      page,
    ).map((media) => media.url.toString()).toList();
  }

  @override
  Future<Uri?> getNextPage(Document page) async => nextPageUrl(page);

  static String gidFromUrl(Uri url, String domain) {
    final pattern = RegExp(
      '^https?://(${RegExp.escape(domain)})/@([a-zA-Z0-9_-]+)(/media/?)?\$',
    );
    final match = pattern.firstMatch(url.toString());
    if (match != null) return '${match.group(1)}@${match.group(2)}';

    throw FormatException(
      'Expected $domain URL format: $domain/@username - got $url instead',
    );
  }

  static Uri firstPageUrl(Uri url, String domain) {
    if (RegExp(r'^/@[a-zA-Z0-9_-]+/media/?$').hasMatch(url.path)) {
      return url;
    }
    return Uri.parse('${url.toString().replaceAll(RegExp(r'/$'), '')}/media');
  }

  static Uri? nextPageUrl(Document page) {
    final links = page.querySelectorAll(
      '.h-entry + .entry > a.load-more.load-gap',
    );
    if (links.isEmpty) return null;

    final href = links.last.attributes['href'];
    if (href == null || href.isEmpty) return null;
    return Uri.parse(href);
  }

  static List<MastodonMedia> mediaFromDocument(Document page) {
    final media = <MastodonMedia>[];
    for (final element in page.querySelectorAll(
      '[data-component="MediaGallery"]',
    )) {
      final props = element.attributes['data-props'];
      if (props == null || props.isEmpty) continue;

      final decoded = jsonDecode(props);
      if (decoded is! Map) continue;

      final items = decoded['media'];
      if (items is! List) continue;

      for (final item in items) {
        if (item is! Map) continue;
        final url = item['url'];
        final id = item['id'];
        if (url == null || id == null) continue;
        media.add(
          MastodonMedia(url: Uri.parse(url.toString()), id: id.toString()),
        );
      }
    }
    return media;
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
