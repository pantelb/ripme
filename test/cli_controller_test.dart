import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/app_version.dart';
import 'package:ripme/cli/cli_controller.dart';
import 'package:ripme/rip_manager.dart';
import 'package:ripme/update_checker.dart';

class _FakeConfigStore implements CliConfigStore {
  final values = <String, Object>{};

  @override
  Future<void> setBoolean(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> setInteger(String key, int value) async {
    values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}

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

  test('CLI setting options use Java config keys and values', () async {
    final config = _FakeConfigStore();
    final result = await CliController(config: config).run(const [
      '--threads',
      '7',
      '--overwrite',
      '--saveorder',
      '--skip404',
      '--ripsdirectory',
      'D:/rips',
      '--history',
      'D:/ripme/url_history.txt',
    ]);

    expect(result.exitCode, 0);
    expect(config.values, {
      'threads.size': 7,
      'file.overwrite': true,
      'download.save_order': true,
      'errors.skip404': true,
      'rips.directory': 'D:/rips',
      'history.location': 'D:/ripme/url_history.txt',
    });
  });

  test('nosaveorder disables ordering', () async {
    final config = _FakeConfigStore();

    final result =
        await CliController(config: config).run(const ['--nosaveorder']);

    expect(result.exitCode, 0);
    expect(config.values['download.save_order'], isFalse);
  });

  test('no-prop-file is the same no-op as current Java behavior', () async {
    final config = _FakeConfigStore();

    final result =
        await CliController(config: config).run(const ['--no-prop-file']);

    expect(result.exitCode, 0);
    expect(result.isError, isFalse);
    expect(config.values, isEmpty);
  });

  test('saveorder and nosaveorder are rejected after Java side effects',
      () async {
    final config = _FakeConfigStore();

    final result = await CliController(config: config).run(const ['-d', '-D']);

    expect(result.exitCode, 1);
    expect(result.output, "Cannot specify '-d' and '-D' simultaneously");
    expect(config.values['download.save_order'], isFalse);
  });

  test('HTTP proxy maps Java CLI syntax to active Flutter settings', () async {
    final config = _FakeConfigStore();

    final result = await CliController(config: config).run(const [
      '--proxy-server',
      ' user:secret@proxy.example:3128 ',
    ]);

    expect(result.exitCode, 0);
    expect(config.values, {
      'proxy.http': 'user:secret@proxy.example:3128',
      'proxy.enabled': true,
      'proxy.host': 'proxy.example',
      'proxy.port': 3128,
      'proxy.username': 'user',
      'proxy.password': 'secret',
    });
  });

  test('SOCKS proxy is rejected explicitly', () async {
    final result = await CliController().run(
      const ['--socks-server', 'proxy.example:1080'],
    );

    expect(result.exitCode, 64);
    expect(result.isError, isTrue);
    expect(result.output, contains('SOCKS proxy is not supported'));
  });

  test('append-to-folder preserves the exact Java suffix value', () async {
    String? suffix;

    final result = await CliController(
      setFolderSuffix: (value) => suffix = value,
    ).run(const ['--append-to-folder', ' -extra ']);

    expect(result.exitCode, 0);
    expect(suffix, ' -extra ');
  });

  test('rerip processes all history entries and delays after successes',
      () async {
    final rippedUrls = <Uri>[];
    final delays = <Duration>[];
    final controller = CliController(
      loadHistory: () async => [
        HistoryEntry(
          url: 'https://example.com/one',
          dir: '',
          date: DateTime(2026),
        ),
        HistoryEntry(
          url: 'not-a-url',
          dir: '',
          date: DateTime(2026),
        ),
        HistoryEntry(
          url: 'https://example.com/fails',
          dir: '',
          date: DateTime(2026),
        ),
        HistoryEntry(
          url: 'https://example.com/two',
          dir: '',
          date: DateTime(2026),
        ),
      ],
      ripUrl: (url) async {
        rippedUrls.add(url);
        if (url.path == '/fails') throw Exception('rip failed');
      },
      delay: (duration) async => delays.add(duration),
    );

    final result = await controller.run(const ['--rerip']);

    expect(result.exitCode, 0);
    expect(result.isError, isTrue);
    expect(rippedUrls, [
      Uri.parse('https://example.com/one'),
      Uri.parse('https://example.com/fails'),
      Uri.parse('https://example.com/two'),
    ]);
    expect(delays, [
      const Duration(milliseconds: 500),
      const Duration(milliseconds: 500),
    ]);
    expect(result.output, contains('Re-ripped 2 history entries'));
    expect(result.output, contains('not-a-url'));
    expect(result.output, contains('rip failed'));
  });

  test('rerip rejects empty history like Java', () async {
    final result = await CliController(
      loadHistory: () async => [],
    ).run(const ['-r']);

    expect(result.exitCode, 1);
    expect(result.isError, isTrue);
    expect(result.output, contains('There are no history entries'));
  });

  test('rerip-selected processes only checked Java history entries', () async {
    final rippedUrls = <Uri>[];
    final controller = CliController(
      loadHistory: () async => [
        HistoryEntry(
          url: 'https://example.com/unchecked',
          dir: '',
          date: DateTime(2026),
        ),
        HistoryEntry(
          url: 'https://example.com/checked',
          dir: '',
          date: DateTime(2026),
          selected: true,
        ),
      ],
      ripUrl: (url) async => rippedUrls.add(url),
      delay: (_) async {},
    );

    final result = await controller.run(const ['--rerip-selected']);

    expect(result.exitCode, 0);
    expect(result.isError, isFalse);
    expect(rippedUrls, [Uri.parse('https://example.com/checked')]);
    expect(result.output, contains('Re-ripped 1 selected history entry'));
  });

  test('rerip-selected rejects history with no checked entries', () async {
    final result = await CliController(
      loadHistory: () async => [
        HistoryEntry(
          url: 'https://example.com/unchecked',
          dir: '',
          date: DateTime(2026),
        ),
      ],
    ).run(const ['-R']);

    expect(result.exitCode, 1);
    expect(result.isError, isTrue);
    expect(result.output, contains("No history entries have been 'Checked'"));
  });

  test('update reports GitHub release availability without self-replacing',
      () async {
    final controller = CliController(
      checkForUpdate: () async => UpdateCheckResult(
        currentVersion: '1.0.0',
        latestVersion: 'v1.2.0',
        releaseUrl:
            Uri.parse('https://github.com/pantelb/ripme/releases/tag/v1.2.0'),
        updateAvailable: true,
      ),
    );

    final result = await controller.run(const ['--update']);

    expect(result.exitCode, 0);
    expect(result.isError, isFalse);
    expect(result.output, contains('Update available: v1.2.0'));
    expect(result.output, contains('/releases/tag/v1.2.0'));
  });

  test('update runs after a URL rip like Java option ordering', () async {
    final events = <String>[];
    final controller = CliController(
      ripUrl: (url) async => events.add('rip:$url'),
      checkForUpdate: () async {
        events.add('update');
        return UpdateCheckResult(
          currentVersion: '1.0.0',
          latestVersion: '1.0.0',
          releaseUrl:
              Uri.parse('https://github.com/pantelb/ripme/releases/latest'),
          updateAvailable: false,
        );
      },
    );

    final result = await controller.run(const [
      '--url',
      'https://example.com/album',
      '--update',
    ]);

    expect(result.exitCode, 0);
    expect(events, [
      'rip:https://example.com/album',
      'update',
    ]);
    expect(result.output, contains('is up to date'));
  });

  test('update lookup failures are reported as CLI errors', () async {
    final result = await CliController(
      checkForUpdate: () async => throw Exception('offline'),
    ).run(const ['-j']);

    expect(result.exitCode, 1);
    expect(result.isError, isTrue);
    expect(result.output, contains('offline'));
  });
}
