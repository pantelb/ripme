import 'dart:io';

void main() {
  final ci = File('.github/workflows/flutter.yml').readAsStringSync();
  final release = File('.github/workflows/release.yml').readAsStringSync();
  final wrapper =
      File('.github/workflows/run-flutter-release.yml').readAsStringSync();

  _requireAll(
    ci,
    const [
      '  pull_request:',
      '  push:',
      "      - '**'",
      'permissions:\n  contents: read',
      'dart run tool/check_workflow_separation.dart',
    ],
    'CI workflow',
  );
  _rejectAll(
    ci,
    const [
      'contents: write',
      'workflow_dispatch:',
      'workflow_call:',
      'softprops/action-gh-release',
      'action-automatic-releases',
      'tags:',
    ],
    'CI workflow',
  );

  _requireAll(
    release,
    const [
      "      - 'v*'",
      '  workflow_dispatch:',
      '  workflow_call:',
      'permissions:\n  contents: read',
      '  publish:',
      '    permissions:\n      contents: write',
      'softprops/action-gh-release@v3',
    ],
    'release workflow',
  );
  final publishOffset = release.indexOf('\n  publish:');
  if (publishOffset < 0) {
    _fail('Release workflow does not define the publish job.');
  }
  final buildSection = release.substring(0, publishOffset);
  if (buildSection.contains('contents: write')) {
    _fail('Release test/build jobs must not receive contents: write.');
  }
  if (release.contains("branches:\n      - '**'")) {
    _fail('Release workflow must not publish from ordinary branch pushes.');
  }

  _requireAll(
    wrapper,
    const [
      '  workflow_dispatch:',
      '      tag:',
      '      build_ref:',
      '      draft:',
      '      prerelease:',
      'uses: pantelb/ripme/.github/workflows/release.yml@Flutter',
      'permissions:\n  contents: write',
      '    permissions:\n      contents: write',
    ],
    'manual release wrapper',
  );
  if (wrapper.contains('pull_request:') || wrapper.contains('  push:')) {
    _fail('Manual release wrapper must only use workflow_dispatch.');
  }

  stdout.writeln(
    'CI is read-only and artifact-only; release publication is isolated to '
    'explicit tag/manual workflows and the publish job alone.',
  );
}

void _requireAll(String contents, List<String> values, String label) {
  for (final value in values) {
    if (!contents.contains(value)) {
      _fail('$label is missing required policy: $value');
    }
  }
}

void _rejectAll(String contents, List<String> values, String label) {
  for (final value in values) {
    if (contents.contains(value)) {
      _fail('$label contains forbidden release capability: $value');
    }
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
