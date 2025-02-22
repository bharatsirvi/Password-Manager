import 'package:audioplayers/audioplayers.dart';
import 'package:password_manager/utills/snakebar.dart';

class SoundUtil {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Play a sound from an asset
  static Future<void> playSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));

      print('Sound played successfully: $assetPath');
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  // Dispose the audio player when no longer needed
  static void dispose() {
    _audioPlayer.dispose();
  }
}
