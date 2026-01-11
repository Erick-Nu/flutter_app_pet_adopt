import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _baseUrl = String.fromEnvironment('GEMINI_API_URL', defaultValue: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent');

  Future<String> sendMessage(String message, List<Message> history) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      
      final List<Map<String, dynamic>> contents = [];
      
      // 1. Historial previo (Contexto)
      // Tomamos los últimos 10 mensajes para que no pierda el hilo, pero no gaste tantos tokens
      final recentHistory = history.length > 10 
          ? history.sublist(history.length - 10) 
          : history;
      
      for (final msg in recentHistory) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.text}]
        });
      }
      
      // 2. Prompt del Sistema + Mensaje Actual
      // Aquí definimos la personalidad y las restricciones estrictas.
      const systemInstruction = """
      INSTRUCCIONES DEL SISTEMA:
      Eres "PetBot", un asistente virtual experto y amable dentro de la app "PetAdopt".
      
      TUS REGLAS DE ORO:
      1. SOLO puedes responder preguntas relacionadas con: Mascotas, Animales, Cuidado Veterinario, Adopción, Razas, Comportamiento animal y temas relacionados directamente con el bienestar animal.
      2. Si el usuario te pregunta sobre CUALQUIER otro tema (matemáticas, política, historia, código, clima, recetas de comida humana, etc.), DEBES rechazar amablemente la respuesta.
         - Ejemplo de rechazo: "Lo siento, solo puedo ayudarte con temas relacionados con mascotas y adopción 🐾."
      3. Tus respuestas deben ser completas, empáticas y útiles.
      4. Usa emojis ocasionalmente para ser amigable.
      
      Pregunta del usuario:
      """;

      contents.add({
        'role': 'user',
        'parts': [{'text': "$systemInstruction $message"}]
      });
      
      final body = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7, 
          'maxOutputTokens': 4096, // AUMENTADO: Evita que se corte el texto a la mitad
        },
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null || data['candidates'] == null || data['candidates'].isEmpty) {
          return 'No pude entender eso, ¿puedes repetirlo?';
        }
        final candidate = data['candidates'][0];
        
        // Verificamos si la respuesta fue bloqueada por seguridad o fin de tokens
        if (candidate['finishReason'] != 'STOP' && candidate['finishReason'] != null) {
           // Si se corta por otra razón, intentamos recuperar lo que haya
        }

        final content = candidate['content'];
        String? text;
        if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
          text = content['parts'][0]['text'];
        }
        
        return text ?? 'La IA no devolvió texto.';
      } else {
        return 'Error de conexión con PetBot (${response.statusCode}).';
      }
    } catch (e) {
      return 'Ocurrió un error: $e';
    }
  }
}
