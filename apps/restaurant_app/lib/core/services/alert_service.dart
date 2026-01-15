import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Service d'alertes sonores et vibrations pour les nouvelles commandes
class AlertService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;
  
  /// Jouer l'alerte nouvelle commande (son + vibration)
  static Future<void> playNewOrderAlert() async {
    if (_isPlaying) return;
    _isPlaying = true;
    
    try {
      // Vibration pattern: court-pause-long-pause-court
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 200, 100, 500, 100, 200], intensities: [0, 255, 0, 255, 0, 255]);
      }
      
      // Son d'alerte (utiliser un son système ou un asset)
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(
        AssetSource('sounds/new_order.mp3'),
        volume: 1.0,
      );
      
      // Répéter le son 3 fois pour être sûr
      for (int i = 0; i < 2; i++) {
        await Future.delayed(const Duration(seconds: 2));
        if (_isPlaying) {
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      // Fallback: vibration système simple
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
    } finally {
      _isPlaying = false;
    }
  }
  
  /// Arrêter l'alerte (quand le restaurateur a vu la commande)
  static Future<void> stopAlert() async {
    _isPlaying = false;
    await _audioPlayer.stop();
    Vibration.cancel();
  }
  
  /// Jouer un son de confirmation court
  static Future<void> playConfirmSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/confirm.mp3'), volume: 0.5);
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }
  
  /// Libérer les ressources
  static void dispose() {
    _audioPlayer.dispose();
  }
}
