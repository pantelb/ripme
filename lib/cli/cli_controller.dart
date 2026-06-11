import 'dart:io';

import '../app_version.dart';
import '../history_provider.dart';
import '../ripper/abstract_ripper.dart';
import '../ripper/ripper_factory.dart';
import '../rip_manager.dart';
import '../utils/proxy_config.dart';
import '../utils/utils.dart';

typedef CliUrlRipper = Future<void> Function(Uri url);
typedef CliUrlFileReader = Future<List<String>> Function(String path);
typedef CliFolderSuffixSetter = void Function(String? suffix);
typedef CliHistoryLoader = Future<List<HistoryEntry>> Function();
typedef CliDelay = Future<void> Function(Duration duration);

abstract class CliConfigStore {
  Future<void> setBoolean(String key, bool value);
  Future<void> setInteger(String key, int value);
  Future<void> setString(String key, String value);
}

class _UtilsCliConfigStore implements CliConfigStore {
  @override
  Future<void> setBoolean(String key, bool value) {
    return Utils.setConfigBoolean(key, value);
  }

  @override
  Future<void> setInteger(String key, int value) {
    return Utils.setConfigInteger(key, value);
  }

  @override
  Future<void> setString(String key, String value) {
    return Utils.setConfigString(key, value);
  }
}

class CliResult {
  final int exitCode;
  final String output;
  final bool isError;

  const CliResult({
    required this.exitCode,
    required this.output,
    this.isError = false,
  });
}

class CliController {
  final CliUrlRipper _ripUrl;
  final CliUrlFileReader _readUrlFile;
  final CliConfigStore _config;
  final CliFolderSuffixSetter _setFolderSuffix;
  final CliHistoryLoader _loadHistory;
  final CliDelay _delay;

  CliController({
    CliUrlRipper? ripUrl,
    CliUrlFileReader? readUrlFile,
    CliConfigStore? config,
    CliFolderSuffixSetter? setFolderSuffix,
    CliHistoryLoader? loadHistory,
    CliDelay? delay,
  })  : _ripUrl = ripUrl ?? _ripUrlWithFactory,
        _readUrlFile = readUrlFile ?? _readLines,
        _config = config ?? _UtilsCliConfigStore(),
        _setFolderSuffix = setFolderSuffix ?? _setDefaultFolderSuffix,
        _loadHistory = loadHistory ?? HistoryProvider.loadHistory,
        _delay = delay ?? Future<void>.delayed;

  static const String helpText = '''
usage: ripme [OPTIONS]
 -h,--help                   Print the help
 -u,--url <URL>              URL of album to rip
 -t,--threads <COUNT>        Number of download threads per rip
 -w,--overwrite              Overwrite existing files
 -r,--rerip                  Re-rip all ripped albums
 -R,--rerip-selected         Re-rip all selected albums
 -d,--saveorder              Save the order of images in album
 -D,--nosaveorder            Don't save order of images
 -4,--skip404                Don't retry after a 404 (not found) error
 -l,--ripsdirectory <PATH>   Rips Directory (Default: ./rips)
 -n,--no-prop-file           Do not create properties file.
 -f,--urls-file <PATH>       Rip URLs from a file.
 -v,--version                Show current version
 -s,--socks-server <SERVER>  Use socks server ([user:password]@host[:port])
 -p,--proxy-server <SERVER>  Use HTTP Proxy server ([user:password]@host[:port])
 -j,--update                 Update ripme
 -a,--append-to-folder <TEXT> Append a string to the output folder name
 -H,--history <PATH>         Set history file location.
''';

  static bool shouldRunHeadless(List<String> args) => args.isNotEmpty;

  Future<CliResult> run(List<String> args) async {
    if (_hasOption(args, '-h', '--help')) {
      return const CliResult(exitCode: 0, output: helpText);
    }
    if (_hasOption(args, '-v', '--version')) {
      return const CliResult(exitCode: 0, output: appVersion);
    }

    final configResult = await _applyConfigOptions(args);
    if (configResult.error != null) {
      return configResult.error!;
    }

    if (_hasOption(args, '-r', '--rerip')) {
      return _reripHistory(selectedOnly: false);
    }
    if (_hasOption(args, '-R', '--rerip-selected')) {
      return _reripHistory(selectedOnly: true);
    }

    final urlFile = _optionValue(args, '-f', '--urls-file');
    if (urlFile != null) {
      return _ripUrlFile(urlFile);
    }

    final urlValue = _optionValue(args, '-u', '--url');
    if (urlValue != null) {
      final url = Uri.tryParse(urlValue.trim());
      if (url == null || !url.hasScheme || url.host.isEmpty) {
        return const CliResult(
          exitCode: 1,
          output:
              '[!] Given URL is not valid. Expected URL format is http://domain.com/...',
          isError: true,
        );
      }

      try {
        await _ripUrl(url);
        return CliResult(exitCode: 0, output: 'Rip complete: $url');
      } on Exception catch (error) {
        return CliResult(
          exitCode: 1,
          output: '[!] Error while ripping URL $url: $error',
          isError: true,
        );
      }
    }

    if (configResult.applied > 0) {
      return const CliResult(exitCode: 0, output: 'CLI settings applied');
    }

    return CliResult(
      exitCode: 64,
      output: 'CLI option handling is not implemented yet: ${args.join(' ')}',
      isError: true,
    );
  }

  static bool _hasOption(
    List<String> args,
    String shortOption,
    String longOption,
  ) {
    return args.contains(shortOption) || args.contains(longOption);
  }

  static String? _optionValue(
    List<String> args,
    String shortOption,
    String longOption,
  ) {
    for (var index = 0; index < args.length; index++) {
      final argument = args[index];
      if (argument == shortOption || argument == longOption) {
        return index + 1 < args.length ? args[index + 1] : null;
      }
      if (argument.startsWith('$longOption=')) {
        return argument.substring(longOption.length + 1);
      }
    }
    return null;
  }

  Future<({int applied, CliResult? error})> _applyConfigOptions(
    List<String> args,
  ) async {
    var applied = 0;

    if (_hasOption(args, '-w', '--overwrite')) {
      await _config.setBoolean('file.overwrite', true);
      applied++;
    }

    if (_hasOption(args, '-n', '--no-prop-file')) {
      // Java passes this through to ripURL, where the value is never read.
      applied++;
    }

    final threads = _optionValue(args, '-t', '--threads');
    if (threads != null) {
      final value = int.tryParse(threads);
      if (value == null) {
        return (
          applied: applied,
          error: CliResult(
            exitCode: 1,
            output: 'Invalid thread count: $threads',
            isError: true,
          ),
        );
      }
      await _config.setInteger('threads.size', value);
      applied++;
    }

    if (_hasOption(args, '-4', '--skip404')) {
      await _config.setBoolean('errors.skip404', true);
      applied++;
    }

    final ripsDirectory = _optionValue(args, '-l', '--ripsdirectory');
    if (ripsDirectory != null) {
      await _config.setString('rips.directory', ripsDirectory);
      applied++;
    }

    final historyLocation = _optionValue(args, '-H', '--history');
    if (historyLocation != null) {
      await _config.setString('history.location', historyLocation);
      applied++;
    }

    final folderSuffix = _optionValue(args, '-a', '--append-to-folder');
    if (folderSuffix != null) {
      _setFolderSuffix(folderSuffix);
      applied++;
    }

    final httpProxy = _optionValue(args, '-p', '--proxy-server');
    if (httpProxy != null) {
      try {
        final trimmed = httpProxy.trim();
        final proxy = ProxyConfig.parseJavaServer(trimmed);
        await _config.setString('proxy.http', trimmed);
        await _config.setBoolean('proxy.enabled', true);
        await _config.setString('proxy.host', proxy.server);
        if (proxy.port != null) {
          await _config.setInteger('proxy.port', proxy.port!);
        }
        await _config.setString('proxy.username', proxy.user ?? '');
        await _config.setString('proxy.password', proxy.password ?? '');
        applied++;
      } on FormatException catch (error) {
        return (
          applied: applied,
          error: CliResult(
            exitCode: 1,
            output: 'Invalid HTTP proxy: ${error.message}',
            isError: true,
          ),
        );
      }
    }

    final socksProxy = _optionValue(args, '-s', '--socks-server');
    if (socksProxy != null) {
      return (
        applied: applied,
        error: const CliResult(
          exitCode: 64,
          output:
              'SOCKS proxy is not supported by the dart:io HttpClient backend',
          isError: true,
        ),
      );
    }

    final saveOrder = _hasOption(args, '-d', '--saveorder');
    final noSaveOrder = _hasOption(args, '-D', '--nosaveorder');
    if (saveOrder) {
      await _config.setBoolean('download.save_order', true);
      applied++;
    }
    if (noSaveOrder) {
      await _config.setBoolean('download.save_order', false);
      applied++;
    }
    if (saveOrder && noSaveOrder) {
      return (
        applied: applied,
        error: const CliResult(
          exitCode: 1,
          output: "Cannot specify '-d' and '-D' simultaneously",
          isError: true,
        ),
      );
    }

    return (applied: applied, error: null);
  }

  Future<CliResult> _ripUrlFile(String path) async {
    List<String> lines;
    try {
      lines = await _readUrlFile(path);
    } on FileSystemException {
      return const CliResult(
        exitCode: 0,
        output: '[!] File containing list of URLs not found. Cannot continue.',
        isError: true,
      );
    }

    final errors = <String>[];
    var ripped = 0;
    for (final value in urlValuesFromLines(lines)) {
      final url = Uri.tryParse(value);
      if (url == null || !url.hasScheme || url.host.isEmpty) {
        errors.add(
          '[!] Given URL is not valid. '
          'Expected URL format is http://domain.com/...',
        );
        continue;
      }
      try {
        await _ripUrl(url);
        ripped++;
      } on Exception catch (error) {
        errors.add('[!] Error while ripping URL $url: $error');
      }
    }

    return CliResult(
      exitCode: 0,
      output: ['Ripped $ripped URL(s) from $path', ...errors].join('\n'),
      isError: errors.isNotEmpty,
    );
  }

  Future<CliResult> _reripHistory({required bool selectedOnly}) async {
    final history = await _loadHistory();
    if (history.isEmpty) {
      return const CliResult(
        exitCode: 1,
        output: 'There are no history entries to re-rip. Rip some albums first',
        isError: true,
      );
    }

    final entries = selectedOnly
        ? history.where((entry) => entry.selected).toList()
        : history;
    if (entries.isEmpty) {
      return const CliResult(
        exitCode: 1,
        output: "No history entries have been 'Checked'\n"
            'Check an entry in the history view before using --rerip-selected',
        isError: true,
      );
    }

    final errors = <String>[];
    var ripped = 0;
    for (final entry in entries) {
      final url = Uri.tryParse(entry.url);
      if (url == null || !url.hasScheme || url.host.isEmpty) {
        errors.add('[!] Failed to rip URL ${entry.url}: invalid URL');
        continue;
      }
      try {
        await _ripUrl(url);
        ripped++;
        await _delay(const Duration(milliseconds: 500));
      } on Exception catch (error) {
        errors.add('[!] Failed to rip URL ${entry.url}: $error');
      }
    }

    return CliResult(
      exitCode: 0,
      output: [
        'Re-ripped $ripped${selectedOnly ? ' selected' : ''} '
            'history entr${ripped == 1 ? 'y' : 'ies'}',
        ...errors
      ].join('\n'),
      isError: errors.isNotEmpty,
    );
  }

  static Iterable<String> urlValuesFromLines(Iterable<String> lines) sync* {
    for (final line in lines) {
      if (line.startsWith('//') || line.startsWith('#')) {
        continue;
      }
      yield line.trim();
    }
  }

  static Future<List<String>> _readLines(String path) {
    return File(path).readAsLines();
  }

  static void _setDefaultFolderSuffix(String? suffix) {
    AbstractRipper.folderNameSuffix = suffix;
  }

  static Future<void> _ripUrlWithFactory(Uri url) async {
    final ripper = RipperFactory.getRipper(url);
    if (ripper == null) {
      throw Exception('No ripper found for $url');
    }

    try {
      await ripper.setup();
      await ripper.rip();
    } finally {
      ripper.dispose();
    }
  }
}
