import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/config_defaults.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reconciles every active Java rip.properties default', () {
    final javaDefaults = <String, String>{};
    for (final rawLine in File(
      'test/fixtures/java_rip_properties.properties',
    ).readAsLinesSync()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      javaDefaults[line.substring(0, separator).trim()] =
          line.substring(separator + 1).trim();
    }

    final flutterDefaults = <String, Object>{
      ...ConfigDefaults.integers,
      ...ConfigDefaults.booleans,
      ...ConfigDefaults.strings,
    };

    expect(javaDefaults.keys, hasLength(15));
    for (final entry in javaDefaults.entries) {
      expect(
        flutterDefaults,
        contains(entry.key),
        reason: 'Missing Java default ${entry.key}',
      );
      expect(
        flutterDefaults[entry.key].toString(),
        entry.value,
        reason: 'Default mismatch for ${entry.key}',
      );
    }
  });

  test('inventories every Java runtime configuration key', () {
    final javaKeys = File(
      'test/fixtures/java_runtime_config_keys.txt',
    )
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet();

    expect(ConfigDefaults.javaRuntimeKeys, javaKeys);
  });

  test('uses Java rip.properties defaults when preferences are unset',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    expect(Utils.getConfigInteger('threads.size', 10), 5);
    expect(Utils.getConfigInteger('download.retries', 0), 3);
    expect(Utils.getConfigInteger('download.retry.sleep', 0), 0);
    expect(Utils.getConfigInteger('proxy.port', 0), 8080);
    expect(Utils.getConfigBoolean('file.overwrite', true), isFalse);
    expect(Utils.getConfigBoolean('errors.skip404', true), isFalse);
    expect(Utils.getConfigBoolean('download.save_order', false), isTrue);
    expect(Utils.getConfigBoolean('enable.finish.command', true), isFalse);
    expect(Utils.getConfigBoolean('album_titles.save', false), isTrue);
    expect(Utils.getConfigBoolean('remember.url_history', false), isTrue);
    expect(Utils.getConfigBoolean('history.warn_before_delete', false), isTrue);
    expect(Utils.getConfigBoolean('ssl.verify.off', true), isFalse);
    expect(Utils.getConfigBoolean('urls_only.save', true), isFalse);
    expect(Utils.getConfigBoolean('prefer.mp4', true), isFalse);
    expect(Utils.getConfigBoolean('proxy.enabled', true), isFalse);
    expect(Utils.getConfigString('download.ignore_extensions', 'fallback'), '');
    expect(Utils.getConfigStringList('download.ignore_extensions'), isEmpty);
    expect(Utils.getConfigString('twitter.auth', null), isNotEmpty);
    expect(Utils.getConfigString('tumblr.auth', null), isNotEmpty);
    expect(Utils.getConfigString('gw.api', null), 'gonewild');
    expect(Utils.getConfigString('erome.laravel_session', 'fallback'), '');
    expect(Utils.getConfigString('finish.command', 'fallback'), 'ls');
    expect(Utils.getConfigString('proxy.host', 'fallback'), '');
    expect(Utils.getConfigString('proxy.username', 'fallback'), '');
    expect(Utils.getConfigString('proxy.password', 'fallback'), '');
    expect(Utils.getConfigString('cookies.reddit.com', 'fallback'), '');
    expect(Utils.getConfigString('cookies.imgur.com', 'fallback'), '');
    expect(Utils.getConfigString('cookies.erome.com', 'fallback'), '');
    expect(Utils.getConfigString('cookies.soundgasm.net', 'fallback'), '');
    expect(Utils.getConfigString('cookies.vidble.com', 'fallback'), '');
  });

  test('stored preferences override default config values', () async {
    SharedPreferences.setMockInitialValues({
      'threads.size': 2,
      'download.save_order': false,
    });
    await Utils.init();

    expect(Utils.getConfigInteger('threads.size', 10), 2);
    expect(Utils.getConfigBoolean('download.save_order', true), isFalse);
  });

  test('non-portable config persists through the platform preference backend',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    await Utils.setConfigInteger('threads.size', 11);
    await Utils.setConfigBoolean('file.overwrite', true);
    await Utils.setConfigString('rips.directory', r'D:\native\rips');
    await Utils.setConfigList('queue', ['https://one', 'https://two']);

    await Utils.init();

    expect(Utils.getConfigInteger('threads.size', 5), 11);
    expect(Utils.getConfigBoolean('file.overwrite', false), isTrue);
    expect(Utils.getConfigString('rips.directory', null), r'D:\native\rips');
    expect(Utils.getConfigList('queue'), ['https://one', 'https://two']);
  });

  test('all non-portable config setters complete backend writes immediately',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    await Utils.setConfigString('rips.directory', '/tmp/rips');
    await Utils.setConfigInteger('threads.size', 12);
    await Utils.setConfigBoolean('file.overwrite', true);
    await Utils.setConfigList('queue', ['one', 'two']);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('rips.directory'), '/tmp/rips');
    expect(preferences.getInt('threads.size'), 12);
    expect(preferences.getBool('file.overwrite'), isTrue);
    expect(preferences.getStringList('queue'), ['one', 'two']);
  });

  test('parses comma-separated string list config values', () async {
    SharedPreferences.setMockInitialValues({
      'download.ignore_extensions': 'mp4, gif, , webm',
    });
    await Utils.init();

    expect(Utils.getConfigStringList('download.ignore_extensions'),
        ['mp4', 'gif', 'webm']);
  });

  test('desktop portable config overrides preferences and Java defaults',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('ripme_portable_config_test');
    addTearDown(() => directory.delete(recursive: true));
    final config = File('${directory.path}/rip.properties');
    await config.writeAsString('''
${File('test/fixtures/java_rip_properties.properties').readAsStringSync()}
threads.size=9
file.overwrite=true
download.ignore_extensions=mp4, gif
rips.directory=C\\:\\\\portable\\\\rips
''');
    SharedPreferences.setMockInitialValues({
      'threads.size': 2,
      'file.overwrite': false,
    });

    await Utils.init(portableConfigFile: config);

    expect(Utils.getConfigInteger('threads.size', 5), 9);
    expect(Utils.getConfigBoolean('file.overwrite', false), isTrue);
    expect(
      Utils.getConfigStringList('download.ignore_extensions'),
      ['mp4', 'gif'],
    );
    expect(Utils.getConfigString('rips.directory', null), r'C:\portable\rips');
  });

  test('portable config setters persist immediately to rip.properties',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('ripme_portable_write_test');
    addTearDown(() => directory.delete(recursive: true));
    final config = File('${directory.path}/rip.properties');
    await config.writeAsString('''
${File('test/fixtures/java_rip_properties.properties').readAsStringSync()}
threads.size=5
''');
    SharedPreferences.setMockInitialValues({});
    await Utils.init(portableConfigFile: config);

    await Utils.setConfigInteger('threads.size', 7);
    await Utils.setConfigBoolean('file.overwrite', true);
    await Utils.setConfigString('rips.directory', r'D:\portable\rips');
    await Utils.setConfigList('queue', ['https://one', 'https://two']);

    final saved = await config.readAsString();
    expect(saved, contains('threads.size=7'));
    expect(saved, contains('file.overwrite=true'));
    expect(saved, contains(r'rips.directory=D\:\\portable\\rips'));
    expect(saved, contains('queue=https\\://one,https\\://two'));
    expect(Utils.getConfigList('queue'), ['https://one', 'https://two']);
  });

  test('obsolete external config is deleted and bundled defaults reload',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('ripme_obsolete_config_test');
    addTearDown(() => directory.delete(recursive: true));
    final config = File('${directory.path}/rip.properties');
    await config.writeAsString('threads.size=9\n');
    SharedPreferences.setMockInitialValues({
      'file.overwrite': true,
    });

    await Utils.init(portableConfigFile: config);

    expect(await config.exists(), isFalse);
    expect(Utils.getConfigInteger('threads.size', 99), 5);
    expect(Utils.getConfigBoolean('file.overwrite', false), isTrue);
    expect(Utils.getConfigString('gw.api', null), 'gonewild');
  });

  test('all seven exact Java sentinels are required for external config',
      () async {
    final source = File(
      'test/fixtures/java_rip_properties.properties',
    ).readAsLinesSync();
    const requiredKeys = {
      'twitter.auth',
      'twitter.max_requests',
      'tumblr.auth',
      'error.skip404',
      'gw.api',
      'page.timeout',
      'download.max_size',
    };

    for (final missingKey in requiredKeys) {
      final directory =
          await Directory.systemTemp.createTemp('ripme_missing_sentinel');
      addTearDown(() => directory.delete(recursive: true));
      final config = File('${directory.path}/rip.properties');
      await config.writeAsString(
        source
            .where((line) => !line.trimLeft().startsWith('$missingKey '))
            .join(
              '\n',
            ),
      );

      await Utils.init(portableConfigFile: config);

      expect(
        await config.exists(),
        isFalse,
        reason: 'External config should be deleted without $missingKey',
      );
    }
  });

  test('portable config path is adjacent to the desktop executable', () {
    expect(
      Utils.portableConfigPath(r'C:\Apps\RipMe\ripme.exe'),
      r'C:\Apps\RipMe\rip.properties',
    );
    expect(
      Utils.portableConfigPath('/opt/ripme/ripme'),
      '/opt/ripme/rip.properties',
    );
  });
}
