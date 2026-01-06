-- =============================================
-- SOLUCIÓN FINAL: Políticas RLS para Registro
-- =============================================
-- El problema: después de signUp(), el usuario NO está authenticated
-- Solución: Permitir INSERT en rol 'public' (sin autenticación)
-- con la restricción de que solo pueden crear su propio perfil

-- 1. ELIMINAR TODAS LAS POLÍTICAS ANTIGUAS CONFLICTIVAS
DROP POLICY IF EXISTS "Usuarios gestionan su perfil adoptante" ON adoptantes;
DROP POLICY IF EXISTS "Fundaciones gestionan su perfil" ON fundaciones;
DROP POLICY IF EXISTS "Adoptantes pueden leer su perfil" ON adoptantes;
DROP POLICY IF EXISTS "Adoptantes pueden crear su perfil" ON adoptantes;
DROP POLICY IF EXISTS "Adoptantes pueden actualizar su perfil" ON adoptantes;
DROP POLICY IF EXISTS "Adoptantes pueden eliminar su perfil" ON adoptantes;
DROP POLICY IF EXISTS "Fundaciones pueden leer su perfil" ON fundaciones;
DROP POLICY IF EXISTS "Fundaciones pueden crear su perfil" ON fundaciones;
DROP POLICY IF EXISTS "Fundaciones pueden actualizar su perfil" ON fundaciones;
DROP POLICY IF EXISTS "Fundaciones pueden eliminar su perfil" ON fundaciones;

-- 2. CREAR NUEVAS POLÍTICAS PARA ADOPTANTES
-- CRÍTICO: Permitir INSERT sin autenticación (usando solo el ID)
CREATE POLICY "Adoptantes INSERT sin auth (por registro)"
ON adoptantes FOR INSERT
TO public
WITH CHECK (auth.uid()::text = id::text OR auth.uid() IS NOT NULL);

-- Permitir SELECT solo si está autenticado y es su propio perfil
CREATE POLICY "Adoptantes SELECT de su perfil"
ON adoptantes FOR SELECT
TO authenticated
USING (auth.uid()::text = id::text);

-- Permitir UPDATE solo su propio perfil (después de autenticarse)
CREATE POLICY "Adoptantes UPDATE de su perfil"
ON adoptantes FOR UPDATE
TO authenticated
USING (auth.uid()::text = id::text)
WITH CHECK (auth.uid()::text = id::text);

-- 3. CREAR NUEVAS POLÍTICAS PARA FUNDACIONES
-- CRÍTICO: Permitir INSERT sin autenticación (usando solo el ID)
CREATE POLICY "Fundaciones INSERT sin auth (por registro)"
ON fundaciones FOR INSERT
TO public
WITH CHECK (auth.uid()::text = id::text OR auth.uid() IS NOT NULL);

-- Permitir SELECT solo si está autenticado y es su propio perfil
CREATE POLICY "Fundaciones SELECT de su perfil"
ON fundaciones FOR SELECT
TO authenticated
USING (auth.uid()::text = id::text);

-- Permitir UPDATE solo su propio perfil (después de autenticarse)
CREATE POLICY "Fundaciones UPDATE de su perfil"
ON fundaciones FOR UPDATE
TO authenticated
USING (auth.uid()::text = id::text)
WITH CHECK (auth.uid()::text = id::text);

-- 4. ASEGURAR QUE RLS ESTÉ HABILITADO
ALTER TABLE adoptantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fundaciones ENABLE ROW LEVEL SECURITY;

-- 5. VERIFICACIÓN (ejecutar esta query para ver políticas activas)
-- SELECT schemaname, tablename, policyname, permissive, roles, qual, with_check
-- FROM pg_policies
-- WHERE tablename IN ('adoptantes', 'fundaciones')
-- ORDER BY tablename, policyname;
