import 'package:audioplayers/audioplayers.dart';

class JavaCompletionSound {
  static const assetPath = 'sounds/camera.wav';

  static Future<void> playJavaCameraSound() async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(assetPath));
  }
}
