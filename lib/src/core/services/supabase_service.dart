import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logger_service.dart';

class SupabaseService {
  /// Inicializa la conexión con Supabase usando variables de entorno
  static Future<void> initialize() async {
    try {
      LoggerService.section('INICIALIZACIÓN DE SUPABASE');
      
      // Obtener las credenciales desde .env
      LoggerService.info('Cargando credenciales desde .env', context: 'Supabase');
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        LoggerService.error(
          'Variables de entorno faltantes',
          context: 'Supabase',
          error: 'SUPABASE_URL o SUPABASE_ANON_KEY no definidas',
        );
        throw Exception(
          'Las variables SUPABASE_URL y SUPABASE_ANON_KEY deben estar definidas en el archivo .env'
        );
      }

      LoggerService.info('Credenciales cargadas correctamente', context: 'Supabase');
      LoggerService.info('URL: ${supabaseUrl.substring(0, 20)}...', context: 'Supabase');

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      LoggerService.success('Conexión a Supabase establecida', context: 'Supabase');
      LoggerService.separator();
    } catch (e, stackTrace) {
      LoggerService.error(
        'Fallo al inicializar Supabase',
        context: 'Supabase',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Getter para obtener el cliente sin llamar a Supabase.instance.client en todas partes
  static SupabaseClient get client => Supabase.instance.client;
}