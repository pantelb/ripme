import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('desktop default rip directory is adjacent to the executable', () {
    expect(
      Utils.defaultRipDirectoryPath(r'C:\Apps\RipMe\ripme.exe'),
      r'C:\Apps\RipMe\rips',
    );
    expect(
      Utils.defaultRipDirectoryPath('/opt/ripme/ripme'),
      '/opt/ripme/rips',
    );
  });

  test('desktop creates the Java executable-adjacent rips directory', () async {
    final root = await Directory.systemTemp.createTemp('ripme_default_rips');
    addTearDown(() => root.delete(recursive: true));
    final executable = File('${root.path}/ripme');
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final workingDirectory = await Utils.getWorkingDirectory(
      executablePath: executable.path,
      android: false,
    );

    expect(workingDirectory.path, '${root.path}${Platform.pathSeparator}rips');
    expect(await workingDirectory.exists(), isTrue);
  });

  test('configured rip directory uses Java creation behavior', () async {
    final root = await Directory.systemTemp.createTemp('ripme_custom_rips');
    addTearDown(() => root.delete(recursive: true));
    final configured = Directory('${root.path}/custom');
    SharedPreferences.setMockInitialValues({
      'rips.directory': configured.path,
    });
    await Utils.init();

    final workingDirectory = await Utils.getWorkingDirectory(android: false);

    expect(workingDirectory.path, configured.path);
    expect(await configured.exists(), isTrue);
  });

  test('failed directory creation falls back to user home like Java', () async {
    final root = await Directory.systemTemp.createTemp('ripme_rips_fallback');
    addTearDown(() => root.delete(recursive: true));
    final fallback = Directory('${root.path}/home');
    await fallback.create();
    SharedPreferences.setMockInitialValues({
      'rips.directory': '${root.path}/missing-parent/rips',
    });
    await Utils.init();

    final workingDirectory = await Utils.getWorkingDirectory(
      android: false,
      fallbackHomeDirectory: fallback,
    );

    expect(workingDirectory.path, fallback.path);
  });

  test('Android retains its writable platform-native rips directory', () async {
    final root = await Directory.systemTemp.createTemp('ripme_android_rips');
    addTearDown(() => root.delete(recursive: true));
    SharedPreferences.setMockInitialValues({});
    await Utils.init();

    final workingDirectory = await Utils.getWorkingDirectory(
      android: true,
      androidBaseDirectory: root,
    );

    expect(workingDirectory.path, '${root.path}${Platform.pathSeparator}rips');
    expect(await workingDirectory.exists(), isTrue);
  });
}
