# Solución para el Error de PRIVATE_KEY

El error `error:1E08010C:DECODER routines::unsupported` indica que la clave privada no está en el formato correcto.

## Pasos para corregir:

### 1. Obtener la clave privada correcta

1. Ve a Firebase Console > Configuración del proyecto > Cuentas de servicio
2. Haz clic en "Generar nueva clave privada"
3. Se descargará un archivo JSON

### 2. Extraer la clave privada del JSON

Abre el archivo JSON descargado y busca el campo `private_key`. Debería verse así:

```json
{
  "type": "service_account",
  "project_id": "tu-proyecto",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "...",
  ...
}
```

### 3. Copiar la clave privada completa

**IMPORTANTE**: Copia TODO el valor del campo `private_key`, incluyendo:
- `-----BEGIN PRIVATE KEY-----`
- Todo el contenido en el medio
- `-----END PRIVATE KEY-----`
- Los `\n` deben mantenerse como están

### 4. Configurar en Render

En Render, ve a tu servicio y agrega la variable de entorno:

**Nombre**: `PRIVATE_KEY`

**Valor**: Pega la clave privada COMPLETA, exactamente como está en el JSON, incluyendo las comillas si es necesario.

**Ejemplo**:
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
(más líneas)
...
-----END PRIVATE KEY-----
```

### 5. Formato alternativo (si Render tiene problemas)

Si Render no acepta saltos de línea, puedes usar el formato con `\n`:

```
-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n
```

### 6. Verificar

Después de actualizar la variable de entorno:
1. Reinicia el servicio en Render
2. Prueba enviar una notificación
3. Revisa los logs del servidor

Si ves `✅ Access token obtenido exitosamente`, el problema está resuelto.

