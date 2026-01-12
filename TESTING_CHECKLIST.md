# Checklist de Testing - Validaciones de Formularios

## Registro de Adoptante

### Campo Cédula
- [ ] Intenta escribir 10 dígitos → Se bloquea en 11 automáticamente
- [ ] Intenta escribir más de 11 → No deja escribir, se queda en 11
- [ ] Escribe 11 números válidos → Pasa validación
- [ ] Escribe 10 números → Muestra error "debe tener exactamente 11 dígitos"
- [ ] Escribe letras o caracteres especiales → Muestra error "solo debe contener números"
- [ ] Intenta registrar con cédula ya existente → Muestra error "ya está registrado"

### Campo Teléfono
- [ ] Intenta escribir más de 10 dígitos → No deja escribir, se queda en 10
- [ ] Escribe 10 números válidos → Pasa validación
- [ ] Escribe 9 números → Muestra error "debe tener exactamente 10 dígitos"
- [ ] Escribe letras → Muestra error "solo debe contener números"

### Campo Email
- [ ] Intenta registrar con email válido y nuevo → Pasa
- [ ] Intenta registrar con email ya existente → Muestra error "correo ya registrado"
- [ ] Intenta registrar con email sin @ → Muestra error de formato

### Campo Contraseña
- [ ] Intenta registrar con < 8 caracteres → Muestra error "Mínimo 8 caracteres"

## Registro de Fundación

### Campo Teléfono
- [ ] Intenta escribir más de 10 dígitos → No deja escribir, se queda en 10
- [ ] Escribe 10 números válidos → Pasa validación
- [ ] Escribe 9 números → Muestra error "debe tener exactamente 10 dígitos"

### Campo Email
- [ ] Intenta registrar con email ya existente → Muestra error "correo ya registrado"

## Edición de Perfil de Adoptante

### Campo Teléfono
- [ ] Intenta escribir más de 10 dígitos → No deja escribir, se queda en 10
- [ ] Escribe 10 números válidos → Pasa validación
- [ ] Guarda con teléfono válido → Se actualiza correctamente

## Edición de Perfil de Fundación

### Campo Teléfono
- [ ] Intenta escribir más de 10 dígitos → No deja escribir, se queda en 10
- [ ] Escribe 10 números válidos → Pasa validación
- [ ] Guarda con teléfono válido → Se actualiza correctamente

## Mensajes de Error Esperados

### Para Cédula
- ❌ "La cédula es requerida" (vacío)
- ❌ "La cédula debe tener exactamente 11 dígitos" (11 < o > 11)
- ❌ "La cédula solo debe contener números" (letras/caracteres)
- ❌ "Este número de cédula ya está registrado." (duplicado)

### Para Teléfono
- ❌ "El teléfono es requerido" (vacío)
- ❌ "El teléfono debe tener exactamente 10 dígitos" (10 ≠ 10)
- ❌ "El teléfono solo debe contener números" (letras/caracteres)

### Para Email
- ❌ "El correo es requerido" (vacío)
- ❌ "Formato de correo inválido" (sin @)
- ❌ "Este correo electrónico ya está registrado." (duplicado)

## Verificaciones Adicionales

- [ ] Los contadores de caracteres no se muestran en los campos (counterText: '')
- [ ] El UI fluye correctamente sin el contador visible
- [ ] Los mensajes aparecen sin mostrar el contador
- [ ] La validación ocurre ANTES de enviar a la BD
- [ ] Si la BD no responde, no bloquea el registro (fallback seguro)
