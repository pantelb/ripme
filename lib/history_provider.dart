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

    return _decodeHistory(json, strictJavaShape: false);
  }

  static Future<void> saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, exportHistory(history));
  }

  static String exportHistory(List<HistoryEntry> history) {
    return jsonEncode(history.map((e) => e.toJson()).toList());
  }

  static List<HistoryEntry> importHistory(String json) {
    return _decodeHistory(json, strictJavaShape: true);
  }

  static List<HistoryEntry> _decodeHistory(
    String json, {
    required bool strictJavaShape,
  }) {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON history array');
    }
    if (!strictJavaShape) {
      return decoded.whereType<Map>().map(HistoryEntry.fromJson).toList();
    }

    return [
      for (var index = 0; index < decoded.length; index++)
        _strictJavaEntry(decoded[index], index),
    ];
  }

  static HistoryEntry _strictJavaEntry(Object? value, int index) {
    if (value is! Map) {
      throw FormatException('History entry $index must be a JSON object');
    }
    if (value['url'] is! String) {
      throw FormatException('History entry $index must contain string url');
    }
    if (value['startDate'] is! num) {
      throw FormatException(
        'History entry $index must contain numeric startDate',
      );
    }
    if (value['modifiedDate'] is! num) {
      throw FormatException(
        'History entry $index must contain numeric modifiedDate',
      );
    }
    return HistoryEntry.fromJson(value);
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
