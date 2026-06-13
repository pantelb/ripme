import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ripme/completion_sound_player.dart';

void main() {
  test('uses the packaged Java camera WAV', () {
    expect(JavaCompletionSound.assetPath, 'sounds/camera.wav');

    final bytes = File(
      'assets/${JavaCompletionSound.assetPath}',
    ).readAsBytesSync();
    expect(bytes.length, 5134);
    expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
    expect(String.fromCharCodes(bytes.skip(8).take(4)), 'WAVE');
  });
}
