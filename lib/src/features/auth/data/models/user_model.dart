import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.type,
  });

  // Factory para convertir el objeto 'User' de Supabase a nuestro 'UserModel'
  factory UserModel.fromSupabase(User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      // Truco: Guardaremos el tipo (adoptante/fundacion) en la metadata del usuario
      // para saber quién es sin hacer consultas extra.
      type: user.userMetadata?['type'] as String?,
    );
  }
}