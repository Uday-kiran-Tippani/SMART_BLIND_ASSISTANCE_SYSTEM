import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService extends ChangeNotifier {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  TtsService() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US"); // Default, can be changed based on locale
    await _flutterTts.setSpeechRate(0.5); // Slightly slower for better clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint("TTS Error: $msg");
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      // Don't interrupt if critical? Or maybe interrupt always for urgency?
      // For safety App, usually interruption is preferred (e.g. "STOP!")
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
