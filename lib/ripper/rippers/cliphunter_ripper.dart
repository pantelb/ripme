import 'dart:convert';

import '../abstract_video_ripper.dart';
import '../../utils/http_utils.dart';

class CliphunterRipper extends AbstractVideoRipper {
  CliphunterRipper(super.url);

  static final RegExp _urlPattern =
      RegExp(r'^https?://[wm.]*cliphunter\.com/w/([0-9]+).*$');

  static const Map<String, String> _decryptDict = {
    r'$': ':',
    '&': '.',
    '(': '=',
    '-': '-',
    '_': '_',
    '^': '&',
    'a': 'h',
    'c': 'c',
    'b': 'b',
    'e': 'v',
    'd': 'e',
    'g': 'f',
    'f': 'o',
    'i': 'd',
    'm': 'a',
    'l': 'n',
    'n': 'm',
    'q': 't',
    'p': 'u',
    'r': 's',
    'w': 'w',
    'v': 'p',
    'y': 'l',
    'x': 'r',
    'z': 'i',
    '=': '/',
    '?': '?',
  };

  @override
  String getHost() => 'cliphunter';

  @override
  bool canRip(Uri url) => _urlPattern.hasMatch(url.toString());

  @override
  Future<String> getGID(Uri url) async {
    final match = _urlPattern.firstMatch(url.toString());
    if (match != null) return match.group(1)!;

    throw FormatException(
      'Expected cliphunter format:cliphunter.com/w/####... Got: $url',
    );
  }

  @override
  Future<Uri> getVideoURLForRip(Uri url) async {
    final html = await Http.getText(url);
    return videoUrlFromHtml(html);
  }

  @override
  Future<VideoDownloadRequest> getVideoDownloadForRip(Uri url) async {
    final videoUrl = await getVideoURLForRip(url);
    return VideoDownloadRequest(
      url: videoUrl,
      fileName: javaDownloadFileName(videoUrl, await getGID(url)),
      headers: {'Referer': videoUrl.toString()},
    );
  }

  static Uri videoUrlFromHtml(String html) {
    const marker = "var flashVars = {d: '";
    final start = html.indexOf(marker);
    if (start < 0) {
      throw const FormatException('Cliphunter page did not include flashVars');
    }

    final encodedStart = start + marker.length;
    final encodedEnd = html.indexOf("'", encodedStart);
    if (encodedEnd < 0) {
      throw const FormatException('Cliphunter flashVars were not terminated');
    }

    final flashVars = jsonDecode(
      utf8.decode(base64.decode(html.substring(encodedStart, encodedEnd))),
    ) as Map<String, dynamic>;
    final encodedUrl = flashVars['url'];
    if (encodedUrl is! String) {
      throw const FormatException('Cliphunter flashVars did not include URL');
    }

    final urlJson = jsonDecode(utf8.decode(base64.decode(encodedUrl)))
        as Map<String, dynamic>;
    final encryptedUrl =
        urlJson['u'] is Map ? (urlJson['u'] as Map)['l'] : null;
    if (encryptedUrl is! String) {
      throw const FormatException('Cliphunter URL JSON did not include u.l');
    }

    return Uri.parse(decryptVideoUrl(encryptedUrl));
  }

  static String decryptVideoUrl(String encryptedUrl) {
    final buffer = StringBuffer();
    for (final rune in encryptedUrl.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_decryptDict[char] ?? char);
    }
    return buffer.toString();
  }

  static String javaDownloadFileName(Uri videoUrl, String gid) {
    var fileName =
        videoUrl.toString().substring(videoUrl.toString().lastIndexOf('/') + 1);
    for (final separator in ['?', '#', '&', ':']) {
      final index = fileName.indexOf(separator);
      if (index >= 0) fileName = fileName.substring(0, index);
    }
    return 'cliphunter_$gid$fileName';
  }
}
