# 🧪 Guía de Pruebas - TaskControl Flutter App

## 📝 Preparación

### 1. Iniciar el Backend
```bash
cd Task-Control-Backend
dotnet run
```

Deberías ver algo como:
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5080
```

### 2. Verificar Backend
Abre en tu navegador: `http://localhost:5080/`

### 3. Crear un Admin General (Primera vez)

Si no existe un Admin General en la base de datos, puedes crear uno usando el endpoint:

**Opción 1: Usando curl**
```bash
curl -X POST http://localhost:5080/api/Auth/register-admingeneral \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@taskcontrol.com",
    "password": "Admin123!@#",
    "nombreCompleto": "Administrador General"
  }'
```

**Opción 2: Usando Postman o Thunder Client**
```json
POST http://localhost:5080/api/Auth/register-admingeneral

Body (JSON):
{
  "email": "admin@taskcontrol.com",
  "password": "Admin123!@#",
  "nombreCompleto": "Administrador General"
}
```

## 🎯 Escenarios de Prueba

### Escenario 1: Primera Instalación (Onboarding)

**Objetivo**: Verificar flujo de onboarding para nuevos usuarios

**Pasos**:
1. Asegúrate de no tener la app instalada (o limpia datos)
2. Ejecuta `flutter run`
3. Verifica el Splash Screen (2 segundos)
4. Deberías ver el Onboarding (4 pantallas)
5. Desliza hacia la derecha para ver todas las screens
6. En cualquier momento puedes presionar "Saltar"
7. Deberías llegar a la pantalla de Login

**Resultado esperado**: ✅ Se muestra onboarding y luego login

---

### Escenario 2: Registro de Empresa

**Objetivo**: Registrar una nueva empresa en el sistema

**Pasos**:
1. Desde el login, presiona "¿No tienes cuenta? Regístrate"
2. Deberías ver el formulario de registro de empresa
3. Lee la descripción informativa
4. Completa los campos:

   **Datos del Administrador:**
   - Nombre Completo: `Juan Pérez`
   - Correo: `juan@miempresa.com`
   - Teléfono: `555-1234` (opcional)
   - Contraseña: `MiPassword123!`
   - Confirmar Contraseña: `MiPassword123!`

   **Datos de la Empresa:**
   - Nombre de la Empresa: `Mi Empresa S.A.`
   - Dirección: `Calle Principal 123` (opcional)
   - Teléfono Empresa: `555-5678` (opcional)

5. Presiona "Enviar Solicitud"
6. Deberías ver un diálogo de éxito
7. Presiona "Entendido"
8. Deberías volver al login

**Resultado esperado**: ✅ Empresa registrada con estado "Pending"

**Verificar en Backend**: 
```sql
SELECT * FROM Empresas WHERE Nombre = 'Mi Empresa S.A.';
-- Estado debería ser 'Pending'
```

---

### Escenario 3: Aprobar Empresa (Backend)

**Objetivo**: Aprobar la empresa desde el dashboard web o manualmente

**Opción A: Dashboard Web**
1. Ve a `LANDING-AND-INTRODUCER-TASKCONTROL`
2. Inicia sesión como Admin General
3. Aprueba la empresa

**Opción B: Manualmente en BD**
```sql
UPDATE Empresas 
SET Estado = 1 -- Active = 1, Pending = 0, Rejected = 2
WHERE Nombre = 'Mi Empresa S.A.';
```

**Opción C: API Call**
```bash
# Primero login como admin
curl -X POST http://localhost:5080/api/Auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@taskcontrol.com",
    "password": "Admin123!@#"
  }'

# Copiar el accessToken de la respuesta

# Aprobar empresa (ID 1 por ejemplo)
curl -X PUT http://localhost:5080/api/Empresas/1/estado \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TU_ACCESS_TOKEN}" \
  -d '{"estado": 1}'
```

---

### Escenario 4: Login como Admin de Empresa

**Objetivo**: Iniciar sesión con cuenta de empresa aprobada

**Pasos**:
1. En la pantalla de login, ingresa:
   - Email: `juan@miempresa.com`
   - Contraseña: `MiPassword123!`
2. Presiona "Iniciar sesión"
3. Deberías ver un mensaje "Bienvenido, Juan Pérez!"
4. La app te lleva al Home de Admin Empresa

**Resultado esperado**: ✅ Login exitoso, home con opciones de empresa

**Home debe mostrar**:
- Tarjeta de bienvenida con nombre y rol
- 4 Cards: Tareas, Trabajadores, Estadísticas, Mi Empresa
- AppBar con nombre de empresa

---

### Escenario 5: Login como Admin General

**Objetivo**: Iniciar sesión con cuenta de admin general

**Pasos**:
1. Cierra sesión si estás logueado
2. En login, ingresa:
   - Email: `admin@taskcontrol.com`
   - Contraseña: `Admin123!@#`
3. Presiona "Iniciar sesión"
4. Deberías ver el Home de Admin General

**Resultado esperado**: ✅ Home con panel de administración global

**Home debe mostrar**:
- Tarjeta de bienvenida con "Administrador General"
- 4 Cards: Empresas, Usuarios, Estadísticas, Configuración
- AppBar "TaskControl - Admin General"

---

### Escenario 6: Persistencia de Sesión

**Objetivo**: Verificar que la sesión persiste al cerrar la app

**Pasos**:
1. Inicia sesión con cualquier usuario
2. Cierra completamente la app (no solo minimize)
3. Vuelve a abrir la app
4. Deberías ir directamente al Home (sin login)

**Resultado esperado**: ✅ Sesión persistida, no se pide login nuevamente

---

### Escenario 7: Cerrar Sesión

**Objetivo**: Verificar que el logout funciona correctamente

**Pasos**:
1. Desde cualquier Home, presiona el ícono de logout en el AppBar
2. Confirma en el diálogo
3. Deberías volver al login
4. Verifica que no puedas volver atrás con el botón back

**Resultado esperado**: ✅ Sesión cerrada, datos eliminados

**Verificar**:
- Cierra la app y abre de nuevo
- Deberías ver el Login (no el Home)
- El onboarding NO debería mostrarse (ya se completó antes)

---

### Escenario 8: Crear Usuario Trabajador (Desde Dashboard Web)

**Objetivo**: Crear un trabajador para probar el Home de Usuario

**Usando API**:
```bash
# Login como admin de empresa
curl -X POST http://localhost:5080/api/Auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "juan@miempresa.com",
    "password": "MiPassword123!"
  }'

# Copiar accessToken

# Crear trabajador
curl -X POST http://localhost:5080/api/Usuarios \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TU_ACCESS_TOKEN}" \
  -d '{
    "email": "trabajador@miempresa.com",
    "password": "Trabajo123!",
    "nombreCompleto": "María García",
    "telefono": "555-9999",
    "rol": "Usuario"
  }'
```

---

### Escenario 9: Login como Trabajador

**Objetivo**: Iniciar sesión como usuario trabajador

**Pasos**:
1. Cierra sesión si estás logueado
2. En login, ingresa:
   - Email: `trabajador@miempresa.com`
   - Contraseña: `Trabajo123!`
3. Presiona "Iniciar sesión"
4. Deberías ver el Home de Usuario

**Resultado esperado**: ✅ Home con vista de trabajador

**Home debe mostrar**:
- Tarjeta de bienvenida con "Trabajador"
- 4 Cards: Tareas Pendientes, En Progreso, Completadas, Mi Perfil
- AppBar "TaskControl - Mis Tareas"

---

## ❌ Pruebas de Error

### Error 1: Login con Empresa Pending

**Pasos**:
1. Registra una empresa nueva
2. NO la apruebes
3. Intenta hacer login con esas credenciales

**Resultado esperado**: ❌ Error "Credenciales incorrectas" (empresa no activa)

---

### Error 2: Login con Credenciales Incorrectas

**Pasos**:
1. Ingresa email correcto pero password incorrecto
2. Presiona "Iniciar sesión"

**Resultado esperado**: ❌ "Credenciales incorrectas"

---

### Error 3: Backend No Disponible

**Pasos**:
1. Detén el backend (`Ctrl+C` en la terminal del backend)
2. Intenta hacer login

**Resultado esperado**: ❌ "No se pudo conectar al servidor. Verifica que el backend esté ejecutándose."

---

### Error 4: Validaciones de Formulario

**Registro de Empresa**:
- Email inválido: "Correo inválido"
- Contraseña < 8 caracteres: "Mínimo 8 caracteres"
- Contraseñas no coinciden: "Las contraseñas no coinciden"
- Campos vacíos: Mostrar error en cada campo

---

## 📊 Checklist de Funcionalidades

### ✅ Autenticación
- [x] Login con backend real
- [x] Registro de empresas
- [x] Guardado de tokens (access + refresh)
- [x] Logout funcional
- [x] Manejo de errores

### ✅ Navegación
- [x] Splash screen
- [x] Onboarding (se muestra solo una vez)
- [x] Login persistente
- [x] Navegación basada en roles
- [x] Ruta inicial inteligente

### ✅ UI/UX
- [x] Diseño moderno y atractivo
- [x] Paleta de colores consistente
- [x] Indicadores de carga
- [x] Mensajes de error claros
- [x] Validaciones de formulario

### ✅ Seguridad
- [x] Contraseñas ocultas
- [x] Tokens guardados de forma segura
- [x] Sesión cerrada correctamente

---

## 🔍 Debugging

### Ver Logs de Flutter
```bash
flutter run --verbose
```

### Ver Logs del Backend
Los logs aparecen en la consola donde ejecutaste `dotnet run`

### Limpiar Cache de Flutter
```bash
flutter clean
flutter pub get
flutter run
```

### Limpiar Datos de la App (Android)
1. Ve a Configuración del dispositivo
2. Apps → TaskControl
3. Almacenamiento → Borrar datos
4. Vuelve a abrir la app

---

## 📝 Reportar Issues

Si encuentras problemas:

1. **Describe el problema**: ¿Qué esperabas vs qué sucedió?
2. **Pasos para reproducir**: Lista los pasos exactos
3. **Logs**: Incluye logs de Flutter y backend
4. **Entorno**: OS, versión de Flutter, dispositivo/emulador

---

**¡Happy Testing! 🎉**
