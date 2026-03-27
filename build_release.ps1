# Script para compilar el Android App Bundle para Google Play Store

Write-Host "=== Compilación de Android App Bundle para Producción ===" -ForegroundColor Cyan
Write-Host ""

$keyPropertiesPath = "android\key.properties"
$keystorePath = "android\upload-keystore.jks"

if (-not (Test-Path $keyPropertiesPath)) {
    Write-Host "[ERROR] No se encontró el archivo key.properties" -ForegroundColor Red
    Write-Host ""
    Write-Host "Debes crear el keystore primero. Ejecuta:" -ForegroundColor Yellow
    Write-Host "  cd android" -ForegroundColor White
    Write-Host "  .\create_keystore.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "O crea manualmente el archivo android/key.properties con:" -ForegroundColor Yellow
    Write-Host "  storePassword=TU_CONTRASEÑA" -ForegroundColor White
    Write-Host "  keyPassword=TU_CONTRASEÑA" -ForegroundColor White
    Write-Host "  keyAlias=upload" -ForegroundColor White
    Write-Host "  storeFile=C:/Users/Maicol RS/Desktop/teconnectesupport/android/upload-keystore.jks" -ForegroundColor White
    Write-Host ""
    exit 1
}

if (-not (Test-Path $keystorePath)) {
    Write-Host "[ERROR] No se encontró el keystore: $keystorePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Debes crear el keystore primero. Ejecuta:" -ForegroundColor Yellow
    Write-Host "  cd android" -ForegroundColor White
    Write-Host "  .\create_keystore.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "[OK] Keystore encontrado" -ForegroundColor Green
Write-Host ""

Write-Host "Limpiando el proyecto..." -ForegroundColor Cyan
flutter clean

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error al limpiar el proyecto" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Compilando el bundle de producción..." -ForegroundColor Cyan
Write-Host ""

$output = flutter build appbundle --release 2>&1

$exitCode = $LASTEXITCODE

$filteredOutput = $output | Where-Object {
    $_ -notmatch "failed to strip debug symbols" -and
    $_ -notmatch "Please run flutter doctor" -and
    $_ -notmatch "file an issue at https://github.com"
}

$filteredOutput | ForEach-Object { Write-Host $_ }

$bundlePath = "build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $bundlePath) {
    $bundleFile = Get-Item $bundlePath
    if ($bundleFile.Length -gt 0) {
        $bundleSize = $bundleFile.Length / 1MB
        Write-Host ""
        Write-Host "[OK] Bundle compilado exitosamente!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Ubicación: $($bundleFile.FullName)" -ForegroundColor White
        Write-Host "Tamaño: $([math]::Round($bundleSize, 2)) MB" -ForegroundColor White
        Write-Host ""
        Write-Host "Ahora puedes subir este archivo a Google Play Console" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "[ERROR] El bundle existe pero está vacío" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "[ERROR] El bundle no se generó en la ubicación esperada" -ForegroundColor Red
    Write-Host "Verifica los mensajes de error anteriores" -ForegroundColor Yellow
    exit 1
}

