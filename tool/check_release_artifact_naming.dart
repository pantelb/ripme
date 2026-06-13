import 'dart:io';

void main() {
  final workflow = File('.github/workflows/release.yml').readAsStringSync();

  const required = <String>[
    r'archive_name="ripme-${RIPME_VERSION}-${{ matrix.platform_suffix }}"',
    r'"dist/ripme-${RIPME_VERSION}-android.apk"',
    r'"dist/ripme-${RIPME_VERSION}-android.aab"',
    'platform_suffix: linux-x64',
    'platform_suffix: windows-x64',
    'platform_suffix: macos-universal',
  ];
  for (final value in required) {
    if (!workflow.contains(value)) {
      stderr
          .writeln('Release workflow is missing artifact naming rule: $value');
      exit(1);
    }
  }

  final obsoleteNames = <String>[
    r'archive_name="${{ matrix.artifact }}-${RELEASE_TAG}"',
    r'ripme-android-${RELEASE_TAG}.apk',
    r'ripme-android-${RELEASE_TAG}.aab',
  ];
  for (final value in obsoleteNames) {
    if (workflow.contains(value)) {
      stderr.writeln(
          'Release workflow still uses obsolete artifact name: $value');
      exit(1);
    }
  }

  stdout.writeln(
    'Release artifacts preserve ripme-<version> and add explicit native target '
    'suffixes for Linux, Windows, macOS, APK, and AAB outputs.',
  );
}
