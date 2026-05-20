import 'dart:convert';

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
