import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop runners forward process arguments to Dart', () {
    final windowsRunner = File('windows/runner/main.cpp').readAsStringSync();
    final linuxRunner =
        File('linux/runner/my_application.cc').readAsStringSync();
    final macosRunner =
        File('macos/Runner/MainFlutterWindow.swift').readAsStringSync();

    expect(windowsRunner, contains('set_dart_entrypoint_arguments'));
    expect(
      linuxRunner,
      contains('fl_dart_project_set_dart_entrypoint_arguments'),
    );
    expect(macosRunner, contains('let project = FlutterDartProject()'));
    expect(
      macosRunner,
      contains('FlutterViewController(project: project)'),
    );
  });
}
