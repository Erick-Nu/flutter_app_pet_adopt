import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  
  Future<UserModel> registerAdoptante({
    required String email,
    required String password,
    required String nombre,
    required String cedula,
    String? telefono,
  });

  Future<UserModel> registerFundacion({
    required String email,
    required String password,
    required String nombre,
    required String direccion,
    String? telefono,
  });

  Future<void> recoverPassword(String email);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error: No se pudo obtener el usuario.');
      }

      return UserModel.fromSupabase(response.user!);
      
    } on AuthException catch (e) {
      // --- VALIDACIÓN DE CREDENCIALES ---
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Correo o contraseña incorrectos.');
      } else if (e.message.contains('Email not confirmed')) {
        throw Exception('Debes confirmar tu correo electrónico.');
      } else {
        // Cualquier otro error de Supabase (ej. red, bloqueo, etc.)
        throw Exception(e.message); 
      }
    } catch (e) {
      // Errores no controlados
      throw Exception('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  @override
  Future<UserModel> registerAdoptante({
    required String email,
    required String password,
    required String nombre,
    required String cedula,
    String? telefono,
  }) async {
    try {
      // 1. Crear usuario en Auth de Supabase
      final authResponse = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'type': 'adoptante'}, 
      );

      if (authResponse.user == null) {
        throw Exception('Registro falló: No se pudo crear el usuario Auth');
      }

      final userId = authResponse.user!.id;

      // 2. Insertar datos en la tabla pública 'adoptantes'
      await supabaseClient.from('adoptantes').insert({
        'id': userId,
        'nombre': nombre,
        'cedula': cedula,
        'telefono': telefono,
        'sexo': 'hombre', 
        // 'avatar_url': ... 
      });

      return UserModel.fromSupabase(authResponse.user!);

    } on AuthException catch (e) {
      // Manejo de errores de registro (ej. usuario ya existe)
      if (e.message.contains('User already registered')) {
        throw Exception('Este correo ya está registrado.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al registrar adoptante: $e');
    }
  }

  @override
  Future<UserModel> registerFundacion({
    required String email,
    required String password,
    required String nombre,
    required String direccion,
    String? telefono,
  }) async {
    try {
      // 1. Crear usuario Auth
      final authResponse = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'type': 'fundacion'},
      );

      if (authResponse.user == null) {
        throw Exception('Registro falló');
      }

      final userId = authResponse.user!.id;

      // 2. Insertar en tabla pública 'fundaciones'
      await supabaseClient.from('fundaciones').insert({
        'id': userId,
        'nombre': nombre,
        'direccion': direccion,
        'telefono': telefono,
        'descripcion': 'Fundación nueva',
      });

      return UserModel.fromSupabase(authResponse.user!);

    } on AuthException catch (e) {
      if (e.message.contains('User already registered')) {
        throw Exception('Este correo ya está registrado.');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al registrar fundación: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión');
    }
  }

  @override
  Future<void> recoverPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al enviar correo de recuperación');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) return null;
      return UserModel.fromSupabase(user);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return UserModel.fromSupabase(user);
    });
  }
}