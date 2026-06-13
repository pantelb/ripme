import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/app_version.dart';

void main() {
  test('Dart defaults match the Flutter package version and build number', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([^\s+]+)\+([0-9]+)\s*$', multiLine: true)
            .firstMatch(pubspec);

    expect(match, isNotNull);
    expect(appVersion, match!.group(1));
    expect(appBuildNumber, match.group(2));
  });

  test('release workflow injects one version identity into every build', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();

    expect(workflow, contains(r'version="${RELEASE_TAG#v}"'));
    expect(workflow, contains(r'RIPME_BUILD_NUMBER=$GITHUB_RUN_NUMBER'));
    expect(
      RegExp(r'--build-name "\$RIPME_VERSION"').allMatches(workflow).length,
      3,
    );
    expect(
      RegExp(r'--build-number "\$RIPME_BUILD_NUMBER"')
          .allMatches(workflow)
          .length,
      3,
    );
    expect(
      RegExp(r'--dart-define "RIPME_VERSION=\$RIPME_VERSION"')
          .allMatches(workflow)
          .length,
      3,
    );
  });

  test('GUI and CLI expose the synchronized version identity', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final cliSource = File('lib/cli/cli_controller.dart').readAsStringSync();

    expect(mainSource, contains(r"const Text('$appVersion+$appBuildNumber')"));
    expect(cliSource, contains('output: appVersion'));
  });
}
