# 🐾 Pet Adopt - Aplicación Flutter de Adopción de Mascotas

Aplicación móvil de adopción de mascotas desarrollada con **Flutter**, implementando **Arquitectura Clean Code con enfoque en Features**. Diseñada para conectar fundaciones rescatistas con personas interesadas en adoptar mascotas de manera segura y sencilla.

## 📋 Tabla de Contenidos

1. [Descripción del Proyecto](#-descripción-del-proyecto)
2. [Arquitectura General](#-arquitectura-general)
3. [Librerías y Dependencias](#-librerías-y-dependencias)
4. [Estructura Detallada del Proyecto](#-estructura-detallada-del-proyecto)
5. [Explicación de Cada Capa](#-explicación-de-cada-capa)
6. [Features Principales](#-features-principales)
7. [Flujos de Trabajo](#-flujos-de-trabajo)
8. [Importaciones Clave](#-importaciones-clave)
9. [Guía de Desarrollo](#-guía-de-desarrollo)
10. [Recursos y Referencias](#-recursos-y-referencias)

---

## 📱 Descripción del Proyecto

**Pet Adopt** es una plataforma moderna que facilita el proceso de adopción y donación de mascotas, conectando:

- 🏢 **Fundaciones**: Organizaciones que rescatan y cuidan mascotas
- 👤 **Adoptantes**: Personas interesadas en adoptar mascotas
- 💬 **Comunicación directa**: Sistema de mensajería integrado
- 📍 **Ubicación**: Integración con GPS y mapas

### Características Principales:

- ✅ **Autenticación segura** (Email, Google OAuth)
- ✅ **Gestión de perfiles** (Adoptantes y Fundaciones)
- ✅ **Catálogo de mascotas** con fotos y detalles
- ✅ **Sistema de solicitudes de adopción**
- ✅ **Mensajería en tiempo real** entre usuarios
- ✅ **Notificaciones** de actualizaciones y nuevas mascotas
- ✅ **Integración con Supabase** (Backend as a Service)
- ✅ **Soporte multi-plataforma**: iOS, Android, Web, Windows, macOS, Linux


---

## 🏗️ Arquitectura General

### Clean Architecture + Feature-Driven Design

La arquitectura implementada sigue los **principios de Clean Architecture** de Robert C. Martin, combinado con un enfoque **Feature-Driven** (basado en características). Esto permite:

- **Separación de responsabilidades**: Cada capa tiene un propósito específico
- **Independencia de frameworks**: Lógica de negocio sin dependencias de Flutter
- **Testabilidad**: Cada componente puede ser probado aisladamente
- **Escalabilidad**: Fácil agregar nuevas características sin afectar las existentes
- **Mantenibilidad**: Código organizado y predecible

### Las Tres Capas Principales

```
┌───────────────────────────────────────────────────┐
│   PRESENTATION (Presentación / UI)                │
│   - Screens (Pantallas)                           │
│   - Widgets (Componentes UI)                      │
│   - BLoC (Gestión de Estado)                      │
│   - Eventos y Estados                             │
└───────────────────────────────────────────────────┘
                        ↕ (Depende de)
┌───────────────────────────────────────────────────┐
│   DOMAIN (Dominio / Lógica de Negocio)            │
│   - Entidades (Modelos puros)                     │
│   - Repositorios (Interfaces)                     │
│   - Casos de Uso (Use Cases)                      │
│   - Excepciones específicas del negocio           │
└───────────────────────────────────────────────────┘
                        ↕ (Implementado por)
┌───────────────────────────────────────────────────┐
│   DATA (Datos)                                    │
│   - Data Sources (Acceso a datos)                 │
│   - Modelos (Transformación JSON)                 │
│   - Repositorios (Implementación)                 │
│   - Mapeo de datos                                │
└───────────────────────────────────────────────────┘
```

### Organización por Features

Cada **Feature** (característica) es un módulo completamente independiente que implementa las 3 capas:

```
feature/
├── data/              ← Capa de Datos
│   ├── datasources/   (Acceso a APIs/BD)
│   ├── models/        (Serialización JSON)
│   └── repositories/  (Implementación de interfaces)
│
├── domain/            ← Capa de Dominio (Pura, sin dependencias)
│   ├── entities/      (Clases de negocio)
│   ├── repositories/  (Contratos/Interfaces)
│   └── usecases/      (Lógica de negocio)
│
└── presentation/      ← Capa de Presentación
    ├── bloc/          (Gestión de estado)
    ├── screens/       (Pantallas)
    └── widgets/       (Componentes reutilizables)
```

### Flujo de Dependencias (Dependency Inversion)

```
Presentation → Domain ← Data
     ↓           ↑
  La UI llama   Los repositorios
 eventos BLoC   implementan
     ↓           interfaces
 Los BLoCs
  llaman
 Use Cases
```

**Regla de Oro**: Las capas internas NO conocen a las externas
- ✅ Data puede usar Domain
- ✅ Presentation puede usar Domain
- ❌ Domain NO debe conocer Data o Presentation

---

## 📂 Estructura Detallada del Proyecto

### Árbol Completo

```
lib/
└── src/
    ├── main.dart                          ← PUNTO DE ENTRADA
    │   - Inyección de dependencias (GetIt)
    │   - Inicialización de Supabase
    │   - Configuración de variables de entorno
    │
    ├── app.dart                           ← WIDGET RAÍZ
    │   - MaterialApp
    │   - Configuración de temas
    │   - Rutas de navegación
    │
    ├── core/                              ← CÓDIGO COMPARTIDO GLOBALMENTE
    │   ├── constants/
    │   │   ├── app_constants.dart         (URLs, timeouts, limites)
    │   │   └── string_constants.dart      (Textos reutilizables)
    │   │
    │   ├── errors/
    │   │   ├── exceptions.dart            (Excepciones personalizadas)
    │   │   └── failures.dart              (Fallos de negocio)
    │   │
    │   ├── router/
    │   │   └── app_router.dart            (Configuración GoRouter)
    │   │
    │   ├── services/
    │   │   ├── supabase_service.dart      (Cliente Supabase)
    │   │   ├── storage_service.dart       (Almacenamiento de archivos)
    │   │   └── logger_service.dart        (Sistema de logging)
    │   │
    │   ├── theme/
    │   │   └── app_theme.dart             (Colores, tipografías, estilos)
    │   │
    │   ├── utils/
    │   │   ├── validators.dart            (Email, teléfono, cédula)
    │   │   ├── formatters.dart            (Fecha, moneda, teléfono)
    │   │   ├── extensions.dart            (Métodos extendidos)
    │   │   └── snackbar_utils.dart        (Notificaciones UI)
    │   │
    │   └── widgets/
    │       ├── app_loader.dart            (Indicador de carga)
    │       ├── custom_button.dart         (Botón reutilizable)
    │       └── custom_textfield.dart      (Campo de texto)
    │
    └── features/                          ← MÓDULOS DE NEGOCIO (Lo más importante)
        │
        ├── auth/                          (AUTENTICACIÓN)
        │   ├── data/
        │   │   ├── datasources/
        │   │   │   └── auth_remote_data_source.dart
        │   │   │       - signInWithPassword()
        │   │   │       - signUp()
        │   │   │       - signInWithGoogle()
        │   │   │       - recoverPassword()
        │   │   │
        │   │   ├── models/
        │   │   │   └── user_model.dart
        │   │   │       - Serialización JSON
        │   │   │       - Hereda de UserEntity
        │   │   │
        │   │   └── repositories/
        │   │       └── auth_repository_impl.dart
        │   │           - Implementa AuthRepository
        │   │           - Maneja errores
        │   │           - Mapea datos
        │   │
        │   ├── domain/
        │   │   ├── entities/
        │   │   │   └── user_entity.dart
        │   │   │       - id, email, type (adoptante/fundacion)
        │   │   │
        │   │   ├── repositories/
        │   │   │   └── auth_repository.dart (Interfaz)
        │   │   │
        │   │   └── usecases/
        │   │       ├── login_usecase.dart
        │   │       ├── register_adoptante_usecase.dart
        │   │       ├── register_fundacion_usecase.dart
        │   │       ├── check_auth_status_usecase.dart
        │   │       └── recover_password_usecase.dart
        │   │
        │   └── presentation/
        │       ├── bloc/
        │       │   ├── auth_bloc.dart
        │       │   │   - on<AuthLoginRequested>()
        │       │   │   - on<AuthRegisterAdoptanteRequested>()
        │       │   │   - on<AuthLogoutRequested>()
        │       │   │
        │       │   ├── auth_event.dart
        │       │   │   - AuthLoginRequested
        │       │   │   - AuthRegisterAdoptanteRequested
        │       │   │   - AuthLogoutRequested
        │       │   │
        │       │   └── auth_state.dart
        │       │       - AuthInitial
        │       │       - AuthLoading
        │       │       - AuthAuthenticated
        │       │       - AuthError
        │       │
        │       ├── screens/
        │       │   ├── login_screen.dart
        │       │   ├── register_adoptante_screen.dart
        │       │   ├── register_fundacion_screen.dart
        │       │   ├── register_selector_screen.dart
        │       │   ├── forgot_password_screen.dart
        │       │   └── welcome_screen.dart
        │       │
        │       └── widgets/
        │           ├── auth_form.dart
        │           └── social_button.dart
        │
        ├── adoptions/                     (ADOPCIONES Y ADOPCIONES)
        │   ├── data/
        │   │   ├── datasources/
        │   │   │   └── adoption_remote_data_source.dart
        │   │   │       - getAdoptionRequests()
        │   │   │       - createAdoptionRequest()
        │   │   │       - updateAdoptionStatus()
        │   │   │
        │   │   ├── models/
        │   │   │   ├── adoption_model.dart
        │   │   │   └── adopter_model.dart
        │   │   │
        │   │   └── repositories/
        │   │       ├── adoption_repository_impl.dart
        │   │       └── adopter_profile_repository_impl.dart
        │   │
        │   ├── domain/
        │   │   ├── entities/
        │   │   │   ├── adoption_entity.dart
        │   │   │   └── adopter_entity.dart
        │   │   │
        │   │   ├── repositories/
        │   │   │   ├── adoption_repository.dart
        │   │   │   └── adopter_profile_repository.dart
        │   │   │
        │   │   └── usecases/
        │   │       ├── get_adoption_requests_usecase.dart
        │   │       ├── create_adoption_request_usecase.dart
        │   │       └── update_adoption_status_usecase.dart
        │   │
        │   └── presentation/
        │       ├── bloc/
        │       │   ├── adoption_bloc.dart
        │       │   ├── adopter_profile_bloc.dart
        │       │   └── adopter_profile_event.dart/state.dart
        │       │
        │       ├── screens/
        │       │   ├── home_adopter_screen.dart
        │       │   ├── adopter_requests_screen.dart
        │       │   └── perfil/
        │       │       └── edit_perfil_adopter_screen.dart
        │       │
        │       └── widgets/
        │           ├── adoption_card.dart
        │           └── adopter_form.dart
        │
        ├── foundations/                   (FUNDACIONES)
        │   ├── data/
        │   │   ├── datasources/
        │   │   │   └── foundation_remote_data_source.dart
        │   │   │       - getFoundations()
        │   │   │       - getFoundationProfile()
        │   │   │       - updateFoundationProfile()
        │   │   │
        │   │   ├── models/
        │   │   │   └── foundation_model.dart
        │   │   │
        │   │   └── repositories/
        │   │       └── foundation_repository_impl.dart
        │   │
        │   ├── domain/
        │   │   ├── entities/
        │   │   │   └── foundation_entity.dart
        │   │   │
        │   │   ├── repositories/
        │   │   │   └── foundation_repository.dart
        │   │   │
        │   │   └── usecases/
        │   │       ├── get_foundations_usecase.dart
        │   │       └── update_foundation_profile_usecase.dart
        │   │
        │   └── presentation/
        │       ├── bloc/
        │       │   ├── profile/
        │       │   │   ├── foundation_profile_bloc.dart
        │       │   │   ├── foundation_profile_event.dart
        │       │   │   └── foundation_profile_state.dart
        │       │   │
        │       │   └── tabs/
        │       │       └── foundation_tabs_bloc.dart
        │       │
        │       ├── screens/
        │       │   ├── home_foundation_screen.dart
        │       │   └── profile/
        │       │       ├── view_foundation_profile_screen.dart
        │       │       └── edit_foundation_profile_screen.dart
        │       │
        │       └── widgets/
        │           ├── foundation_card.dart
        │           └── foundation_form.dart
        │
        ├── pets/                          (MASCOTAS)
        │   ├── data/
        │   │   ├── datasources/
        │   │   │   └── pet_remote_data_source.dart
        │   │   │       - getPets()
        │   │   │       - createPet()
        │   │   │       - updatePet()
        │   │   │       - deletePet()
        │   │   │
        │   │   ├── models/
        │   │   │   └── pet_model.dart
        │   │   │
        │   │   └── repositories/
        │   │       └── pet_repository_impl.dart
        │   │
        │   ├── domain/
        │   │   ├── entities/
        │   │   │   └── pet_entity.dart
        │   │   │
        │   │   ├── repositories/
        │   │   │   └── pet_repository.dart
        │   │   │
        │   │   └── usecases/
        │   │       ├── get_pets_usecase.dart
        │   │       ├── get_pet_detail_usecase.dart
        │   │       ├── create_pet_usecase.dart
        │   │       ├── update_pet_usecase.dart
        │   │       └── delete_pet_usecase.dart
        │   │
        │   └── presentation/
        │       ├── bloc/
        │       │   └── pet_bloc.dart
        │       │
        │       ├── screens/
        │       │   ├── pets_list_screen.dart
        │       │   ├── pet_detail_screen.dart
        │       │   ├── create_pet_screen.dart
        │       │   └── edit_pet_screen.dart
        │       │
        │       └── widgets/
        │           ├── pet_card.dart
        │           ├── pet_gallery.dart
        │           └── pet_form.dart
        │
        └── chat/                          (MENSAJERÍA)
            ├── data/
            │   ├── datasources/
            │   │   └── chat_remote_data_source.dart
            │   │       - getMessages()
            │   │       - sendMessage()
            │   │       - listenToMessages()
            │   │
            │   ├── models/
            │   │   └── message_model.dart
            │   │
            │   └── repositories/
            │       └── chat_repository_impl.dart
            │
            ├── domain/
            │   ├── entities/
            │   │   └── message_entity.dart
            │   │
            │   ├── repositories/
            │   │   └── chat_repository.dart
            │   │
            │   └── usecases/
            │       ├── get_messages_usecase.dart
            │       ├── send_message_usecase.dart
            │       └── listen_to_messages_usecase.dart
            │
            └── presentation/
                ├── bloc/
                │   ├── chat_bloc.dart
                │   ├── chat_event.dart
                │   └── chat_state.dart
                │
                ├── screens/
                │   ├── chats_list_screen.dart
                │   └── chat_detail_screen.dart
                │
                └── widgets/
                    ├── message_bubble.dart
                    ├── message_input.dart
                    └── chat_tile.dart
```

### Archivo `pubspec.yaml`
```yaml
name: flutter_app_pet_adopt
description: Aplicación de adopción de mascotas con Flutter

environment:
  sdk: ^3.11.0-242.0.dev

dependencies:
  flutter:
    sdk: flutter
  
  # Gestión de estado
  flutter_bloc: ^9.1.1
  equatable: ^2.0.8
  
  # Inyección de dependencias
  get_it: ^9.2.0
  
  # Backend
  supabase_flutter: ^2.8.0
  http: ^1.6.0
  
  # UI y Diseño
  google_fonts: ^6.3.3
  
  # Configuración
  flutter_dotenv: ^5.2.1
  
  # Manejo de archivos e imágenes
  image_picker: ^1.1.2
  path: ^1.9.0
  
  # PDF
  pdf: ^3.11.3
  printing: ^5.14.2
  
  # Mapas y ubicación
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  geocoding: ^3.0.0
  geolocator: ^9.0.2
  
  # Notificaciones
  flutter_local_notifications: ^14.1.1
  app_links: ^3.4.5
  
  # Audio
  flutter_tts: ^8.2.0
  
  # Almacenamiento local
  shared_preferences: ^2.0.0
  
  # URLs
  url_launcher: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## 📦 Librerías y Dependencias

### Gestión de Estado

#### **flutter_bloc** (^9.1.1)
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
```
- **Propósito**: Gestión de estado con el patrón BLoC (Business Logic Component)
- **Uso**: Gestiona eventos y estados en AuthBloc, PetBloc, AdopterProfileBloc, etc.
- **Ventajas**: Separación clara entre lógica y UI, fácil testing, escalable

#### **equatable** (^2.0.8)
```dart
import 'package:equatable/equatable.dart';
```
- **Propósito**: Comparación de objetos sin escribir `==` manualmente
- **Uso**: Las entidades, eventos y estados heredan de `Equatable`
- **Ejemplo**: `UserEntity extends Equatable` para comparar usuarios

### Backend y Base de Datos

#### **supabase_flutter** (^2.8.0)
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```
- **Propósito**: Cliente de Supabase (Backend as a Service similar a Firebase)
- **Uso**: 
  - Autenticación (Email, Google OAuth)
  - Base de datos PostgreSQL
  - Almacenamiento de archivos
  - Real-time subscriptions
- **Características**:
  - `supabaseClient.auth` → Manejo de usuarios
  - `supabaseClient.from('table')` → Consultas a BD
  - `supabaseClient.storage` → Almacenamiento de imágenes

### Inyección de Dependencias

#### **get_it** (^9.2.0)
```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;
getIt.registerSingleton<AuthRepository>(AuthRepositoryImpl(...));
getIt.registerSingleton<LoginUseCase>(LoginUseCase(...));
```
- **Propósito**: Service Locator para inyección de dependencias
- **Uso**: Registra y recupera instancias de servicios
- **Ventajas**: Fácil acceso a dependencias sin pasar por constructores

### UI y Diseño

#### **google_fonts** (^6.3.3)
```dart
import 'package:google_fonts/google_fonts.dart';

TextStyle titleStyle = GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold);
```
- **Propósito**: Acceso a fuentes de Google directamente en Flutter
- **Uso**: Tipografías consistentes con diseño moderno

### Utilidades

#### **flutter_dotenv** (^5.2.1)
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabaseUrl = dotenv.env['SUPABASE_URL'];
final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
```
- **Propósito**: Cargar variables de entorno desde archivo `.env`
- **Uso**: Guardar claves API sin exponerlas en el código

#### **http** (^1.6.0)
```dart
import 'package:http/http.dart' as http;

final response = await http.post(url, headers: headers, body: body);
```
- **Propósito**: Realizar peticiones HTTP
- **Uso**: Llamadas a APIs REST

#### **image_picker** (^1.1.2)
```dart
import 'package:image_picker/image_picker.dart';

final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
```
- **Propósito**: Seleccionar imágenes de cámara o galería
- **Uso**: Cambiar avatar, subir fotos de mascotas

#### **path** (^1.9.0)
```dart
import 'package:path/path.dart' as path;

String filename = path.basename(imagePath);
```
- **Propósito**: Manipulación de rutas de archivos
- **Uso**: Gestionar nombres de archivos

#### **pdf** (^3.11.3)
```dart
import 'package:pdf/pdf.dart';
```
- **Propósito**: Generación de documentos PDF
- **Uso**: Crear reportes o documentos de adopción

#### **printing** (^5.14.2)
```dart
import 'package:printing/printing.dart';

await Printing.layoutPdf(onLayout: (format) => pdfBytes);
```
- **Propósito**: Impresión de documentos
- **Uso**: Imprimir documentos PDF

#### **flutter_map** (^6.1.0)
```dart
import 'package:flutter_map/flutter_map.dart';

FlutterMap(
  mapController: _mapController,
  options: MapOptions(center: LatLng(-0.180653, -78.467834)),
  children: [TileLayer(...), MarkerLayer(...)]
)
```
- **Propósito**: Mapas interactivos OpenStreetMap
- **Uso**: Mostrar ubicación de fundaciones, adopción cercana

#### **latlong2** (^0.9.0)
```dart
import 'package:latlong2/latlong.dart';

LatLng location = LatLng(-0.180653, -78.467834);
```
- **Propósito**: Representar coordenadas geográficas
- **Uso**: Manejo de latitud y longitud

#### **geocoding** (^3.0.0)
```dart
import 'package:geocoding/geocoding.dart';

List<Location> locations = await locationFromAddress("Quito, Ecuador");
```
- **Propósito**: Convertir direcciones a coordenadas (Geocoding)
- **Uso**: Localizar fundaciones por dirección

#### **geolocator** (^9.0.2)
```dart
import 'package:geolocator/geolocator.dart';

Position position = await Geolocator.getCurrentPosition();
```
- **Propósito**: Obtener ubicación GPS del dispositivo
- **Uso**: Localizar al usuario en tiempo real

#### **flutter_local_notifications** (^14.1.1)
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
```
- **Propósito**: Notificaciones locales
- **Uso**: Alertas sobre nuevas solicitudes, mensajes

#### **flutter_tts** (^8.2.0)
```dart
import 'package:flutter_tts/flutter_tts.dart';

await flutterTts.speak("Nuevo mensaje disponible");
```
- **Propósito**: Síntesis de voz (Text-to-Speech)
- **Uso**: Accesibilidad, lectura de mensajes

#### **shared_preferences** (^2.0.0)
```dart
import 'package:shared_preferences/shared_preferences.dart';

final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_id', userId);
```
- **Propósito**: Almacenamiento local key-value
- **Uso**: Guardar preferencias de usuario, tokens

#### **app_links** (^3.4.5)
```dart
import 'package:app_links/app_links.dart';
```
- **Propósito**: Deep linking (abrir app desde enlaces)
- **Uso**: Redirigir a pantallas específicas desde notificaciones

#### **url_launcher** (^6.1.0)
```dart
import 'package:url_launcher/url_launcher.dart';

await launchUrl(Uri.parse('https://example.com'));
```
- **Propósito**: Abrir URLs, llamadas, emails
- **Uso**: Contactar fundaciones, abrir enlaces

---

## 🎯 Explicación de Cada Capa

### 1️⃣ DATA LAYER (Capa de Datos)

**Ubicación**: `lib/src/features/[feature]/data/`

#### Responsabilidades
- Comunicación con APIs y bases de datos
- Transformación de datos JSON en objetos Dart
- Manejo de errores técnicos (conexión, timeout, etc.)
- Implementación concreta de interfaces del Domain

#### Componentes

##### **DataSources** (datasources/)
```dart
// auth_remote_data_source.dart
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> registerAdoptante({required String email, ...});
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  @override
  Future<UserModel> login(String email, String password) async {
    try {
      // Llamada real a Supabase
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return UserModel.fromJson(response.user.toJson());
    } catch (e) {
      // Manejo de errores
      throw Exception('Error: $e');
    }
  }
}
```

**Tipos de DataSources**:
- **RemoteDataSource**: Comunica con APIs externas (Supabase)
- **LocalDataSource**: Accede a almacenamiento local (SharedPreferences, SQLite)

##### **Models** (models/)
```dart
// user_model.dart
class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String email,
    String? type,
  }) : super(id: id, email: email, type: type);
  
  // JSON serialization
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      type: json['user_metadata']?['type'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'type': type,
  };
}
```

**Características de Models**:
- ✅ Heredan de Entidades
- ✅ JSON serializable (fromJson, toJson)
- ✅ Convertibles a Entidades puras

##### **Repositories** (repositories/)
```dart
// auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      return userModel; // Retorna como UserEntity
    } on SocketException {
      throw const ServerException('Sin conexión');
    } on FormatException {
      throw const CacheException('Datos inválidos');
    }
  }
}
```

**Responsabilidades**:
- Coordinar múltiples datasources
- Manejar lógica de caché
- Transformar errores técnicos en excepciones de negocio

---

### 2️⃣ DOMAIN LAYER (Capa de Dominio)

**Ubicación**: `lib/src/features/[feature]/domain/`

**Restricción**: ❌ NO debe importar nada de `data/` ni `presentation/`

#### Responsabilidades
- Definir la lógica de negocio pura
- Establecer interfaces (contratos)
- Independencia de frameworks y herramientas
- Testeable sin dependencias externas

#### Componentes

##### **Entities** (entities/)
```dart
// user_entity.dart
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? type; // 'adoptante' o 'fundacion'
  
  const UserEntity({
    required this.id,
    required this.email,
    this.type,
  });
  
  @override
  List<Object?> get props => [id, email, type];
}
```

**Características**:
- ✅ Clases puras sin métodos técnicos
- ✅ Representan conceptos del negocio
- ✅ NO tienen JSON (eso es trabajo de Models)
- ✅ Heredan de Equatable para comparación

##### **Repositories** (repositories/)
```dart
// auth_repository.dart (INTERFAZ/CONTRATO)
abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> registerAdoptante({
    required String email,
    required String password,
    required String nombre,
    required String cedula,
    required String telefono,
  });
  Future<void> logout();
  Stream<UserEntity?> get authStateChanges;
}
```

**Importante**: Es una **interfaz (abstract)**, no implementación.

##### **UseCases** (usecases/)
```dart
// login_usecase.dart
class LoginUseCase {
  final AuthRepository repository;
  
  LoginUseCase(this.repository);
  
  // El patrón __call__ permite usar la clase como función
  Future<UserEntity> call(String email, String password) async {
    // Validaciones de negocio
    if (email.isEmpty || password.isEmpty) {
      throw const FormatException('Email y contraseña requeridos');
    }
    
    // Llamar repositorio
    return await repository.login(email, password);
  }
}

// Uso en BLoC:
// final user = await loginUseCase('user@example.com', 'pass123');
```

**Patrón UseCase**:
- ✅ Una acción = Un UseCase
- ✅ Contiene lógica de negocio
- ✅ Retorna Entidades, no Models
- ✅ Usa patrón `call()` para invocación

---

### 3️⃣ PRESENTATION LAYER (Capa de Presentación)

**Ubicación**: `lib/src/features/[feature]/presentation/`

#### Responsabilidades
- Mostrar UI al usuario
- Gestionar estado de la aplicación
- Capturar entrada del usuario
- Coordinar navegación

#### Componentes

##### **BLoC** (bloc/)
```dart
// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterAdoptanteUseCase registerAdoptanteUseCase;
  
  AuthBloc({
    required this.loginUseCase,
    required this.registerAdoptanteUseCase,
  }) : super(AuthInitial()) {
    
    // Escuchar eventos y emitir estados
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading()); // Estado de carga
      
      try {
        final user = await loginUseCase(event.email, event.password);
        emit(AuthAuthenticated(user)); // Éxito
      } catch (e) {
        emit(AuthError(e.toString())); // Error
      }
    });
  }
}
```

**Patrón BLoC (Business Logic Component)**:
- ✅ Reacciona a **Events** (acciones del usuario)
- ✅ Emite **States** (estados de UI)
- ✅ Llama UseCases para lógica
- ✅ Separación clara entre lógica y UI

##### **Events** (bloc/)
```dart
// auth_event.dart (Acciones que el usuario puede hacer)
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const AuthLoginRequested(this.email, this.password);
  
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterAdoptanteRequested extends AuthEvent {
  final String email;
  final String password;
  final String nombre;
  final String cedula;
  final String telefono;
  
  const AuthRegisterAdoptanteRequested({
    required this.email,
    required this.password,
    required this.nombre,
    required this.cedula,
    required this.telefono,
  });
  
  @override
  List<Object?> get props => [email, password, nombre, cedula, telefono];
}
```

##### **States** (bloc/)
```dart
// auth_state.dart (Estados posibles de la pantalla)
abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  @override
  List<Object?> get props => [];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  
  const AuthAuthenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

##### **Screens** (screens/)
```dart
// login_screen.dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return LoginForm(
              onLogin: (email, password) {
                context.read<AuthBloc>().add(
                  AuthLoginRequested(email, password),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

**BLoC Listeners y Builders**:
- **BlocListener**: Para efectos secundarios (navegación, snackbars)
- **BlocBuilder**: Para renderizar UI según estado

##### **Widgets** (widgets/)
```dart
// login_form.dart (Componentes reutilizables)
class LoginForm extends StatefulWidget {
  final Function(String, String) onLogin;
  
  const LoginForm({required this.onLogin});
  
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.onLogin(
              _emailCtrl.text,
              _passCtrl.text,
            ),
            child: Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
```

---

### 🔄 CORE (Código Compartido)

**Ubicación**: `lib/src/core/`

**Acceso**: Cualquier feature puede importar desde core

#### Componentes

##### **Services**
```dart
// logger_service.dart - Logging centralizado
class LoggerService {
  static void info(String message) {
    print('[INFO] $message');
  }
  
  static void error(String message, {dynamic error}) {
    print('[ERROR] $message: $error');
  }
}

// Uso en cualquier parte:
LoggerService.info('Usuario autenticado');
```

##### **Utils**
```dart
// validators.dart
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email requerido';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Teléfono requerido';
    if (value.length != 10) return 'Teléfono debe tener 10 dígitos';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Solo números';
    return null;
  }
}
```

##### **Theme**
```dart
// app_theme.dart
class AppTheme {
  static const primaryOrange = Color(0xFFFF8C42);
  static const textPrimary = Color(0xFF212121);
  static const background = Color(0xFFFAFAFA);
  
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryOrange,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
  );
}
```

##### **Exceptions & Failures**
```dart
// exceptions.dart
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

// failures.dart
abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(String message) : super(message);
}
```

### Crear un Nuevo Feature

1. **Crear la estructura de carpetas:**
   ```
   lib/src/features/mi_feature/
   ├── data/
   │   ├── datasources/
   │   ├── models/
   │   └── repositories/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── usecases/
   └── presentation/
       ├── bloc/
       ├── screens/
       └── widgets/
   ```

2. **Implementar el orden correcto:**
   - ✅ Entities (domain/entities)
   - ✅ Repository interface (domain/repositories)
   - ✅ Models (data/models)
   - ✅ DataSources (data/datasources)
   - ✅ Repository implementation (data/repositories)
   - ✅ UseCases (domain/usecases)
   - ✅ Events/States (presentation/bloc)
   - ✅ BLoC (presentation/bloc)
   - ✅ Screens & Widgets (presentation)

### Flujo de Datos

```
UI (Screen) 
  ↓
Evento (BLoC Event)
  ↓
BLoC (Lógica de presentación)
  ↓
UseCase (Solicita acción)
  ↓
Repository (Obtiene datos)
  ↓
DataSource (API/BD)
  ↓
Respuesta (State del BLoC)
  ↓
UI actualizada
```

---

## 📚 Recursos

- [Clean Architecture en Flutter](https://resocoder.com/flutter-clean-architecture)
- [BLoC Library](https://bloclibrary.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Supabase Flutter](https://supabase.com/docs/reference/flutter/introduction)
- [Flutter Best Practices](https://docs.flutter.dev/)
