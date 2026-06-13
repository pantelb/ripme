import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final metadataFile = File('.flutter-plugins-dependencies');

  test('desktop targets register every Java desktop integration replacement',
      () {
    final plugins = _pluginsByPlatform(metadataFile);

    expect(
      plugins['windows'],
      containsAll(<String>{
        'audioplayers_windows',
        'local_notifier',
        'tray_manager',
        'url_launcher_windows',
        'window_manager',
      }),
    );
    expect(
      plugins['linux'],
      containsAll(<String>{
        'audioplayers_linux',
        'local_notifier',
        'tray_manager',
        'url_launcher_linux',
        'window_manager',
      }),
    );
    expect(
      plugins['macos'],
      containsAll(<String>{
        'audioplayers_darwin',
        'local_notifier',
        'tray_manager',
        'url_launcher_macos',
        'window_manager',
      }),
    );
  });

  test('Android registers its launcher without desktop-only integrations', () {
    final androidPlugins = _pluginsByPlatform(metadataFile)['android']!;

    expect(androidPlugins, contains('audioplayers_android'));
    expect(androidPlugins, contains('url_launcher_android'));
    expect(
      androidPlugins,
      isNot(containsAll(<String>{
        'local_notifier',
        'tray_manager',
        'window_manager',
      })),
    );
  });
}

Map<String, Set<String>> _pluginsByPlatform(File metadataFile) {
  expect(
    metadataFile.existsSync(),
    isTrue,
    reason: 'Run flutter pub get before executing platform integration tests.',
  );
  final metadata =
      jsonDecode(metadataFile.readAsStringSync()) as Map<String, dynamic>;
  final platforms = metadata['plugins'] as Map<String, dynamic>;

  return platforms.map((platform, entries) {
    final plugins = (entries as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((entry) => entry['name'] as String)
        .toSet();
    return MapEntry(platform, plugins);
  });
}
