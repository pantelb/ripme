import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String ci;
  late String release;
  late String wrapper;

  setUpAll(() {
    ci = File('.github/workflows/flutter.yml').readAsStringSync();
    release = File('.github/workflows/release.yml').readAsStringSync();
    wrapper =
        File('.github/workflows/run-flutter-release.yml').readAsStringSync();
  });

  test('ordinary CI is read-only and cannot publish releases', () {
    expect(ci, contains('  pull_request:'));
    expect(ci, contains("      - '**'"));
    expect(ci, contains('permissions:\n  contents: read'));
    expect(ci, isNot(contains('contents: write')));
    expect(ci, isNot(contains('workflow_dispatch:')));
    expect(ci, isNot(contains('workflow_call:')));
    expect(ci, isNot(contains('softprops/action-gh-release')));
    expect(ci, isNot(contains('action-automatic-releases')));
    expect(ci, isNot(contains('tags:')));
  });

  test('release builds are explicit and only publish job can write', () {
    expect(release, contains("      - 'v*'"));
    expect(release, contains('  workflow_dispatch:'));
    expect(release, contains('  workflow_call:'));
    expect(release, contains('permissions:\n  contents: read'));

    final publishOffset = release.indexOf('\n  publish:');
    expect(publishOffset, greaterThan(0));
    expect(
      release.substring(0, publishOffset),
      isNot(contains('contents: write')),
    );
    expect(
      release.substring(publishOffset),
      contains('    permissions:\n      contents: write'),
    );
    expect(release, isNot(contains("branches:\n      - '**'")));
  });

  test('manual wrapper preserves Java branch release inputs', () {
    expect(wrapper, contains('  workflow_dispatch:'));
    for (final input in ['tag', 'build_ref', 'draft', 'prerelease']) {
      expect(wrapper, contains('      $input:'));
    }
    expect(
      wrapper,
      contains('uses: pantelb/ripme/.github/workflows/release.yml@Flutter'),
    );
    expect(wrapper, isNot(contains('pull_request:')));
    expect(wrapper, isNot(contains('  push:')));
  });
}
