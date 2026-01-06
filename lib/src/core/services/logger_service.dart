import 'package:flutter/foundation.dart';

/// Servicio centralizado de logging para la aplicación
/// Maneja diferentes niveles de logs y asegura que no se expongan datos sensibles
class LoggerService {
  static const String _tag = '🐾 PetAdopt';

  /// Log de información general
  static void info(String message, {String? context}) {
    if (kDebugMode) {
      final contextStr = context != null ? '[$context]' : '';
      debugPrint('$_tag ℹ️ $contextStr $message');
    }
  }

  /// Log de éxito
  static void success(String message, {String? context}) {
    if (kDebugMode) {
      final contextStr = context != null ? '[$context]' : '';
      debugPrint('$_tag ✅ $contextStr $message');
    }
  }

  /// Log de advertencia
  static void warning(String message, {String? context}) {
    if (kDebugMode) {
      final contextStr = context != null ? '[$context]' : '';
      debugPrint('$_tag ⚠️ $contextStr $message');
    }
  }

  /// Log de error con stack trace opcional
  static void error(
    String message, {
    String? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? '[$context]' : '';
      debugPrint('$_tag ❌ $contextStr $message');
      if (error != null) {
        debugPrint('$_tag 🔍 Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_tag 📚 StackTrace:\n$stackTrace');
      }
    }
  }

  /// Log de datos de red (sanitizado)
  static void network(String method, String endpoint, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('$_tag 🌐 [$method] $endpoint');
      if (data != null) {
        final sanitized = _sanitizeData(data);
        debugPrint('$_tag 📦 Data: $sanitized');
      }
    }
  }

  /// Log de autenticación (datos sensibles sanitizados)
  static void auth(String event, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('$_tag 🔐 [Auth] $event');
      if (data != null) {
        final sanitized = _sanitizeData(data);
        debugPrint('$_tag 📋 Params: $sanitized');
      }
    }
  }

  /// Log de base de datos
  static void database(String operation, String table, {String? detail}) {
    if (kDebugMode) {
      debugPrint('$_tag 💾 [DB] $operation en tabla "$table"');
      if (detail != null) {
        debugPrint('$_tag 📝 Detalle: $detail');
      }
    }
  }

  /// Log de navegación
  static void navigation(String from, String to) {
    if (kDebugMode) {
      debugPrint('$_tag 🧭 Navegando: $from → $to');
    }
  }

  /// Log de eventos del usuario
  static void userEvent(String event, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('$_tag 👤 [Evento] $event');
      if (data != null) {
        final sanitized = _sanitizeData(data);
        debugPrint('$_tag 📊 Data: $sanitized');
      }
    }
  }

  /// Sanitiza datos sensibles antes de hacer log
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    
    // Lista de campos sensibles que NO deben mostrarse en logs
    const sensitiveFields = [
      'password',
      'contraseña',
      'token',
      'api_key',
      'secret',
      'cedula',
      'telefono',
      'direccion',
    ];

    for (var key in sanitized.keys.toList()) {
      final lowerKey = key.toString().toLowerCase();
      
      // Si el campo es sensible, ocultarlo
      if (sensitiveFields.any((field) => lowerKey.contains(field))) {
        sanitized[key] = '***OCULTO***';
      }
      
      // Si el valor es un Map anidado, sanitizarlo recursivamente
      if (sanitized[key] is Map<String, dynamic>) {
        sanitized[key] = _sanitizeData(sanitized[key] as Map<String, dynamic>);
      }
    }

    return sanitized;
  }

  /// Línea separadora para logs extensos
  static void separator() {
    if (kDebugMode) {
      debugPrint('$_tag ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Log de inicio de sección
  static void section(String title) {
    if (kDebugMode) {
      separator();
      debugPrint('$_tag 📌 $title');
      separator();
    }
  }
}
