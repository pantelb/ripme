import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/app_version.dart';
import 'package:ripme/cli/cli_controller.dart';

void main() {
  test('only non-empty argument lists select headless mode', () {
    expect(CliController.shouldRunHeadless(const []), isFalse);
    expect(CliController.shouldRunHeadless(const ['--help']), isTrue);
    expect(CliController.shouldRunHeadless(const ['--url', 'https://x.test']),
        isTrue);
  });

  test('short and long help options print the Java CLI option surface',
      () async {
    for (final args in const [
      ['-h'],
      ['--help'],
    ]) {
      final result = await CliController().run(args);

      expect(result.exitCode, 0);
      expect(result.isError, isFalse);
      expect(result.output, startsWith('usage: ripme [OPTIONS]'));
      expect(result.output, contains('-u,--url <URL>'));
      expect(result.output, contains('-R,--rerip-selected'));
      expect(result.output, contains('-s,--socks-server <SERVER>'));
      expect(result.output, contains('-H,--history <PATH>'));
    }
  });

  test('short and long version options print the Flutter app version',
      () async {
    for (final args in const [
      ['-v'],
      ['--version'],
    ]) {
      final result = await CliController().run(args);

      expect(result.exitCode, 0);
      expect(result.output, appVersion);
      expect(result.isError, isFalse);
    }
  });

  test('single URL options run through the injected headless ripper', () async {
    final rippedUrls = <Uri>[];
    final controller = CliController(
      ripUrl: (url) async => rippedUrls.add(url),
    );

    for (final args in const [
      ['-u', 'https://example.com/album'],
      ['--url=https://example.com/second'],
    ]) {
      final result = await controller.run(args);

      expect(result.exitCode, 0);
      expect(result.isError, isFalse);
    }
    expect(rippedUrls, [
      Uri.parse('https://example.com/album'),
      Uri.parse('https://example.com/second'),
    ]);
  });

  test('single URL mode rejects malformed URLs like Java', () async {
    final result = await CliController().run(const ['--url', 'not-a-url']);

    expect(result.exitCode, 1);
    expect(result.isError, isTrue);
    expect(
        result.output, contains('Expected URL format is http://domain.com/'));
  });

  test('URL-file parsing skips only lines beginning with Java comments', () {
    expect(
      CliController.urlValuesFromLines(const [
        '// comment',
        '# another comment',
        '  // not a Java comment before trimming',
        ' https://example.com/one ',
        '',
      ]),
      [
        '// not a Java comment before trimming',
        'https://example.com/one',
        '',
      ],
    );
  });

  test('URL-file mode rips valid lines sequentially and continues on errors',
      () async {
    final rippedUrls = <Uri>[];
    final controller = CliController(
      readUrlFile: (_) async => const [
        '# comment',
        ' https://example.com/one ',
        'not-a-url',
        'https://example.com/two',
      ],
      ripUrl: (url) async {
        rippedUrls.add(url);
        if (url.path == '/one') throw Exception('first failed');
      },
    );

    final result = await controller.run(const ['--urls-file', 'urls.txt']);

    expect(result.exitCode, 0);
    expect(result.isError, isTrue);
    expect(rippedUrls, [
      Uri.parse('https://example.com/one'),
      Uri.parse('https://example.com/two'),
    ]);
    expect(result.output, contains('Ripped 1 URL(s) from urls.txt'));
    expect(result.output, contains('Expected URL format'));
    expect(result.output, contains('first failed'));
  });

  test('unported CLI options fail without launching the GUI', () async {
    final result = await CliController().run(const ['--rerip']);

    expect(result.exitCode, 64);
    expect(result.isError, isTrue);
    expect(result.output, contains('--rerip'));
  });
}
