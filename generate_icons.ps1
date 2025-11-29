# Script para generar los iconos de la app en diferentes resoluciones
# Requiere que el logo esté en assets/images/logo-apk.png

$sourceLogo = "assets\images\logo-apk.png"
$androidResPath = "android\app\src\main\res"

# Definir las resoluciones necesarias para Android
$resolutions = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

Write-Host "Generando iconos de lanzador para TaskControl..." -ForegroundColor Cyan

# Cargar la imagen original
Add-Type -AssemblyName System.Drawing

try {
    $originalImage = [System.Drawing.Image]::FromFile((Resolve-Path $sourceLogo))

    foreach ($folder in $resolutions.Keys) {
        $size = $resolutions[$folder]
        $destFolder = Join-Path $androidResPath $folder
        $destFile = Join-Path $destFolder "ic_launcher.png"

        Write-Host "Creando icono ${size}x${size} en $folder..." -ForegroundColor Green

        # Crear bitmap redimensionado
        $newImage = New-Object System.Drawing.Bitmap($size, $size)
        $graphics = [System.Drawing.Graphics]::FromImage($newImage)

        # Configurar calidad de redimensionamiento
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

        # Dibujar imagen redimensionada
        $graphics.DrawImage($originalImage, 0, 0, $size, $size)

        # Guardar
        $newImage.Save($destFile, [System.Drawing.Imaging.ImageFormat]::Png)

        # Limpiar
        $graphics.Dispose()
        $newImage.Dispose()
    }

    $originalImage.Dispose()

    Write-Host "`n¡Iconos generados exitosamente!" -ForegroundColor Green
    Write-Host "Tu app ahora usará el logo personalizado de TaskControl." -ForegroundColor Cyan

} catch {
    Write-Host "Error al generar iconos: $_" -ForegroundColor Red
    Write-Host "Asegúrate de que el archivo $sourceLogo existe." -ForegroundColor Yellow
}
