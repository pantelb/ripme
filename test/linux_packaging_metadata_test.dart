import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux metadata identifies the packaged ripme executable', () {
    final desktop = File('linux/ripme.desktop').readAsStringSync();
    final metadata =
        File('linux/com.rarchives.ripme.metainfo.xml').readAsStringSync();

    expect(desktop, contains('Exec=ripme'));
    expect(desktop, contains('TryExec=ripme'));
    expect(desktop, contains('Icon=ripme'));
    expect(desktop, contains('Terminal=false'));
    expect(metadata, contains('<id>com.rarchives.ripme</id>'));
    expect(metadata, contains('<binary>ripme</binary>'));
    expect(
      metadata,
      contains('<launchable type="desktop-id">ripme.desktop</launchable>'),
    );
  });

  test('Linux CMake installs a relocatable complete bundle', () {
    final cmake = File('linux/CMakeLists.txt').readAsStringSync();

    expect(cmake, contains('set(BINARY_NAME "ripme")'));
    expect(cmake, contains(r'set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")'));
    expect(cmake, contains(r'install(TARGETS ${BINARY_NAME}'));
    expect(cmake, contains('share/applications'));
    expect(cmake, contains('share/icons/hicolor/256x256/apps'));
    expect(cmake, contains('share/metainfo'));
    expect(cmake, contains('../LICENSE.txt'));
  });

  test('CI verifies Linux bundle contents before archiving', () {
    const command = 'bash tool/verify_linux_bundle.sh';
    expect(
      File('.github/workflows/flutter.yml').readAsStringSync(),
      contains(command),
    );
    expect(
      File('.github/workflows/release.yml').readAsStringSync(),
      contains(command),
    );
  });
}
