import 'dart:io';
import 'dart:typed_data';

Future<void> main() async {
  final result = await Process.run(
    'git',
    const ['show', 'origin/main:src/main/resources/camera.wav'],
    stdoutEncoding: null,
  );
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }

  final javaSound = result.stdout as Uint8List;
  final flutterSound = File('assets/sounds/camera.wav').readAsBytesSync();
  if (!_equalBytes(javaSound, flutterSound)) {
    stderr.writeln(
      'assets/sounds/camera.wav does not match Java camera.wav.',
    );
    exit(1);
  }

  stdout.writeln('Flutter completion sound matches Java camera.wav.');
}

bool _equalBytes(Uint8List expected, Uint8List actual) {
  if (expected.length != actual.length) return false;
  for (var index = 0; index < expected.length; index++) {
    if (expected[index] != actual[index]) return false;
  }
  return true;
}
