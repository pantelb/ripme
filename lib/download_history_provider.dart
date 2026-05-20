import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class DownloadHistoryProvider {
  static const String _key = 'downloaded_urls';

  static Future<Set<String>> loadDownloadedUrls() async {
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
    return urls.contains(_normalize(url));
  }

  static Future<void> markDownloaded(Uri url) async {
    final prefs = await SharedPreferences.getInstance();
    final urls = await loadDownloadedUrls();
    urls.add(_normalize(url));
    await prefs.setString(_key, jsonEncode(urls.toList()..sort()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String _normalize(Uri url) {
    return url.removeFragment().toString();
  }
}
