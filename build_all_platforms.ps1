# Script completo de construcción para TaskControl
# Construye la aplicación para Web, Android e iOS

param(
    [ValidateSet("web", "android", "ios", "all")]
    [string]$Platform = "all",
    
    [ValidateSet("debug", "release")]
    [string]$Mode = "release",
    
    [switch]$SkipIconGeneration,
    
    [switch]$SkipClean
)

Write-Host "=== TaskControl Build Script ===" -ForegroundColor Green
Write-Host "Plataforma: $Platform | Modo: $Mode" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (!(Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: No se encontró pubspec.yaml" -ForegroundColor Red
    Write-Host "Ejecuta este script desde el directorio raíz del proyecto Flutter." -ForegroundColor Yellow
    exit 1
}

# Función para ejecutar comandos y mostrar el resultado
function Invoke-BuildCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "`n🔄 $Description..." -ForegroundColor Yellow
    Write-Host "Ejecutando: $Command" -ForegroundColor Gray
    
    try {
        Invoke-Expression $Command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $Description completado" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Error en: $Description" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Excepción en: $Description - $_" -ForegroundColor Red
        return $false
    }
}

# Función para construir Web
function Build-Web {
    Write-Host "`n📱 === CONSTRUYENDO PARA WEB ===" -ForegroundColor Magenta
    
    $webMode = if ($Mode -eq "debug") { "--debug" } else { "--release" }
    
    if (!(Invoke-BuildCommand "flutter build web $webMode --web-renderer html" "Construcción Web")) {
        return $false
    }
    
    Write-Host "✅ Web build completado en: build/web/" -ForegroundColor Green
    Write-Host "Para servir localmente: flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080" -ForegroundColor Cyan
    return $true
}

# Función para construir Android
function Build-Android {
    Write-Host "`n🤖 === CONSTRUYENDO PARA ANDROID ===" -ForegroundColor Magenta
    
    $androidMode = if ($Mode -eq "debug") { "apk --debug" } else { "apk --release" }
    
    if (!(Invoke-BuildCommand "flutter build $androidMode" "Construcción Android APK")) {
        return $false
    }
    
    $apkPath = if ($Mode -eq "debug") { "build/app/outputs/flutter-apk/app-debug.apk" } else { "build/app/outputs/flutter-apk/app-release.apk" }
    
    if (Test-Path $apkPath) {
        $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
        Write-Host "✅ APK generado: $apkPath ($apkSize MB)" -ForegroundColor Green
    }
    
    # Si es release, también construir AAB
    if ($Mode -eq "release") {
        if (Invoke-BuildCommand "flutter build appbundle --release" "Construcción Android AAB") {
            $aabPath = "build/app/outputs/bundle/release/app-release.aab"
            if (Test-Path $aabPath) {
                $aabSize = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)
                Write-Host "✅ AAB generado: $aabPath ($aabSize MB)" -ForegroundColor Green
            }
        }
    }
    
    return $true
}

# Función para construir iOS
function Build-iOS {
    Write-Host "`n🍎 === CONSTRUYENDO PARA iOS ===" -ForegroundColor Magenta
    
    # Verificar si estamos en macOS
    if ($env:OS -eq "Windows_NT") {
        Write-Host "⚠️  iOS solo se puede construir en macOS con Xcode" -ForegroundColor Yellow
        Write-Host "Pasos para construir en macOS:" -ForegroundColor Cyan
        Write-Host "1. Transfiere el proyecto a una Mac" -ForegroundColor White
        Write-Host "2. Ejecuta: flutter build ios --release" -ForegroundColor White
        Write-Host "3. Abre ios/Runner.xcworkspace en Xcode" -ForegroundColor White
        Write-Host "4. Configura certificados y provisioning profiles" -ForegroundColor White
        Write-Host "5. Ejecuta Product > Archive para generar IPA" -ForegroundColor White
        return $false
    }
    
    $iosMode = if ($Mode -eq "debug") { "--debug" } else { "--release" }
    
    if (!(Invoke-BuildCommand "flutter build ios $iosMode" "Construcción iOS")) {
        return $false
    }
    
    Write-Host "✅ iOS build completado" -ForegroundColor Green
    Write-Host "Para generar IPA:" -ForegroundColor Cyan
    Write-Host "1. Abre ios/Runner.xcworkspace en Xcode" -ForegroundColor White
    Write-Host "2. Configura tu equipo de desarrollo" -ForegroundColor White
    Write-Host "3. Ejecuta Product > Archive" -ForegroundColor White
    Write-Host "4. Distribuye usando el Organizer" -ForegroundColor White
    
    return $true
}

# Inicio del proceso de construcción
Write-Host "`n🚀 Iniciando proceso de construcción..." -ForegroundColor Blue

# Paso 1: Limpiar proyecto (opcional)
if (!$SkipClean) {
    if (!(Invoke-BuildCommand "flutter clean" "Limpieza del proyecto")) {
        exit 1
    }
}

# Paso 2: Obtener dependencias
if (!(Invoke-BuildCommand "flutter pub get" "Obtención de dependencias")) {
    exit 1
}

# Paso 3: Generar iconos (opcional)
if (!$SkipIconGeneration) {
    Write-Host "`n🎨 Generando iconos..." -ForegroundColor Yellow
    try {
        & ".\generate_icons.ps1"
        Write-Host "✅ Iconos generados correctamente" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Error generando iconos, continuando... $_" -ForegroundColor Yellow
    }
}

# Paso 4: Verificar configuración
if (!(Invoke-BuildCommand "flutter doctor" "Verificación de configuración")) {
    Write-Host "⚠️  Hay problemas en la configuración, pero continuando..." -ForegroundColor Yellow
}

# Paso 5: Construir según la plataforma
$success = $true

switch ($Platform) {
    "web" {
        $success = Build-Web
    }
    "android" {
        $success = Build-Android
    }
    "ios" {
        $success = Build-iOS
    }
    "all" {
        $webSuccess = Build-Web
        $androidSuccess = Build-Android
        $iosSuccess = Build-iOS
        $success = $webSuccess -and $androidSuccess
    }
}

# Resumen final
Write-Host "`n" + "="*50 -ForegroundColor Blue
if ($success) {
    Write-Host "🎉 ¡CONSTRUCCIÓN COMPLETADA EXITOSAMENTE!" -ForegroundColor Green
} else {
    Write-Host "❌ CONSTRUCCIÓN FALLÓ" -ForegroundColor Red
}

Write-Host "`n📊 Resumen de archivos generados:" -ForegroundColor Cyan

# Mostrar archivos generados
if (Test-Path "build/web") {
    Write-Host "  🌐 Web: build/web/" -ForegroundColor Green
}

if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {
    $size = [math]::Round((Get-Item "build/app/outputs/flutter-apk/app-release.apk").Length / 1MB, 2)
    Write-Host "  🤖 Android APK: build/app/outputs/flutter-apk/app-release.apk ($size MB)" -ForegroundColor Green
}

if (Test-Path "build/app/outputs/bundle/release/app-release.aab") {
    $size = [math]::Round((Get-Item "build/app/outputs/bundle/release/app-release.aab").Length / 1MB, 2)
    Write-Host "  📦 Android AAB: build/app/outputs/bundle/release/app-release.aab ($size MB)" -ForegroundColor Green
}

Write-Host "`n🚀 TaskControl listo para distribución!" -ForegroundColor Blue