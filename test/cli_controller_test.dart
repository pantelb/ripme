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

  test('short and long help options print the Java CLI option surface', () {
    for (final args in const [
      ['-h'],
      ['--help'],
    ]) {
      final result = CliController().run(args);

      expect(result.exitCode, 0);
      expect(result.isError, isFalse);
      expect(result.output, startsWith('usage: ripme [OPTIONS]'));
      expect(result.output, contains('-u,--url <URL>'));
      expect(result.output, contains('-R,--rerip-selected'));
      expect(result.output, contains('-s,--socks-server <SERVER>'));
      expect(result.output, contains('-H,--history <PATH>'));
    }
  });

  test('short and long version options print the Flutter app version', () {
    for (final args in const [
      ['-v'],
      ['--version'],
    ]) {
      final result = CliController().run(args);

      expect(result.exitCode, 0);
      expect(result.output, appVersion);
      expect(result.isError, isFalse);
    }
  });

  test('unported CLI options fail without launching the GUI', () {
    final result = CliController().run(
      const ['--url', 'https://example.com/album'],
    );

    expect(result.exitCode, 64);
    expect(result.isError, isTrue);
    expect(result.output, contains('--url https://example.com/album'));
  });
}
