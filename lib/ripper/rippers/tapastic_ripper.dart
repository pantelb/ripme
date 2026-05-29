import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:html/dom.dart';
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_html_ripper.dart';
import '../abstract_ripper.dart';

class TapasticEpisode {
  final int id;
  final String filename;

  TapasticEpisode({required this.id, required String title})
      : filename = Utils.filesystemSafe(title);
}

class TapasticRipper extends AbstractHTMLRipper {
  static final RegExp _seriesGidPattern =
      RegExp(r'^https?://tapas\.io/series/([^/?]+).*$');
  static final RegExp _episodeGidPattern =
      RegExp(r'^https?://tapas\.io/episode/([^/?]+).*$');

  final List<TapasticEpisode> episodes = <TapasticEpisode>[];

  TapasticRipper(super.url);

  @override
  String getHost() => 'tapas';

  String getDomain() => 'tapas.io';

  @override
  bool canRip(Uri url) => url.host == getDomain();

  @override
  Future<String> getGID(Uri url) async {
    final value = url.toString();
    final seriesMatch = _seriesGidPattern.firstMatch(value);
    if (seriesMatch != null) return 'series_ ${seriesMatch.group(1)!}';

    final episodeMatch = _episodeGidPattern.firstMatch(value);
    if (episodeMatch != null) return 'ep_${episodeMatch.group(1)!}';

    throw FormatException(
      'Expected tapastic.com URL format: '
      'tapastic.com/[series|episode]/name - got $url instead',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());

    Document page;
    try {
      page = await Http.get(url);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
      return;
    }

    final episodeUrls = await getURLsFromPage(page);
    final downloads = <RipperDownload>[];
    final epiLog = digitCount(episodes.length);

    for (var index = 0; index < episodeUrls.length; index++) {
      if (isStopped) break;

      final episodeUrl = Uri.parse(episodeUrls[index]);
      try {
        sendUpdate(RipStatus.loadingResource, episodeUrl.toString());
        final episodePage = await Http.get(episodeUrl);
        downloads.addAll(
          downloadsFromEpisodePage(
            episodePage,
            episodes[index],
            episodeIndex: index + 1,
            episodeDigitCount: epiLog,
            workingDirectory: workingDir,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    await downloadFiles(downloads);
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<List<String>> getURLsFromPage(Document page) async {
    episodes
      ..clear()
      ..addAll(episodesFromDocument(page));

    return [
      for (final episode in episodes)
        'http://tapastic.com/episode/${episode.id}',
    ];
  }

  @override
  Future<Uri?> getNextPage(Document page) async => null;

  static List<TapasticEpisode> episodesFromDocument(Document page) {
    final html = page.outerHtml;
    if (!html.contains('episodeList : ')) return const [];

    final jsonString = betweenFirst(html, 'episodeList : ', ',\n');
    if (jsonString == null || jsonString.isEmpty) return const [];

    final decoded = jsonDecode(jsonString);
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          TapasticEpisode(
            id: item['id'] as int,
            title: item['title'] as String,
          ),
    ];
  }

  static List<RipperDownload> downloadsFromEpisodePage(
    Document page,
    TapasticEpisode episode, {
    required int episodeIndex,
    required int episodeDigitCount,
    required Directory workingDirectory,
  }) {
    final images = page.querySelectorAll('article.ep-contents img');
    final imgLog = digitCount(images.length);

    return [
      for (var i = 0; i < images.length; i++)
        if ((images[i].attributes['src'] ?? '').isNotEmpty)
          RipperDownload(
            url: Uri.parse(images[i].attributes['src']!),
            saveAs: File(
              p.join(
                workingDirectory.path,
                fileNameForUrl(
                  Uri.parse(images[i].attributes['src']!),
                  prefix: filenamePrefix(
                    episode,
                    episodeIndex: episodeIndex,
                    episodeDigitCount: episodeDigitCount,
                    imageIndex: i + 1,
                    imageCount: images.length,
                    imageDigitCount: imgLog,
                  ),
                ),
              ),
            ),
          ),
    ];
  }

  static String? betweenFirst(String value, String start, String end) {
    final startIndex = value.indexOf(start);
    if (startIndex < 0) return null;
    final contentStart = startIndex + start.length;
    final endIndex = value.indexOf(end, contentStart);
    if (endIndex < 0) return null;
    return value.substring(contentStart, endIndex);
  }

  static String filenamePrefix(
    TapasticEpisode episode, {
    required int episodeIndex,
    required int episodeDigitCount,
    required int imageIndex,
    required int imageCount,
    required int imageDigitCount,
  }) {
    final episodeNumber =
        episodeIndex.toString().padLeft(episodeDigitCount, '0');
    final imageNumber = imageIndex.toString().padLeft(imageDigitCount, '0');
    final totalImages = imageCount.toString().padLeft(imageDigitCount, '0');
    final title = episode.filename.replaceAll(' ', '-');
    return 'ep$episodeNumber-${imageNumber}of$totalImages-$title-';
  }

  static String fileNameForUrl(Uri uri, {required String prefix}) {
    final fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    return Utils.sanitizeSaveAs('$prefix$fileName');
  }

  static int digitCount(int value) {
    if (value <= 0) return 1;
    return (math.log(value) / math.ln10).floor() + 1;
  }
}
