# Configurar Variables de Entorno en Render

## Paso a Paso

### 1. Ve a tu servicio en Render
- Abre tu dashboard de Render
- Selecciona tu servicio `fcm-v10server`

### 2. Ve a la sección "Environment"
- En el menú lateral, haz clic en "Environment"

### 3. Configura las variables

#### Variable 1: FIREBASE_PROJECT_ID
**Nombre**: `FIREBASE_PROJECT_ID`
**Valor**: `proyecto-a7911`

#### Variable 2: SERVICE_ACCOUNT_EMAIL
**Nombre**: `SERVICE_ACCOUNT_EMAIL`
**Valor**: `firebase-adminsdk-fbsvc@proyecto-a7911.iam.gserviceaccount.com`

#### Variable 3: PRIVATE_KEY (IMPORTANTE)
**Nombre**: `PRIVATE_KEY`

**Valor**: Copia EXACTAMENTE esto (sin comillas adicionales):

```
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC9DaEwdbcQUKh/
GIHLps4xb483IIstWAYh5j6uku9WHnGm2KwWq/6wBY0zrSfXxqyq2jxcEwivVd8b
c09kZo23DlyI2WZPXYdQViSUgSiihrgfVae55q9CRKw3dr/nWqPdwkQ4t6SCH1gX
2CPIo0v1ep3VQep8jk+mdEGcpPvxq3EiT56iLNIrNJxtE2OJS0xk2JFRKdA/zcCD
IkJ3pnvDpxMQPKSb4RdP9ydsgcT60wbPF7qUscQaz54t0gAIx6FQw1bw5CTbV3Hb
bKy/i9Azr3C68FA/NgwHHC8H2J5/nTq0cXhZdVQMPe+LWNmyPB2edu/AYkzooHw2
RFmXaRexAgMBAAECggEAXPVzueFX94TBpWUGhX3qy3IgiKnO5afvtAGD9tE3MDBe
D/1gePFvlVvVd4CAI+CEDKqsnVWaoqRlxRipBCRNMKK2K3BCl2nU3FLPP9pWgbwe
kwHKLGXa7YnY6JjSec8e3i7k3sKl+HmzFl5oEgMBmZ4GN9NmmoJbdeyaSozxeX3L
83rhIoXyFi4BhsCPK/WRB6HTBR+FFjO9MdPfV2xa9hpqVvHFAxWLS0g5tv2FtP38
k603z3CvuD/8h2xIHJi2/AhCkMexD5hJYdMACiSaRwxZF3JwhIVRarSz74ydxPhQ
2PpbcN6cjIzTpvGUzJDrBVIv8dHzyyBsoydYVbcepQKBgQDjyUGhPq7gmiVM8prV
CbXg1jTAWSHCU1ChcVgj6ajb46IgprkHisfWyVni5+w1W/17J0ZG8f+uew3F3i2e
VdHsqE3b4TwLUWfJv6SSRarDqnmz+X/hj+UQ7fUqBhO3+WFQnTq64YgGlNWppGaZ
D3ac7QsvjS/qJm0m+TNoFH9QhwKBgQDUeDaCC3A+OgPdg36qkaB8hjhj8aHT1qLD
+DFmWfmR59dgNI6+Xqs078xwo1F3Wt3TpeW2nYUinwVO8hfot/tbeJ4J65ytZp8m
ok4CzzGvxmYPeL7+BXS64KsqT4Oa5DZrJBTrJ0cRbmdTewHje0yetkn8brMDMJ9T
1/41DU/8BwKBgQC4y52i4uec73Eza96Q1r/nF+DT63un20+eqgWHnRiQy6vMMXYK
2FwntFJn8x9+apLKRqKNC+cR9mLGE+mOerFD/Yasy52a0QASfJdW044mDzeM+uz0
YXjEs0giP6vfpUF91RDAbBeev0BX0DgsFI914BkjCrfEjkgfRiyeU4K2IQKBgQCZ
dLG5v1U0PGaqSNzliQSmq7JyzQSaof0xGUNkrzuH3DE8dPlcGbgCJeg8uliOofxx
bvK4sJCF7uDAoi4OkUNkT3ulopyoyOPN3ZAGi2tRjzQLnKQlh/9FMhuuFXvyFT4Q
qCDLrrSvrFPIgaFdkaJHR1Wskq+McEPDJM+ftZu9ZQKBgFL3fTxjEW6z+Cycw05J
N4gEa6aCMqv/Mh2LTDyW7RjDFGJtSocQ+6dpb3l1bxM3bzwuPe7OUTsAPIAqHYsZ
Z+ctT443r8vVuri6/eGNpW3w4z3UTHNLetZHmqD7WXtoa1tSY7NCOdv9Ni/DDasq
6HwHPRfeAYlVHFNd4E4eDBRZ
-----END PRIVATE KEY-----
```

### 4. Formato Alternativo (si Render no acepta saltos de línea)

Si Render no te permite pegar con saltos de línea, usa este formato con `\n`:

**Valor**:
```
-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC9DaEwdbcQUKh/\nGIHLps4xb483IIstWAYh5j6uku9WHnGm2KwWq/6wBY0zrSfXxqyq2jxcEwivVd8b\nc09kZo23DlyI2WZPXYdQViSUgSiihrgfVae55q9CRKw3dr/nWqPdwkQ4t6SCH1gX\n2CPIo0v1ep3VQep8jk+mdEGcpPvxq3EiT56iLNIrNJxtE2OJS0xk2JFRKdA/zcCD\nIkJ3pnvDpxMQPKSb4RdP9ydsgcT60wbPF7qUscQaz54t0gAIx6FQw1bw5CTbV3Hb\nbKy/i9Azr3C68FA/NgwHHC8H2J5/nTq0cXhZdVQMPe+LWNmyPB2edu/AYkzooHw2\nRFmXaRexAgMBAAECggEAXPVzueFX94TBpWUGhX3qy3IgiKnO5afvtAGD9tE3MDBe\nD/1gePFvlVvVd4CAI+CEDKqsnVWaoqRlxRipBCRNMKK2K3BCl2nU3FLPP9pWgbwe\nkwHKLGXa7YnY6JjSec8e3i7k3sKl+HmzFl5oEgMBmZ4GN9NmmoJbdeyaSozxeX3L\n83rhIoXyFi4BhsCPK/WRB6HTBR+FFjO9MdPfV2xa9hpqVvHFAxWLS0g5tv2FtP38\nk603z3CvuD/8h2xIHJi2/AhCkMexD5hJYdMACiSaRwxZF3JwhIVRarSz74ydxPhQ\n2PpbcN6cjIzTpvGUzJDrBVIv8dHzyyBsoydYVbcepQKBgQDjyUGhPq7gmiVM8prV\nCbXg1jTAWSHCU1ChcVgj6ajb46IgprkHisfWyVni5+w1W/17J0ZG8f+uew3F3i2e\nVdHsqE3b4TwLUWfJv6SSRarDqnmz+X/hj+UQ7fUqBhO3+WFQnTq64YgGlNWppGaZ\nD3ac7QsvjS/qJm0m+TNoFH9QhwKBgQDUeDaCC3A+OgPdg36qkaB8hjhj8aHT1qLD\n+DFmWfmR59dgNI6+Xqs078xwo1F3Wt3TpeW2nYUinwVO8hfot/tbeJ4J65ytZp8m\nok4CzzGvxmYPeL7+BXS64KsqT4Oa5DZrJBTrJ0cRbmdTewHje0yetkn8brMDMJ9T\n1/41DU/8BwKBgQC4y52i4uec73Eza96Q1r/nF+DT63un20+eqgWHnRiQy6vMMXYK\n2FwntFJn8x9+apLKRqKNC+cR9mLGE+mOerFD/Yasy52a0QASfJdW044mDzeM+uz0\nYXjEs0giP6vfpUF91RDAbBeev0BX0DgsFI914BkjCrfEjkgfRiyeU4K2IQKBgQCZ\ndLG5v1U0PGaqSNzliQSmq7JyzQSaof0xGUNkrzuH3DE8dPlcGbgCJeg8uliOofxx\nbvK4sJCF7uDAoi4OkUNkT3ulopyoyOPN3ZAGi2tRjzQLnKQlh/9FMhuuFXvyFT4Q\nqCDLrrSvrFPIgaFdkaJHR1Wskq+McEPDJM+ftZu9ZQKBgFL3fTxjEW6z+Cycw05J\nN4gEa6aCMqv/Mh2LTDyW7RjDFGJtSocQ+6dpb3l1bxM3bzwuPe7OUTsAPIAqHYsZ\nZ+ctT443r8vVuri6/eGNpW3w4z3UTHNLetZHmqD7WXtoa1tSY7NCOdv9Ni/DDasq\n6HwHPRfeAYlVHFNd4E4eDBRZ\n-----END PRIVATE KEY-----\n
```

### 5. Guardar y Reiniciar
- Haz clic en "Save Changes"
- Render reiniciará automáticamente el servicio
- Espera unos segundos a que el servicio esté listo

### 6. Verificar
- Ve a la pestaña "Logs" en Render
- Deberías ver: `Servidor FCM V1 corriendo en puerto 3000`
- Prueba enviar una notificación desde la app
- En los logs deberías ver: `✅ Access token obtenido exitosamente`

