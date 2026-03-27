# Script para compilar el app bundle y verificar que se generó correctamente
# Filtra el mensaje de stripping de símbolos que es solo una advertencia

Write-Host "Compilando app bundle..." -ForegroundColor Cyan

$bundlePath = "build\app\outputs\bundle\release\app-release.aab"

# Eliminar bundle anterior si existe
if (Test-Path $bundlePath) {
    Remove-Item $bundlePath -Force
}

# Ejecutar build y filtrar el mensaje de stripping
$output = flutter build appbundle --release 2>&1 | Where-Object { 
    $_ -notmatch "failed to strip debug symbols" -and 
    $_ -notmatch "Please run flutter doctor" -and
    $_ -notmatch "file an issue at https://github.com"
}

# Mostrar salida filtrada
$output | ForEach-Object { Write-Host $_ }

if (Test-Path $bundlePath) {
    $fileInfo = Get-Item $bundlePath
    Write-Host "`n✓ Bundle generado correctamente!" -ForegroundColor Green
    Write-Host "  Ubicación: $bundlePath" -ForegroundColor White
    Write-Host "  Tamaño: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor White
    Write-Host "  Listo para subir a Google Play Store`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n✗ Error: El bundle no se generó correctamente" -ForegroundColor Red
    exit 1
}

