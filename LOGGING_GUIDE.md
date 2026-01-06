# 📊 Guía de Logging - PetAdopt App

## 🎯 Propósito

Este proyecto ahora incluye un sistema de logging comprehensivo que permite monitorear:
- ✅ Conexión a base de datos
- ✅ Flujos de autenticación (login, registro, logout)
- ✅ Operaciones de base de datos
- ✅ Errores y excepciones con stack traces
- ✅ Eventos de usuario
- ✅ Navegación entre pantallas

## 🔍 Cómo ver los logs

### Opción 1: Run & Debug en VS Code
1. Presiona `F5` o ve a **Run > Start Debugging**
2. Los logs aparecerán en la pestaña **Debug Console**

### Opción 2: Terminal
```bash
flutter run
```
Los logs aparecerán directamente en la terminal.

### Opción 3: Logs en tiempo real
```bash
flutter logs
```

## 📝 Tipos de logs implementados

### 🔐 Autenticación (`LoggerService.auth`)
```dart
// Ejemplo de salida:
🐾 PetAdopt 🔐 [Auth] Iniciando sesión
🐾 PetAdopt 📋 Params: {email: user@example.com, password: ***OCULTO***}
🐾 PetAdopt ✅ [Auth] Autenticación exitosa
🐾 PetAdopt ℹ️ [Auth] User ID: abc-123-def
```

### 💾 Base de datos (`LoggerService.database`)
```dart
// Ejemplo de salida:
🐾 PetAdopt 💾 [DB] SELECT en tabla "adoptantes"
🐾 PetAdopt 📝 Detalle: Verificando tipo de usuario
```

### ❌ Errores (`LoggerService.error`)
```dart
// Ejemplo de salida:
🐾 PetAdopt ❌ [Auth] Error de autenticación en login
🐾 PetAdopt 🔍 Error: Invalid login credentials
🐾 PetAdopt 📚 StackTrace:
#0      AuthRemoteDataSourceImpl.login
#1      LoginBloc._onLoginSubmitted
...
```

### ℹ️ Información general (`LoggerService.info`)
```dart
// Ejemplo de salida:
🐾 PetAdopt ℹ️ [Supabase] Cargando credenciales desde .env
🐾 PetAdopt ℹ️ [Supabase] URL: https://abcdefgh...
```

### ✅ Éxitos (`LoggerService.success`)
```dart
// Ejemplo de salida:
🐾 PetAdopt ✅ [Supabase] Conexión a Supabase establecida
🐾 PetAdopt ✅ [Auth] Usuario identificado como ADOPTANTE
```

### ⚠️ Advertencias (`LoggerService.warning`)
```dart
// Ejemplo de salida:
🐾 PetAdopt ⚠️ [Auth] Tipo de usuario no identificado
```

## 🔒 Seguridad de datos sensibles

El sistema automáticamente **oculta** datos sensibles en los logs:

### ❌ Datos que NUNCA se muestran:
- `password` / `contraseña`
- `token` / `api_key` / `secret`
- `cedula`
- `telefono`
- `direccion`

### Ejemplo:
```dart
LoggerService.auth('Registro', data: {
  'email': 'user@example.com',
  'password': 'MySecret123',
  'cedula': '123456789',
});

// Salida sanitizada:
🐾 PetAdopt 🔐 [Auth] Registro
🐾 PetAdopt 📋 Params: {
  email: user@example.com, 
  password: ***OCULTO***, 
  cedula: ***OCULTO***
}
```

## 📍 Archivos con logging implementado

### ✅ Ya implementado:
- `lib/src/core/services/supabase_service.dart`
  - Inicialización de conexión
  - Carga de credenciales desde `.env`
  
- `lib/src/features/auth/data/datasources/auth_remote_data_source.dart`
  - Login
  - Registro adoptante
  - Registro fundación
  - Logout
  - Recuperación de contraseña
  - Obtener usuario actual
  - Stream de cambios de autenticación

## 🎨 Formato de logs

### Secciones importantes
```dart
LoggerService.section('REGISTRO DE FUNDACIÓN');

// Salida:
🐾 PetAdopt ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐾 PetAdopt 📌 REGISTRO DE FUNDACIÓN
🐾 PetAdopt ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🛠️ Cómo usar LoggerService en tu código

### 1. Importar el servicio
```dart
import 'package:flutter_app_pet_adopt/src/core/services/logger_service.dart';
```

### 2. Usar los métodos disponibles

#### Información general
```dart
LoggerService.info('Cargando mascotas', context: 'Adopciones');
```

#### Éxito
```dart
LoggerService.success('Mascota adoptada correctamente', context: 'Adopciones');
```

#### Advertencia
```dart
LoggerService.warning('No hay mascotas disponibles', context: 'Adopciones');
```

#### Error
```dart
LoggerService.error(
  'Fallo al cargar mascotas',
  context: 'Adopciones',
  error: e,
  stackTrace: stackTrace,
);
```

#### Base de datos
```dart
LoggerService.database('INSERT', 'mascotas', detail: 'ID: abc-123');
```

#### Autenticación
```dart
LoggerService.auth('Login exitoso', data: {'userId': user.id});
```

#### Navegación
```dart
LoggerService.navigation('WelcomeScreen', 'LoginScreen');
```

#### Evento de usuario
```dart
LoggerService.userEvent('Botón adoptado presionado', data: {'petId': 123});
```

#### Separador visual
```dart
LoggerService.separator();
```

## 📖 Ejemplo de flujo de registro completo

```
🐾 PetAdopt ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐾 PetAdopt 📌 REGISTRO DE FUNDACIÓN
🐾 PetAdopt ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐾 PetAdopt 🔐 [Auth] Registrando fundación
🐾 PetAdopt 📋 Params: {email: fundacion@example.com, nombre: Mi Fundación, direccion: ***OCULTO***, telefono: ***OCULTO***}
🐾 PetAdopt ℹ️ [Auth] Creando usuario en auth.users
🐾 PetAdopt ✅ [Auth] Usuario creado en auth.users
🐾 PetAdopt ℹ️ [Auth] User ID: abc-123-def-456
🐾 PetAdopt ℹ️ [Auth] Trigger SQL insertará datos en tabla fundaciones
```

## ⚙️ Configuración

### Los logs solo aparecen en modo DEBUG
```dart
// En producción (flutter run --release), los logs NO se muestran
// para optimizar performance y seguridad
```

### Personalizar el tag
Edita `lib/src/core/services/logger_service.dart`:
```dart
static const String _tag = '🐾 PetAdopt'; // Cambia esto
```

## 🚀 Próximos pasos

Para extender el logging a otras partes de la app:

1. **Repositorios**: Agrega logs en `auth_repository_impl.dart`
2. **BLoC**: Logs en eventos y estados de `auth_bloc.dart`
3. **Screens**: Logs de navegación y eventos de usuario
4. **Mascotas**: Implementar en el módulo de adopción de mascotas

## 📚 Buenas prácticas

✅ **DO**
- Usa `context` para identificar el origen del log
- Sanitiza datos sensibles automáticamente
- Incluye stack traces en errores críticos
- Usa `section()` para marcar flujos importantes

❌ **DON'T**
- No incluyas contraseñas sin sanitizar
- No hagas logs excesivos en bucles
- No uses `print()`, usa `LoggerService`
- No expongas tokens o API keys

## 🔍 Troubleshooting

### No veo los logs
1. Verifica que estés en modo DEBUG (`flutter run` sin `--release`)
2. Revisa la consola correcta (Debug Console en VS Code)
3. Asegúrate que `kDebugMode` esté en `true`

### Logs muy largos
- Aumenta el buffer de la consola en VS Code
- Usa `maxResults` en queries de base de datos

### Logs con caracteres raros
- Asegúrate que tu terminal soporte UTF-8 (emojis)
