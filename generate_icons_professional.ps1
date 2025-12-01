# TaskControl - Script de Generación de Iconos Actualizado
# Este script usa flutter_launcher_icons para generar iconos profesionales

Write-Host "=== TaskControl - Generación de Iconos Profesional ===" -ForegroundColor Green

# Verificar que estamos en el directorio correcto
if (!(Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: No se encontró pubspec.yaml" -ForegroundColor Red
    Write-Host "Ejecuta este script desde el directorio raíz del proyecto Flutter." -ForegroundColor Yellow
    exit 1
}

# Verificar que existe el logo fuente
$logoPath = "assets\images\TaskControl_logo.png"
if (!(Test-Path $logoPath)) {
    Write-Host "❌ Error: No se encontró $logoPath" -ForegroundColor Red
    Write-Host "Asegúrate de que el logo existe en la ruta especificada." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Logo encontrado: $logoPath" -ForegroundColor Green

# Obtener dependencias
Write-Host "`n🔄 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error obteniendo dependencias" -ForegroundColor Red
    exit 1
}

# Generar iconos usando flutter_launcher_icons
Write-Host "`n🎨 Generando iconos para todas las plataformas..." -ForegroundColor Yellow
flutter pub run flutter_launcher_icons:main

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error generando iconos" -ForegroundColor Red
    exit 1
}

# Verificar que los iconos se generaron correctamente
Write-Host "`n📊 Verificando iconos generados:" -ForegroundColor Cyan

# iOS
$iosIconPath = "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png"
if (Test-Path $iosIconPath) {
    $iosSize = [math]::Round((Get-Item $iosIconPath).Length / 1KB, 1)
    Write-Host "  ✅ iOS: Icon-App-1024x1024@1x.png ($iosSize KB)" -ForegroundColor Green
} else {
    Write-Host "  ❌ iOS: Icono principal no encontrado" -ForegroundColor Red
}

# Android
$androidIconPath = "android\app\src\main\res\mipmap-xxxhdpi\launcher_icon.png"
if (Test-Path $androidIconPath) {
    $androidSize = [math]::Round((Get-Item $androidIconPath).Length / 1KB, 1)
    Write-Host "  ✅ Android: launcher_icon.png ($androidSize KB)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Android: Icono principal no encontrado" -ForegroundColor Red
}

# Web
$webIconPath = "web\icons\Icon-512.png"
if (Test-Path $webIconPath) {
    $webSize = [math]::Round((Get-Item $webIconPath).Length / 1KB, 1)
    Write-Host "  ✅ Web: Icon-512.png ($webSize KB)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Web: Icono principal no encontrado" -ForegroundColor Red
}

Write-Host "`n🚀 Iconos generados exitosamente!" -ForegroundColor Green
Write-Host "`nConfiguraciones aplicadas:" -ForegroundColor White
Write-Host "  • iOS: Sin canal alpha (App Store compliant)" -ForegroundColor Cyan
Write-Host "  • Android: Múltiples densidades (MDPI a XXXHDPI)" -ForegroundColor Cyan  
Write-Host "  • Web: PWA icons + maskable icons" -ForegroundColor Cyan
Write-Host "  • Todos los tamaños requeridos por cada plataforma" -ForegroundColor Cyan

Write-Host "`n📱 Tu app ahora tendrá iconos profesionales en todas las plataformas!" -ForegroundColor Blue
Write-Host "`nEn macOS, puedes ahora construir el IPA con:" -ForegroundColor Yellow
Write-Host "  flutter build ios --release" -ForegroundColor White
Write-Host "  open ios/Runner.xcworkspace" -ForegroundColor White