import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/app_logger.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('uses Java log labels and defaults invalid values to error', () {
    expect(
      AppLogLevel.fromConfig('Log level: Debug'),
      AppLogLevel.debug,
    );
    expect(AppLogLevel.fromConfig('Log level: Info'), AppLogLevel.info);
    expect(AppLogLevel.fromConfig('Log level: Warn'), AppLogLevel.warn);
    expect(AppLogLevel.fromConfig('Log level: Error'), AppLogLevel.error);
    expect(AppLogLevel.fromConfig('invalid'), AppLogLevel.error);
  });

  test('filters configured levels and saves Java-style ripme.log', () async {
    SharedPreferences.setMockInitialValues({
      'log.level': 'Log level: Warn',
      'log.save': true,
    });
    await Utils.init();
    final directory = await Directory.systemTemp.createTemp('ripme_logger');
    addTearDown(() => directory.delete(recursive: true));
    final console = <String>[];
    final logger = AppLogger(
      directoryProvider: () async => directory,
      consoleSink: console.add,
    );
    await logger.configure();

    await logger.info('hidden');
    await logger.warn('visible warning');
    await logger.error('visible error');

    final contents = await File('${directory.path}/ripme.log').readAsString();
    expect(contents, isNot(contains('hidden')));
    expect(contents, contains('WARN visible warning'));
    expect(contents, contains('ERROR visible error'));
    expect(console, hasLength(2));
  });

  test('rolls ripme.log into Java-compatible gzip archives', () async {
    SharedPreferences.setMockInitialValues({
      'log.level': 'Log level: Debug',
      'log.save': true,
    });
    await Utils.init();
    final directory = await Directory.systemTemp.createTemp('ripme_logger');
    addTearDown(() => directory.delete(recursive: true));
    final logger = AppLogger(
      directoryProvider: () async => directory,
      consoleSink: (_) {},
      maxFileBytes: 80,
    );
    await logger.configure();

    await logger.info('first message that fills the active log file');
    await logger.info('second message triggers a compressed rollover');

    final archive = File('${directory.path}/ripme.1.log.gz');
    expect(await archive.exists(), isTrue);
    final archivedText = utf8.decode(gzip.decode(await archive.readAsBytes()));
    expect(archivedText, contains('first message'));
    expect(
      await File('${directory.path}/ripme.log').readAsString(),
      contains('second message'),
    );
  });
}
