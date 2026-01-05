# Pet Adopt - Flutter App

Aplicación móvil de adopción de mascotas desarrollada con Flutter, implementando **Arquitectura Clean Code con enfoque en Features**.

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Arquitectura](#arquitectura)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Dependencias](#dependencias)
- [Guía de Desarrollo](#guía-de-desarrollo)
- [Recursos](#recursos)

---

## 📱 Descripción

Pet Adopt es una plataforma que facilita el proceso de adopción y donación de mascotas, conectando fundaciones con personas interesadas en adoptar. La app incluye:

- ✅ Autenticación de usuarios y fundaciones
- ✅ Gestión de perfiles de mascotas
- ✅ Sistema de adopción y donación
- ✅ Mensajería entre usuarios y fundaciones
- ✅ Soporte multi-plataforma (iOS, Android, Web, Windows, macOS, Linux)

---

## 🏗️ Arquitectura

### Clean Architecture + Feature-Driven

La arquitectura implementada sigue los principios de **Clean Architecture** de Robert C. Martin, combinado con un enfoque **basado en Features** para una mejor organización y escalabilidad.

#### Principios Clave:

1. **Independencia de Frameworks**: La lógica de negocio no depende de Flutter
2. **Testeable**: Cada capa puede ser testeada de forma independiente
3. **Independencia de UI**: La lógica no conoce cómo se presentan los datos
4. **Independencia de BD**: La lógica no está acoplada a la base de datos
5. **Independencia de agentes externos**: Fácil de cambiar APIs, bases de datos, etc.

#### Capas de la Arquitectura:

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │  ← UI, BLoC/Provider, Screens
├─────────────────────────────────────────┤
│           DOMAIN LAYER                  │  ← Entidades, Casos de Uso, Interfaces
├─────────────────────────────────────────┤
│             DATA LAYER                  │  ← Repositorios, DataSources, Modelos
└─────────────────────────────────────────┘
```

### Por Feature (Dominio)

Cada **Feature** representa un módulo de negocio independiente. Dentro de cada feature se implementan las 3 capas de arquitectura clean:

```
feature/
├── data/              ← Implementación concreta (BD, API, Cache)
├── domain/            ← Lógica de negocio pura
└── presentation/      ← UI y gestión de estado
```

**Ventajas:**
- ✅ Fácil de mantener y escalar
- ✅ Independencia entre features
- ✅ Modularización clara
- ✅ Facilita el trabajo en equipo

---

## 📂 Estructura del Proyecto

```
lib/
└── src/
    ├── core/                          ← Lo compartido por toda la app
    │   ├── constants/                 (Colores, rutas de API, strings fijos)
    │   ├── errors/                    (Manejo de excepciones y Failures)
    │   ├── router/                    (Configuración de GoRouter o rutas)
    │   ├── services/                  (Servicios externos: Supabase, Storage, etc.)
    │   ├── theme/                     (Estilos, colores, tema claro/oscuro)
    │   ├── utils/                     (Validadores, formateadores, extensiones)
    │   └── widgets/                   (Botones, inputs genéricos reutilizables)
    │
    └── features/                      ← Módulos de negocio (Lo más importante)
        │
        ├── auth/                      (Autenticación y Registro)
        │   ├── data/
        │   │   ├── datasources/       (Llamadas a Supabase Auth)
        │   │   ├── models/            (UserModel extiende UserEntity)
        │   │   └── repositories/      (AuthRepositoryImpl - implementación)
        │   ├── domain/
        │   │   ├── entities/          (UserEntity - clase pura)
        │   │   ├── repositories/      (AuthRepository - interfaz/contrato)
        │   │   └── usecases/          (LoginUser, RegisterUser, LogoutUser)
        │   └── presentation/
        │       ├── bloc/              (AuthBloc - gestión de estado)
        │       ├── screens/           (LoginScreen, RegisterScreen)
        │       └── widgets/           (AuthForm, SocialButton)
        │
        ├── pets/                      (Gestión de Mascotas)
        │   ├── data/
        │   │   ├── datasources/       (PetRemoteDataSource, PetLocalDataSource)
        │   │   ├── models/            (PetModel)
        │   │   └── repositories/      (PetRepositoryImpl)
        │   ├── domain/
        │   │   ├── entities/          (PetEntity)
        │   │   ├── repositories/      (PetRepository)
        │   │   └── usecases/          (GetPets, CreatePet, UpdatePet, DeletePet)
        │   └── presentation/
        │       ├── bloc/              (PetBloc)
        │       ├── screens/           (PetsListScreen, PetDetailScreen)
        │       └── widgets/           (PetCard, PetForm)
        │
        ├── adoptions/                 (Adopción y Donación)
        │   ├── data/
        │   │   ├── datasources/
        │   │   ├── models/
        │   │   └── repositories/
        │   ├── domain/
        │   │   ├── entities/
        │   │   ├── repositories/
        │   │   └── usecases/
        │   └── presentation/
        │       ├── bloc/
        │       ├── screens/
        │       └── widgets/
        │
        └── chat/                      (Mensajería)
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
    │
    ├── main.dart                      (Punto de entrada - Inyección de dependencias)
    └── app.dart                       (Widget raíz - MaterialApp + Router)
```

### Explicación de Cada Carpeta:

#### **`core/`** - Código Compartido
- **constants**: Colores, URLs de API, strings constantes
- **errors**: Clases base para excepciones y Failures (sin conexión, servidor, etc.)
- **router**: Configuración de rutas (GoRouter)
- **services**: Clientes Supabase, Storage, Notificaciones
- **theme**: Temas de colores, tipografías, estilos globales
- **utils**: Validadores de email/teléfono, formateadores de fecha, extensiones
- **widgets**: Componentes reutilizables (CustomButton, CustomTextField, etc.)

#### **`features/`** - Módulos de Negocio

Cada feature tiene 3 carpetas principales:

##### **`data/`** - Capa de Datos
```
data/
├── datasources/
│   ├── remote_datasource.dart    (Llamadas a API/Supabase)
│   └── local_datasource.dart     (Almacenamiento local - SQLite, Hive)
├── models/
│   └── user_model.dart           (JSON serializable, extiende Entity)
└── repositories/
    └── user_repository_impl.dart (Implementación, maneja errores)
```

**Responsabilidades:**
- Comunicación con APIs y bases de datos
- Transformación de datos JSON a modelos
- Manejo de excepciones técnicas

##### **`domain/`** - Capa de Dominio (Lógica de Negocio)
```
domain/
├── entities/
│   └── user_entity.dart          (Clase pura, sin JSON)
├── repositories/
│   └── user_repository.dart      (Interfaz - contrato)
└── usecases/
    ├── login_user.dart
    ├── register_user.dart
    └── logout_user.dart
```

**Responsabilidades:**
- Entidades de negocio puras
- Interfaces de repositorios
- Casos de uso (acciones del usuario)
- **NO depende de Firebase, Supabase, Flutter, etc.**

##### **`presentation/`** - Capa de Presentación
```
presentation/
├── bloc/
│   ├── auth_bloc.dart            (Gestión de estado)
│   └── auth_event.dart
├── screens/
│   ├── login_screen.dart
│   └── register_screen.dart
└── widgets/
    ├── auth_form.dart
    └── social_button.dart
```

**Responsabilidades:**
- Widgets/UI
- BLoC/Provider para gestión de estado
- Interacción con el usuario

---

## 📦 Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Estado
  flutter_bloc: ^8.x.x
  equatable: ^2.x.x
  
  # Inyección de dependencias
  get_it: ^7.x.x
  
  # Rutas
  go_router: ^11.x.x
  
  # Backend
  supabase_flutter: ^1.x.x
  
  # Utilidades
  dio: ^5.x.x
  shared_preferences: ^2.x.x
```

*(Las versiones exactas se configurarán en pubspec.yaml)*

---

## 🚀 Guía de Desarrollo

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
