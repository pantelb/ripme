import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_ripper.dart';
import '../abstract_video_ripper.dart';

class TwitchVideoRipper extends AbstractVideoRipper {
  static final RegExp _urlPattern = RegExp(r'^https://clips\.twitch\.tv/.*$');
  static final RegExp _gidPattern = RegExp(r'^https://clips\.twitch\.tv/(.*)$');
  static final RegExp _sourcePattern = RegExp(r'"source":"(.*?)"');

  TwitchVideoRipper(super.url);

  @override
  String getHost() => 'twitch';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _gidPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected Twitch.tv format:https://clips.twitch.tv/#### Got: $url',
    );
  }

  @override
  Future<void> rip() async {
    sendUpdate(RipStatus.loadingResource, url.toString());
    try {
      final document = await Http.get(url);
      final downloads = videoDownloadsFromDocument(document, url)
          .map(
            (request) => RipperDownload(
              url: request.url,
              saveAs: File(
                p.join(
                  workingDir.path,
                  Utils.sanitizeSaveAs(request.fileName ?? ''),
                ),
              ),
            ),
          )
          .toList(growable: false);
      await downloadFiles(downloads);
    } catch (e) {
      sendUpdate(RipStatus.ripErrored, e.toString());
    }
    sendUpdate(RipStatus.ripComplete, workingDir.path);
  }

  @override
  Future<Uri> getVideoURLForRip(Uri url) async {
    final document = await Http.get(url);
    final urls = videoUrlsFromDocument(document, url);
    if (urls.isEmpty) {
      throw HttpException('Could not find video URL at $url');
    }
    return urls.first;
  }

  static Document documentFromHtml(String html, Uri pageUrl) {
    return html_parser.parse(html, sourceUrl: pageUrl.toString());
  }

  static List<VideoDownloadRequest> videoDownloadsFromDocument(
    Document document,
    Uri pageUrl,
  ) {
    final title = document.querySelector('title')?.text ?? '';
    return videoUrlsFromDocument(document, pageUrl)
        .map(
          (videoUrl) => VideoDownloadRequest(
            url: videoUrl,
            fileName: javaDownloadFileName(videoUrl, title),
          ),
        )
        .toList(growable: false);
  }

  static List<Uri> videoUrlsFromDocument(Document document, Uri pageUrl) {
    final scripts = document.querySelectorAll('script');
    if (scripts.isEmpty) {
      throw HttpException('Could not find script code at $pageUrl');
    }

    final urls = <Uri>[];
    for (final script in scripts) {
      final match = _sourcePattern.firstMatch(script.text);
      if (match != null) {
        urls.add(Uri.parse(match.group(1)!));
      }
    }
    return urls;
  }

  static String javaDownloadFileName(Uri videoUrl, String title) {
    var fileName = videoUrl.toString();
    fileName = fileName.substring(fileName.lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return 'twitch_$title$fileName';
  }
}
