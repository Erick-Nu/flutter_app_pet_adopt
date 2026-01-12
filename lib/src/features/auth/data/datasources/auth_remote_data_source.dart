
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../../../../core/services/logger_service.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);

  Future<bool> signInWithGoogle();
  
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
    String? telefono,
  });

  Future<void> createAdoptanteProfile(String userId, Map<String, dynamic> data);
  Future<void> createFundacionProfile(String userId, Map<String, dynamic> data);

  Future<void> recoverPassword(String email);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  // Obtener credenciales desde las variables de compilación
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // URL DE REDIRECCIÓN (Asegúrate que coincida con tu Vercel)
  final String _redirectUrl = 'https://web-page-app-pet-adopt-git-master-ericks-projects-cf837703.vercel.app';

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      LoggerService.auth('Iniciando sesión', data: {'email': email});
      
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('No se pudo obtener el usuario.');
      }

      final userId = response.user!.id;
      String? userType;
      
      // Consultamos el rol
      final adoptanteResponse = await supabaseClient.from('adoptantes').select('id').eq('id', userId).maybeSingle();
      if (adoptanteResponse != null) {
        userType = 'adoptante';
      } else {
        final fundacionResponse = await supabaseClient.from('fundaciones').select('id').eq('id', userId).maybeSingle();
        if (fundacionResponse != null) userType = 'fundacion';
      }

      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? '',
        type: userType,
      );
      
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) throw Exception('Debes confirmar tu correo antes de iniciar sesión.');
      if (e.message.contains('Invalid login')) throw Exception('Credenciales incorrectas.');
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
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
      LoggerService.section('REGISTRO ADOPTANTE');
      LoggerService.auth('Iniciando registro...', data: {'email': email, 'cedula': cedula});
      
      // 1. VALIDACIÓN PREVIA: Email y Cédula (comentado temporalmente si RPC no existe)
      // await _validateAdoptanteRegistration(email, cedula);
      
      // 2. URL de la API
      final url = Uri.parse('$_supabaseUrl/auth/v1/signup?redirect_to=$_redirectUrl/confirm-email');
      
      final headers = {
        'apikey': _anonKey,
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'email': email,
        'password': password,
        'data': {
          'type': 'adoptante', 
          'nombre': nombre,
          'cedula': cedula,
          'telefono': telefono,
          'sexo': 'hombre', 
        }
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['msg'] ?? errorJson['error_description'] ?? 'Error en el registro');
      }

      final jsonResponse = jsonDecode(response.body);
      final userMap = jsonResponse['user'] ?? jsonResponse; 
      
      if (userMap == null || userMap['id'] == null) {
        throw Exception('Registro exitoso pero no se recibió ID del servidor.');
      }

      final String newUserId = userMap['id'];
      LoggerService.success('Registro completado. ID: $newUserId', context: 'Auth');
      
      return UserModel(
        id: newUserId,
        email: email,
        type: 'adoptante',
      );

    } catch (e) {
      LoggerService.error('Falló el registro de adoptante', context: 'Auth', error: e);
      _handleRegistrationErrors(e);
      throw Exception('Error: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> registerFundacion({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
  }) async {
    try {
      LoggerService.section('REGISTRO FUNDACIÓN');
      LoggerService.auth('Iniciando registro...', data: {'email': email});

      // 1. VALIDACIÓN PREVIA: Email (comentado temporalmente si RPC no existe)
      // await _validateFundacionRegistration(email);

      // 2. URL de la API
      final url = Uri.parse('$_supabaseUrl/auth/v1/signup?redirect_to=$_redirectUrl/confirm-email');
      
      final headers = {
        'apikey': _anonKey,
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'email': email,
        'password': password,
        'data': {
          'type': 'fundacion',
          'nombre': nombre,
          'telefono': telefono,
        }
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['msg'] ?? errorJson['error_description'] ?? 'Error en el registro');
      }

      final jsonResponse = jsonDecode(response.body);
      final userMap = jsonResponse['user'] ?? jsonResponse;
      
      if (userMap == null || userMap['id'] == null) {
        throw Exception('Registro exitoso pero no se recibió ID del servidor.');
      }

      final String newUserId = userMap['id'];
      LoggerService.success('Registro completado. ID: $newUserId', context: 'Auth');

      return UserModel(
        id: newUserId,
        email: email,
        type: 'fundacion',
      );

    } catch (e) {
      LoggerService.error('Falló el registro de fundación', context: 'Auth', error: e);
      _handleRegistrationErrors(e);
      throw Exception('Error: $e');
    }
  }

  @override
  Future<void> recoverPassword(String email) async {
    try {
      LoggerService.section('RECUPERACIÓN DE CONTRASEÑA');
      LoggerService.auth('Solicitando recuperación', data: {'email': email});
      
      final url = Uri.parse('$_supabaseUrl/auth/v1/recover?redirect_to=$_redirectUrl/reset-password');
      
      final response = await http.post(
        url,
        headers: {
          'apikey': _anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        LoggerService.error('Error en API recover (${response.statusCode})', context: 'Auth', error: response.body);
        
        if (response.body.contains('Rate limit')) {
          throw Exception('Demasiados intentos. Espera unos minutos.');
        }
        throw Exception('Error al enviar correo: ${response.body}');
      }
      
      LoggerService.success('Correo de recuperación enviado', context: 'Auth');
      
    } catch (e) {
      LoggerService.error('Error en recoverPassword', context: 'Auth', error: e);
      throw Exception('No se pudo enviar el correo: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      LoggerService.error('Error al cerrar sesión', context: 'Auth', error: e);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) return null;

      final userId = session.user.id;
      final email = session.user.email ?? '';

      // 1. Verificar si es Fundación
      final foundationData = await supabaseClient
          .from('fundaciones')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (foundationData != null) {
        return UserModel(
          id: userId,
          email: email,
          type: 'fundacion',
        );
      }

      // 2. Verificar si es Adoptante
      final adopterData = await supabaseClient
          .from('adoptantes')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (adopterData != null) {
        return UserModel(
          id: userId,
          email: email,
          type: 'adoptante',
        );
      }

      // 3. Si no está en ninguna tabla, retornamos usuario con tipo 'unknown'
      LoggerService.warning('Usuario sin tipo definido: $userId', context: 'getCurrentUser');
      return UserModel(id: userId, email: email, type: 'unknown');
      
    } catch (e) {
      LoggerService.error('Error al obtener usuario actual', context: 'getCurrentUser', error: e);
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;
      return await _getUserWithRole(user.id, user.email ?? '');
    });
  }

  Future<UserModel> _getUserWithRole(String userId, String email) async {
    String? userType;
    final adoptante = await supabaseClient.from('adoptantes').select('id').eq('id', userId).maybeSingle();
    if (adoptante != null) {
      userType = 'adoptante';
    } else {
      final fundacion = await supabaseClient.from('fundaciones').select('id').eq('id', userId).maybeSingle();
      if (fundacion != null) userType = 'fundacion';
    }
    return UserModel(id: userId, email: email, type: userType);
  }

  // ---------------------------------------------------------------------------
  // GOOGLE OAUTH
  // ---------------------------------------------------------------------------

  @override
  Future<bool> signInWithGoogle() async {
    try {
      LoggerService.auth('Iniciando Google Sign In', data: {});
      
      // Aquí utilizamos el método de Supabase para OAuth de Google
      // En mobile, esto abrirá el navegador y retornará a la app con el deep link
      final result = await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback',
      );
      
      LoggerService.success('Google Sign In iniciado', context: 'signInWithGoogle');
      return result;
    } catch (e) {
      LoggerService.error('Error en Google Sign In', context: 'signInWithGoogle', error: e);
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  @override
  Future<void> createAdoptanteProfile(String userId, Map<String, dynamic> data) async {
    try {
      LoggerService.auth('Creando perfil adoptante desde Google', data: {
        'userId': userId,
        'nombre': data['nombre'],
      });

      // CORRECCIÓN: 
      // 1. No enviamos 'email' porque no existe en la tabla 'adoptantes'.
      // 2. No enviamos 'cedula' porque ahora es opcional (NULL).
      // 3. No enviamos 'ubicacion' porque no existe en la tabla SQL.
      await supabaseClient.from('adoptantes').insert({
        'id': userId,
        'nombre': data['nombre'],
        'avatar_url': data['avatar_url'],
        'sexo': 'hombre', // Valor por defecto (user_sex_enum)
        'edad': 18, // Valor por defecto
      });

      LoggerService.success('Perfil adoptante creado', context: 'createAdoptanteProfile');
    } catch (e) {
      LoggerService.error('Error creando perfil adoptante', context: 'createAdoptanteProfile', error: e);
      print("Error detallado al crear adoptante: $e");
      throw Exception('Error creando perfil adoptante: $e');
    }
  }

  @override
  Future<void> createFundacionProfile(String userId, Map<String, dynamic> data) async {
    try {
      LoggerService.auth('Creando perfil fundación desde Google', data: {
        'userId': userId,
        'nombre': data['nombre'],
      });

      await supabaseClient.from('fundaciones').insert({
        'id': userId,
        'nombre': data['nombre'],
        'direccion': data['direccion'] ?? '',
        'logo_url': data['logo_url'],
        // 'telefono': ... (Opcional si lo pides)
      });

      LoggerService.success('Perfil fundación creado', context: 'createFundacionProfile');
    } catch (e) {
      LoggerService.error('Error creando perfil fundación', context: 'createFundacionProfile', error: e);
      print("Error detallado al crear fundación: $e");
      throw Exception('Error creando perfil fundación: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MANEJO DE ERRORES Y VALIDACIONES
  // ---------------------------------------------------------------------------

  void _handleRegistrationErrors(dynamic e) {
    final msg = e.toString();
    if (msg.contains('cedula') || msg.contains('adoptantes_cedula_key') || msg.contains('Este número de cédula')) {
      throw Exception('Este número de cédula ya está registrado.');
    }
    if (msg.contains('User already registered') || msg.contains('already registered') || msg.contains('Este correo electrónico')) {
      throw Exception('Este correo electrónico ya está registrado.');
    }
    if (msg.contains('Password should be')) {
      // Supabase mensaje de contraseña débil
      throw Exception('La contraseña debe tener al menos 8 caracteres.');
    }
    throw Exception(msg.replaceAll('Exception:', '').trim());
  }
}