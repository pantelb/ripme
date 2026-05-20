import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'rip_manager.dart';

class HistoryProvider {
  static const String _key = 'rip_history';

  static Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_key);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => HistoryEntry(
              url: e['url'],
              dir: e['dir'],
              date: DateTime.parse(e['date']),
            ))
        .toList();
  }

  static Future<void> saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(history
        .map((e) => {
              'url': e.url,
              'dir': e.dir,
              'date': e.date.toIso8601String(),
            })
        .toList());
    await prefs.setString(_key, json);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
