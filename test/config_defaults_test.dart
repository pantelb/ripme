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
    expect(Utils.getConfigInteger('download.retry.sleep', 0), 5000);
    expect(Utils.getConfigInteger('proxy.port', 0), 8080);
    expect(Utils.getConfigBoolean('file.overwrite', true), isFalse);
    expect(Utils.getConfigBoolean('download.save_order', false), isTrue);
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

  test('parses comma-separated string list config values', () async {
    SharedPreferences.setMockInitialValues({
      'download.ignore_extensions': 'mp4, gif, , webm',
    });
    await Utils.init();

    expect(Utils.getConfigStringList('download.ignore_extensions'),
        ['mp4', 'gif', 'webm']);
  });
}
