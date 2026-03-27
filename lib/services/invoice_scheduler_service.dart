import '../services/invoice_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../models/invoice_model.dart';
import '../models/invoice_schedule_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceSchedulerService {
  static final InvoiceService _invoiceService = InvoiceService();
  static final NotificationService _notificationService = NotificationService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calcular fecha de vencimiento: siempre el día 10 del mes siguiente
  static DateTime calculateDueDate(DateTime issueDate) {
    // Si la factura se emite antes del día 10, vence el día 10 del mes actual
    // Si se emite después del día 10, vence el día 10 del mes siguiente
    if (issueDate.day <= 10) {
      return DateTime(issueDate.year, issueDate.month, 10);
    } else {
      // Mes siguiente
      final nextMonth = issueDate.month == 12 ? 1 : issueDate.month + 1;
      final nextYear = issueDate.month == 12 ? issueDate.year + 1 : issueDate.year;
      return DateTime(nextYear, nextMonth, 10);
    }
  }

  // Verificar y enviar facturas automáticamente el día 25 de cada mes
  static Future<void> checkAndSendPendingInvoices() async {
    try {
      final now = DateTime.now();
      final currentDay = now.day;
      
      // El día 25: enviar todas las facturas pendientes automáticamente
      if (currentDay == 25) {
        await _sendAllPendingInvoices(now);
      }
      
      // Día 30: enviar notificaciones de recordatorio
      if (currentDay == 30) {
        await _sendUpcomingReminders(now, currentDay);
      }
      
      // Día 5: enviar notificaciones de recordatorio
      if (currentDay == 5) {
        await _sendUpcomingReminders(now, currentDay);
      }
      
      // Día 10: marcar facturas vencidas como "Corte de Servicio"
      if (currentDay == 10) {
        await _markOverdueInvoicesAsServiceCut(now);
      }
    } catch (e) {
      // Error silencioso
    }
  }

  // Enviar todas las facturas pendientes el día 25
  static Future<void> _sendAllPendingInvoices(DateTime now) async {
    try {
      // Primero, generar facturas automáticas para usuarios con configuración activa
      await _generateAutomaticInvoices(now);
      
      // Obtener todas las facturas pendientes que aún no han sido enviadas
      final snapshot = await _firestore
          .collection('invoices')
          .where('status', isEqualTo: 'Pendiente')
          .get();

      final pendingInvoices = snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .where((invoice) => invoice.sentAt == null) // Solo las que no han sido enviadas
          .toList();

      if (pendingInvoices.isEmpty) {
        return;
      }

      // Agrupar facturas por usuario
      final Map<String, List<InvoiceModel>> invoicesByUser = {};
      for (var invoice in pendingInvoices) {
        if (!invoicesByUser.containsKey(invoice.userId)) {
          invoicesByUser[invoice.userId] = [];
        }
        invoicesByUser[invoice.userId]!.add(invoice);
      }

      // Obtener usuarios con configuración activa
      final activeSchedules = await _firestore
          .collection('invoice_schedules')
          .where('isActive', isEqualTo: true)
          .get();
      
      final activeUserIds = activeSchedules.docs
          .map((doc) => InvoiceScheduleModel.fromMap(doc.data(), doc.id).userId)
          .toSet();
      
      // Enviar cada factura y notificar al usuario (solo usuarios con configuración activa)
      for (var entry in invoicesByUser.entries) {
        final userId = entry.key;
        
        // Solo procesar usuarios con configuración activa
        if (!activeUserIds.contains(userId)) {
          continue;
        }
        
        final userInvoices = entry.value;

        // Verificar si el usuario tiene todas las facturas pagadas
        final allUserInvoices = await _firestore
            .collection('invoices')
            .where('userId', isEqualTo: userId)
            .get();

        bool hasPendingInvoices = false;
        for (var doc in allUserInvoices.docs) {
          final invoice = InvoiceModel.fromMap(doc.data(), doc.id);
          if (invoice.status == 'Pendiente') {
            hasPendingInvoices = true;
            break;
          }
        }

        // Solo enviar si el usuario tiene facturas pendientes
        if (hasPendingInvoices && userId.isNotEmpty) {
          for (var invoice in userInvoices) {
            if (invoice.id.isEmpty) continue;
            
            try {
              // Marcar factura como enviada
              await _firestore.collection('invoices').doc(invoice.id).update({
                'sentAt': FieldValue.serverTimestamp(),
              });

              // Enviar notificación al usuario
              await _notificationService.sendToUser(
                userId: userId,
                title: 'Nueva factura disponible',
                body: 'Tu factura ${invoice.invoiceNumber} por ${_formatCurrency(invoice.amount)} está disponible. Vence el ${_formatDate(invoice.dueDate)}.',
                data: {
                  'type': 'invoice_sent',
                  'invoiceId': invoice.id,
                },
              );
            } catch (e) {
              // Error silencioso, continuar con la siguiente factura
            }
          }
        }
      }
    } catch (e) {
      // Error silencioso
    }
  }

  // Generar facturas automáticas para usuarios con configuración activa
  static Future<void> _generateAutomaticInvoices(DateTime now) async {
    try {
      // Obtener todas las configuraciones activas de facturación automática
      final schedulesSnapshot = await _firestore
          .collection('invoice_schedules')
          .where('isActive', isEqualTo: true)
          .get();

      if (schedulesSnapshot.docs.isEmpty) {
        return;
      }

      // Obtener información de usuarios
      final userService = UserService();
      final allUsersStream = userService.getAllUsers();
      final allUsers = await allUsersStream.first;

      for (var scheduleDoc in schedulesSnapshot.docs) {
        final schedule = InvoiceScheduleModel.fromMap(scheduleDoc.data(), scheduleDoc.id);
        
        // Validar que schedule.userId no esté vacío
        if (schedule.userId.isEmpty) continue;
        
        final user = allUsers.firstWhere(
          (u) => u.id == schedule.userId,
          orElse: () => throw Exception('Usuario no encontrado'),
        );

        // Validar que user.id no esté vacío
        if (user.id.isEmpty) continue;

        // Verificar si ya existe una factura para este mes
        final currentMonth = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        
        final existingInvoice = await _firestore
            .collection('invoices')
            .where('userId', isEqualTo: user.id)
            .where('issueDate', isGreaterThanOrEqualTo: currentMonth)
            .where('issueDate', isLessThan: nextMonth)
            .limit(1)
            .get();

        if (existingInvoice.docs.isNotEmpty) {
          continue; // Ya existe una factura para este mes
        }

        // Calcular monto basado en el plan del usuario usando el método centralizado
        final planString = user.internetPlan ?? 'plan_basico';
        final amount = InvoiceModel.getPlanPrice(planString);

        // Calcular fechas
        final issueDate = DateTime(now.year, now.month, 25);
        final dueDate = calculateDueDate(issueDate);

        // Generar número de factura
        final invoiceNumber = await _invoiceService.generateInvoiceNumber();
        if (invoiceNumber.isEmpty) continue;

        // Crear factura
        final invoiceId = _firestore.collection('invoices').doc().id;
        if (invoiceId.isEmpty) continue;
        
        final invoice = InvoiceModel(
          id: invoiceId,
          userId: user.id,
          invoiceNumber: invoiceNumber,
          customerName: user.name,
          customerLastName: user.lastName,
          customerAddress: user.address,
          customerPhone: user.phone,
          customerEmail: user.email,
          internetPlan: planString,
          amount: amount,
          issueDate: issueDate,
          dueDate: dueDate,
          status: 'Pendiente',
          createdAt: DateTime.now(),
          autoSend: true,
        );

        await _invoiceService.createInvoice(invoice);
      }
    } catch (e) {
      // Error silencioso
    }
  }

  // Enviar recordatorios de facturas próximas a vencer
  static Future<void> _sendUpcomingReminders(DateTime now, int currentDay) async {
    try {
      // Obtener facturas próximas a vencer
      final upcomingInvoices = await _invoiceService.getUpcomingInvoices();
      
      if (upcomingInvoices.isEmpty) {
        return;
      }
      
      // Agrupar facturas por usuario
      final Map<String, List<InvoiceModel>> invoicesByUser = {};
      for (var invoice in upcomingInvoices) {
        if (!invoicesByUser.containsKey(invoice.userId)) {
          invoicesByUser[invoice.userId] = [];
        }
        invoicesByUser[invoice.userId]!.add(invoice);
      }
      
      // Obtener usuarios con configuración activa
      final activeSchedules = await _firestore
          .collection('invoice_schedules')
          .where('isActive', isEqualTo: true)
          .get();
      
      final activeUserIds = activeSchedules.docs
          .map((doc) => InvoiceScheduleModel.fromMap(doc.data(), doc.id).userId)
          .toSet();
      
      // Verificar cada usuario y enviar notificación solo si tiene facturas pendientes y configuración activa
      for (var entry in invoicesByUser.entries) {
        final userId = entry.key;
        
        // Validar que el userId no esté vacío
        if (userId.isEmpty) continue;
        
        // Solo procesar usuarios con configuración activa
        if (!activeUserIds.contains(userId)) {
          continue;
        }
        
        final userInvoices = entry.value;
        if (userInvoices.isEmpty) continue;
        
        // Verificar si el usuario tiene todas las facturas pagadas
        final allUserInvoices = await _firestore
            .collection('invoices')
            .where('userId', isEqualTo: userId)
            .get();
        
        bool hasPendingInvoices = false;
        for (var doc in allUserInvoices.docs) {
          final invoice = InvoiceModel.fromMap(doc.data(), doc.id);
          if (invoice.status == 'Pendiente') {
            hasPendingInvoices = true;
            break;
          }
        }
        
        // Solo enviar notificación si el usuario tiene facturas pendientes
        if (hasPendingInvoices) {
          final invoice = userInvoices.first;
          if (invoice.id.isEmpty) continue;
          
          final daysUntilDue = invoice.dueDate.difference(now).inDays;
          
          String message;
          if (currentDay == 5) {
            message = 'Tu factura ${invoice.invoiceNumber} vence en $daysUntilDue días. Por favor realiza el pago antes del día 10.';
          } else if (currentDay == 30) {
            message = 'Tu factura ${invoice.invoiceNumber} vence pronto. Por favor realiza el pago antes del día 10.';
          } else {
            message = 'Tu factura ${invoice.invoiceNumber} está próxima a vencer.';
          }
          
          try {
            await _notificationService.sendToUser(
              userId: userId,
              title: 'Factura próxima a vencer',
              body: message,
              data: {
                'type': 'invoice_upcoming',
                'invoiceId': invoice.id,
              },
            );
          } catch (e) {
            // Error silencioso
          }
        }
      }
    } catch (e) {
      // Error silencioso
    }
  }

  // Marcar facturas vencidas como "Corte de Servicio" el día 10
  static Future<void> _markOverdueInvoicesAsServiceCut(DateTime now) async {
    try {
      // Obtener facturas que vencen el día 10 del mes actual y están pendientes
      final dueDateStart = DateTime(now.year, now.month, 10);
      final dueDateEnd = DateTime(now.year, now.month, 10, 23, 59, 59);
      
      // Obtener todas las facturas pendientes
      final snapshot = await _firestore
          .collection('invoices')
          .where('status', isEqualTo: 'Pendiente')
          .get();

      final overdueInvoices = snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .where((invoice) {
            final dueDate = invoice.dueDate;
            // Facturas que vencieron el día 10 del mes actual
            return dueDate.isAfter(dueDateStart.subtract(const Duration(days: 1))) &&
                   dueDate.isBefore(dueDateEnd.add(const Duration(days: 1))) &&
                   now.isAfter(dueDate);
          })
          .toList();

      if (overdueInvoices.isEmpty) {
        return;
      }

      // Agrupar facturas por usuario
      final Map<String, List<InvoiceModel>> invoicesByUser = {};
      for (var invoice in overdueInvoices) {
        if (!invoicesByUser.containsKey(invoice.userId)) {
          invoicesByUser[invoice.userId] = [];
        }
        invoicesByUser[invoice.userId]!.add(invoice);
      }

      // Obtener usuarios con configuración activa
      final activeSchedules = await _firestore
          .collection('invoice_schedules')
          .where('isActive', isEqualTo: true)
          .get();
      
      final activeUserIds = activeSchedules.docs
          .map((doc) => InvoiceScheduleModel.fromMap(doc.data(), doc.id).userId)
          .toSet();
      
      // Marcar cada factura como "Corte de Servicio" y notificar (solo usuarios con configuración activa)
      for (var entry in invoicesByUser.entries) {
        final userId = entry.key;
        
        // Validar que el userId no esté vacío
        if (userId.isEmpty) continue;
        
        // Solo procesar usuarios con configuración activa
        if (!activeUserIds.contains(userId)) {
          continue;
        }

        final userInvoices = entry.value;

        for (var invoice in userInvoices) {
          if (invoice.id.isEmpty) continue;
          
          try {
            // Marcar factura como "Corte de Servicio"
            await _firestore.collection('invoices').doc(invoice.id).update({
              'status': 'Corte de Servicio',
            });

            // Enviar notificación al usuario
            await _notificationService.sendToUser(
              userId: userId,
              title: 'Servicio Suspendido',
              body: 'Tu factura ${invoice.invoiceNumber} ha sido marcada como "Corte de Servicio" por falta de pago. Por favor contacta con soporte.',
              data: {
                'type': 'invoice_service_cut',
                'invoiceId': invoice.id,
              },
            );
          } catch (e) {
            // Error silencioso, continuar con la siguiente factura
          }
        }
      }
    } catch (e) {
      // Error silencioso
    }
  }

  // Formatear fecha
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formatear moneda
  static String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} COP';
  }

  // Programar envío de factura
  static Future<void> scheduleInvoiceSend(String invoiceId, DateTime sendDate) async {
    // La lógica ahora se maneja automáticamente en checkAndSendPendingInvoices
  }

  // Cancelar programación de factura
  static Future<void> cancelScheduledInvoice(String invoiceId) async {
    // No se necesita acción específica
  }
}

