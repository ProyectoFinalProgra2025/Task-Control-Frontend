# 🛠️ Comandos Útiles - TaskControl Flutter

## 📱 Comandos de Flutter

### Instalación y Configuración
```bash
# Instalar dependencias
flutter pub get

# Limpiar cache y reinstalar
flutter clean
flutter pub get

# Ver versión de Flutter
flutter --version

# Ver doctor (verificar instalación)
flutter doctor
flutter doctor -v
```

### Ejecución
```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device-id>
flutter run -d windows
flutter run -d chrome
flutter run -d emulator-5554

# Ejecutar con logs detallados
flutter run --verbose

# Hot reload (durante ejecución)
# Presionar 'r' en la terminal

# Hot restart (durante ejecución)
# Presionar 'R' en la terminal
```

### Build
```bash
# Build APK (Android)
flutter build apk
flutter build apk --release
flutter build apk --split-per-abi

# Build App Bundle (Android)
flutter build appbundle

# Build iOS (requiere Mac)
flutter build ios

# Build Web
flutter build web
```

### Testing
```bash
# Ejecutar tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage

# Ejecutar test específico
flutter test test/widget_test.dart
```

### Análisis y Formato
```bash
# Analizar código
flutter analyze

# Formatear código
flutter format .
flutter format lib/
```

### Manejo de Paquetes
```bash
# Actualizar dependencias
flutter pub upgrade

# Ver dependencias desactualizadas
flutter pub outdated

# Agregar paquete
flutter pub add <package_name>
flutter pub add http
flutter pub add provider

# Remover paquete
flutter pub remove <package_name>
```

---

## 🖥️ Comandos del Backend (.NET)

### Desarrollo
```bash
# Ejecutar en modo desarrollo
cd Task-Control-Backend
dotnet run

# Ejecutar con hot reload
dotnet watch run

# Ejecutar en puerto específico
dotnet run --urls "http://localhost:5080"
```

### Build y Publicación
```bash
# Build
dotnet build

# Build en Release
dotnet build --configuration Release

# Publicar
dotnet publish -c Release -o ./publish
```

### Base de Datos
```bash
# Crear migración
dotnet ef migrations add <NombreMigracion>

# Aplicar migraciones
dotnet ef database update

# Revertir migración
dotnet ef database update <MigracionAnterior>

# Eliminar última migración
dotnet ef migrations remove

# Ver migraciones
dotnet ef migrations list
```

### Gestión de Paquetes
```bash
# Agregar paquete
dotnet add package <NombrePaquete>

# Remover paquete
dotnet remove package <NombrePaquete>

# Restaurar paquetes
dotnet restore

# Ver paquetes instalados
dotnet list package
```

---

## 🐛 Debugging

### Flutter Logs
```bash
# Ver logs en tiempo real
flutter logs

# Ver logs con filtro
flutter logs --verbose

# Limpiar logs
flutter logs --clear
```

### Android Logs (ADB)
```bash
# Ver logs de Android
adb logcat

# Ver logs de app específica
adb logcat | grep flutter

# Limpiar logs
adb logcat -c
```

### Inspeccionar App
```bash
# Abrir DevTools
flutter pub global activate devtools
flutter pub global run devtools

# O durante ejecución
# Presionar 'w' en la terminal
```

---

## 📦 Gestión de Dependencias

### Flutter pubspec.yaml
```yaml
dependencies:
  # HTTP requests
  http: ^1.1.0
  
  # Local storage
  shared_preferences: ^2.2.2
  
  # Page indicators
  smooth_page_indicator: ^1.1.0
  
  # State management
  provider: ^6.1.1
  
  # JSON serialization
  json_annotation: ^4.8.1

dev_dependencies:
  # JSON code generation
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

### Generar código (json_serializable)
```bash
# Una vez
flutter pub run build_runner build

# Modo watch
flutter pub run build_runner watch

# Limpiar y regenerar
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🧹 Limpieza

### Flutter
```bash
# Limpiar build
flutter clean

# Limpiar pub cache
flutter pub cache clean

# Limpiar todo
flutter clean
rm -rf .dart_tool
rm pubspec.lock
flutter pub get
```

### Android
```bash
# Limpiar Gradle cache
cd android
./gradlew clean

# Invalidar caches (desde Android Studio)
# File > Invalidate Caches / Restart
```

---

## 🔧 Configuración

### Cambiar nombre de la app
```yaml
# pubspec.yaml
name: task_control_frontend

# android/app/src/main/AndroidManifest.xml
android:label="TaskControl"

# ios/Runner/Info.plist
<key>CFBundleName</key>
<string>TaskControl</string>
```

### Cambiar package name (Android)
```bash
# Usar flutter_rename package
flutter pub global activate rename
flutter pub global run rename --bundleId com.taskcontrol.app
```

### Cambiar íconos
```bash
# Instalar flutter_launcher_icons
flutter pub add --dev flutter_launcher_icons

# Configurar en pubspec.yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"

# Generar íconos
flutter pub run flutter_launcher_icons
```

---

## 🌐 API Testing

### curl Commands
```bash
# Login
curl -X POST http://localhost:5080/api/Auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Registrar empresa
curl -X POST http://localhost:5080/api/Auth/register-adminempresa \
  -H "Content-Type: application/json" \
  -d '{
    "email":"admin@empresa.com",
    "password":"Password123!",
    "nombreCompleto":"Admin Empresa",
    "nombreEmpresa":"Mi Empresa"
  }'

# Request con token
curl -X GET http://localhost:5080/api/Tareas \
  -H "Authorization: Bearer {TOKEN}"
```

---

## 📊 Performance

### Análisis de rendimiento
```bash
# Profile mode
flutter run --profile

# Análisis de tamaño
flutter build apk --analyze-size
flutter build appbundle --analyze-size

# Trace startup time
flutter run --trace-startup --profile
```

---

## 🚀 Deployment

### Android
```bash
# Generar keystore
keytool -genkey -v -keystore ~/taskcontrol.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias taskcontrol

# Build release APK
flutter build apk --release

# Build release App Bundle
flutter build appbundle --release
```

### iOS (requiere Mac)
```bash
# Build
flutter build ios --release

# Abrir en Xcode
open ios/Runner.xcworkspace
```

### Web
```bash
# Build
flutter build web --release

# Servir localmente
cd build/web
python -m http.server 8000
```

---

## 🔍 Útiles para Desarrollo

### Snippets VS Code

**Crear StatelessWidget**
```dart
stl + Tab
```

**Crear StatefulWidget**
```dart
stf + Tab
```

### Atajos de Teclado (VS Code)
```
Ctrl + Shift + P   - Command Palette
Ctrl + Space       - IntelliSense
Alt + Shift + F    - Format Document
F5                 - Start Debugging
Shift + F5         - Stop Debugging
Ctrl + F5          - Run Without Debugging
```

---

## 📝 Git Commands

```bash
# Estado
git status

# Ver cambios
git diff

# Agregar cambios
git add .
git add lib/screens/login_screen.dart

# Commit
git commit -m "feat: implementar autenticación con backend"

# Push
git push origin main

# Pull
git pull origin main

# Ver logs
git log --oneline
```

---

## 💡 Tips

### Flutter DevTools en navegador
```bash
# Ejecutar app
flutter run

# En otra terminal
flutter pub global activate devtools
flutter pub global run devtools
```

### Verificar conexión a backend desde emulador
```bash
# Android Emulator usa 10.0.2.2 para localhost
# En api_config.dart:
static const String baseUrl = 'http://10.0.2.2:5080';

# iOS Simulator usa localhost directamente
static const String baseUrl = 'http://localhost:5080';
```

### Restart app completamente
```bash
# Durante ejecución, presiona:
# Shift + R
```

---

**Comandos actualizados: Noviembre 2025**
