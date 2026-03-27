# Script para crear el keystore de producción
# Ejecuta este script desde la carpeta android/

Write-Host "=== Creación de Keystore para Producción ===" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "$PSScriptRoot\upload-keystore.jks"
$keyPropertiesPath = "$PSScriptRoot\key.properties"

if (Test-Path $keystorePath) {
    Write-Host "ADVERTENCIA: Ya existe un keystore en $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "¿Deseas sobrescribirlo? (s/n)"
    if ($overwrite -ne "s") {
        Write-Host "Operación cancelada." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Se te pedirán los siguientes datos:" -ForegroundColor Yellow
Write-Host "  1. Contraseña del keystore (guárdala de forma segura)" -ForegroundColor White
Write-Host "  2. Contraseña de la key (puede ser la misma)" -ForegroundColor White
Write-Host "  3. Información personal/organizacional" -ForegroundColor White
Write-Host ""

$keytoolPath = $null
$possiblePaths = @(
    "C:\Program Files\Java\jdk-*\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "$env:LOCALAPPDATA\Android\Android Studio\jbr\bin\keytool.exe"
)

foreach ($path in $possiblePaths) {
    $files = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    if ($files) {
        $keytoolPath = $files[0].FullName
        break
    }
}

if (-not $keytoolPath) {
    $keytoolPath = "keytool"
}

$keytoolCommand = "& `"$keytoolPath`" -genkey -v -keystore `"$keystorePath`" -keyalg RSA -keysize 2048 -validity 10000 -alias upload"

Write-Host "Ejecutando keytool..." -ForegroundColor Cyan
Write-Host ""

if ($keytoolPath -ne "keytool") {
    & $keytoolPath -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias upload
} else {
    keytool -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias upload
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[OK] Keystore creado exitosamente en: $keystorePath" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Ahora necesitas crear el archivo key.properties" -ForegroundColor Yellow
    Write-Host ""
    
    $storePassword = Read-Host "Contraseña del keystore" -AsSecureString
    $storePasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword))
    
    $keyPassword = Read-Host "Contraseña de la key (presiona Enter si es la misma)" -AsSecureString
    if ($keyPassword.Length -eq 0) {
        $keyPasswordPlain = $storePasswordPlain
    } else {
        $keyPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword))
    }
    
    $keystoreAbsolutePath = (Resolve-Path $keystorePath -ErrorAction SilentlyContinue).Path
    if (-not $keystoreAbsolutePath) {
        $keystoreAbsolutePath = $keystorePath
    }
    # Convertir la ruta a formato compatible con key.properties (usar / o \\)
    $keystoreAbsolutePath = $keystoreAbsolutePath -replace '\\', '/'
    
    $keyPropertiesContent = @"
storePassword=$storePasswordPlain
keyPassword=$keyPasswordPlain
keyAlias=upload
storeFile=$keystoreAbsolutePath
"@
    
    Set-Content -Path $keyPropertiesPath -Value $keyPropertiesContent
    
    Write-Host ""
    Write-Host "[OK] Archivo key.properties creado en: $keyPropertiesPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANTE:" -ForegroundColor Red
    Write-Host "  1. Guarda de forma segura las contraseñas" -ForegroundColor Yellow
    Write-Host "  2. Haz backup del archivo keystore ($keystorePath)" -ForegroundColor Yellow
    Write-Host "  3. Si pierdes el keystore o las contraseñas, NO podras actualizar tu app en Google Play" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Ahora puedes compilar el bundle con: flutter build appbundle --release" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[ERROR] Error al crear el keystore" -ForegroundColor Red
    exit 1
}

