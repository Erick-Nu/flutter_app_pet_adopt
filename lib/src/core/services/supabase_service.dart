import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger_service.dart';

class SupabaseService {
  /// Getter para obtener el cliente sin llamar a Supabase.instance.client en todas partes
  /// NOTA: Supabase debe inicializarse primero en main.dart
  static SupabaseClient get client => Supabase.instance.client;
}