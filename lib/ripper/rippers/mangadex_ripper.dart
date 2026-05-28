import 'dart:io';

import 'package:path/path.dart' as p;

import '../../ui/rip_status_message.dart';
import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_json_ripper.dart';

class MangadexRipper extends AbstractJSONRipper {
  MangadexRipper(
    super.url, {
    this.chapterApiEndPoint = 'https://mangadex.org/api/chapter/',
    this.mangaApiEndPoint = 'https://mangadex.org/api/manga/',
  });

  static final RegExp _chapterPattern =
      RegExp(r'^https://mangadex\.org/chapter/([\d]+)/([\d+]?)$');
  static final RegExp _mangaPattern =
      RegExp(r'^https://mangadex\.org/title/([\d]+)/(.+)$');

  final String chapterApiEndPoint;
  final String mangaApiEndPoint;
  bool _isSingleChapter = false;

  @override
  String getHost() => 'mangadex';

  String getDomain() => 'mangadex.org';

  @override
  bool canRip(Uri url) => url.host.endsWith(getDomain());

  @override
  Future<String> getGID(Uri url) async {
    final chapterId = getChapterID(url.toString());
    final mangaId = getMangaID(url.toString());
    if (chapterId != null) {
      _isSingleChapter = true;
      return chapterId;
    }
    if (mangaId != null) {
      _isSingleChapter = false;
      return mangaId;
    }
    throw FormatException('Unable to get chapter ID from$url');
  }

  @override
  Future<void> parseJSON(Uri url) async {
    await getGID(url);

    final firstJson = await getFirstPage();
    final imageUrls = _isSingleChapter
        ? urlsFromChapterJson(firstJson)
        : await urlsFromMangaJson(firstJson);

    var index = 0;
    for (final imageUrl in imageUrls) {
      if (isStopped) break;
      await Http.delay(const Duration(seconds: 1));
      index++;
      final uri = Uri.parse(imageUrl);
      await downloadFile(
        uri,
        File(p.join(workingDir.path, fileNameForUrl(uri, index))),
      );
    }
  }

  Future<Map<String, dynamic>> getFirstPage() async {
    final chapterId = getChapterID(url.toString());
    final mangaId = getMangaID(url.toString());
    if (mangaId != null) return getJson(Uri.parse('$mangaApiEndPoint$mangaId'));
    return getJson(Uri.parse('$chapterApiEndPoint$chapterId'));
  }

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final json = await Http.getJSON(uri);
    if (json is Map<String, dynamic>) return json;
    throw FormatException('Expected MangaDex JSON object from $uri');
  }

  Future<List<String>> urlsFromMangaJson(Map<String, dynamic> json) async {
    final chapters = englishChapterIdsByNumber(json);
    final imageUrls = <String>[];
    for (final entry in chapters.entries) {
      if (isStopped) break;
      final chapterJson =
          await getJson(Uri.parse('$chapterApiEndPoint${entry.value}'));
      sendUpdate(RipStatus.loadingResource, 'chapter ${entry.key}');
      imageUrls.addAll(urlsFromChapterJson(chapterJson));
    }
    return imageUrls;
  }

  bool get isSingleChapterForTesting => _isSingleChapter;

  static String? getChapterID(String url) {
    final match = _chapterPattern.firstMatch(url);
    return match?.group(1);
  }

  static String? getMangaID(String url) {
    final match = _mangaPattern.firstMatch(url);
    return match?.group(1);
  }

  static String imageUrl(String chapterHash, String imageName, String server) {
    return '$server$chapterHash/$imageName';
  }

  static List<String> urlsFromChapterJson(Map<String, dynamic> json) {
    final chapterHash = json['hash'];
    final server = json['server'];
    final pageArray = json['page_array'];
    if (chapterHash is! String || server is! String || pageArray is! List) {
      return const [];
    }

    return [
      for (final imageName in pageArray)
        imageUrl(chapterHash, imageName.toString(), server),
    ];
  }

  static Map<double, String> englishChapterIdsByNumber(
    Map<String, dynamic> json,
  ) {
    final chapters = json['chapter'];
    if (chapters is! Map) return const {};

    final byNumber = <double, String>{};
    for (final entry in chapters.entries) {
      final chapter = entry.value;
      if (chapter is! Map) continue;
      if (chapter['lang_name'] != 'English') continue;
      final number = _chapterNumber(chapter['chapter']);
      if (number == null) continue;
      byNumber[number] = entry.key.toString();
    }

    return Map.fromEntries(
      byNumber.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  static double? _chapterNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String fileNameForUrl(Uri uri, int index) {
    var fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file';
    for (final separator in ['?', '#', '&', ':']) {
      final separatorIndex = fileName.indexOf(separator);
      if (separatorIndex >= 0) fileName = fileName.substring(0, separatorIndex);
    }
    return Utils.sanitizeSaveAs('${prefixForIndex(index)}$fileName');
  }

  static String prefixForIndex(int index) {
    if (!Utils.getConfigBoolean('download.save_order', true)) return '';
    return '${index.toString().padLeft(3, '0')}_';
  }
}
