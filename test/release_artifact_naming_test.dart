import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'release files preserve Java version-first naming with platform suffixes',
      () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();

    expect(
      workflow,
      contains(
        r'archive_name="ripme-${RIPME_VERSION}-${{ matrix.platform_suffix }}"',
      ),
    );
    expect(workflow, contains('platform_suffix: linux-x64'));
    expect(workflow, contains('platform_suffix: windows-x64'));
    expect(workflow, contains('platform_suffix: macos-universal'));
    expect(
      workflow,
      contains(r'dist/ripme-${RIPME_VERSION}-android.apk'),
    );
    expect(
      workflow,
      contains(r'dist/ripme-${RIPME_VERSION}-android.aab'),
    );
  });

  test('Actions artifact containers remain stable across release versions', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();

    for (final name in <String>[
      'artifact: ripme-linux-x64',
      'artifact: ripme-windows-x64',
      'artifact: ripme-macos-universal',
      'name: ripme-android',
    ]) {
      expect(workflow, contains(name));
    }
  });
}
