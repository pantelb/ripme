import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionMatch =
      RegExp(r'^version:\s*([^\s+]+)\+([0-9]+)\s*$', multiLine: true)
          .firstMatch(pubspec);
  if (versionMatch == null) {
    _fail('pubspec.yaml must declare version as <name>+<build number>.');
  }
  final version = versionMatch.group(1)!;
  final buildNumber = versionMatch.group(2)!;

  final appVersion = File('lib/app_version.dart').readAsStringSync();
  _requireContains(
    appVersion,
    "defaultValue: '$version'",
    'lib/app_version.dart',
  );
  _requireContains(
    appVersion,
    "defaultValue: '$buildNumber'",
    'lib/app_version.dart',
  );

  _requireContains(
    File('android/app/build.gradle.kts').readAsStringSync(),
    'versionCode = flutter.versionCode',
    'android/app/build.gradle.kts',
  );
  _requireContains(
    File('android/app/build.gradle.kts').readAsStringSync(),
    'versionName = flutter.versionName',
    'android/app/build.gradle.kts',
  );
  _requireContains(
    File('macos/Runner/Info.plist').readAsStringSync(),
    r'$(FLUTTER_BUILD_NAME)',
    'macos/Runner/Info.plist',
  );
  _requireContains(
    File('macos/Runner/Info.plist').readAsStringSync(),
    r'$(FLUTTER_BUILD_NUMBER)',
    'macos/Runner/Info.plist',
  );
  final windowsResource = File('windows/runner/Runner.rc').readAsStringSync();
  _requireContains(
    windowsResource,
    'FLUTTER_VERSION_BUILD',
    'windows/runner/Runner.rc',
  );
  _requireContains(
    windowsResource,
    'VERSION_AS_STRING FLUTTER_VERSION',
    'windows/runner/Runner.rc',
  );

  final releaseWorkflow =
      File('.github/workflows/release.yml').readAsStringSync();
  for (final expected in <String>[
    r'version="${RELEASE_TAG#v}"',
    r'RIPME_BUILD_NUMBER=$GITHUB_RUN_NUMBER',
    r'--build-name "$RIPME_VERSION"',
    r'--build-number "$RIPME_BUILD_NUMBER"',
    r'--dart-define "RIPME_VERSION=$RIPME_VERSION"',
    r'--dart-define "RIPME_BUILD_NUMBER=$RIPME_BUILD_NUMBER"',
  ]) {
    _requireContains(
      releaseWorkflow,
      expected,
      '.github/workflows/release.yml',
    );
  }

  stdout.writeln(
    'Flutter version metadata is synchronized at $version+$buildNumber and '
    'release builds inject tag/run identity into Dart and native targets.',
  );
}

void _requireContains(
  String source,
  String expected,
  String path,
) {
  if (!source.contains(expected)) {
    _fail('$path does not contain required version metadata: $expected');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
