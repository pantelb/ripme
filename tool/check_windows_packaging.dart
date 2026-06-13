import 'dart:io';

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

void main() {
  final cmake = File('windows/CMakeLists.txt').readAsStringSync();
  final runnerCmake = File('windows/runner/CMakeLists.txt').readAsStringSync();
  final resource = File('windows/runner/Runner.rc').readAsStringSync();
  final manifest =
      File('windows/runner/runner.exe.manifest').readAsStringSync();
  final ci = File('.github/workflows/flutter.yml').readAsStringSync();
  final release = File('.github/workflows/release.yml').readAsStringSync();

  for (final rule in [
    'set(BINARY_NAME "ripme")',
    r'set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")',
    '../LICENSE.txt',
  ]) {
    if (!cmake.contains(rule)) {
      _fail('Windows CMake packaging is missing: $rule');
    }
  }

  for (final rule in [
    'add_executable(\${BINARY_NAME} WIN32',
    '"Runner.rc"',
    '"runner.exe.manifest"',
    'FLUTTER_VERSION_BUILD',
  ]) {
    if (!runnerCmake.contains(rule)) {
      _fail('Windows runner configuration is missing: $rule');
    }
  }

  for (final value in [
    r'ICON                    "resources\\app_icon.ico"',
    'FILEVERSION VERSION_AS_NUMBER',
    'PRODUCTVERSION VERSION_AS_NUMBER',
    'VALUE "FileDescription", "RipMe"',
    'VALUE "OriginalFilename", "ripme.exe"',
    'VALUE "ProductName", "RipMe"',
  ]) {
    if (!resource.contains(value)) {
      _fail('Windows executable metadata is missing: $value');
    }
  }

  if (!manifest.contains('PerMonitorV2') ||
      !manifest.contains('Windows 10 and Windows 11')) {
    _fail('Windows manifest must declare DPI awareness and supported OSes.');
  }

  const verificationCommand =
      'pwsh -File tool/verify_windows_bundle.ps1 -Bundle';
  if (!ci.contains(verificationCommand) ||
      !release.contains(verificationCommand)) {
    _fail('CI and release workflows must verify the built Windows bundle.');
  }

  stdout.writeln('Windows metadata and executable packaging verified.');
}
