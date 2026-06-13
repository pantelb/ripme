import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Windows executable icon carries the exact Java ICO', () {
    expect(
      File('windows/runner/resources/app_icon.ico').readAsBytesSync(),
      File('assets/icon.ico').readAsBytesSync(),
    );
  });

  test('macOS icon set contains non-empty Java-derived sizes', () async {
    for (final size in <int>[16, 32, 64, 128, 256, 512, 1024]) {
      await _expectImage(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/'
        'app_icon_$size.png',
        size,
      );
    }
  });

  test('Android launcher icons contain non-empty density sizes', () async {
    const sizes = <String, int>{
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final entry in sizes.entries) {
      await _expectImage(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
      );
    }
  });

  test('Linux bundle installs the Java-derived hicolor application icon',
      () async {
    await _expectImage('linux/ripme.png', 256);
    final cmake = File('linux/CMakeLists.txt').readAsStringSync();
    final desktop = File('linux/ripme.desktop').readAsStringSync();

    expect(cmake, contains('share/icons/hicolor/256x256/apps'));
    expect(desktop, contains('Icon=ripme'));
  });
}

Future<void> _expectImage(String path, int size) async {
  final bytes = File(path).readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  addTearDown(() {
    image.dispose();
    codec.dispose();
  });

  expect(image.width, size, reason: path);
  expect(image.height, size, reason: path);
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(pixels, isNotNull, reason: path);
  final rgba = pixels!.buffer.asUint8List();
  expect(
    [for (var index = 3; index < rgba.length; index += 4) rgba[index]],
    contains(isNot(0)),
    reason: '$path must contain visible icon pixels',
  );
}
