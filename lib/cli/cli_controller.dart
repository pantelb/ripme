import 'dart:io';

import '../app_version.dart';
import '../ripper/ripper_factory.dart';

typedef CliUrlRipper = Future<void> Function(Uri url);
typedef CliUrlFileReader = Future<List<String>> Function(String path);

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

  CliController({
    CliUrlRipper? ripUrl,
    CliUrlFileReader? readUrlFile,
  })  : _ripUrl = ripUrl ?? _ripUrlWithFactory,
        _readUrlFile = readUrlFile ?? _readLines;

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
