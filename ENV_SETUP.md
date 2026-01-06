# 🔐 Configuración de Variables de Entorno

## 📋 Instrucciones

El proyecto ahora utiliza variables de entorno para mayor seguridad de las credenciales de Supabase.

### 1️⃣ Crear archivo .env

1. Copia el archivo `.env.example` y renómbralo a `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edita el archivo `.env` y reemplaza los valores:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu-anon-key-aqui
   ```

### 2️⃣ Obtener credenciales de Supabase

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Click en **Settings** (⚙️) > **API**
3. Copia:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`

### 3️⃣ Instalar dependencias

```bash
flutter pub get
```

### 4️⃣ Ejecutar la aplicación

```bash
flutter run
```

## ⚠️ Seguridad

- ✅ El archivo `.env` está en `.gitignore` (no se sube a Git)
- ✅ Usa `.env.example` como plantilla para otros desarrolladores
- ❌ **NUNCA** subas el archivo `.env` con tus credenciales reales

## 🔄 Para otros desarrolladores

Si clonas este proyecto:

1. Copia `.env.example` a `.env`
2. Pide las credenciales al líder del proyecto
3. O crea tu propio proyecto de Supabase

## 📦 Dependencias agregadas

- `flutter_dotenv: ^5.2.1` - Manejo de variables de entorno

## 🎯 Archivos modificados

- ✅ `pubspec.yaml` - Agregada dependencia y asset `.env`
- ✅ `lib/main.dart` - Carga de `.env` antes de inicializar
- ✅ `lib/src/core/services/supabase_service.dart` - Lee variables desde `.env`
- ✅ `.gitignore` - Agregado `.env` para no subirlo a Git
- ✅ `.env.example` - Plantilla para otros desarrolladores
