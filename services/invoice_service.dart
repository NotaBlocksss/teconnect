import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generar número de factura único
  Future<String> generateInvoiceNumber() async {
    try {
      final year = DateTime.now().year;
      final month = DateTime.now().month.toString().padLeft(2, '0');
      
      // Obtener el último número de factura del mes
      final lastInvoice = await _firestore
          .collection('invoices')
          .where('invoiceNumber', isGreaterThan: 'FAC-$year$month-000')
          .where('invoiceNumber', isLessThan: 'FAC-$year$month-999')
          .orderBy('invoiceNumber', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;
      if (lastInvoice.docs.isNotEmpty) {
        final lastNumber = lastInvoice.docs.first.data()['invoiceNumber'] as String;
        final parts = lastNumber.split('-');
        if (parts.length == 3) {
          nextNumber = (int.tryParse(parts[2]) ?? 0) + 1;
        }
      }

      return 'FAC-$year$month-${nextNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      // Si hay error, generar número basado en timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'FAC-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${timestamp.toString().substring(timestamp.toString().length - 3)}';
    }
  }

  // Crear factura
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    try {
      // Validar que el ID de la factura no esté vacío
      if (invoice.id.isEmpty) {
        throw Exception('El ID de la factura no puede estar vacío');
      }

      final invoiceNumber = invoice.invoiceNumber.isEmpty 
          ? await generateInvoiceNumber()
          : invoice.invoiceNumber;

      if (invoiceNumber.isEmpty) {
        throw Exception('No se pudo generar el número de factura');
      }

      final invoiceWithNumber = invoice.copyWith(
        invoiceNumber: invoiceNumber,
      );

      await _firestore
          .collection('invoices')
          .doc(invoiceWithNumber.id)
          .set(invoiceWithNumber.toMap());

      return invoiceWithNumber;
    } catch (e) {
      throw Exception('Error al crear factura: $e');
    }
  }

  // Obtener todas las facturas
  Stream<List<InvoiceModel>> getAllInvoices() {
    return _firestore
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener facturas por usuario
  Stream<List<InvoiceModel>> getInvoicesByUser(String userId) {
    return _firestore
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener factura por ID
  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    try {
      if (invoiceId.isEmpty) {
        throw Exception('El ID de la factura no puede estar vacío');
      }
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();
      if (doc.exists) {
        return InvoiceModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener factura: $e');
    }
  }

  // Actualizar factura
  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      if (invoice.id.isEmpty) {
        throw Exception('El ID de la factura no puede estar vacío');
      }
      await _firestore
          .collection('invoices')
          .doc(invoice.id)
          .set(invoice.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al actualizar factura: $e');
    }
  }

  // Eliminar factura
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      if (invoiceId.isEmpty) {
        throw Exception('El ID de la factura no puede estar vacío');
      }
      await _firestore.collection('invoices').doc(invoiceId).delete();
    } catch (e) {
      throw Exception('Error al eliminar factura: $e');
    }
  }

  // Marcar factura como pagada
  Future<void> markAsPaid(String invoiceId, String? paymentMethod, String? paymentReference) async {
    try {
      if (invoiceId.isEmpty) {
        throw Exception('El ID de la factura no puede estar vacío');
      }
      await _firestore.collection('invoices').doc(invoiceId).update({
        'status': 'Pagada',
        'paidAt': DateTime.now(),
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
      });
    } catch (e) {
      throw Exception('Error al marcar factura como pagada: $e');
    }
  }

  // Marcar factura como enviada (ya no se usa, pero se mantiene por compatibilidad)
  Future<void> markAsSent(String invoiceId) async {
    try {
      if (invoiceId.isEmpty) {
        throw Exception('El ID de la factura no puede estar vacío');
      }
      await _firestore.collection('invoices').doc(invoiceId).update({
        'status': 'Pendiente',
        'sentAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Error al marcar factura como enviada: $e');
    }
  }

  // Obtener facturas pendientes de envío
  Future<List<InvoiceModel>> getPendingInvoices() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('invoices')
          .where('status', isEqualTo: 'Pendiente')
          .where('autoSend', isEqualTo: true)
          .where('sendDate', isLessThanOrEqualTo: now)
          .get();

      return snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener facturas pendientes: $e');
    }
  }

  // Obtener facturas vencidas
  Stream<List<InvoiceModel>> getOverdueInvoices() {
    final now = DateTime.now();
    return _firestore
        .collection('invoices')
        .where('status', isEqualTo: 'Pendiente')
        .where('dueDate', isLessThan: now)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Obtener facturas próximas a vencer (días 25, 30 y 5 de cada mes)
  Future<List<InvoiceModel>> getUpcomingInvoices() async {
    try {
      final now = DateTime.now();
      final currentDay = now.day;
      
      // Solo verificar en los días 25, 30 y 5
      if (currentDay != 25 && currentDay != 30 && currentDay != 5) {
        return [];
      }
      
      // Calcular fecha de vencimiento (día 10 del mes actual o siguiente)
      DateTime dueDateStart;
      DateTime dueDateEnd;
      
      if (currentDay == 5) {
        // Si estamos el día 5, las facturas vencen el día 10 del mes actual
        dueDateStart = DateTime(now.year, now.month, 10);
        dueDateEnd = DateTime(now.year, now.month, 10, 23, 59, 59);
      } else {
        // Si estamos el día 25 o 30, las facturas vencen el día 10 del mes siguiente
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        dueDateStart = DateTime(nextYear, nextMonth, 10);
        dueDateEnd = DateTime(nextYear, nextMonth, 10, 23, 59, 59);
      }
      
      // Obtener todas las facturas pendientes y filtrar por fecha
      final snapshot = await _firestore
          .collection('invoices')
          .where('status', isEqualTo: 'Pendiente')
          .get();

      final invoices = snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .where((invoice) {
            final dueDate = invoice.dueDate;
            return dueDate.isAfter(dueDateStart.subtract(const Duration(days: 1))) &&
                   dueDate.isBefore(dueDateEnd.add(const Duration(days: 1)));
          })
          .toList();

      return invoices;
    } catch (e) {
      throw Exception('Error al obtener facturas próximas a vencer: $e');
    }
  }

  // Obtener estadísticas de facturas
  Future<Map<String, dynamic>> getInvoiceStats() async {
    try {
      final allInvoices = await _firestore.collection('invoices').get();
      
      int total = 0;
      int pending = 0;
      int paid = 0;
      int overdue = 0;
      int sent = 0;
      double totalAmount = 0.0;
      double paidAmount = 0.0;
      double pendingAmount = 0.0;

      for (var doc in allInvoices.docs) {
        final invoice = InvoiceModel.fromMap(doc.data(), doc.id);
        total++;
        totalAmount += invoice.amount;

        if (invoice.status == 'Pagada') {
          paid++;
          paidAmount += invoice.amount;
        } else if (invoice.status == 'Pendiente') {
          pending++;
          pendingAmount += invoice.amount;
        }

        if (invoice.isOverdue) {
          overdue++;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'paid': paid,
        'overdue': overdue,
        'sent': sent,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}

