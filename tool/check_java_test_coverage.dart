import 'dart:io';

import 'package:ripme/java_test_inventory.dart';

Future<void> main() async {
  final result = await Process.run('git', const [
    'ls-tree',
    '-r',
    '--name-only',
    'origin/main',
    'src/test/java/com/rarchives/ripme',
  ]);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exitCode = result.exitCode;
    return;
  }

  final javaClasses = JavaTestInventory.classNamesFromPaths(
    (result.stdout as String).split(RegExp(r'\r?\n')),
  );
  final dartStems = Directory('test')
      .listSync()
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .where((name) => name.endsWith('_test.dart'))
      .map((name) => name.substring(0, name.length - '_test.dart'.length))
      .toSet();

  final missing = javaClasses
      .where(
        (javaClass) =>
            !dartStems.contains(JavaTestInventory.coverageStem(javaClass)),
      )
      .toList()
    ..sort();
  final staleAliases = JavaTestInventory.coverageAliases.keys
      .where((javaClass) => !javaClasses.contains(javaClass))
      .toList()
    ..sort();

  if (missing.isNotEmpty || staleAliases.isNotEmpty) {
    if (missing.isNotEmpty) {
      stderr.writeln(
        'Java test classes without Dart coverage mappings: '
        '${missing.join(', ')}',
      );
    }
    if (staleAliases.isNotEmpty) {
      stderr.writeln(
        'Dart test coverage aliases absent from origin/main: '
        '${staleAliases.join(', ')}',
      );
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Dart tests cover all ${javaClasses.length} Java test classes '
    '(${JavaTestInventory.coverageAliases.length} explicit aliases).',
  );
}
