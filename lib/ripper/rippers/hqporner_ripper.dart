import 'dart:io';

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';

class HqpornerRipper extends AbstractHTMLRipper {
  HqpornerRipper(super.url);

  static const String videoUrlPrefix = 'https://hqporner.com';
  static final RegExp _videoPattern =
      RegExp(r'^https?://hqporner\.com/hdporn/([a-zA-Z0-9_-]*).html/?$');
  static final RegExp _listingPattern =
      RegExp(r'^https://hqporner\.com/([a-zA-Z0-9/_-]+)$');
  static final RegExp _mp4Pattern = RegExp(r'https?://[A-Za-z0-9/._-]+\.mp4');
  static final RegExp _myDaddyPattern =
      RegExp(r'(//[a-zA-Z0-9.]+/pub/cid/[a-z0-9]+/1080\.mp4)');

  @override
  String getHost() => 'hqporner';

  String getDomain() => 'hqporner.com';

  @override
  bool canRip(Uri url) =>
      _videoPattern.hasMatch(url.toString()) ||
      _listingPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final videoMatch = _videoPattern.firstMatch(url.toString());
    if (videoMatch != null) return videoMatch.group(1)!;

    final listingMatch = _listingPattern.firstMatch(url.toString());
    if (listingMatch != null) {
      final path = listingMatch.group(1)!;
      final slash = path.indexOf('/');
      return slash == -1 ? path : path.substring(0, slash);
    }

    throw FormatException(
      'Expected hqporner URL format: hqporner.com/hdporn/NAME\n'
      'hqporner.com/category/myfavcategory\n'
      'hqporner.com/actress/myfavactress\n'
      'hqporner.com/studio/myFavStudio\n'
      ' - got $url instead.',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    try {
      if (_videoPattern.hasMatch(url.toString())) {
        await _downloadVideoPage(url, '');
      } else {
        await _ripListing();
      }
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }

    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  Future<void> _ripListing() async {
    var page = await Http.get(url);
    final subdirectory = subdirectoryForListing(url);
    while (!isStopped) {
      for (final videoPage in await getURLsFromPage(page)) {
        if (isStopped) break;
        await _downloadVideoPage(Uri.parse(videoPage), subdirectory);
      }
      if (isStopped) break;

      final next = await getNextPage(page);
      if (next == null) break;
      sendUpdate(RipStatus.loadingResource, next.toString());
      page = await Http.get(next);
    }
  }

  Future<void> _downloadVideoPage(Uri videoPageUrl, String subdirectory) async {
    final request = await getVideoDownloadForPage(videoPageUrl);
    if (request == null) return;

    final fileName = '${await getGID(videoPageUrl)}.mp4';
    final pathParts = [
      workingDir.path,
      if (subdirectory.isNotEmpty) Utils.filesystemSafe(subdirectory),
      Utils.sanitizeSaveAs(fileName),
    ];
    final saveAs = File(
      p.joinAll(pathParts),
    );
    await downloadFile(request, saveAs);
  }

  Future<Uri?> getVideoDownloadForPage(Uri videoPageUrl) async {
    final page = await Http.get(videoPageUrl);
    final iframeSource =
        page.querySelector('div.videoWrapper > iframe')?.attributes['src'] ??
            '';
    final embedUrl = normalizeProtocolRelative(iframeSource);
    if (embedUrl == null) return null;

    if (embedUrl.toString().contains('mydaddy')) {
      return getVideoFromMyDaddy(embedUrl, videoPageUrl);
    }
    if (embedUrl.toString().contains('flyflv')) {
      return getVideoFromFlyFlv(embedUrl, videoPageUrl);
    }
    return getVideoFromUnknown(embedUrl, videoPageUrl);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    if (_videoPattern.hasMatch(url.toString())) return [url.toString()];
    return getAllVideoUrls(page);
  }

  @override
  Future<Uri?> getNextPage(Document page) async {
    final pageNumbers = page.querySelectorAll('ul.pagination a[href]');
    if (pageNumbers.isEmpty) return null;
    final last = pageNumbers.last;
    if (!last.text.contains('Next')) return null;
    return Uri.parse('$videoUrlPrefix${last.attributes['href']}');
  }

  static List<String> getAllVideoUrls(Document page) {
    return [
      for (final link
          in page.querySelectorAll('div[class="6u"] h3 a.click-trigger'))
        if ((link.attributes['href'] ?? '').isNotEmpty)
          '$videoUrlPrefix${link.attributes['href']}',
    ];
  }

  static String subdirectoryForListing(Uri url) {
    final match = _listingPattern.firstMatch(url.toString());
    if (match == null) return '';
    final path = match.group(1)!;
    final slash = path.indexOf('/');
    return slash == -1 ? '' : path.substring(slash + 1);
  }

  static Uri? normalizeProtocolRelative(String source) {
    if (source.isEmpty) return null;
    if (source.startsWith('//')) return Uri.parse('https:$source');
    return Uri.parse(source);
  }

  static Future<Uri?> getVideoFromMyDaddy(Uri embedUrl, Uri referer) async {
    final page =
        await Http.get(embedUrl, headers: {'Referer': referer.toString()});
    final match = _myDaddyPattern.firstMatch(page.outerHtml);
    if (match == null) return null;
    return Uri.parse('https:${match.group(0)}');
  }

  static Future<Uri?> getVideoFromFlyFlv(Uri embedUrl, Uri referer) async {
    final page =
        await Http.get(embedUrl, headers: {'Referer': referer.toString()});
    for (final quality in ['1080p', '720p', '360p']) {
      final source = page
          .querySelector('video > source[label="$quality"]')
          ?.attributes['src'];
      final uri = normalizeProtocolRelative(source ?? '');
      if (uri != null) return uri;
    }
    return null;
  }

  static Future<Uri?> getVideoFromUnknown(Uri embedUrl, Uri referer) async {
    final page =
        await Http.get(embedUrl, headers: {'Referer': referer.toString()});

    final directSources = [
      for (final element in page.querySelectorAll('[src\$=".mp4"]'))
        if ((element.attributes['src'] ?? '').isNotEmpty)
          element.attributes['src']!,
    ];
    if (directSources.isNotEmpty) {
      return normalizeProtocolRelative(bestQualityLink(directSources));
    }

    final matched = _matchBestByPattern(page.outerHtml);
    if (matched != null) return Uri.parse(matched);

    final host = embedUrl.host;
    final sameHostSources = page
        .querySelectorAll('[src*="$host"]')
        .where((element) {
          final source = element.attributes['src'] ?? '';
          return RegExp(r'/[A-Za-z0-9_-]+$').hasMatch(source);
        })
        .map((element) => element.attributes['src']!)
        .toList();
    for (final source in sameHostSources) {
      final child =
          await Http.get(Uri.parse(source), headers: {'Referer': host});
      final link = _matchBestByPattern(child.outerHtml);
      if (link != null) return Uri.parse(link);
    }
    return null;
  }

  static String? _matchBestByPattern(String html) {
    final matches =
        _mp4Pattern.allMatches(html).map((match) => match.group(0)!);
    final list = matches.toList();
    if (list.isEmpty) return null;
    return bestQualityLink(list);
  }

  static String bestQualityLink(List<String> links) {
    if (links.isEmpty) return '';
    const qualities = [
      '2160',
      '2160p',
      '1440',
      '1440p',
      '1080',
      '1080p',
      '720',
      '720p',
      '480',
      '480p',
    ];
    for (final quality in qualities) {
      for (final link in links) {
        if (link.contains(quality)) return link;
      }
    }
    return links.first;
  }
}
