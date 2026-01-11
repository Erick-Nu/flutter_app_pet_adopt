import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool isSpeaking = false;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("es-ES"); // Configurar español
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() => isSpeaking = true);
    _flutterTts.setCompletionHandler(() => isSpeaking = false);
    _flutterTts.setCancelHandler(() => isSpeaking = false);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
  
  void dispose() {
    _flutterTts.stop();
  }
}
