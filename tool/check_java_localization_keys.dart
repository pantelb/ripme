import 'dart:io';

import 'package:ripme/localization_key_inventory.dart';

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

  final bundleResult = await Process.run('git', const [
    'show',
    'origin/main:src/main/resources/LabelsBundle.properties',
  ]);
  if (bundleResult.exitCode != 0) {
    stderr.write(bundleResult.stderr);
    exitCode = bundleResult.exitCode;
    return;
  }

  final usedKeys = JavaLocalizationKeyInventory.keysFromSources(sources);
  final defaultKeys = JavaLocalizationKeyInventory.keysFromProperties(
    bundleResult.stdout as String,
  );
  final missing = usedKeys.difference(defaultKeys).toList()..sort();
  if (missing.isNotEmpty) {
    stderr.writeln(
      'Java localized keys missing from the packaged default bundle: '
      '${missing.join(', ')}',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Flutter localization assets cover all ${usedKeys.length} Java-used keys.',
  );
}
