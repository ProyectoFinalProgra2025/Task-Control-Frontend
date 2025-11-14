# Task Control - Frontend

## 📱 Secuencia de Pantallas de Autenticación

Esta aplicación Flutter implementa un flujo completo de autenticación con las siguientes pantallas:

### 1. **Onboarding Screen** (Pantalla de Bienvenida)
- Diseño inspirado en ASANA
- Mensaje de bienvenida: "Let's Get You Set Up for Success"
- Botón "Get started" que lleva al Login
- Adaptado para móvil y desktop (responsive)
- En desktop, muestra el logo TaskControl

### 2. **Login Screen** (Pantalla de Inicio de Sesión)
- Fondo: `BackgroundAuthScreen.png`
- Campos de entrada:
  - Username
  - Password (con toggle para mostrar/ocultar)
- Checkbox "Remember Me"
- Enlace "Forgot Password?"
- Botones de login social (Apple y Google)
- Enlace para ir a Sign Up

#### 🔐 Credenciales de Prueba:
```
Username: mateo2208
Password: mateo123
```

### 3. **Sign Up Screen** (Pantalla de Registro)
- Fondo: `BackgroundAuthScreen.png`
- Campos de entrada:
  - Email
  - Password
  - Confirm Password
- Validaciones:
  - Email válido
  - Contraseña de mínimo 6 caracteres
  - Las contraseñas deben coincidir
- Checkbox "Remember Me"
- Botones de registro social (Apple y Google)
- Enlace para volver a Login

### 4. **Home Screen** (Dashboard)
- Aparece después de un login exitoso
- Muestra el nombre de usuario: "mateo2208"
- Estadísticas del dashboard:
  - Total de tareas
  - Proyectos
  - Tareas completadas
  - Tareas pendientes
- Lista de tareas recientes
- Botón de logout en la esquina superior derecha

## 🎨 Características de Diseño

- **Color Principal**: Cyan (#00BCD4)
- **Tipografía**: Google Fonts - Poppins
- **Responsive Design**: Adapta el layout automáticamente entre móvil y desktop
- **Desktop Mode**: Usa el logo `TaskControl - Logo.png`
- **Mobile Mode**: Usa ilustraciones y gradientes
- **Animaciones**: Loading states en botones

## 🚀 Cómo Ejecutar

1. Asegúrate de tener Flutter instalado
2. Instala las dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── screens/
│   ├── onboarding_screen.dart  # Pantalla de bienvenida
│   ├── login_screen.dart       # Pantalla de login
│   ├── signup_screen.dart      # Pantalla de registro
│   └── home_screen.dart        # Dashboard principal
├── widgets/                     # Widgets reutilizables (vacío por ahora)
└── models/                      # Modelos de datos (vacío por ahora)

assets/
├── BackgroundAuthScreen.png    # Fondo para login/signup
├── TaskControl - Logo.png      # Logo para desktop
└── TaskControlNoBackground.png # Logo alternativo
```

## ✨ Flujo de Usuario

1. **Inicio** → Usuario ve la pantalla de Onboarding
2. **Onboarding** → Click en "Get started" → Navega a Login
3. **Login** → Dos opciones:
   - Ingresar credenciales (mateo2208/mateo123) → Home Screen
   - Click en "Sign Up" → Sign Up Screen
4. **Sign Up** → Registrar cuenta → Redirección automática a Login
5. **Home** → Usuario puede hacer logout y volver al Login

## 🔧 Funcionalidades Implementadas

- ✅ Navegación entre pantallas
- ✅ Validación de formularios
- ✅ Autenticación simulada con datos hardcodeados
- ✅ Loading states
- ✅ Mensajes de error
- ✅ Diseño responsive (móvil y desktop)
- ✅ Toggle de visibilidad de contraseña
- ✅ Diálogo de confirmación de logout

## 📝 Notas

- Esta es una implementación **frontend only** con datos de prueba
- No hay conexión a backend real
- Las credenciales están hardcodeadas para pruebas
- Los botones de login social (Apple/Google) no están implementados funcionalmente

## 🔜 Próximos Pasos

- Integrar con backend real
- Implementar autenticación OAuth (Google/Apple)
- Agregar persistencia de sesión
- Implementar recuperación de contraseña
- Agregar más pantallas del dashboard
