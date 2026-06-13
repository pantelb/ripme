import 'dart:io';
import 'dart:typed_data';

const _binaryResources = <String, String>{
  'camera.wav': 'assets/sounds/camera.wav',
  'comment.png': 'assets/comment.png',
  'folder.png': 'assets/folder.png',
  'gear.png': 'assets/gear.png',
  'icon.ico': 'assets/icon.ico',
  'icon.png': 'assets/icon.png',
  'list.png': 'assets/list.png',
  'stop.png': 'assets/stop.png',
  'time.png': 'assets/time.png',
  'wrench.png': 'assets/wrench.png',
};

Future<void> main() async {
  _requireEqual(
    await _gitBytes('LICENSE.txt'),
    File('LICENSE.txt').readAsBytesSync(),
    'LICENSE.txt',
  );

  for (final entry in _binaryResources.entries) {
    _requireEqual(
      await _gitBytes('src/main/resources/${entry.key}'),
      File(entry.value).readAsBytesSync(),
      entry.value,
    );
  }

  final javaResourcePaths = await _gitLines('src/main/resources');
  final javaBundles = javaResourcePaths
      .where((path) =>
          RegExp(r'LabelsBundle(?:_[A-Za-z_]+)?\.properties$').hasMatch(path))
      .toSet();
  final missingBundles =
      javaBundles.where((path) => !File(path).existsSync()).toList()..sort();
  if (missingBundles.isNotEmpty) {
    _fail('Missing packaged Java label bundles: ${missingBundles.join(', ')}');
  }

  final pubspec = File('pubspec.yaml').readAsStringSync();
  _requireContains(pubspec, '- LICENSE.txt', 'pubspec.yaml');
  _requireContains(pubspec, '- assets/', 'pubspec.yaml');
  _requireContains(pubspec, '- src/main/resources/', 'pubspec.yaml');

  final linuxCmake = File('linux/CMakeLists.txt').readAsStringSync();
  final windowsCmake = File('windows/CMakeLists.txt').readAsStringSync();
  final macosProject =
      File('macos/Runner.xcodeproj/project.pbxproj').readAsStringSync();
  final linuxMetadata =
      File('linux/com.rarchives.ripme.metainfo.xml').readAsStringSync();
  _requireContains(linuxCmake, '../LICENSE.txt', 'linux/CMakeLists.txt');
  _requireContains(windowsCmake, '../LICENSE.txt', 'windows/CMakeLists.txt');
  _requireContains(
    macosProject,
    'LICENSE.txt in Resources',
    'macos/Runner.xcodeproj/project.pbxproj',
  );
  _requireContains(
    linuxMetadata,
    '<project_license>MIT</project_license>',
    'linux/com.rarchives.ripme.metainfo.xml',
  );

  stdout.writeln(
    'Flutter packages the exact Java MIT license, '
    '${_binaryResources.length} user-facing binary resources, and '
    '${javaBundles.length} label bundles.',
  );
}

Future<Uint8List> _gitBytes(String path) async {
  final result = await Process.run(
    'git',
    ['show', 'origin/main:$path'],
    stdoutEncoding: null,
  );
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  return result.stdout as Uint8List;
}

Future<List<String>> _gitLines(String path) async {
  final result = await Process.run(
    'git',
    ['ls-tree', '-r', '--name-only', 'origin/main', path],
  );
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  return (result.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((line) => line.isNotEmpty)
      .toList();
}

void _requireEqual(Uint8List expected, Uint8List actual, String path) {
  if (expected.length != actual.length) {
    _fail('$path does not match origin/main.');
  }
  for (var index = 0; index < expected.length; index++) {
    if (expected[index] != actual[index]) {
      _fail('$path does not match origin/main.');
    }
  }
}

void _requireContains(String source, String expected, String path) {
  if (!source.contains(expected)) {
    _fail('$path does not declare $expected.');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
