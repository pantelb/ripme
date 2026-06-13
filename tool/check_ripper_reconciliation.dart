import 'dart:io';

import 'package:ripme/ripper/ripper_reconciliation_inventory.dart';

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

  final javaPaths = (result.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((path) => path.endsWith('.java'))
      .toList();
  final dartSources = _readDartFiles(Directory('lib/ripper/rippers'));
  final focusedTests = _readDartFiles(Directory('test'))
    ..removeWhere((path, _) => path.endsWith('ripper_factory_test.dart'));
  final factory = File('lib/ripper/ripper_factory.dart').readAsStringSync();
  final factoryTest = File('test/ripper_factory_test.dart').readAsStringSync();

  final resolvedClasses = <String>{};
  final errors = <String>[];
  var videoPaths = 0;
  var helperPaths = 0;

  for (final javaPath in javaPaths) {
    final dartClass =
        RipperReconciliationInventory.dartClassForJavaPath(javaPath);
    final helper = RipperReconciliationInventory.isHelperPath(javaPath);
    final video = RipperReconciliationInventory.isVideoPath(javaPath);
    if (helper) helperPaths++;
    if (video) videoPaths++;
    if (!resolvedClasses.add(dartClass)) {
      errors.add('Multiple Java paths resolve to the same Dart class: '
          '$javaPath -> $dartClass');
    }

    final declaration =
        RegExp(r'\bclass\s+' + RegExp.escape(dartClass) + r'\b');
    final sourceEntries = dartSources.entries
        .where((entry) => declaration.hasMatch(entry.value))
        .toList();
    if (sourceEntries.length != 1) {
      errors.add('$javaPath must map to exactly one Dart declaration for '
          '$dartClass; found ${sourceEntries.length}.');
      continue;
    }

    final source = sourceEntries.single.value;
    for (final placeholder in const [
      'UnimplementedError',
      'TODO: Implement',
      'UnsupportedLegacyRipper',
    ]) {
      if (source.contains(placeholder)) {
        errors
            .add('$dartClass still contains placeholder marker $placeholder.');
      }
    }

    final focusedCoverage = focusedTests.entries
        .where((entry) => RegExp(r'\b' + RegExp.escape(dartClass) + r'\b')
            .hasMatch(entry.value))
        .map((entry) => entry.key)
        .toList();
    if (focusedCoverage.isEmpty) {
      errors
          .add('$dartClass has no focused Dart test outside factory coverage.');
    }

    if (helper) {
      if (factory.contains('(uri) => $dartClass(uri),')) {
        errors.add('Helper $dartClass must not be registered as a ripper.');
      }
      continue;
    }

    if (!factory.contains('(uri) => $dartClass(uri),')) {
      errors.add('$dartClass is not registered in RipperFactory.');
    }
    if (!factoryTest.contains('isA<$dartClass>()')) {
      errors.add(
          '$dartClass has no asserted URL fixture in ripper_factory_test.');
    }
  }

  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln(error);
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Reconciled ${javaPaths.length} Java source paths to '
    '${resolvedClasses.length} distinct Dart classes, including '
    '$videoPaths video paths and $helperPaths helper path; every ripper has '
    'focused tests, factory registration, and an asserted URL fixture.',
  );
}

Map<String, String> _readDartFiles(Directory directory) {
  return {
    for (final file in directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')))
      file.path: file.readAsStringSync(),
  };
}
