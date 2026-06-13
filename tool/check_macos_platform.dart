import 'dart:io';

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

void main() {
  final releaseEntitlements =
      File('macos/Runner/Release.entitlements').readAsStringSync();
  final debugEntitlements =
      File('macos/Runner/DebugProfile.entitlements').readAsStringSync();
  final project =
      File('macos/Runner.xcodeproj/project.pbxproj').readAsStringSync();
  final podfile = File('macos/Podfile').readAsStringSync();
  final infoPlist = File('macos/Runner/Info.plist').readAsStringSync();

  for (final entitlements in [releaseEntitlements, debugEntitlements]) {
    if (entitlements.contains('com.apple.security.app-sandbox')) {
      _fail('RipMe must remain unsandboxed to preserve Java filesystem paths.');
    }
    if (!entitlements
        .contains('com.apple.security.files.user-selected.read-write')) {
      _fail('file_picker requires user-selected read-write access on macOS.');
    }
  }

  if (!debugEntitlements.contains('com.apple.security.cs.allow-jit')) {
    _fail('Flutter debug/profile builds require the JIT entitlement.');
  }
  if (project.split('MACOSX_DEPLOYMENT_TARGET = 12.0;').length - 1 != 3) {
    _fail('Every Xcode project configuration must target macOS 12.0.');
  }
  if (!podfile.contains("platform :osx, '12.0'")) {
    _fail('CocoaPods must use the same macOS 12.0 deployment target.');
  }
  if (!infoPlist.contains(r'$(MACOSX_DEPLOYMENT_TARGET)')) {
    _fail('Info.plist must publish the configured deployment target.');
  }

  stdout.writeln('macOS entitlements and minimum version verified.');
}
