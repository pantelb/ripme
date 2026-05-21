import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/update_checker.dart';

void main() {
  test('compares release tags with current app versions', () {
    expect(UpdateChecker.isNewerVersion('v1.0.1', '1.0.0'), isTrue);
    expect(UpdateChecker.isNewerVersion('1.1.0', '1.0.9'), isTrue);
    expect(UpdateChecker.isNewerVersion('2.0.0', '1.9.9+3'), isTrue);
    expect(UpdateChecker.isNewerVersion('v1.0.0', '1.0.0+1'), isFalse);
    expect(UpdateChecker.isNewerVersion('1.0.0', '1.0.1'), isFalse);
    expect(UpdateChecker.isNewerVersion('1.0.0-beta', '1.0.0'), isFalse);
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
}
