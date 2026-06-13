import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../config_defaults.dart';

class Utils {
  static const String ripDirectory = "rips";
  static const Set<String> _requiredExternalConfigKeys = {
    'twitter.auth',
    'twitter.max_requests',
    'tumblr.auth',
    'error.skip404',
    'gw.api',
    'page.timeout',
    'download.max_size',
  };
  static SharedPreferences? _prefs;
  static File? _portableConfigFile;
  static Map<String, String>? _portableConfig;
  static final Map<String, Map<String, String>> _cookieCache = {};

  static Future<void> init({
    File? portableConfigFile,
    bool detectPortableConfig = false,
  }) async {
    _prefs = await SharedPreferences.getInstance();
    _portableConfigFile = null;
    _portableConfig = null;

    final candidate = portableConfigFile ??
        (detectPortableConfig && !Platform.isAndroid
            ? File(portableConfigPath(Platform.resolvedExecutable))
            : null);
    if (candidate != null && await candidate.exists()) {
      final values = _parseProperties(await candidate.readAsString());
      if (_requiredExternalConfigKeys.every(values.containsKey)) {
        _portableConfigFile = candidate;
        _portableConfig = values;
      } else {
        await candidate.delete();
      }
    }
  }

  static String portableConfigPath(String executablePath) {
    final context = _pathContext(executablePath);
    return context.join(context.dirname(executablePath), 'rip.properties');
  }

  static String defaultRipDirectoryPath(String executablePath) {
    final context = _pathContext(executablePath);
    return context.join(context.dirname(executablePath), ripDirectory);
  }

  static p.Context _pathContext(String path) {
    final isWindowsPath =
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');
    return isWindowsPath ? p.windows : p.posix;
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

  static Future<Directory> getWorkingDirectory({
    String? executablePath,
    bool? android,
    Directory? androidBaseDirectory,
    Directory? fallbackHomeDirectory,
  }) async {
    final customPath = getConfigString("rips.directory", null);
    final isAndroid = android ?? Platform.isAndroid;
    late Directory workingDir;
    if (customPath != null) {
      workingDir = Directory(customPath);
    } else if (isAndroid) {
      final baseDir = androidBaseDirectory ??
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      workingDir = Directory(p.join(baseDir.path, ripDirectory));
    } else {
      workingDir = Directory(
        defaultRipDirectoryPath(executablePath ?? Platform.resolvedExecutable),
      );
    }

    if (await workingDir.exists()) return workingDir;
    try {
      return await workingDir.create();
    } on FileSystemException {
      return fallbackHomeDirectory ?? Directory(_userHomePath());
    }
  }

  static String _userHomePath() =>
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      Directory.current.path;

  static bool supportsCustomRipDirectory({bool? android}) =>
      !(android ?? Platform.isAndroid);

  static String? getConfigString(String key, String? defaultValue) {
    final portableConfig = _portableConfig;
    if (portableConfig != null) {
      return portableConfig[key] ?? defaultValue;
    }
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

  static Map<String, String> getCookies(String host) {
    return _cookieCache.putIfAbsent(host, () {
      final cookies = <String, String>{};
      final configured = getConfigString('cookies.$host', '') ?? '';
      for (var pair in configured.split(' ')) {
        pair = pair.trim();
        if (!pair.contains('=')) continue;
        final separator = pair.indexOf('=');
        cookies[pair.substring(0, separator)] = pair.substring(separator + 1);
      }
      return cookies;
    });
  }

  static void resetCookieCache() {
    _cookieCache.clear();
  }

  static List<String> getConfigList(String key) {
    final portableConfig = _portableConfig;
    if (portableConfig != null) {
      final portableValue = portableConfig[key];
      if (portableValue == null) return const [];
      if (portableValue.trim().isEmpty) return const [];
      return portableValue.split(',').map((value) => value.trim()).toList();
    }
    return List<String>.of(_prefs?.getStringList(key) ?? const []);
  }

  static int getConfigInteger(String key, int defaultValue) {
    final portableConfig = _portableConfig;
    if (portableConfig != null) {
      return int.tryParse(portableConfig[key] ?? '') ?? defaultValue;
    }
    return _prefs?.getInt(key) ?? ConfigDefaults.integers[key] ?? defaultValue;
  }

  static bool getConfigBoolean(String key, bool defaultValue) {
    final portableConfig = _portableConfig;
    final portableValue = portableConfig?[key]?.toLowerCase();
    if (portableConfig != null) {
      return switch (portableValue) {
        'true' => true,
        'false' => false,
        _ => defaultValue,
      };
    }
    return switch (portableValue) {
      'true' => true,
      'false' => false,
      _ => _prefs?.getBool(key) ?? ConfigDefaults.booleans[key] ?? defaultValue,
    };
  }

  static bool getConfigBooleanWithFallback(
      String key, String fallbackKey, bool defaultValue) {
    final portableConfig = _portableConfig;
    final portableValue = portableConfig?[key] ?? portableConfig?[fallbackKey];
    final portableBoolean = switch (portableValue?.toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => null,
    };
    if (portableConfig != null) {
      return portableBoolean ?? defaultValue;
    }
    return portableBoolean ??
        _prefs?.getBool(key) ??
        _prefs?.getBool(fallbackKey) ??
        ConfigDefaults.booleans[key] ??
        ConfigDefaults.booleans[fallbackKey] ??
        defaultValue;
  }

  static Future<void> setConfigString(String key, String value) async {
    if (_portableConfig != null) {
      await _setPortableConfig(key, value);
      return;
    }
    await _prefs?.setString(key, value);
  }

  static Future<void> setConfigInteger(String key, int value) async {
    if (_portableConfig != null) {
      await _setPortableConfig(key, value.toString());
      return;
    }
    await _prefs?.setInt(key, value);
  }

  static Future<void> setConfigBoolean(String key, bool value) async {
    if (_portableConfig != null) {
      await _setPortableConfig(key, value.toString());
      return;
    }
    await _prefs?.setBool(key, value);
  }

  static Future<void> setConfigList(String key, Iterable<String> value) async {
    if (_portableConfig != null) {
      await _setPortableConfig(key, value.join(','));
      return;
    }
    await _prefs?.setStringList(key, List<String>.of(value));
  }

  static Future<void> _setPortableConfig(String key, String value) async {
    _portableConfig![key] = value;
    final entries = _portableConfig!.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final contents = entries
        .map(
          (entry) =>
              '${_escapeProperty(entry.key)}=${_escapeProperty(entry.value)}',
        )
        .join('\n');
    await _portableConfigFile!.writeAsString('$contents\n', flush: true);
  }

  static Map<String, String> _parseProperties(String contents) {
    final values = <String, String>{};
    for (final rawLine in contents.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trimLeft();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) {
        continue;
      }
      final separator = _propertySeparatorIndex(line);
      if (separator < 0) continue;
      final key = _unescapeProperty(line.substring(0, separator).trim());
      final value = _unescapeProperty(line.substring(separator + 1).trim());
      values[key] = value;
    }
    return values;
  }

  static int _propertySeparatorIndex(String line) {
    var escaped = false;
    for (var index = 0; index < line.length; index++) {
      final char = line[index];
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == '=' || char == ':') {
        return index;
      }
    }
    return -1;
  }

  static String _escapeProperty(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t')
      .replaceAll('=', r'\=')
      .replaceAll(':', r'\:');

  static String _unescapeProperty(String value) {
    final output = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final char = value[index];
      if (char != r'\' || index == value.length - 1) {
        output.write(char);
        continue;
      }
      final next = value[++index];
      output.write(switch (next) {
        'n' => '\n',
        'r' => '\r',
        't' => '\t',
        _ => next,
      });
    }
    return output.toString();
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
