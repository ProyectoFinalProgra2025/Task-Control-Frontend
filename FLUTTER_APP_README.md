# TaskControl Flutter App

## 🚀 Descripción

Aplicación móvil Flutter para gestión de tareas empresariales conectada al backend de TaskControl. La aplicación incluye autenticación completa, onboarding, y pantallas diferenciadas según el rol del usuario.

## ✨ Características Implementadas

### 🔐 Autenticación
- **Login**: Autenticación con backend real en `localhost:5080`
- **Registro de Empresas**: Formulario completo para solicitar registro de empresas
- **Gestión de Tokens**: Almacenamiento seguro de Access Token y Refresh Token
- **Persistencia de Sesión**: Los usuarios permanecen logueados entre sesiones

### 🎯 Onboarding
- Secuencia de 4 pantallas informativas
- Botón "Saltar" para ir directo al login
- Se muestra solo una vez (primera vez que se abre la app sin credenciales)

### 👥 Arquitectura Basada en Roles
La aplicación detecta el rol del usuario y muestra diferentes interfaces:

#### Admin General
- Gestión de empresas
- Gestión de usuarios
- Estadísticas globales
- Configuración del sistema

#### Admin Empresa
- Gestión de tareas de la empresa
- Gestión de trabajadores
- Estadísticas de empresa
- Perfil de la empresa

#### Usuario (Trabajador)
- Vista de tareas asignadas
- Tareas pendientes, en progreso y completadas
- Perfil personal

## 📋 Requisitos Previos

1. **Flutter SDK** instalado (versión 3.9.2 o superior)
2. **Backend TaskControl** ejecutándose en `http://localhost:5080`
3. Emulador Android/iOS o dispositivo físico configurado

## 🛠️ Instalación y Configuración

### 1. Instalar Dependencias

```bash
cd Task-Control-Frontend
flutter pub get
```

### 2. Iniciar el Backend

Asegúrate de que el backend esté ejecutándose en el puerto 5080:

```bash
cd Task-Control-Backend
dotnet run
```

Verifica que el backend responda en: `http://localhost:5080`

### 3. Ejecutar la Aplicación

```bash
flutter run
```

O selecciona un dispositivo específico:

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en un dispositivo específico
flutter run -d <device-id>
```

## 📱 Flujo de Navegación

### Primera Vez (Sin Credenciales Guardadas)
```
Splash Screen → Onboarding (4 screens) → Login
                     ↓ (Skip)
                    Login
```

### Con Credenciales Guardadas
```
Splash Screen → Home (según rol del usuario)
```

### Después del Onboarding
```
Splash Screen → Login → Home (según rol)
```

## 🔑 Credenciales de Prueba

Para probar la aplicación necesitas crear usuarios en el backend o usar credenciales existentes.

### Registro de Empresa
1. Ir a "Registrarse" desde el login
2. Completar formulario con datos del administrador y empresa
3. La solicitud quedará en estado "Pending"
4. Un Admin General debe aprobar la empresa desde el dashboard web
5. Una vez aprobada, usar las credenciales para login

### Admin General
Debe ser creado directamente en el backend o a través del endpoint específico.

## 🌐 Configuración del API

La URL del API está configurada en `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:5080';
```

### Para Producción
Cuando despliegues a producción, actualiza la URL:

```dart
static const String baseUrl = 'https://tu-dominio.com';
```

### Para Testing con Dispositivo Físico
Si pruebas en un dispositivo físico en la misma red, usa la IP local:

```dart
static const String baseUrl = 'http://192.168.1.XXX:5080';
```

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                      # Punto de entrada, lógica de navegación inicial
├── config/
│   └── api_config.dart           # Configuración de endpoints y URLs
├── models/
│   ├── user_model.dart           # Modelo de usuario
│   └── auth_response.dart        # Modelo de respuesta de autenticación
├── services/
│   ├── auth_service.dart         # Servicio de autenticación (login, register, logout)
│   └── storage_service.dart      # Almacenamiento local (tokens, preferences)
└── screens/
    ├── splash_screen.dart        # Pantalla de carga inicial
    ├── onboarding_screen.dart    # Secuencia de onboarding (4 pages)
    ├── login_screen.dart         # Pantalla de inicio de sesión
    ├── signup_screen.dart        # Registro de empresas
    └── home_screen.dart          # Home adaptativo según rol
```

## 🎨 Paleta de Colores

La aplicación usa una paleta de colores moderna:

- **Primary (Indigo)**: `#4F46E5`
- **Secondary (Purple)**: `#7C3AED`
- **Accent (Pink)**: `#EC4899`
- **Warning (Amber)**: `#F59E0B`

## 🔧 Endpoints Utilizados

### Autenticación
- `POST /api/Auth/login` - Iniciar sesión
- `POST /api/Auth/refresh` - Renovar token
- `POST /api/Auth/logout` - Cerrar sesión
- `POST /api/Auth/register-adminempresa` - Registro de empresa

### Empresas (próximamente)
- `GET /api/Empresas` - Listar empresas
- `GET /api/Empresas/{id}` - Obtener empresa

### Tareas (próximamente)
- `GET /api/Tareas` - Listar tareas
- `POST /api/Tareas` - Crear tarea
- `PUT /api/Tareas/{id}` - Actualizar tarea

### Usuarios (próximamente)
- `GET /api/Usuarios` - Listar usuarios
- `POST /api/Usuarios` - Crear usuario

## 🐛 Solución de Problemas

### Error: "No se pudo conectar al servidor"
- Verifica que el backend esté ejecutándose
- Confirma la URL en `api_config.dart`
- Si usas dispositivo físico, usa la IP local en lugar de localhost

### Error: "Credenciales incorrectas"
- Verifica que la empresa esté aprobada (estado "Active")
- Confirma que el email y contraseña sean correctos
- Revisa los logs del backend para más detalles

### Onboarding se muestra en cada inicio
- Verifica que `shared_preferences` esté instalado correctamente
- Limpia la caché de la app y reinstala

### Errores de compilación
```bash
flutter clean
flutter pub get
flutter run
```

## 🚧 Próximas Funcionalidades

- [ ] Gestión completa de tareas
- [ ] Dashboard de estadísticas con gráficos
- [ ] Notificaciones push
- [ ] Chat entre usuarios
- [ ] Sistema de capacidades y asignación inteligente
- [ ] Filtros avanzados y búsqueda
- [ ] Modo offline con sincronización
- [ ] Tema oscuro

## 📝 Notas Importantes

### Registro de Empresas
El registro desde la app móvil **SIEMPRE** es para empresas. Los usuarios regulares son creados por las empresas desde su dashboard web. El flujo es:

1. Empresa se registra desde la app móvil
2. Admin General aprueba la empresa desde el dashboard web
3. Empresa inicia sesión en la app móvil
4. Empresa crea usuarios trabajadores desde el dashboard web
5. Usuarios trabajadores inician sesión en la app móvil

### Manejo de Sesión
- Los tokens se guardan automáticamente al hacer login
- La sesión persiste entre reinicios de la app
- El token se renueva automáticamente cuando expira
- Al cerrar sesión se eliminan todos los datos locales

## 📄 Licencia

Este proyecto es parte del sistema TaskControl para gestión empresarial de tareas.

---

**Desarrollado con ❤️ usando Flutter y ASP.NET Core**
