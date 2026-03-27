# Teconnect Support - Sistema de Gestión de Tickets

## 📋 Descripción General

**Teconnect Support** es una aplicación móvil desarrollada en Flutter para la gestión integral de tickets de soporte técnico. El sistema permite a usuarios crear, gestionar y resolver tickets de soporte, facilitando la comunicación entre clientes y el equipo de soporte técnico.

### Características Principales

- ✅ Sistema de autenticación con roles (Admin, Worker, User)
- ✅ Gestión completa de tickets con estados y prioridades
- ✅ Chat en tiempo real con mensajería instantánea
- ✅ Indicadores de estado de mensajes (enviado, entregado, leído)
- ✅ Detección de presencia en línea/offline
- ✅ Indicadores de escritura (typing indicators)
- ✅ Mensajes de audio con grabación y reproducción
- ✅ Notificaciones push personalizadas
- ✅ Sistema de facturación integrado
- ✅ Alertas del sistema
- ✅ Actualizador automático de aplicación
- ✅ Tema claro/oscuro

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Directorios

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/                   # Modelos de datos
│   ├── user_model.dart
│   ├── ticket_model.dart
│   ├── message_model.dart
│   ├── invoice_model.dart
│   └── alert_model.dart
├── services/                 # Servicios de negocio
│   ├── auth_service.dart
│   ├── ticket_service.dart
│   ├── message_service.dart
│   ├── presence_service.dart
│   ├── notification_service.dart
│   ├── fcm_service.dart
│   ├── invoice_service.dart
│   └── app_updater_service.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   └── theme_provider.dart
├── screens/                  # Pantallas de la aplicación
│   ├── auth/                 # Autenticación
│   ├── user/                 # Pantallas de usuario
│   ├── worker/               # Pantallas de trabajador
│   ├── admin/                # Pantallas de administrador
│   ├── tickets/              # Gestión de tickets
│   └── invoices/             # Gestión de facturas
├── widgets/                  # Widgets reutilizables
└── theme/                    # Configuración de temas
    └── app_theme.dart
```

### Stack Tecnológico

- **Framework**: Flutter 3.x
- **Lenguaje**: Dart
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
  - Cloud Messaging (FCM)
- **State Management**: Provider
- **Navegación**: Navigator 2.0

---

## 🚀 Instalación y Configuración

### Requisitos Previos

- Flutter SDK 3.0 o superior
- Dart SDK 3.0 o superior
- Android Studio / Xcode (para desarrollo móvil)
- Cuenta de Firebase configurada
- Node.js (para servidor de notificaciones, opcional)

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd teconnectesupport
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   - Agregar `google-services.json` (Android) en `android/app/`
   - Agregar `GoogleService-Info.plist` (iOS) en `ios/Runner/`
   - Configurar Firebase en `lib/main.dart`

4. **Configurar permisos**
   - Android: Verificar `AndroidManifest.xml`
   - iOS: Verificar `Info.plist`

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

---

## 📱 Funcionalidades Detalladas

### 1. Sistema de Autenticación

#### Roles de Usuario

- **Admin**: Acceso completo al sistema
- **Worker**: Gestión de tickets asignados
- **User**: Creación y seguimiento de tickets propios

#### Características

- Registro de usuarios
- Inicio de sesión con email/contraseña
- Recuperación de contraseña
- Detección automática de eliminación de usuario
- Cierre de sesión automático si el usuario es eliminado

### 2. Gestión de Tickets

#### Estados de Ticket

- `open`: Ticket abierto, pendiente de asignación
- `in_progress`: Ticket en progreso, asignado a un trabajador
- `resolved`: Ticket resuelto
- `closed`: Ticket cerrado

#### Prioridades

- `urgent`: Urgente (rojo)
- `high`: Alta (naranja)
- `medium`: Media (azul)
- `low`: Baja (verde)

#### Funcionalidades

- Creación de tickets con motivo y descripción
- Asignación automática o manual de tickets
- Filtrado y búsqueda de tickets
- Restricción: un usuario solo puede tener un ticket abierto a la vez
- Mensaje del sistema automático al crear ticket

### 3. Sistema de Mensajería

#### Tipos de Mensajes

- `text`: Mensaje de texto
- `image`: Imagen adjunta
- `file`: Archivo adjunto
- `audio`: Mensaje de audio
- `system`: Mensaje del sistema

#### Estados de Mensaje

- `sending`: Enviando
- `sent`: Enviado
- `delivered`: Entregado (destinatario en línea)
- `read`: Leído (destinatario viendo el ticket)

#### Características

- Mensajería en tiempo real
- Indicadores de escritura
- Mensajes optimistas (UI inmediata)
- Respuestas a mensajes
- Reacciones con emojis
- Grabación y envío de audio
- Mensajes del sistema automáticos

### 4. Sistema de Presencia

#### Funcionalidades

- Detección de usuarios en línea/offline
- Heartbeat cada 30 segundos
- Detección de usuarios viendo un ticket específico
- Indicadores de escritura en tiempo real
- Última vez visto (last seen)

### 5. Notificaciones Push

#### Tipos de Notificaciones

- Nuevo ticket creado
- Nuevo mensaje en ticket
- Asignación de ticket
- Cierre de ticket
- Alertas del sistema

#### Características

- Notificaciones personalizadas por usuario
- Notificaciones a grupos (admins, workers)
- Notificaciones a usuarios específicos
- Configuración de imagen, sonido y prioridad

### 6. Sistema de Facturación

#### Funcionalidades

- Generación automática de facturas
- Visualización de facturas por usuario
- Estados de factura (pendiente, pagada, vencida)
- Programación de envío de facturas

---

## 🔧 Configuración de Firebase

### Estructura de Firestore

```
users/
  {userId}/
    - email, name, role, createdAt, isOnline, lastSeen, lastHeartbeat
    fcmTokens/
      {deviceId}/
        - token, deviceName, platform, createdAt, lastUpdated

tickets/
  {ticketId}/
    - title, description, createdBy, assignedTo, status, priority, createdAt, updatedAt
    messages/
      {messageId}/
        - ticketId, senderId, senderName, content, timestamp, type, status, attachmentUrl
    viewers/
      {userId}/
        - userId, viewingSince
    typing/
      {userId}/
        - userId, isTyping

alerts/
  {alertId}/
    - title, message, isActive, createdAt, expiresAt

invoices/
  {invoiceId}/
    - userId, amount, status, dueDate, createdAt

app_config/
  updates/
    - latestVersion, isRequired, downloadUrl, releaseNotes
  fcm/
    - serverUrl
```

### Reglas de Seguridad (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas para usuarios
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reglas para tickets
    match /tickets/{ticketId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

---

## 📚 Documentación de Servicios

### AuthService

**Ubicación**: `lib/services/auth_service.dart`

**Responsabilidades**:
- Autenticación de usuarios
- Registro de nuevos usuarios
- Gestión de sesiones
- Obtención de datos de usuario

**Métodos Principales**:
- `signInWithEmailAndPassword()`: Iniciar sesión
- `signUpWithEmailAndPassword()`: Registrar usuario
- `signOut()`: Cerrar sesión
- `getUserData()`: Obtener datos del usuario

### TicketService

**Ubicación**: `lib/services/ticket_service.dart`

**Responsabilidades**:
- Creación de tickets
- Actualización de tickets
- Asignación de tickets
- Consulta de tickets

**Métodos Principales**:
- `createTicket()`: Crear nuevo ticket
- `updateTicket()`: Actualizar ticket
- `assignTicket()`: Asignar ticket a trabajador
- `closeTicket()`: Cerrar ticket
- `hasOpenTickets()`: Verificar tickets abiertos

### MessageService

**Ubicación**: `lib/services/message_service.dart`

**Responsabilidades**:
- Envío de mensajes
- Gestión de estados de mensajes
- Actualización de estados (sent, delivered, read)

**Métodos Principales**:
- `sendMessage()`: Enviar mensaje
- `getMessagesByTicket()`: Obtener mensajes de un ticket
- `markMessageAsRead()`: Marcar mensaje como leído
- `markAllMessagesAsRead()`: Marcar todos los mensajes como leídos

### PresenceService

**Ubicación**: `lib/services/presence_service.dart`

**Responsabilidades**:
- Gestión de presencia de usuarios
- Indicadores de escritura
- Detección de usuarios viendo tickets

**Métodos Principales**:
- `setUserOnline()`: Establecer usuario en línea
- `setUserOffline()`: Establecer usuario offline
- `isUserOnline()`: Verificar si usuario está en línea
- `setUserTyping()`: Establecer indicador de escritura
- `setUserViewingTicket()`: Usuario viendo ticket

### NotificationService

**Ubicación**: `lib/services/notification_service.dart`

**Responsabilidades**:
- Envío de notificaciones push
- Gestión de tokens FCM
- Notificaciones personalizadas

**Métodos Principales**:
- `sendToAllUsers()`: Enviar a todos los usuarios
- `sendToAdminsAndWorkers()`: Enviar a admins y workers
- `sendToTicketUsers()`: Enviar a usuarios del ticket
- `sendToSpecificUsers()`: Enviar a usuarios específicos

---

## 🎨 Sistema de Temas

### Tema Claro

- Color primario: Azul (#2196F3)
- Color secundario: Azul oscuro (#1976D2)
- Fondo: Blanco/Gris claro
- Texto: Gris oscuro

### Tema Oscuro

- Color primario: Azul claro (#64B5F6)
- Fondo: Gris oscuro (#0B141A)
- Texto: Blanco/Gris claro

### Personalización

Los temas se configuran en `lib/theme/app_theme.dart` y se gestionan mediante `ThemeProvider`.

---

## 🔐 Seguridad

### Medidas Implementadas

1. **Autenticación Firebase**: Autenticación segura con Firebase Auth
2. **Reglas de Firestore**: Control de acceso a datos
3. **Validación de datos**: Validación en cliente y servidor
4. **Detección de eliminación**: Cierre automático de sesión si el usuario es eliminado
5. **Tokens FCM**: Gestión segura de tokens de notificaciones

---

## 📊 Flujos de Usuario

### Flujo: Crear Ticket

1. Usuario accede a "Crear Ticket"
2. Selecciona motivo del ticket
3. Ingresa descripción detallada
4. Sistema valida que no tenga tickets abiertos
5. Se crea el ticket
6. Se genera mensaje del sistema automático
7. Se envía notificación a admins/workers

### Flujo: Responder Ticket

1. Worker/Admin asigna ticket a sí mismo
2. Accede al detalle del ticket
3. Ve mensaje del sistema con título y descripción
4. Responde con mensajes
5. Usuario recibe notificaciones
6. Estados de mensajes se actualizan automáticamente

### Flujo: Cerrar Ticket

1. Worker/Admin envía comando `/close [razón]`
2. Sistema marca ticket como cerrado
3. Se envía notificación al usuario
4. Usuario puede crear nuevo ticket

---

## 🧪 Testing

### Pruebas Recomendadas

1. **Pruebas Unitarias**: Servicios y modelos
2. **Pruebas de Widgets**: Componentes UI
3. **Pruebas de Integración**: Flujos completos
4. **Pruebas de Rendimiento**: Optimización de consultas

### Ejecutar Tests

```bash
flutter test
```

---

## 🚢 Deployment

### Android

1. Generar keystore
2. Configurar `build.gradle`
3. Build release: `flutter build apk --release`
4. Subir a Google Play Store

### iOS

1. Configurar certificados en Xcode
2. Build release: `flutter build ios --release`
3. Subir a App Store Connect

---

## 📝 Changelog

### Versión 1.0.0

- Sistema de autenticación completo
- Gestión de tickets
- Mensajería en tiempo real
- Notificaciones push
- Sistema de facturación
- Tema claro/oscuro
- Actualizador automático

---

## 👥 Contribución

Este es un proyecto privado. Para contribuciones, contactar al equipo de desarrollo.

---

## 📄 Licencia

Propietario - Todos los derechos reservados

---

## 📞 Soporte

Para soporte técnico, contactar al equipo de desarrollo o crear un ticket en el sistema.

---

**Desarrollado con ❤️ usando Flutter y Firebase**

