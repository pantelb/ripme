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

  test('unported CLI options fail without launching the GUI', () async {
    final result = await CliController().run(const ['--rerip']);

    expect(result.exitCode, 64);
    expect(result.isError, isTrue);
    expect(result.output, contains('--rerip'));
  });
}
