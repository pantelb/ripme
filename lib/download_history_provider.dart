import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'utils/utils.dart';

class DownloadHistoryProvider {
  static const String _key = 'downloaded_urls';

  static Future<Set<String>> loadDownloadedUrls() async {
    final configuredFile = _configuredFile();
    if (configuredFile != null) {
      if (!await configuredFile.exists()) return <String>{};
      return (await configuredFile.readAsLines())
          .where((line) => line.isNotEmpty)
          .toSet();
    }

    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return <String>{};

    final decoded = jsonDecode(json);
    if (decoded is! List) return <String>{};
    return decoded.whereType<String>().toSet();
  }

  static String exportDownloadedUrls(Set<String> urls) {
    return jsonEncode(urls.toList()..sort());
  }

  static Set<String> importDownloadedUrls(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON URL array');
    }
    return decoded.whereType<String>().toSet();
  }

  static Future<void> saveDownloadedUrls(Set<String> urls) async {
    final configuredFile = _configuredFile();
    if (configuredFile != null) {
      if (!await configuredFile.parent.exists()) {
        await configuredFile.parent.create(recursive: true);
      }
      final sorted = urls.toList()..sort();
      await configuredFile.writeAsString(
        sorted.isEmpty ? '' : '${sorted.join('\n')}\n',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, exportDownloadedUrls(urls));
  }

  static Future<void> exportToFile(File file) async {
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(exportDownloadedUrls(await loadDownloadedUrls()));
  }

  static Future<void> importFromFile(File file) async {
    await saveDownloadedUrls(importDownloadedUrls(await file.readAsString()));
  }

  static Future<bool> hasDownloaded(Uri url) async {
    final urls = await loadDownloadedUrls();
    return urls.contains(url.toString());
  }

  static Future<void> markDownloaded(Uri url) async {
    final configuredFile = _configuredFile();
    if (configuredFile != null) {
      await configuredFile.writeAsString(
        url.toString(),
        mode: FileMode.append,
      );
      return;
    }

    final urls = await loadDownloadedUrls();
    urls.add(url.toString());
    await saveDownloadedUrls(urls);
  }

  static Future<void> clear() async {
    final configuredFile = _configuredFile();
    if (configuredFile != null) {
      if (await configuredFile.exists()) {
        await configuredFile.delete();
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static File? _configuredFile() {
    final path = Utils.getConfigString('history.location', null);
    return path == null || path.isEmpty ? null : File(path);
  }
}
