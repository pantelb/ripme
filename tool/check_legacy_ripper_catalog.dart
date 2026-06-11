import 'dart:io';

import 'package:ripme/ripper/legacy_ripper_inventory.dart';
import 'package:ripme/ripper/ripper_migration_catalog.dart';

Future<void> main() async {
  final result = await Process.run('git', const [
    'ls-tree',
    '-r',
    '--name-only',
    'origin/main',
    'src/main/java/com/rarchives/ripme/ripper/rippers',
  ]);

  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exitCode = result.exitCode;
    return;
  }

  final paths = (result.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((line) => line.isNotEmpty);
  final javaClasses = LegacyRipperInventory.classNamesFromPaths(paths);
  final catalogClasses = RipperMigrationCatalog.legacyRipperClasses.toSet();
  final missing = javaClasses.difference(catalogClasses).toList()..sort();
  final stale = catalogClasses.difference(javaClasses).toList()..sort();

  if (missing.isNotEmpty || stale.isNotEmpty) {
    if (missing.isNotEmpty) {
      stderr.writeln(
        'Java rippers missing from RipperMigrationCatalog: '
        '${missing.join(', ')}',
      );
    }
    if (stale.isNotEmpty) {
      stderr.writeln(
        'Catalog entries without a Java ripper in origin/main: '
        '${stale.join(', ')}',
      );
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'RipperMigrationCatalog matches ${javaClasses.length} unique Java '
    'ripper classes from origin/main.',
  );
}
