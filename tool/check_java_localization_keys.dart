import 'dart:io';

import 'package:ripme/localization_catalog.dart';
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

  final resourcePathsResult = await Process.run('git', const [
    'ls-tree',
    '-r',
    '--name-only',
    'origin/main',
    'src/main/resources',
  ]);
  if (resourcePathsResult.exitCode != 0) {
    stderr.write(resourcePathsResult.stderr);
    exitCode = resourcePathsResult.exitCode;
    return;
  }
  final javaLanguageTags = RegExp(
    r'LabelsBundle_([A-Za-z_]+)\.properties$',
    multiLine: true,
  )
      .allMatches(resourcePathsResult.stdout as String)
      .map((match) => match.group(1)!.replaceAll('_', '-'))
      .toSet();
  final flutterLanguageTags = LocalizationCatalog.supportedLanguageTags.toSet();
  final missingLanguageTags =
      javaLanguageTags.difference(flutterLanguageTags).toList()..sort();
  final extraLanguageTags =
      flutterLanguageTags.difference(javaLanguageTags).toList()..sort();
  if (missingLanguageTags.isNotEmpty || extraLanguageTags.isNotEmpty) {
    stderr.writeln(
      'Flutter language tags do not match Java bundles. '
      'Missing: ${missingLanguageTags.join(', ')}; '
      'extra: ${extraLanguageTags.join(', ')}',
    );
    exitCode = 1;
    return;
  }

  final defaultSource = bundleResult.stdout as String;
  final localizedBundlePaths =
      (resourcePathsResult.stdout as String).split(RegExp(r'\r?\n')).where(
            (path) => RegExp(
              r'LabelsBundle_[A-Za-z_]+\.properties$',
            ).hasMatch(path),
          );
  for (final path in localizedBundlePaths) {
    final javaBundleResult = await Process.run(
      'git',
      ['show', 'origin/main:$path'],
    );
    if (javaBundleResult.exitCode != 0) {
      stderr.write(javaBundleResult.stderr);
      exitCode = javaBundleResult.exitCode;
      return;
    }
    final javaUnexpected = JavaLocalizationKeyInventory.unexpectedLocalizedKeys(
      defaultSource: defaultSource,
      localizedSource: javaBundleResult.stdout as String,
    );
    if (javaUnexpected.isNotEmpty) {
      stderr.writeln(
        '$path contains keys absent from the Java default bundle: '
        '${(javaUnexpected.toList()..sort()).join(', ')}',
      );
      exitCode = 1;
      return;
    }

    final flutterBundle = File(path);
    if (!flutterBundle.existsSync()) {
      stderr.writeln('Flutter is not packaging Java bundle $path.');
      exitCode = 1;
      return;
    }
    final flutterUnexpected =
        JavaLocalizationKeyInventory.unexpectedLocalizedKeys(
      defaultSource: defaultSource,
      localizedSource: flutterBundle.readAsStringSync(),
    );
    if (flutterUnexpected.isNotEmpty) {
      stderr.writeln(
        '$path contains Flutter-packaged keys absent from the default bundle: '
        '${(flutterUnexpected.toList()..sort()).join(', ')}',
      );
      exitCode = 1;
      return;
    }
  }

  final usedKeys = JavaLocalizationKeyInventory.keysFromSources(sources);
  final defaultKeys =
      JavaLocalizationKeyInventory.keysFromProperties(defaultSource);
  final missingFromJavaBundle = usedKeys.difference(defaultKeys).toList()
    ..sort();
  if (missingFromJavaBundle.isNotEmpty) {
    stderr.writeln(
      'Java localized keys missing from the packaged default bundle: '
      '${missingFromJavaBundle.join(', ')}',
    );
    exitCode = 1;
    return;
  }

  final flutterBundle = File('src/main/resources/LabelsBundle.properties');
  if (!flutterBundle.existsSync()) {
    stderr.writeln(
      'Flutter is not packaging src/main/resources/LabelsBundle.properties.',
    );
    exitCode = 1;
    return;
  }
  final flutterKeys = JavaLocalizationKeyInventory.keysFromProperties(
    flutterBundle.readAsStringSync(),
  );
  final missingFromFlutter = defaultKeys.difference(flutterKeys).toList()
    ..sort();
  if (missingFromFlutter.isNotEmpty) {
    stderr.writeln(
      'Java default labels missing from the Flutter-packaged bundle: '
      '${missingFromFlutter.join(', ')}',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Flutter localization assets cover all ${defaultKeys.length} Java default '
    'labels, including ${usedKeys.length} keys used by Java production code, '
    'across all ${javaLanguageTags.length} Java bundle language tags.',
  );
}
