import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';

class GetUserRoleUseCase {
  /// Verifica el rol del usuario (adoptante o fundacion)
  /// Retorna: 'adoptante', 'fundacion', o null si no tiene perfil
  Future<String?> call(String userId) async {
    try {
      LoggerService.auth('Verificando rol del usuario', data: {'userId': userId});
      
      final supabase = Supabase.instance.client;

      // 1. Buscar en Adoptantes
      final adoptante = await supabase
          .from('adoptantes')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (adoptante != null) {
        LoggerService.success('Usuario es adoptante', context: 'GetUserRoleUseCase');
        return 'adoptante';
      }

      // 2. Buscar en Fundaciones
      final fundacion = await supabase
          .from('fundaciones')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (fundacion != null) {
        LoggerService.success('Usuario es fundación', context: 'GetUserRoleUseCase');
        return 'fundacion';
      }

      // 3. No tiene perfil (Es nuevo registro con Google u otro OAuth)
      LoggerService.warning('Usuario sin perfil definido', context: 'GetUserRoleUseCase');
      return null;
    } catch (e) {
      LoggerService.error('Error verificando rol del usuario', 
          context: 'GetUserRoleUseCase', error: e);
      return null;
    }
  }
}
