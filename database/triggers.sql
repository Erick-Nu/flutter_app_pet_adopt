-- =============================================
-- TRIGGERS OPCIONALES PARA AUTOMATIZAR REGISTRO
-- =============================================
-- Estos triggers son OPCIONALES. El código Flutter ya funciona sin ellos
-- haciendo los INSERTs manualmente. Pero si prefieres automatizarlo en DB:

-- 1. Función para crear perfil automáticamente después del registro
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Verificar el tipo de usuario desde raw_user_meta_data
  IF NEW.raw_user_meta_data->>'type' = 'adoptante' THEN
    INSERT INTO public.adoptantes (id, nombre, cedula, telefono, sexo)
    VALUES (
      NEW.id,
      NEW.raw_user_meta_data->>'nombre',
      NEW.raw_user_meta_data->>'cedula',
      NEW.raw_user_meta_data->>'telefono',
      COALESCE(NEW.raw_user_meta_data->>'sexo', 'hombre')::user_sex_enum
    );
  ELSIF NEW.raw_user_meta_data->>'type' = 'fundacion' THEN
    INSERT INTO public.fundaciones (id, nombre, direccion, telefono)
    VALUES (
      NEW.id,
      NEW.raw_user_meta_data->>'nombre',
      NEW.raw_user_meta_data->>'direccion',
      NEW.raw_user_meta_data->>'telefono'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Crear el trigger en la tabla auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- NOTA: Si activas este trigger, debes MODIFICAR
-- el código Flutter para pasar los datos en 'data:'
-- durante el signUp, como estaba originalmente.
-- =============================================

-- Para usar este trigger, comenta los INSERTs manuales
-- en auth_remote_data_source.dart y descomenta la
-- parte que pasa 'data: { type: ..., nombre: ... }'
