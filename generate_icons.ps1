# Script para generar los iconos de la app en diferentes resoluciones para todas las plataformas
# Requiere que el logo esté en assets/images/TaskControl_logo.png

$sourceLogo = "assets\images\TaskControl_logo.png"
$androidResPath = "android\app\src\main\res"
$iosAssetsPath = "ios\Runner\Assets.xcassets\AppIcon.appiconset"
$webPath = "web"

# Definir las resoluciones necesarias para Android
$androidResolutions = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

# Definir las resoluciones necesarias para iOS
$iosResolutions = @{
    "Icon-App-20x20@1x.png" = 20
    "Icon-App-20x20@2x.png" = 40
    "Icon-App-20x20@3x.png" = 60
    "Icon-App-29x29@1x.png" = 29
    "Icon-App-29x29@2x.png" = 58
    "Icon-App-29x29@3x.png" = 87
    "Icon-App-40x40@1x.png" = 40
    "Icon-App-40x40@2x.png" = 80
    "Icon-App-40x40@3x.png" = 120
    "Icon-App-60x60@2x.png" = 120
    "Icon-App-60x60@3x.png" = 180
    "Icon-App-76x76@1x.png" = 76
    "Icon-App-76x76@2x.png" = 152
    "Icon-App-83.5x83.5@2x.png" = 167
    "Icon-App-1024x1024@1x.png" = 1024
}

# Definir las resoluciones necesarias para Web
$webResolutions = @{
    "favicon.png" = 32
    "icons\Icon-192.png" = 192
    "icons\Icon-512.png" = 512
    "icons\Icon-maskable-192.png" = 192
    "icons\Icon-maskable-512.png" = 512
}

Write-Host "Generando iconos de TaskControl para todas las plataformas..." -ForegroundColor Cyan

# Cargar la imagen original
Add-Type -AssemblyName System.Drawing

function Generate-Icon {
    param(
        [System.Drawing.Image]$SourceImage,
        [string]$DestPath,
        [int]$Size
    )

    try {
        # Crear bitmap redimensionado
        $newImage = New-Object System.Drawing.Bitmap($Size, $Size)
        $graphics = [System.Drawing.Graphics]::FromImage($newImage)

        # Configurar calidad de redimensionamiento
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

        # Dibujar imagen redimensionada
        $graphics.DrawImage($SourceImage, 0, 0, $Size, $Size)

        # Crear directorio si no existe
        $destDir = Split-Path -Parent $DestPath
        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        # Guardar
        $newImage.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)

        # Limpiar
        $graphics.Dispose()
        $newImage.Dispose()

        return $true
    } catch {
        Write-Host "Error generando $DestPath`: $_" -ForegroundColor Red
        return $false
    }
}

try {
    if (!(Test-Path $sourceLogo)) {
        Write-Host "Error: No se encontró el logo en $sourceLogo" -ForegroundColor Red
        Write-Host "Asegúrate de que el archivo TaskControl_logo.png existe en assets/images/" -ForegroundColor Yellow
        exit 1
    }

    $originalImage = [System.Drawing.Image]::FromFile((Resolve-Path $sourceLogo))

    # Generar iconos para Android
    Write-Host "`nGenerando iconos para Android..." -ForegroundColor Green
    foreach ($folder in $androidResolutions.Keys) {
        $size = $androidResolutions[$folder]
        $destFolder = Join-Path $androidResPath $folder
        $destFile = Join-Path $destFolder "ic_launcher.png"

        if (Generate-Icon -SourceImage $originalImage -DestPath $destFile -Size $size) {
            Write-Host "  ✓ Android ${size}x${size} → $folder/ic_launcher.png" -ForegroundColor Cyan
        }
    }

    # Generar iconos para iOS
    Write-Host "`nGenerando iconos para iOS..." -ForegroundColor Green
    foreach ($iconName in $iosResolutions.Keys) {
        $size = $iosResolutions[$iconName]
        $destFile = Join-Path $iosAssetsPath $iconName

        if (Generate-Icon -SourceImage $originalImage -DestPath $destFile -Size $size) {
            Write-Host "  ✓ iOS ${size}x${size} → $iconName" -ForegroundColor Cyan
        }
    }

    # Generar iconos para Web
    Write-Host "`nGenerando iconos para Web..." -ForegroundColor Green
    foreach ($iconPath in $webResolutions.Keys) {
        $size = $webResolutions[$iconPath]
        $destFile = Join-Path $webPath $iconPath

        if (Generate-Icon -SourceImage $originalImage -DestPath $destFile -Size $size) {
            Write-Host "  ✓ Web ${size}x${size} → $iconPath" -ForegroundColor Cyan
        }
    }

    $originalImage.Dispose()

    Write-Host "`n🎉 ¡Iconos generados exitosamente para todas las plataformas!" -ForegroundColor Green
    Write-Host "   - Android: Iconos en resoluciones MDPI a XXXHDPI" -ForegroundColor White
    Write-Host "   - iOS: Todos los tamaños requeridos para iPhone/iPad" -ForegroundColor White
    Write-Host "   - Web: Favicon y iconos para PWA" -ForegroundColor White
    Write-Host "`nYa puedes construir tu app para cualquier plataforma." -ForegroundColor Cyan

} catch {
    Write-Host "Error al generar iconos: $_" -ForegroundColor Red
    Write-Host "Asegúrate de que el archivo $sourceLogo existe y es una imagen válida." -ForegroundColor Yellow
}
