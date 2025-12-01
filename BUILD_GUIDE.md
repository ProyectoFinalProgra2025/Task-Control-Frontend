# TaskControl - Guía de Construcción para Múltiples Plataformas

Esta guía te ayudará a construir TaskControl para Web, Android e iOS con todas las configuraciones correctas.

## 📋 Resumen de Configuración Actualizada

### ✅ Configuraciones Aplicadas

- **iOS**: Bundle ID `com.taskcontrol.app`, metadatos actualizados, permisos de red configurados
- **Android**: Ya configurado con iconos y metadatos correctos
- **Web**: Título actualizado, descripciones SEO, manifest.json configurado

## 🚀 Scripts de Construcción Disponibles

### 1. Generar Iconos para Todas las Plataformas

```powershell
.\generate_icons.ps1
```

Este script genera automáticamente todos los iconos necesarios desde `assets/images/TaskControl_logo.png`:

- **Android**: MDPI, HDPI, XHDPI, XXHDPI, XXXHDPI
- **iOS**: Todos los tamaños requeridos (20x20 hasta 1024x1024)
- **Web**: Favicon, iconos PWA (192x192, 512x512, maskables)

### 2. Construcción para iOS (Solo en macOS)

```powershell
.\build_ios_release.ps1
```

**Nota**: iOS solo se puede construir en macOS con Xcode instalado.

### 3. Construcción Completa Multi-Plataforma

```powershell
# Construir todas las plataformas
.\build_all_platforms.ps1

# Construir solo para web
.\build_all_platforms.ps1 -Platform web

# Construir solo para Android
.\build_all_platforms.ps1 -Platform android

# Construir en modo debug
.\build_all_platforms.ps1 -Mode debug

# Saltar generación de iconos
.\build_all_platforms.ps1 -SkipIconGeneration
```

## 📱 Configuración por Plataforma

### iOS Configuration

#### Metadatos Actualizados:
- **App Name**: TaskControl
- **Bundle ID**: `com.taskcontrol.app`
- **Permisos**: Cámara, galería, micrófono para evidencias
- **Configuración de red**: NSAppTransportSecurity configurado

#### Para crear IPA:
1. En macOS, ejecuta: `flutter build ios --release`
2. Abre `ios/Runner.xcworkspace` en Xcode
3. Configura tu Team ID en "Signing & Capabilities"
4. Selecciona "Product → Archive"
5. En Organizer: "Distribute App"

### Android Configuration

#### Ya está configurado con:
- **App Name**: TaskControl
- **Package**: Configuración existente
- **Iconos**: Todos los tamaños generados automáticamente
- **Permisos**: Internet y estado de red

#### Generar APK/AAB:
```bash
# APK para distribución directa
flutter build apk --release

# AAB para Google Play Store
flutter build appbundle --release
```

### Web Configuration

#### Metadatos Actualizados:
- **Título**: "TaskControl - Gestión de Tareas Empresarial"
- **Descripción**: "Plataforma empresarial multi-tenant para gestión de tareas..."
- **Favicon y iconos PWA**: Generados automáticamente
- **Manifest.json**: Configurado para PWA

#### Para construir y servir:
```bash
# Construir para web
flutter build web --release

# Servir localmente para pruebas
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## 📦 Archivos Generados

### Después de la construcción completa encontrarás:

#### Web:
- `build/web/` - Aplicación web lista para deploy
- Optimizada para PWA con Service Worker

#### Android:
- `build/app/outputs/flutter-apk/app-release.apk` - APK para instalación directa
- `build/app/outputs/bundle/release/app-release.aab` - AAB para Google Play

#### iOS (solo en macOS):
- Proyecto configurado en `ios/Runner.xcworkspace`
- IPA generado desde Xcode Organizer

## 🔧 Requisitos del Sistema

### Para Web y Android (Windows/macOS/Linux):
- Flutter SDK configurado
- Android SDK para builds de Android
- Navegador web para pruebas

### Para iOS (solo macOS):
- macOS con Xcode instalado
- Cuenta de desarrollador Apple
- Certificados y provisioning profiles configurados

## 🚀 Proceso de Distribución

### Web (GitHub Pages, Netlify, Vercel):
1. Construye: `flutter build web --release`
2. Sube el contenido de `build/web/`
3. Configura el servidor para servir `index.html` en todas las rutas

### Android (Google Play Store):
1. Construye AAB: `flutter build appbundle --release`
2. Firma el AAB con tu keystore
3. Sube a Google Play Console

### iOS (App Store):
1. En macOS, construye y archiva en Xcode
2. Sube usando Xcode Organizer
3. Procesa en App Store Connect

## ⚡ Comandos Rápidos

```powershell
# Setup completo
.\generate_icons.ps1
flutter clean
flutter pub get

# Build para todas las plataformas
.\build_all_platforms.ps1

# Solo Android optimizado
flutter build appbundle --release

# Solo Web optimizado
flutter build web --release --web-renderer html
```

## 📝 Notas Importantes

1. **Bundle Identifier iOS**: Actualizado a `com.taskcontrol.app`
2. **Iconos**: Se generan automáticamente desde `TaskControl_logo.png`
3. **Web PWA**: Completamente configurado con manifest y service worker
4. **Permisos iOS**: Configurados para adjuntar evidencias (cámara/galería)
5. **Red**: Configuración NSAppTransportSecurity permite conexiones HTTP en desarrollo

¡Tu aplicación TaskControl está lista para distribución en todas las plataformas! 🎉