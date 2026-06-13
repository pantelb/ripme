import 'dart:io';
import 'dart:typed_data';

Future<void> main() async {
  final javaPng = await _javaResource('icon.png');
  final javaIco = await _javaResource('icon.ico');

  _requireEqual(
    javaPng,
    File('assets/icon.png').readAsBytesSync(),
    'assets/icon.png',
  );
  _requireEqual(
    javaIco,
    File('assets/icon.ico').readAsBytesSync(),
    'assets/icon.ico',
  );
  _requireEqual(
    javaIco,
    File('windows/runner/resources/app_icon.ico').readAsBytesSync(),
    'windows/runner/resources/app_icon.ico',
  );

  stdout.writeln(
    'Flutter tray and Windows icons match Java icon.png and icon.ico.',
  );
}

Future<Uint8List> _javaResource(String name) async {
  final result = await Process.run(
    'git',
    ['show', 'origin/main:src/main/resources/$name'],
    stdoutEncoding: null,
  );
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  return result.stdout as Uint8List;
}

void _requireEqual(Uint8List expected, Uint8List actual, String path) {
  if (expected.length != actual.length) {
    stderr.writeln('$path does not match the Java resource.');
    exit(1);
  }
  for (var index = 0; index < expected.length; index++) {
    if (expected[index] != actual[index]) {
      stderr.writeln('$path does not match the Java resource.');
      exit(1);
    }
  }
}
