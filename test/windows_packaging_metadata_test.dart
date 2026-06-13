import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Windows resource embeds Java icon and native version metadata', () {
    final resource = File('windows/runner/Runner.rc').readAsStringSync();

    expect(
      File('windows/runner/resources/app_icon.ico').readAsBytesSync(),
      File('assets/icon.ico').readAsBytesSync(),
    );
    expect(
      resource,
      contains(r'ICON                    "resources\\app_icon.ico"'),
    );
    expect(resource, contains('FILEVERSION VERSION_AS_NUMBER'));
    expect(resource, contains('PRODUCTVERSION VERSION_AS_NUMBER'));
    expect(resource, contains('VALUE "FileDescription", "RipMe"'));
    expect(resource, contains('VALUE "OriginalFilename", "ripme.exe"'));
    expect(resource, contains('VALUE "ProductName", "RipMe"'));
  });

  test('Windows bundle installs native runtime beside ripme.exe', () {
    final cmake = File('windows/CMakeLists.txt').readAsStringSync();
    final runner = File('windows/runner/CMakeLists.txt').readAsStringSync();

    expect(cmake, contains('set(BINARY_NAME "ripme")'));
    expect(
      cmake,
      contains(r'set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")'),
    );
    expect(cmake, contains('../LICENSE.txt'));
    expect(runner, contains(r'add_executable(${BINARY_NAME} WIN32'));
    expect(runner, contains('"Runner.rc"'));
    expect(runner, contains('"runner.exe.manifest"'));
    expect(runner, contains('FLUTTER_VERSION_BUILD'));
  });

  test('CI verifies Windows bundle before archiving', () {
    const command = 'pwsh -File tool/verify_windows_bundle.ps1 -Bundle';
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
