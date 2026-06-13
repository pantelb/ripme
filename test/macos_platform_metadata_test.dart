import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS release preserves Java filesystem access without sandboxing', () {
    final entitlements =
        File('macos/Runner/Release.entitlements').readAsStringSync();

    expect(entitlements, isNot(contains('com.apple.security.app-sandbox')));
    expect(
      entitlements,
      contains('com.apple.security.files.user-selected.read-write'),
    );
  });

  test('macOS deployment target is consistently 12.0', () {
    final project =
        File('macos/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final podfile = File('macos/Podfile').readAsStringSync();
    final infoPlist = File('macos/Runner/Info.plist').readAsStringSync();

    expect(
      'MACOSX_DEPLOYMENT_TARGET = 12.0;'.allMatches(project),
      hasLength(3),
    );
    expect(podfile, contains("platform :osx, '12.0'"));
    expect(infoPlist, contains(r'$(MACOSX_DEPLOYMENT_TARGET)'));
  });
}
