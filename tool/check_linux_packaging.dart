import 'dart:io';

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

void main() {
  final cmake = File('linux/CMakeLists.txt').readAsStringSync();
  final desktop = File('linux/ripme.desktop').readAsStringSync();
  final metadata =
      File('linux/com.rarchives.ripme.metainfo.xml').readAsStringSync();
  final ci = File('.github/workflows/flutter.yml').readAsStringSync();
  final release = File('.github/workflows/release.yml').readAsStringSync();

  const cmakeRules = [
    'set(BINARY_NAME "ripme")',
    r'set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")',
    r'install(TARGETS ${BINARY_NAME}',
    'share/applications',
    'share/icons/hicolor/256x256/apps',
    'share/metainfo',
    '../LICENSE.txt',
  ];
  for (final rule in cmakeRules) {
    if (!cmake.contains(rule)) {
      _fail('Linux CMake packaging is missing: $rule');
    }
  }

  for (final entry in [
    'Type=Application',
    'Name=RipMe',
    'Exec=ripme',
    'TryExec=ripme',
    'Icon=ripme',
    'Terminal=false',
  ]) {
    if (!desktop.contains(entry)) {
      _fail('Linux desktop metadata is missing: $entry');
    }
  }

  for (final entry in [
    '<id>com.rarchives.ripme</id>',
    '<project_license>MIT</project_license>',
    '<launchable type="desktop-id">ripme.desktop</launchable>',
    '<binary>ripme</binary>',
  ]) {
    if (!metadata.contains(entry)) {
      _fail('Linux AppStream metadata is missing: $entry');
    }
  }

  const verificationCommand = 'bash tool/verify_linux_bundle.sh';
  if (!ci.contains(verificationCommand) ||
      !release.contains(verificationCommand)) {
    _fail('CI and release workflows must verify the built Linux bundle.');
  }

  stdout.writeln('Linux metadata and executable packaging verified.');
}
