import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentAudioPath;

  bool get isPlaying => _isPlaying;

  // تشغيل الملف الصوتي من المسار المخزن
  Future<void> playAudio(String filePath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
      _isPlaying = true;
      _currentAudioPath = filePath;
      notifyListeners();
    } catch (e) {
      debugPrint('Playback error: $e');
    }
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}