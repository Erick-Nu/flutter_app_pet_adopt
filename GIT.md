 # 📋 Guía de Convención de Commits - Pet Adoption App

Mantener un historial de cambios legible y ordenado es fundamental para la colaboración en equipo. Esta guía sigue la especificación **Conventional Commits** adaptada a nuestro proyecto.

---

## 1️⃣ Estructura del Mensaje

Cada commit debe seguir esta estructura rigurosa:

```
[<tipo>][<alcance>]: <descripción corta>

[Cuerpo opcional: explicación más detallada del cambio]

[Footer opcional: referencias a issues, breaking changes, etc.]
```

### Ejemplo Completo:
```
[Feature][Pets]: agregar filtrado por categorías

- Permite filtrar mascotas por categoría
- Añade debounce para mejor performance
- Actualiza estado global de categorías seleccionadas

Closes #42
Breaking Change: API anterior de pets_service deprecada
```

---

## 2️⃣ Tipos de Commits (<tipo>)

| Tipo | Descripción | Ejemplo | Cuándo Usar |
|------|-------------|---------|------------|
| **Feature** | Nueva funcionalidad | `[Feature][Adoption]: agregar solicitud de adopción` | Añades una característica nueva |
| **Fix** | Solución a un bug | `[Fix][Pets]: corregir error en búsqueda` | Arreglas un error en producción |
| **Docs** | Cambios en documentación | `[Docs][Core]: actualizar guia de instalacion` | Modificas README, comentarios de código |
| **Style** | Formato, espacios, puntuación | `[Style][UI]: formatear codigo con dart fix` | Solo cambios de formato, sin lógica |
| **Refactor** | Reorganizar código sin cambiar funcionalidad | `[Refactor][Auth]: extraer logica validacion` | Mejoras calidad sin agregar features |
| **Performance** | Mejora de rendimiento | `[Performance][Pets]: optimizar lazy loading` | Optimizas velocidad o memoria |
| **Test** | Agregar o actualizar tests | `[Test][Adoption]: agregar unit tests` | Escribes/modificas pruebas |
| **Chore** | Configuración, dependencias, build | `[Chore][Deps]: actualizar flutter a 3.19` | Cambios que no afectan al código fuente |
| **CI** | Cambios en CI/CD | `[CI][GitHub]: configurar github actions` | Pipelines, workflows automáticos |
| **DB** | Cambios en base de datos | `[DB][Schema]: agregar tabla de solicitudes` | Migraciones, schemas, SQL |
| **Revert** | Revertir commit anterior | `[Revert][Pets]: revertir filtrado` | Deshacer un commit previo |

---

## 3️⃣ Alcance (<alcance>)

El alcance es **opcional pero RECOMENDADO**. Indica qué módulo o componente se modificó:

### Alcances Disponibles para Pet Adoption:

```
core          → Configuración general, widgets reutilizables, servicios base
auth          → Autenticación y autorización de usuarios
pets          → Catálogo de mascotas, búsqueda, filtros
favorites     → Mascotas favoritas, lista de deseos
adoption      → Proceso de adopción, solicitudes, estado
user          → Perfil de usuario, preferencias, mis adopciones
notifications → Notificaciones push, alertas de nuevas mascotas
shelter       → Información de refugios, detalles del albergue
payments      → Métodos de pago, tarifas de adopción
ui            → Componentes UI globales
assets        → Imágenes, fuentes, iconos
api           → Integración con backend
db            → Base de datos local (SQLite, Hive)
navigation    → Enrutamiento y navegación
maps          → Integración con mapas, ubicación de refugios
chat          → Chat con adoptadores o refugios
```

### Alcances Secundarios (cuando aplique):
```
feat(pets/search)     → Búsqueda dentro del módulo pets
fix(adoption/status)  → Error específico en estado de adopción
```

---

## 4️⃣ Reglas de la Descripción

### ✅ Debe:
- **Imperativo**: Usa modo imperativo como si le dieras orden al código
  - ✅ "agregar filtro por raza"
  - ❌ "agregado filtro por raza"
  - ❌ "agregué filtro por raza"

- **Minúsculas**: Comienza sin mayúscula
  - ✅ `[Feature][Pets]: agregar búsqueda`
  - ❌ `[Feature][Pets]: Agregar búsqueda`

- **Sin punto final**: No terminies con punto
  - ✅ `[Fix][Adoption]: corregir validacion de formulario`
  - ❌ `[Fix][Adoption]: corregir validacion de formulario.`

- **Conciso**: Máximo 72 caracteres en la primera línea
  - ✅ `[Feature][Adoption]: agregar solicitud de adopción`
  - ❌ `[Feature][Adoption]: agregar funcionalidad que permite a los usuarios solicitar la adopción de mascotas de forma rápida y sencilla`

- **Específico**: Sé claro sobre qué cambia
  - ✅ `[Fix][Pets]: resolver duplicación en lista de mascotas`
  - ❌ `[Fix][Core]: corregir error`

### ❌ No Debe:
- Usar jerga o código sin contexto
- Cambiar múltiples cosas sin relación en un commit
- Escribir en primera persona

---

## 5️⃣ Cuerpo del Commit (Opcional pero Recomendado)

Usa el cuerpo para explicar **QUÉ cambió y POR QUÉ**, no el CÓMO.

### ✅ Buen Cuerpo:
```
[Feature][Pets]: agregar filtrado dinámico por rango de edad

- Los usuarios pueden filtrar mascotas entre edad mínima y máxima
- Se usa RangeSlider con valores precargados según disponibilidad
- El filtrado se aplica en tiempo real con debounce de 300ms
- Mejora experiencia cuando hay >200 mascotas en catálogo

Closes #89
```

### ❌ Mal Cuerpo:
```
[Feature][Pets]: agregar filtrado

Cambié el código de pets.
```

---

## 6️⃣ Breaking Changes

Si tu cambio rompe compatibilidad hacia atrás, **debes indicarlo claramente**:

```
[Feature][API]: cambiar estructura de respuesta de mascotas

BREAKING CHANGE: La respuesta de /pets ahora usa 'petId' en lugar de 'id'
- Migra código cliente para usar: pet.petId
- El antiguo campo 'id' será removido en v2.0
```

O más simple en commits sin cuerpo:
```
[Feature!][API]: cambiar estructura de respuesta
```

---

## 7️⃣ Ejemplos Prácticos para Pet Adoption

### Scenario 1: Nueva Feature - Filtrado Avanzado de Mascotas
```bash
[Feature][Pets]: agregar filtrado por edad, raza y tamaño

- Usuarios pueden filtrar mascotas disponibles por edad, raza, tamaño
- Se usa MultiSelectFilter con opciones precargadas según disponibilidad
- El filtrado se aplica en tiempo real con debounce de 300ms
- Mejora experiencia cuando hay >200 mascotas en catálogo

Closes #42
```

### Scenario 2: Bug en Solicitud de Adopción
```bash
[Fix][Adoption]: resolver error al enviar solicitud

El problema ocurría cuando el usuario enviaba la solicitud muy rápido.
Se agregó debounce a las solicitudes y validación de datos antes de enviar.

Closes #203
```

### Scenario 3: Optimización de Imágenes de Mascotas
```bash
[Performance][Pets]: optimizar carga de imágenes de catálogo

- Usar lazy loading para imágenes fuera de viewport
- Comprimir a WebP formato con fallback a PNG
- Cache local de imágenes durante 30 días
- Reduce tiempo carga inicial de 2.5s a 1.2s
```

### Scenario 4: Refactoring de Validación de Solicitud
```bash
[Refactor][Adoption]: extraer lógica de validación a servicio

- Centraliza validaciones de formulario de adopción
- Mejor testabilidad de reglas de negocio
- Reutilizable en validación cliente y servidor
```

### Scenario 5: Tests para Búsqueda de Mascotas
```bash
[Test][Pets]: agregar unit tests para PetSearchService

- Test para búsqueda por nombre
- Test para filtrado por múltiples criterios
- Test para búsqueda vacía y resultados no encontrados
- Cobertura: 92%
```

### Scenario 6: Actualización de Dependencias
```bash
[Chore][Deps]: actualizar flutter a 3.19 y dart a 3.3

- Implementa latest Flutter security patches
- Mejora compilación en dispositivos M1/M2
- Requiere mínimo Xcode 15.1 en iOS
```

### Scenario 7: Cambios en Base de Datos
```bash
[DB][Schema]: crear tabla de solicitudes de adopción

- Tabla adoption_requests con campos: id, user_id, pet_id, status, created_at
- Implementar RLS policy para que usuarios vean solo sus solicitudes
- Crear índices en user_id y pet_id para performance
```

### Scenario 8: Configurar Pipeline CI/CD
```bash
[CI][GitHub]: agregar github actions para testing automático

- Ejecuta tests en cada push a main
- Genera reporte de cobertura con codecov
- Previene merge si coverage cae <80%
```

---

## 8️⃣ Gitmoji (Opcional pero Visual)

Si prefieres añadir emojis para identificar cambios visualmente:

| Emoji | Código | Tipo |
|-------|--------|------|
| ✨ | `:sparkles:` | Nueva feature |
| 🐛 | `:bug:` | Bug fix |
| 📚 | `:books:` o `:memo:` | Documentación |
| 💄 | `:lipstick:` | Cambios UI/style |
| ♻️ | `:recycle:` | Refactoring |
| ⚡ | `:zap:` | Mejora performance |
| ✅ | `:white_check_mark:` | Tests |
| 🔧 | `:wrench:` | Configuración |
| 🗃️ | `:card_file_box:` | Base de datos |
| 🚀 | `:rocket:` | Deployment |

### Ejemplo con Emoji:
```bash
git commit -m "✨ [Feature][Pets]: agregar búsqueda fuzzy"
git commit -m "🐛 [Fix][Auth]: corregir error en login"
git commit -m "📚 [Docs][Core]: actualizar instrucciones"
```

---

## 9️⃣ Comandos Git Útiles

### Ver histórico de commits formateado:
```bash
# Ver últimos 10 commits con resumen
git log --oneline -10

# Ver log con colores y estructura
git log --all --graph --decorate --oneline

# Crear alias (añade a ~/.gitconfig)
git config --global alias.logs 'log --graph --oneline --all --decorate'
```

### Amend (corregir último commit sin crear nuevo):
```bash
# Cambiar mensaje del último commit
git commit --amend -m "[Feature][Pets]: mensaje corregido"

# Agregar cambios al último commit
git add .
git commit --amend --no-edit
```

### Revert (deshacer commit de forma segura):
```bash
git revert <commit-hash>
```

---

## 🔟 Errores Comunes a Evitar

| ❌ Incorrecto | ✅ Correcto | Razón |
|---|---|---|
| `[Feature]: agregar muchas cosas` | `[Feature][Pets]: agregar filtro` | Siempre incluir alcance |
| `[feature][pets]: agregar filtro` | `[Feature][Pets]: agregar filtro` | Tipo y alcance en mayúsculas |
| `[Fix][Adoption]: arreglé el bug.` | `[Fix][Adoption]: corregir error` | Sin punto, imperativo |
| `[Update][Core]: stuff` | `[Refactor][Core]: simplificar validación` | Descriptivo y específico |
| `[WIP][Pets]: trabajo en progreso` | Commit solo cuando esté listo | Mantén historia limpia |

---

## 1️⃣1️⃣ Flujo de Trabajo Recomendado

```bash
# 1. Crear rama feature
git checkout -b feat/agregar-filtros-mascotas

# 2. Hacer cambios y commitear con buena convención
git add .
git commit -m "[Feature][Pets]: agregar filtro por raza"
git commit -m "[Style][Pets]: formatear código de filtros"

# 3. Antes de push, revisar commits
git log origin/main..HEAD --oneline

# 4. Push a rama feature
git push origin feat/agregar-filtros-mascotas

# 5. Crear Pull Request en GitHub
# → Título PR también debe seguir convención
# → Descripción explica QUÉ y POR QUÉ

# 6. Una vez aprobado, hacer squash merge o merge directo
git checkout main
git pull origin main
git merge --ff-only feat/agregar-filtros-mascotas
# O desde GitHub si prefieres
```

---

## 1️⃣2️⃣ Configurar Editor de Commits

Para asegurar que escribes buenos commits, puedes configurar un editor:

```bash
# Usar VS Code como editor de commits
git config --global core.editor "code --wait"

# Usar Vim (por defecto)
git config --global core.editor "vim"
```

---

## 1️⃣3️⃣ Herramientas Útiles

### Commitizen (CLI interactivo)
```bash
npm install -g commitizen cz-conventional-changelog
cz commit  # En lugar de git commit
```

### Husky + Commit-lint (Validación automática)
```bash
npm install -D husky @commitlint/config-conventional @commitlint/cli
npx husky install
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
```

---

## 1️⃣4️⃣ Primer Commit del Proyecto

Cuando inicies el proyecto:

```bash
git add .
git commit -m "chore(init): inicializar proyecto pet adoption con clean architecture"
git push origin main
```

---

## Resumen Rápido

- 📌 **Tipo**: Feature, Fix, Docs, Style, Refactor, Performance, Test, Chore, CI, DB, Revert
- 🎯 **Formato**: `[Tipo][Alcance]: descripción`
- 📝 **Máximo 72 caracteres** en título
- 💬 **Usa imperativo** (agregar, no agregado)
- 🔤 **Minúsculas en descripción**
- ✋ **Sin punto final**
- 💡 **Un commit = Un cambio**
- 📚 **Cuerpo explica QUÉ y POR QUÉ**

¡Commits claros = Código feliz! 🚀