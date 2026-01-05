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
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login falló: El usuario es nulo');
    }

    return UserModel.fromSupabase(response.user!);
  }

  @override
  Future<UserModel> registerAdoptante({
    required String email,
    required String password,
    required String nombre,
    required String cedula,
    String? telefono,
  }) async {
    // 1. Crear usuario en Auth de Supabase
    // Guardamos 'type': 'adoptante' en la metadata para identificarlo fácil luego
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
    // Usamos el mismo ID que nos dio Auth
    await supabaseClient.from('adoptantes').insert({
      'id': userId,
      'nombre': nombre,
      'cedula': cedula,
      'telefono': telefono,
      'sexo': 'hombre', // Valor por defecto o pedirlo en el form
      // 'avatar_url': ... (se puede actualizar después)
    });

    return UserModel.fromSupabase(authResponse.user!);
  }

  @override
  Future<UserModel> registerFundacion({
    required String email,
    required String password,
    required String nombre,
    required String direccion,
    String? telefono,
  }) async {
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
      'descripcion': 'Fundación nueva', // Valor inicial
    });

    return UserModel.fromSupabase(authResponse.user!);
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<void> recoverPassword(String email) async {
    await supabaseClient.auth.resetPasswordForEmail(email);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabase(user);
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