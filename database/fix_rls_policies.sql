-- =============================================
-- SOLUCIÓN: Políticas RLS actualizadas
-- =============================================
-- Ejecuta esto en el SQL Editor de Supabase para corregir el error

-- 1. ELIMINAR POLÍTICAS ANTIGUAS
DROP POLICY IF EXISTS "Usuarios gestionan su perfil adoptante" ON adoptantes;
DROP POLICY IF EXISTS "Fundaciones gestionan su perfil" ON fundaciones;

-- 2. CREAR NUEVAS POLÍTICAS PARA ADOPTANTES

-- Permitir SELECT (leer su propio perfil)
CREATE POLICY "Adoptantes pueden leer su perfil"
ON adoptantes FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Permitir INSERT (crear su perfil durante registro)
CREATE POLICY "Adoptantes pueden crear su perfil"
ON adoptantes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Permitir UPDATE (actualizar su propio perfil)
CREATE POLICY "Adoptantes pueden actualizar su perfil"
ON adoptantes FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Permitir DELETE (eliminar su propio perfil)
CREATE POLICY "Adoptantes pueden eliminar su perfil"
ON adoptantes FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- 3. CREAR NUEVAS POLÍTICAS PARA FUNDACIONES

-- Permitir SELECT (leer su propio perfil)
CREATE POLICY "Fundaciones pueden leer su perfil"
ON fundaciones FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Permitir INSERT (crear su perfil durante registro)
CREATE POLICY "Fundaciones pueden crear su perfil"
ON fundaciones FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Permitir UPDATE (actualizar su propio perfil)
CREATE POLICY "Fundaciones pueden actualizar su perfil"
ON fundaciones FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Permitir DELETE (eliminar su propio perfil)
CREATE POLICY "Fundaciones pueden eliminar su perfil"
ON fundaciones FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- 4. VERIFICAR QUE RLS ESTÉ HABILITADO
ALTER TABLE adoptantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fundaciones ENABLE ROW LEVEL SECURITY;

-- =============================================
-- OPCIONAL: Ver todas las políticas activas
-- =============================================
-- SELECT * FROM pg_policies WHERE tablename IN ('adoptantes', 'fundaciones');
