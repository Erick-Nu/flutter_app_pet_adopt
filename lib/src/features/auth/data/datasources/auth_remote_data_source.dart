
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

      final user = response.user;

      if (user == null) {
        throw const AuthException('No se pudo obtener el usuario.');
      }

      final userWithRole = await _buildUserFromSessionUser(
        user,
        ensureProfile: true,
      );

      if (userWithRole == null) {
        throw const AuthException('No se pudo resolver el perfil del usuario.');
      }

      return userWithRole;
      
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
      
      // 1. VALIDACIÓN PREVIA: Verificar si el email ya está registrado
      final emailExists = await _checkEmailExists(email);
      if (emailExists) {
        throw Exception('Este correo electrónico ya está registrado.');
      }

      // 2. VALIDACIÓN PREVIA: Verificar si la cédula ya está registrada
      final cedulaExists = await _checkCedulaExists(cedula);
      if (cedulaExists) {
        throw Exception('Este número de cédula ya está registrado.');
      }
      
      // 3. URL de la API
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

      // 1. VALIDACIÓN PREVIA: Verificar si el email ya está registrado
      final emailExists = await _checkEmailExists(email);
      if (emailExists) {
        throw Exception('Este correo electrónico ya está registrado.');
      }

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
      return await _buildUserFromSessionUser(
        session.user,
        ensureProfile: true,
      );
    } catch (e) {
      LoggerService.error('Error al obtener usuario actual', context: 'getCurrentUser', error: e);
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.asyncMap((data) async {
      return await _buildUserFromSessionUser(
        data.session?.user,
        ensureProfile: true,
      );
    });
  }

  Future<UserModel?> _buildUserFromSessionUser(
    User? user, {
    bool ensureProfile = false,
  }) async {
    if (user == null) return null;

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final metadataType = metadata['type'] as String?;

    final adoptanteRecord = await supabaseClient
        .from('adoptantes')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    Map<String, dynamic>? fundacionRecord;

    if (adoptanteRecord == null) {
      fundacionRecord = await supabaseClient
          .from('fundaciones')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
    }

    String? resolvedType;

    if (adoptanteRecord != null) {
      resolvedType = 'adoptante';
    } else if (fundacionRecord != null) {
      resolvedType = 'fundacion';
    } else {
      resolvedType = metadataType;
    }

    if (ensureProfile && resolvedType != null) {
      await _ensureProfileExists(
        userId: user.id,
        type: resolvedType,
        metadata: metadata,
        hasAdoptanteRecord: adoptanteRecord != null,
        hasFundacionRecord: fundacionRecord != null,
      );
    }

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      type: resolvedType,
    );
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
      // 2. Guardamos 'cedula' si el usuario la proporciona (es opcional).
      // 3. No enviamos 'ubicacion' porque no existe en la tabla SQL.
      await supabaseClient.from('adoptantes').insert({
        'id': userId,
        'nombre': data['nombre'],
        'avatar_url': data['avatar_url'],
        'telefono': data['telefono'], // Teléfono del usuario
        'cedula': data['cedula'], // Cédula del usuario (si la proporciona)
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
    
    // Errores de cédula duplicada
    if (msg.contains('Este número de cédula ya está registrado')) {
      throw Exception('Este número de cédula ya está registrado. Por favor, utiliza otro.');
    }
    if (msg.contains('cedula') || msg.contains('adoptantes_cedula_key')) {
      throw Exception('Este número de cédula ya está registrado. Por favor, utiliza otro.');
    }
    
    // Errores de email duplicado
    if (msg.contains('Este correo electrónico ya está registrado')) {
      throw Exception('Este correo electrónico ya está registrado. Por favor, utiliza otro o intenta recuperar tu contraseña.');
    }
    if (msg.contains('User already registered') || msg.contains('already registered')) {
      throw Exception('Este correo electrónico ya está registrado. Por favor, utiliza otro o intenta recuperar tu contraseña.');
    }
    
    // Errores de contraseña débil
    if (msg.contains('Password should be')) {
      throw Exception('La contraseña debe tener al menos 8 caracteres.');
    }
    
    throw Exception(msg.replaceAll('Exception:', '').trim());
  }

  Future<void> _ensureProfileExists({
    required String userId,
    required String type,
    required Map<String, dynamic> metadata,
    required bool hasAdoptanteRecord,
    required bool hasFundacionRecord,
  }) async {
    try {
      if (type == 'adoptante') {
        if (hasAdoptanteRecord) return;
        await supabaseClient.from('adoptantes').insert({
          'id': userId,
          'nombre': metadata['nombre'] ?? metadata['full_name'] ?? metadata['name'] ?? 'Adoptante',
          'telefono': metadata['telefono'],
          'cedula': metadata['cedula'],
          'sexo': metadata['sexo'] ?? 'hombre',
          'edad': metadata['edad'] ?? 18,
          'avatar_url': metadata['avatar_url'],
        });
        return;
      }

      if (type == 'fundacion') {
        if (hasFundacionRecord) return;
        await supabaseClient.from('fundaciones').insert({
          'id': userId,
          'nombre': metadata['nombre'] ?? 'Fundación',
          'telefono': metadata['telefono'],
          'direccion': metadata['direccion'] ?? '',
          'logo_url': metadata['logo_url'],
        });
      }
    } catch (e) {
      LoggerService.error(
        'No se pudo crear el perfil automáticamente',
        context: '_ensureProfileExists',
        error: e,
      );
      throw Exception('No se pudo preparar tu perfil. Intenta nuevamente.');
    }
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES DE DUPLICADOS
  // ---------------------------------------------------------------------------

  /// Verifica si un email ya existe en la tabla de usuarios (auth.users)
  Future<bool> _checkEmailExists(String email) async {
    try {
      LoggerService.auth('Verificando si el email existe', data: {'email': email});
      
      // Intentamos obtener el usuario por email usando el API de Supabase
      // No podemos consultarlo directamente desde auth.users, pero podemos intentar
      // verificar en las tablas de adoptantes y fundaciones
      
      final adoptantesWithEmail = await supabaseClient
          .from('adoptantes')
          .select('id')
          .eq('id', email)  // Comparar con el ID del usuario (que es el email en auth)
          .maybeSingle();

      final fundacionesWithEmail = await supabaseClient
          .from('fundaciones')
          .select('id')
          .eq('id', email)  // Comparar con el ID del usuario (que es el email en auth)
          .maybeSingle();

      return adoptantesWithEmail != null || fundacionesWithEmail != null;
    } catch (e) {
      // Si hay error en la búsqueda, continuamos (mejor dejar registrarse que bloquear)
      LoggerService.info('No se pudo verificar email duplicado: $e', context: '_checkEmailExists');
      return false;
    }
  }

  /// Verifica si una cédula ya existe en la tabla de adoptantes
  Future<bool> _checkCedulaExists(String cedula) async {
    try {
      LoggerService.auth('Verificando si la cédula existe', data: {'cedula': cedula});
      
      final adoptanteWithCedula = await supabaseClient
          .from('adoptantes')
          .select('id')
          .eq('cedula', cedula)
          .maybeSingle();

      return adoptanteWithCedula != null;
    } catch (e) {
      // Si hay error en la búsqueda, continuamos
      LoggerService.info('No se pudo verificar cédula duplicada: $e', context: '_checkCedulaExists');
      return false;
    }
  }
}