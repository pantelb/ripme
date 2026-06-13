import 'dart:io';

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final utils = File('lib/utils/utils.dart').readAsStringSync();
  final mainSource = File('lib/main.dart').readAsStringSync();

  const forbiddenManifestEntries = [
    'READ_EXTERNAL_STORAGE',
    'WRITE_EXTERNAL_STORAGE',
    'READ_MEDIA_IMAGES',
    'READ_MEDIA_VIDEO',
    'MANAGE_EXTERNAL_STORAGE',
    'requestLegacyExternalStorage',
  ];
  for (final entry in forbiddenManifestEntries) {
    if (manifest.contains(entry)) {
      _fail('Android storage policy must not declare $entry.');
    }
  }

  if (!manifest.contains('android.permission.INTERNET')) {
    _fail('Android still requires INTERNET for downloads.');
  }
  if (pubspec.contains('permission_handler:') ||
      utils.contains('package:permission_handler/')) {
    _fail(
        'App-specific Android storage must not request broad runtime permissions.');
  }
  if (!utils.contains('getExternalStorageDirectory()') ||
      !utils.contains('getApplicationDocumentsDirectory()')) {
    _fail('Android working-directory fallback is no longer app-specific.');
  }
  if (!utils.contains('supportsCustomRipDirectory') ||
      !mainSource.contains('Utils.supportsCustomRipDirectory') ||
      !mainSource.contains('FilePicker.getDirectoryPath')) {
    _fail(
        'Directory selection must remain enabled on desktop and disabled on Android.');
  }

  stdout.writeln('Android scoped-storage policy verified.');
}
