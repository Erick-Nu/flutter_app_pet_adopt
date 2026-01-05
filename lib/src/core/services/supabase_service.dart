import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // NOTA: Más adelante moveremos esto a un archivo .env para mayor seguridad,
  // pero por ahora está bien tenerlo aquí encapsulado.
  static const String _url = 'https://sskhkgzlsjmveqtojvay.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNza2hrZ3psc2ptdmVxdG9qdmF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2NDQwMzYsImV4cCI6MjA4MzIyMDAzNn0.nJZ_ulIwBE-S8QQsl0nQ5lpSODB1JaW9dqfeGPERJ1o';

  /// Inicializa la conexión con Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      // Aquí puedes agregar config extra como debug: true, authFlowType, etc.
    );
  }

  /// Getter para obtener el cliente sin llamar a Supabase.instance.client en todas partes
  static SupabaseClient get client => Supabase.instance.client;
}