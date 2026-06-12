import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'utils/utils.dart';

enum AppLogLevel {
  debug('Log level: Debug', 'DEBUG'),
  info('Log level: Info', 'INFO'),
  warn('Log level: Warn', 'WARN'),
  error('Log level: Error', 'ERROR');

  const AppLogLevel(this.configValue, this.label);

  final String configValue;
  final String label;

  static AppLogLevel fromConfig(String? value) {
    return AppLogLevel.values.firstWhere(
      (level) => level.configValue == value,
      orElse: () => AppLogLevel.error,
    );
  }
}

typedef LogDirectoryProvider = Future<Directory> Function();
typedef LogConsoleSink = void Function(String line);

class AppLogger {
  AppLogger({
    LogDirectoryProvider? directoryProvider,
    LogConsoleSink? consoleSink,
    this.maxFileBytes = 20 * 1024 * 1024,
    this.maxArchives = 2,
  })  : _directoryProvider = directoryProvider ?? _defaultDirectory,
        _consoleSink = consoleSink ?? ((line) => stdout.writeln(line));

  static final AppLogger instance = AppLogger();

  final LogDirectoryProvider _directoryProvider;
  final LogConsoleSink _consoleSink;
  final int maxFileBytes;
  final int maxArchives;

  AppLogLevel _level = AppLogLevel.debug;
  bool _saveToFile = false;
  Future<void> _pendingWrite = Future<void>.value();

  AppLogLevel get level => _level;
  bool get saveToFile => _saveToFile;

  Future<void> configure() async {
    _level = AppLogLevel.fromConfig(
      Utils.getConfigString('log.level', AppLogLevel.debug.configValue),
    );
    _saveToFile = Utils.getConfigBoolean('log.save', false);
  }

  Future<void> debug(Object message) => log(AppLogLevel.debug, message);
  Future<void> info(Object message) => log(AppLogLevel.info, message);
  Future<void> warn(Object message) => log(AppLogLevel.warn, message);

  Future<void> error(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final details = StringBuffer(message);
    if (error != null) details.write(': $error');
    if (stackTrace != null) details.write('\n$stackTrace');
    return log(AppLogLevel.error, details.toString());
  }

  Future<void> log(AppLogLevel level, Object message) {
    if (level.index < _level.index) return Future<void>.value();
    final line = '${_timestamp(DateTime.now())} ${level.label} $message';
    _consoleSink(line);
    if (!_saveToFile) return Future<void>.value();

    _pendingWrite = _pendingWrite.then((_) => _writeLine(line));
    return _pendingWrite;
  }

  Future<void> _writeLine(String line) async {
    try {
      final directory = await _directoryProvider();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File('${directory.path}${Platform.pathSeparator}ripme.log');
      final bytes = utf8.encode('$line\n');
      if (await file.exists() &&
          await file.length() + bytes.length > maxFileBytes) {
        await _rotate(file);
      }
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    } on FileSystemException catch (error) {
      _consoleSink(
        '${_timestamp(DateTime.now())} ERROR Failed to write ripme.log: $error',
      );
    }
  }

  Future<void> _rotate(File file) async {
    if (maxArchives <= 0) {
      await file.writeAsBytes(const []);
      return;
    }

    final directory = file.parent.path;
    final separator = Platform.pathSeparator;
    final oldest = File('$directory${separator}ripme.$maxArchives.log.gz');
    if (await oldest.exists()) await oldest.delete();
    for (var index = maxArchives - 1; index >= 1; index--) {
      final source = File('$directory${separator}ripme.$index.log.gz');
      if (await source.exists()) {
        await source.rename(
          '$directory${separator}ripme.${index + 1}.log.gz',
        );
      }
    }

    final archive = File('$directory${separator}ripme.1.log.gz');
    await archive.writeAsBytes(gzip.encode(await file.readAsBytes()));
    await file.writeAsBytes(const []);
  }

  static Future<Directory> _defaultDirectory() async {
    if (Platform.isAndroid) return getApplicationDocumentsDirectory();
    return Directory.current;
  }

  static String _timestamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year.toString().padLeft(4, '0')}-'
        '${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
