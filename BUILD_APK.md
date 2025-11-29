# Guía para Generar APK de TaskControl

## Metadata Configurada

✅ **Nombre de la App**: TaskControl
✅ **Package ID**: work.taskcontrol.app
✅ **Versión**: 1.0.0 (versionCode: 1)
✅ **Icono de Launcher**: Logo personalizado en todas las resoluciones
✅ **Permisos**: INTERNET, ACCESS_NETWORK_STATE

## Comandos para Generar APK

### 1. APK de Debug (para pruebas)
```bash
flutter build apk --debug
```

El APK se generará en:
`build/app/outputs/flutter-apk/app-debug.apk`

### 2. APK de Release (para producción)
```bash
flutter build apk --release
```

El APK se generará en:
`build/app/outputs/flutter-apk/TaskControl-v1.0.0-release.apk`

### 3. APK Split por ABI (más pequeño, recomendado)
```bash
flutter build apk --split-per-abi --release
```

Esto generará 3 APKs optimizados:
- `build/app/outputs/flutter-apk/TaskControl-v1.0.0-armeabi-v7a-release.apk` (ARM 32-bit)
- `build/app/outputs/flutter-apk/TaskControl-v1.0.0-arm64-v8a-release.apk` (ARM 64-bit)
- `build/app/outputs/flutter-apk/TaskControl-v1.0.0-x86_64-release.apk` (Intel 64-bit)

**Recomendación**: Usa el APK `arm64-v8a` para la mayoría de dispositivos modernos.

## Antes de Generar el APK de Producción

### Configurar Firma de la App (Signing)

Para distribuir en Google Play Store o de forma oficial, necesitas firmar tu app:

1. **Generar el keystore**:
```bash
keytool -genkey -v -keystore taskcontrol-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias taskcontrol
```

2. **Crear archivo `android/key.properties`**:
```properties
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=taskcontrol
storeFile=../../taskcontrol-key.jks
```

3. **Modificar `android/app/build.gradle.kts`** (agregar antes de `android {`):
```kotlin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Y dentro de `buildTypes`:
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.release
    }
}
```

**IMPORTANTE**:
- Guarda `taskcontrol-key.jks` en un lugar seguro
- NO subas `key.properties` ni el keystore a Git
- Agrega ambos archivos a `.gitignore`

## Verificar el APK Generado

```bash
# Ver información del APK
flutter build apk --release && ls -lh build/app/outputs/flutter-apk/

# Instalar directamente en un dispositivo conectado
flutter install --release
```

## Información Adicional

- **Nombre del archivo APK**: El APK se nombrará automáticamente como `TaskControl-v1.0.0-release.apk`
- **Tamaño aproximado**: ~20-40 MB (dependiendo del split por ABI)
- **Versión mínima de Android**: La definida en `minSdk` (generalmente Android 5.0 - API 21)
- **Arquitecturas soportadas**: ARM 32/64-bit, x86 64-bit

## Solución de Problemas

### Error: "Unspecified version"
Asegúrate de que `pubspec.yaml` tenga:
```yaml
version: 1.0.0+1
```

### Error: "No signature of method"
Verifica que estés usando la sintaxis correcta de Kotlin en `build.gradle.kts`.

### APK muy grande
Usa `--split-per-abi` para reducir el tamaño significativamente.

## Próximos Pasos

Para publicar en Google Play Store:
1. Generar un App Bundle en lugar de APK: `flutter build appbundle --release`
2. Configurar la firma (ver sección anterior)
3. Crear una cuenta de desarrollador en Google Play Console ($25 único pago)
4. Subir el App Bundle y configurar el listing de la app
