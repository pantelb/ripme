import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../config_defaults.dart';

class Utils {
  static const String ripDirectory = "rips";
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String bytesToHumanReadable(int bytes) {
    var value = bytes.toDouble();
    const magnitudes = ['', 'K', 'M', 'G', 'T'];
    var magnitude = 0;
    while (value >= 1024) {
      value /= 1024;
      magnitude++;
    }
    return '${value.toStringAsFixed(2)}${magnitudes[magnitude]}iB';
  }

  static String getByteStatusText(
    int completionPercentage,
    int bytesCompleted,
    int bytesTotal,
  ) {
    return '$completionPercentage%  - '
        '${bytesToHumanReadable(bytesCompleted)} / '
        '${bytesToHumanReadable(bytesTotal)}';
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

  static List<String> getConfigStringList(String key) {
    final value = getConfigString(key, null);
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> getConfigList(String key) {
    return List<String>.of(_prefs?.getStringList(key) ?? const []);
  }

  static int getConfigInteger(String key, int defaultValue) {
    return _prefs?.getInt(key) ?? ConfigDefaults.integers[key] ?? defaultValue;
  }

  static bool getConfigBoolean(String key, bool defaultValue) {
    return _prefs?.getBool(key) ?? ConfigDefaults.booleans[key] ?? defaultValue;
  }

  static bool getConfigBooleanWithFallback(
      String key, String fallbackKey, bool defaultValue) {
    return _prefs?.getBool(key) ??
        _prefs?.getBool(fallbackKey) ??
        ConfigDefaults.booleans[key] ??
        ConfigDefaults.booleans[fallbackKey] ??
        defaultValue;
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

  static Future<void> setConfigList(String key, Iterable<String> value) async {
    await _prefs?.setStringList(key, List<String>.of(value));
  }

  static Future<bool> ensureStorageAccess() async {
    if (!Platform.isAndroid) return true;

    final storage = await Permission.storage.request();
    if (storage.isGranted || storage.isLimited) return true;

    final mediaStatuses = await [
      Permission.photos,
      Permission.videos,
    ].request();
    return mediaStatuses.values.any((status) =>
        status.isGranted || status.isLimited || status.isProvisional);
  }

  static String filesystemSafe(String text) {
    final safe = text.replaceAll(RegExp(r'[^a-zA-Z0-9-.,_ ]'), '').trim();
    return safe.length > 100 ? safe.substring(0, 99) : safe;
  }

  static String filesystemSanitized(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');
  }

  static Future<String> getOriginalDirectory(
    String path, {
    bool? caseSensitivePlatform,
  }) async {
    final shouldCheckCase = caseSensitivePlatform ?? !Platform.isWindows;
    if (!shouldCheckCase) return path;

    final parent = Directory(p.dirname(path));
    if (!await parent.exists()) {
      throw FileSystemException(
        'Original directory "${parent.path}" is no directory or not writeable.',
        parent.path,
      );
    }

    final requestedName = p.basename(path).toLowerCase();
    await for (final entry in parent.list(followLinks: false)) {
      if (p.basename(entry.path).toLowerCase() == requestedName) {
        return p.join(parent.path, p.basename(entry.path));
      }
    }
    return path;
  }

  static String sanitizeSaveAs(String fileName) {
    return fileName.replaceAll(RegExp(r'[\\:*?"<>|]'), '_');
  }

  static String shortenSaveAsWindows(String ripsDirPath, String fileName) {
    final pathLength = ripsDirPath.length;
    if (pathLength == 260) {
      throw FileSystemException(
        'File path is too long for this OS',
        ripsDirPath,
      );
    }

    final fullPath = p.windows.join(ripsDirPath, fileName);
    final fileNameParts = fileName.split('.');
    final extension = fileNameParts.last;
    final end = 260 - pathLength - extension.length;
    return '${fullPath.substring(0, end)}.$extension';
  }

  static String shortenPath(String path) {
    final normalized = p.normalize(path);
    if (normalized.length < 24) return normalized;
    return '${normalized.substring(0, 12)}...'
        '${normalized.substring(normalized.length - 12)}';
  }

  static Map<String, String> parseUrlQuery(String query) {
    final result = <String, String>{};
    if (query.isEmpty) return result;

    for (final part in _javaQueryParts(query)) {
      final equals = part.indexOf('=');
      if (equals >= 0) {
        result[Uri.decodeQueryComponent(part.substring(0, equals))] =
            Uri.decodeQueryComponent(part.substring(equals + 1));
      } else {
        result[Uri.decodeQueryComponent(part)] = '';
      }
    }
    return result;
  }

  static String? parseUrlQueryValue(String query, String key) {
    if (query.isEmpty) return null;

    for (final part in _javaQueryParts(query)) {
      final equals = part.indexOf('=');
      if (equals >= 0) {
        if (Uri.decodeQueryComponent(part.substring(0, equals)) == key) {
          return Uri.decodeQueryComponent(part.substring(equals + 1));
        }
      } else if (Uri.decodeQueryComponent(part) == key) {
        return '';
      }
    }
    return null;
  }

  static List<String> _javaQueryParts(String query) {
    final parts = query.split('&');
    while (parts.isNotEmpty && parts.last.isEmpty) {
      parts.removeLast();
    }
    return parts;
  }
}
