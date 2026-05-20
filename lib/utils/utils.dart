import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../config_defaults.dart';

class Utils {
  static const String ripDirectory = "rips";
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<Directory> getWorkingDirectory() async {
    String? customPath = getConfigString("rips.directory", null);
    if (customPath != null) {
      return Directory(customPath);
    }

    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = (await getExternalStorageDirectory()) ??
          (await getApplicationDocumentsDirectory());
    } else {
      // For desktop, use a folder next to the executable or in documents
      baseDir = await getApplicationDocumentsDirectory();
    }

    Directory workingDir = Directory(p.join(baseDir.path, ripDirectory));
    if (!await workingDir.exists()) {
      await workingDir.create(recursive: true);
    }
    return workingDir;
  }

  static String? getConfigString(String key, String? defaultValue) {
    return _prefs?.getString(key) ??
        ConfigDefaults.strings[key] ??
        defaultValue;
  }

  static int getConfigInteger(String key, int defaultValue) {
    return _prefs?.getInt(key) ?? ConfigDefaults.integers[key] ?? defaultValue;
  }

  static bool getConfigBoolean(String key, bool defaultValue) {
    return _prefs?.getBool(key) ?? ConfigDefaults.booleans[key] ?? defaultValue;
  }

  static Future<void> setConfigString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static Future<void> setConfigInteger(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  static Future<void> setConfigBoolean(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static String filesystemSafe(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9-.,_ ]'), '').trim();
  }

  static String sanitizeSaveAs(String fileName) {
    return fileName.replaceAll(RegExp(r'[\\:*?"<>|]'), '_');
  }
}
