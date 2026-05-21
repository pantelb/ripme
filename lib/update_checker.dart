import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_version.dart';

typedef ReleaseJsonFetcher = Future<Map<String, dynamic>> Function(Uri url);

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.updateAvailable,
    this.releaseName,
  });

  final String currentVersion;
  final String latestVersion;
  final Uri releaseUrl;
  final bool updateAvailable;
  final String? releaseName;
}

class UpdateChecker {
  const UpdateChecker({
    this.repository = releaseRepository,
    this.currentVersion = appVersion,
    ReleaseJsonFetcher? fetcher,
  }) : _fetcher = fetcher ?? _fetchLatestReleaseJson;

  final String repository;
  final String currentVersion;
  final ReleaseJsonFetcher _fetcher;

  Future<UpdateCheckResult> check() async {
    final release = await _fetcher(
      Uri.https('api.github.com', '/repos/$repository/releases/latest'),
    );
    final tagName = _stringValue(release['tag_name']);
    final htmlUrl = _stringValue(release['html_url']);
    if (tagName == null || tagName.isEmpty) {
      throw const FormatException(
          'Latest release response is missing tag_name');
    }
    if (htmlUrl == null || htmlUrl.isEmpty) {
      throw const FormatException(
          'Latest release response is missing html_url');
    }

    return UpdateCheckResult(
      currentVersion: currentVersion,
      latestVersion: tagName,
      releaseUrl: Uri.parse(htmlUrl),
      releaseName: _stringValue(release['name']),
      updateAvailable: isNewerVersion(tagName, currentVersion),
    );
  }

  static bool isNewerVersion(String latestVersion, String currentVersion) {
    final latest = _versionNumbers(latestVersion);
    final current = _versionNumbers(currentVersion);
    final length =
        latest.length > current.length ? latest.length : current.length;

    for (var index = 0; index < length; index++) {
      final latestPart = index < latest.length ? latest[index] : 0;
      final currentPart = index < current.length ? current[index] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }

  static List<int> _versionNumbers(String version) {
    final normalized = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
    return normalized
        .split(RegExp(r'[.\-+]'))
        .take(4)
        .map((part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
  }

  static String? _stringValue(Object? value) => value is String ? value : null;

  static Future<Map<String, dynamic>> _fetchLatestReleaseJson(Uri url) async {
    final response = await http.get(
      url,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'GitHub release lookup failed with HTTP ${response.statusCode}',
        url,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Latest release response was not an object');
    }
    return decoded;
  }
}
