import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/update_checker.dart';

void main() {
  test('matches Java four-component version comparisons', () {
    expect(
        UpdateChecker.isNewerVersion('1.7.94', '1.7.94-10-b6345398'), isFalse);
    expect(UpdateChecker.isNewerVersion('1.7.94-9-asdf', '1.7.94-10-b6345398'),
        isFalse);
    expect(UpdateChecker.isNewerVersion('1.7.94-11-asdf', '1.7.94-10-b6345398'),
        isTrue);
    expect(
        UpdateChecker.isNewerVersion('1.7.95', '1.7.94-10-b6345398'), isTrue);
    expect(UpdateChecker.isNewerVersion('1.1.0', '1.0.9'), isTrue);
    expect(UpdateChecker.isNewerVersion('2.0.0', '1.9.9+3'), isTrue);
    expect(UpdateChecker.isNewerVersion('1.0.0', '1.0.1'), isFalse);
  });

  test('matches Java exact-string fallback after numeric equality', () {
    expect(UpdateChecker.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    expect(UpdateChecker.isNewerVersion('1.0.0-beta', '1.0.0'), isTrue);
    expect(
        UpdateChecker.isNewerVersion('1.7.94-10-other', '1.7.94-10-b6345398'),
        isTrue);
    expect(UpdateChecker.isNewerVersion('1.0.0.0.1', '1.0.0.0.2'), isTrue);
  });

  test('adapts v-prefixed Flutter release tags before Java comparison',
      () async {
    final checker = UpdateChecker(
      currentVersion: '1.0.0',
      fetcher: (_) async => {
        'tag_name': 'v1.0.1',
        'html_url': 'https://github.com/owner/repo/releases/tag/v1.0.1',
      },
    );

    expect((await checker.check()).updateAvailable, isTrue);
  });

  test('builds GitHub latest release URL and parses update result', () async {
    late Uri requestedUrl;
    final checker = UpdateChecker(
      repository: 'owner/repo',
      currentVersion: '1.0.0',
      fetcher: (url) async {
        requestedUrl = url;
        return {
          'tag_name': 'v1.2.0',
          'name': 'RipMe 1.2.0',
          'body': 'Fixed update behavior.',
          'html_url': 'https://github.com/owner/repo/releases/tag/v1.2.0',
        };
      },
    );

    final result = await checker.check();

    expect(requestedUrl.toString(),
        'https://api.github.com/repos/owner/repo/releases/latest');
    expect(result.currentVersion, '1.0.0');
    expect(result.latestVersion, 'v1.2.0');
    expect(result.releaseName, 'RipMe 1.2.0');
    expect(result.releaseNotes, 'Fixed update behavior.');
    expect(result.releaseUrl.toString(),
        'https://github.com/owner/repo/releases/tag/v1.2.0');
    expect(result.updateAvailable, isTrue);
  });

  test('rejects malformed latest release responses', () async {
    final checker = UpdateChecker(
      fetcher: (_) async => {'html_url': 'https://example.com/release'},
    );

    expect(checker.check(), throwsA(isA<FormatException>()));
  });

  test('honors Java testing.always_try_to_update override', () async {
    final checker = UpdateChecker(
      currentVersion: '9.0.0',
      alwaysTryToUpdate: true,
      fetcher: (_) async => {
        'tag_name': 'v1.0.0',
        'html_url': 'https://github.com/owner/repo/releases/tag/v1.0.0',
      },
    );

    expect((await checker.check()).updateAvailable, isTrue);
  });
}
