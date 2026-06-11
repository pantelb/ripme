import '../app_version.dart';

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

  CliResult run(List<String> args) {
    if (_hasOption(args, '-h', '--help')) {
      return const CliResult(exitCode: 0, output: helpText);
    }
    if (_hasOption(args, '-v', '--version')) {
      return const CliResult(exitCode: 0, output: appVersion);
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
}
