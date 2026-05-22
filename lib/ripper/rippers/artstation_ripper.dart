import 'dart:io';

import 'package:path/path.dart' as p;

import '../../utils/http_utils.dart';
import '../../utils/utils.dart';
import '../abstract_json_ripper.dart';
import '../abstract_ripper.dart';

enum ArtStationUrlType { singleProject, userPortfolio, unknown }

class ParsedArtStationUrl {
  final ArtStationUrlType type;
  final Uri? jsonUrl;
  final String? id;

  const ParsedArtStationUrl(this.type, this.jsonUrl, this.id);
}

class ArtStationAsset {
  final Uri url;
  final String? projectTitle;

  const ArtStationAsset(this.url, {this.projectTitle});
}

class ArtStationRipper extends AbstractJSONRipper {
  ArtStationRipper(super.url);

  static const Map<String, String> _headers = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Upgrade-Insecure-Requests': '1',
  };

  ParsedArtStationUrl? _albumUrl;

  @override
  String getHost() => 'ArtStation';

  @override
  bool canRip(Uri url) => url.host.endsWith('artstation.com');

  @override
  Future<String> getGID(Uri url) async {
    final parsed = await parseUrl(url);
    _albumUrl = parsed;

    switch (parsed.type) {
      case ArtStationUrlType.singleProject:
        final json = await _getJson(parsed.jsonUrl!);
        return projectTitleFromJson(json);
      case ArtStationUrlType.userPortfolio:
        final json = await _getJson(Uri.parse(
            'https://www.artstation.com/users/${parsed.id}/quick.json'));
        return fullNameFromQuickJson(json);
      case ArtStationUrlType.unknown:
        throw FormatException(
            "Expected URL to an ArtStation 'project url' or 'user profile url' - got $url instead");
    }
  }

  @override
  Future<void> parseJSON(Uri url) async {
    final parsed = _albumUrl ?? await parseUrl(this.url);
    switch (parsed.type) {
      case ArtStationUrlType.singleProject:
        final json = await _getJson(parsed.jsonUrl!);
        await _downloadProject(json);
        return;
      case ArtStationUrlType.userPortfolio:
        await _downloadPortfolio(parsed);
        return;
      case ArtStationUrlType.unknown:
        throw FormatException(
            "Expected URL to an ArtStation 'project url' or 'user profile url' - got $url instead");
    }
  }

  Future<void> _downloadPortfolio(ParsedArtStationUrl parsed) async {
    var page = 1;
    var processed = 0;
    while (!isStopped) {
      final pageUrl =
          parsed.jsonUrl!.replace(queryParameters: {'page': '$page'});
      final portfolioJson = await _getJson(pageUrl);
      final total = (portfolioJson['total_count'] as num?)?.toInt() ?? 0;
      final data = portfolioJson['data'];
      if (data is! List || data.isEmpty) break;

      for (final item in data) {
        if (isStopped) break;
        if (item is! Map || item['permalink'] == null) continue;
        final projectUrl =
            await parseUrl(Uri.parse(item['permalink'].toString()));
        if (projectUrl.type != ArtStationUrlType.singleProject ||
            projectUrl.jsonUrl == null) {
          continue;
        }
        final projectJson = await _getJson(projectUrl.jsonUrl!);
        await _downloadProject(projectJson, useProjectSubfolder: true);
        processed++;
      }

      if (processed >= total) break;
      page++;
    }
  }

  Future<void> _downloadProject(dynamic json,
      {bool useProjectSubfolder = false}) async {
    final downloads = <RipperDownload>[];
    for (final asset in urlsFromProjectJson(json)) {
      if (isStopped) break;
      final saveAs = useProjectSubfolder && asset.projectTitle != null
          ? File(p.join(workingDir.path, projectFolderName(asset.projectTitle!),
              _fileNameFor(asset.url)))
          : File(p.join(workingDir.path, _fileNameFor(asset.url)));
      downloads.add(RipperDownload(url: asset.url, saveAs: saveAs));
    }
    await downloadFiles(downloads);
  }

  static Future<ParsedArtStationUrl> parseUrl(Uri url) async {
    String html = '';
    try {
      html = await Http.getText(url, headers: _headers);
    } catch (_) {
      if (url.pathSegments.length >= 2 && url.pathSegments[0] == 'artwork') {
        final id = url.pathSegments.last;
        return ParsedArtStationUrl(
          ArtStationUrlType.singleProject,
          Uri.parse('https://www.artstation.com/projects/$id.json'),
          id,
        );
      }
    }
    return parseUrlFromHtml(url, html);
  }

  static ParsedArtStationUrl parseUrlFromHtml(Uri url, String html) {
    final project = RegExp(r"'/projects/(\w+)\.json'").firstMatch(html);
    if (project != null) {
      final id = project.group(1)!;
      return ParsedArtStationUrl(
        ArtStationUrlType.singleProject,
        Uri.parse('https://www.artstation.com/projects/$id.json'),
        id,
      );
    }

    final user = RegExp(r"'/users/([\w-]+)/quick\.json'").firstMatch(html);
    if (user != null) {
      final id = user.group(1)!;
      return ParsedArtStationUrl(
        ArtStationUrlType.userPortfolio,
        Uri.parse('https://www.artstation.com/users/$id/projects.json'),
        id,
      );
    }

    if (url.pathSegments.length >= 2 && url.pathSegments[0] == 'artwork') {
      final id = url.pathSegments.last;
      return ParsedArtStationUrl(
        ArtStationUrlType.singleProject,
        Uri.parse('https://www.artstation.com/projects/$id.json'),
        id,
      );
    }

    return const ParsedArtStationUrl(ArtStationUrlType.unknown, null, null);
  }

  static List<ArtStationAsset> urlsFromProjectJson(dynamic json) {
    if (json is! Map) return const [];
    final title = json['title']?.toString();
    final assets = json['assets'];
    if (assets is! List) return const [];

    return assets
        .whereType<Map>()
        .map((asset) => asset['image_url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .map((url) => ArtStationAsset(Uri.parse(url), projectTitle: title))
        .toList();
  }

  static String projectTitleFromJson(dynamic json) {
    if (json is Map && json['title'] != null) return json['title'].toString();
    throw const FormatException(
        'ArtStation project JSON did not include title');
  }

  static String fullNameFromQuickJson(dynamic json) {
    if (json is Map && json['full_name'] != null) {
      return json['full_name'].toString();
    }
    throw const FormatException(
        'ArtStation user JSON did not include full_name');
  }

  static String projectFolderName(String projectName) {
    var folderName = projectName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    folderName = folderName.replaceAll(RegExp(r'\s+$'), '');
    folderName = folderName.replaceAll(RegExp(r'\.+$'), '');
    return folderName;
  }

  static String _fileNameFor(Uri url) {
    var fileName = url.pathSegments.isNotEmpty ? url.pathSegments.last : 'file';
    final queryIndex = fileName.indexOf('?');
    if (queryIndex >= 0) fileName = fileName.substring(0, queryIndex);
    return Utils.sanitizeSaveAs(fileName);
  }

  Future<dynamic> _getJson(Uri url) {
    return Http.getJSON(url, headers: _headers);
  }
}
