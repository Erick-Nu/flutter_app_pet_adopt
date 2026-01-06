# 🔧 Configuración de Supabase para Pet Adoption App

## 📋 Pasos para configurar la base de datos

### 1️⃣ Crear el proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com)
2. Crea un nuevo proyecto
3. Guarda tu **Project URL** y **anon key**

### 2️⃣ Ejecutar el script de base de datos

1. Abre el SQL Editor en tu proyecto de Supabase
2. Copia y pega el contenido del archivo de base de datos que te proporcionaron
3. Ejecuta el script completo

### 3️⃣ Configurar autenticación en Supabase

**Importante:** Desactiva la confirmación de email para desarrollo

1. Ve a **Authentication > Settings** en Supabase
2. Busca la sección **Email Auth**
3. Desactiva **"Enable email confirmations"**
4. Guarda los cambios

### 4️⃣ Verificar políticas RLS

Las políticas ya están incluidas en el script SQL. Verifica que estén activas:

- ✅ `adoptantes` - Policy para gestionar perfil propio
- ✅ `fundaciones` - Policy para gestionar perfil propio
- ✅ `mascotas` - Lectura pública, escritura autenticada

### 5️⃣ Configurar credenciales en Flutter

Actualiza el archivo de configuración con tus credenciales:

```dart
// lib/main.dart o donde inicialices Supabase
await Supabase.initialize(
  url: 'TU_PROJECT_URL',
  anonKey: 'TU_ANON_KEY',
);
```

## 🔍 Verificar que funciona

### Probar registro de adoptante:

```sql
-- En SQL Editor de Supabase, después de registrar un usuario
SELECT * FROM auth.users;
SELECT * FROM adoptantes;
```

### Probar registro de fundación:

```sql
SELECT * FROM fundaciones;
```

## ⚠️ Solución de problemas

### Error: "new row violates row level security policy for table fundaciones" o "adoptantes"

- **Causa:** Las políticas RLS no permiten INSERT durante el registro
- **Solución:** Ejecuta el script `database/fix_rls_policies.sql` en Supabase SQL Editor
  
  ```sql
  -- Esto creará políticas separadas para INSERT, UPDATE, SELECT, DELETE
  -- permitiendo que los usuarios creen su perfil durante el registro
  ```

### Error: "duplicate key value violates unique constraint"

- **Causa:** Ya existe un usuario con esa cédula o email
- **Solución:** Usa datos diferentes o elimina el usuario existente

### Error: "permission denied for table adoptantes"

- **Causa:** Las políticas RLS no están correctamente configuradas
- **Solución:** Vuelve a ejecutar las políticas del script SQL

### Error: "Email not confirmed"

- **Causa:** Tienes activada la confirmación de email
- **Solución:** Sigue el paso 3️⃣ arriba

### Los usuarios no aparecen en las tablas

- **Causa:** El INSERT manual está fallando silenciosamente
- **Solución:** Revisa los logs en Supabase Dashboard > Logs

## 🎯 Trigger automático (OPCIONAL)

Si prefieres usar triggers en lugar de INSERTs manuales:

1. Ejecuta el script `database/triggers.sql`
2. Modifica `auth_remote_data_source.dart` para pasar datos en metadata
3. Comenta los INSERTs manuales

## 📊 Estructura actual

**Flujo de registro:**
1. `auth.signUp()` → Crea usuario en `auth.users`
2. `from('adoptantes').insert()` → Inserta en tabla pública
3. Retorna `UserModel` con tipo de usuario

**Flujo de login:**
1. `auth.signInWithPassword()` → Autentica
2. Consulta `adoptantes` y `fundaciones` → Determina tipo
3. Retorna `UserModel` con tipo correcto

## ✅ Checklist de configuración

- [ ] Proyecto creado en Supabase
- [ ] Script SQL ejecutado
- [ ] Confirmación de email desactivada
- [ ] Credenciales configuradas en Flutter
- [ ] Políticas RLS verificadas
- [ ] Primer registro de prueba exitoso
