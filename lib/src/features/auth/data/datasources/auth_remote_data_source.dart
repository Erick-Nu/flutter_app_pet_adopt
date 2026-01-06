
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import '../../../../core/services/logger_service.dart';

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
  
  // Variables de entorno
  String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  String get _anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

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
      
      // 1. VALIDACIÓN PREVIA: Email y Cédula
      await _validateAdoptanteRegistration(email, cedula);
      
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
    required String direccion,
    String? telefono,
  }) async {
    try {
      LoggerService.section('REGISTRO FUNDACIÓN');
      LoggerService.auth('Iniciando registro...', data: {'email': email});

      // 1. VALIDACIÓN PREVIA: Email
      await _validateFundacionRegistration(email);

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
          'direccion': direccion,
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
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;
    return await _getUserWithRole(user.id, user.email ?? '');
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
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }
    throw Exception(msg.replaceAll('Exception:', '').trim());
  }

  /// Verifica Email y Cédula (para Adoptantes)
  Future<void> _validateAdoptanteRegistration(String email, String cedula) async {
    // 1. Validar Email
    await _validateEmail(email);

    // 2. Validar Cédula
    try {
      final bool exists = await supabaseClient.rpc(
        'check_cedula_exists', 
        params: {'cedula_to_check': cedula},
      );
      if (exists) throw Exception('Este número de cédula ya está registrado.');
    } catch (e) {
      if (e.toString().contains('cédula ya está registrado')) rethrow;
      LoggerService.warning('Error RPC Cédula: $e', context: 'Auth');
    }
  }

  /// Verifica Email (para Fundaciones)
  Future<void> _validateFundacionRegistration(String email) async {
    // 1. Validar Email
    await _validateEmail(email);
  }

  /// Lógica centralizada de validación de Email
  Future<void> _validateEmail(String email) async {
    // A. Formato
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('El formato del correo electrónico no es válido.');
    }

    // B. Unicidad (Usando RPC)
    try {
      final bool exists = await supabaseClient.rpc(
        'check_email_exists', 
        params: {'email_to_check': email},
      );
      if (exists) throw Exception('Este correo electrónico ya está registrado.');
    } catch (e) {
      if (e.toString().contains('correo electrónico ya está registrado')) rethrow;
      LoggerService.warning('Error RPC Email: $e', context: 'Auth');
    }
  }
}