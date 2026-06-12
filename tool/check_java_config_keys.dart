import 'dart:io';

import 'package:ripme/config_defaults.dart';
import 'package:ripme/config_key_inventory.dart';

Future<void> main() async {
  final pathsResult = await Process.run('git', const [
    'ls-tree',
    '-r',
    '--name-only',
    'origin/main',
    'src/main/java/com/rarchives/ripme',
  ]);
  if (pathsResult.exitCode != 0) {
    stderr.write(pathsResult.stderr);
    exitCode = pathsResult.exitCode;
    return;
  }

  final javaPaths = (pathsResult.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((path) => path.endsWith('.java'));
  final sources = <String>[];
  for (final path in javaPaths) {
    final result = await Process.run('git', ['show', 'origin/main:$path']);
    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      exitCode = result.exitCode;
      return;
    }
    sources.add(result.stdout as String);
  }

  final propertiesResult = await Process.run('git', const [
    'show',
    'origin/main:src/main/resources/rip.properties',
  ]);
  if (propertiesResult.exitCode != 0) {
    stderr.write(propertiesResult.stderr);
    exitCode = propertiesResult.exitCode;
    return;
  }

  final javaKeys = JavaConfigKeyInventory.keysFromSources(sources)
    ..addAll(
      JavaConfigKeyInventory.keysFromProperties(
        propertiesResult.stdout as String,
      ),
    );
  const flutterKeys = ConfigDefaults.javaRuntimeKeys;
  final missing = javaKeys.difference(flutterKeys).toList()..sort();
  final stale = flutterKeys.difference(javaKeys).toList()..sort();

  if (missing.isNotEmpty || stale.isNotEmpty) {
    if (missing.isNotEmpty) {
      stderr.writeln(
        'Java config keys without a Flutter parity disposition: '
        '${missing.join(', ')}',
      );
    }
    if (stale.isNotEmpty) {
      stderr.writeln(
        'Flutter config inventory entries absent from origin/main: '
        '${stale.join(', ')}',
      );
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Flutter config inventory covers all ${javaKeys.length} Java keys.',
  );
}
