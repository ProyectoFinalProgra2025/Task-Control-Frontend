# Script para construir IPA de TaskControl para iOS
# Asegúrate de tener Xcode instalado y configurado con certificados de desarrollo

Write-Host "=== Construyendo TaskControl para iOS ===" -ForegroundColor Green

# Verificar que estamos en el directorio correcto
if (!(Test-Path "pubspec.yaml")) {
    Write-Host "Error: No se encontró pubspec.yaml. Ejecuta este script desde el directorio raíz del proyecto Flutter." -ForegroundColor Red
    exit 1
}

Write-Host "1. Limpiando proyecto..." -ForegroundColor Yellow
flutter clean

Write-Host "2. Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

Write-Host "3. Verificando configuración de iOS..." -ForegroundColor Yellow
flutter doctor

Write-Host "4. Construyendo para iOS (Release)..." -ForegroundColor Yellow
Write-Host "NOTA: Esto abrirá Xcode donde podrás:" -ForegroundColor Cyan
Write-Host "  - Configurar tu Team ID y certificados" -ForegroundColor Cyan
Write-Host "  - Establecer el Bundle Identifier" -ForegroundColor Cyan
Write-Host "  - Crear el archivo IPA para distribución" -ForegroundColor Cyan

# Construir para iOS y abrir Xcode
flutter build ios --release

Write-Host "5. Abriendo Xcode para finalizar el proceso..." -ForegroundColor Yellow
Write-Host "En Xcode, selecciona 'Product > Archive' para crear el IPA" -ForegroundColor Cyan

# Abrir el workspace de Xcode
$xcworkspace = "ios/Runner.xcworkspace"
if (Test-Path $xcworkspace) {
    Start-Process "open" -ArgumentList $xcworkspace
} else {
    Write-Host "No se pudo abrir Xcode automáticamente. Abre manualmente: $xcworkspace" -ForegroundColor Yellow
}

Write-Host "`n=== Siguiente pasos en Xcode ===" -ForegroundColor Green
Write-Host "1. Configura tu Team ID en 'Signing & Capabilities'" -ForegroundColor White
Write-Host "2. Verifica el Bundle Identifier (ej: com.tuempresa.taskcontrol)" -ForegroundColor White
Write-Host "3. Selecciona 'Product > Archive'" -ForegroundColor White
Write-Host "4. En el Organizer, selecciona 'Distribute App'" -ForegroundColor White
Write-Host "5. Elige el método de distribución (App Store, Ad Hoc, Enterprise, etc.)" -ForegroundColor White

Write-Host "`nProceso completado. Revisa Xcode para continuar." -ForegroundColor Green