import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'rip_manager.dart';

class HistoryProvider {
  static const String _key = 'rip_history';

  static Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_key);
    if (json == null) return [];

    return importHistory(json);
  }

  static Future<void> saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, exportHistory(history));
  }

  static String exportHistory(List<HistoryEntry> history) {
    return jsonEncode(history.map((e) => e.toJson()).toList());
  }

  static List<HistoryEntry> importHistory(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON history array');
    }
    return decoded.whereType<Map>().map(HistoryEntry.fromJson).toList();
  }

  static Future<void> exportToFile(
      List<HistoryEntry> history, File file) async {
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(exportHistory(history));
  }

  static Future<List<HistoryEntry>> importFromFile(File file) async {
    return importHistory(await file.readAsString());
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
