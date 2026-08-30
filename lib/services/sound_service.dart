import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:crows_nest/services/database_service.dart';

class SoundService extends ChangeNotifier {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal() {
    _loadSettings();
  }

  final AudioPlayer _crowPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final DatabaseService _db = DatabaseService();

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  Future<void> _loadSettings() async {
    try {
      final val = await _db.getSetting('sound_enabled');
      if (val != null) {
        _soundEnabled = val == 'true';
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    try {
      await _db.setSetting('sound_enabled', enabled.toString());
    } catch (_) {}
    if (!enabled) {
      stopAll();
    }
  }

  Future<void> toggleSound() async {
    await setSoundEnabled(!_soundEnabled);
  }

  /// Plays crow caw sound effect
  Future<void> playCrowCaw() async {
    if (!_soundEnabled) return;
    try {
      await _crowPlayer.stop();
      await _crowPlayer.play(AssetSource('audio/crow_caw.wav'), volume: 0.85);
    } catch (e) {
      debugPrint('Error playing crow caw: $e');
    }
  }

  /// Plays ocean waves ambiance
  Future<void> playOceanWaves() async {
    if (!_soundEnabled) return;
    try {
      await _ambientPlayer.stop();
      await _ambientPlayer.play(AssetSource('audio/ocean_waves.wav'), volume: 0.6);
    } catch (e) {
      debugPrint('Error playing ocean waves: $e');
    }
  }

  /// Plays ship bell strike
  Future<void> playShipBell() async {
    if (!_soundEnabled) return;
    try {
      await _crowPlayer.stop();
      await _crowPlayer.play(AssetSource('audio/ship_bell.wav'), volume: 0.7);
    } catch (e) {
      debugPrint('Error playing ship bell: $e');
    }
  }

  /// Plays startup atmosphere (gentle ocean swell + crow caw)
  Future<void> playStartupSound() async {
    if (!_soundEnabled) return;
    try {
      // Start sea wave ambiance
      await _ambientPlayer.play(AssetSource('audio/ocean_waves.wav'), volume: 0.5);
      // Crow caws after slight tide intro
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_soundEnabled) {
          playCrowCaw();
        }
      });
    } catch (e) {
      debugPrint('Error playing startup sound: $e');
    }
  }

  void stopAll() {
    _crowPlayer.stop();
    _ambientPlayer.stop();
  }

  @override
  void dispose() {
    _crowPlayer.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }
}
