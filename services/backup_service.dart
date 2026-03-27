import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear backup completo de todas las colecciones
  Future<Map<String, dynamic>> createBackup({
    Function(String)? onProgress,
  }) async {
    final backup = <String, dynamic>{
      'version': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
      'collections': <String, dynamic>{},
    };

    try {
      // Backup de usuarios
      onProgress?.call('Respaldando usuarios...');
      final usersSnapshot = await _firestore.collection('users').get();
      backup['collections']['users'] = usersSnapshot.docs
          .map((doc) => {'id': doc.id, 'data': doc.data()})
          .toList();

      // Backup de tickets
      onProgress?.call('Respaldando tickets...');
      final ticketsSnapshot = await _firestore.collection('tickets').get();
      final tickets = <Map<String, dynamic>>[];

      for (var ticketDoc in ticketsSnapshot.docs) {
        final ticketData = {
          'id': ticketDoc.id,
          'data': ticketDoc.data(),
          'messages': <Map<String, dynamic>>[],
        };

        // Backup de mensajes de cada ticket
        try {
          final messagesSnapshot = await ticketDoc.reference
              .collection('messages')
              .get();
          ticketData['messages'] = messagesSnapshot.docs
              .map((doc) => {'id': doc.id, 'data': doc.data()})
              .toList();
        } catch (e) {
          // Si hay error al obtener mensajes, continuar sin ellos
        }

        tickets.add(ticketData);
      }
      backup['collections']['tickets'] = tickets;

      // Backup de alertas
      onProgress?.call('Respaldando alertas...');
      final alertsSnapshot = await _firestore.collection('alerts').get();
      backup['collections']['alerts'] = alertsSnapshot.docs
          .map((doc) => {'id': doc.id, 'data': doc.data()})
          .toList();

      onProgress?.call('Backup completado');
      return backup;
    } catch (e) {
      throw Exception('Error al crear backup: $e');
    }
  }

  /// Exportar backup como archivo JSON y compartirlo
  Future<void> exportBackup({
    Function(String)? onProgress,
  }) async {
    try {
      // Crear backup
      final backup = await createBackup(onProgress: onProgress);

      // Convertir a JSON
      onProgress?.call('Generando archivo JSON...');
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      // Guardar temporalmente
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'teconnect_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Compartir archivo
      onProgress?.call('Compartiendo archivo...');
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Backup Teconnect Support',
        text: 'Backup completo del sistema Teconnect Support generado el ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      throw Exception('Error al exportar backup: $e');
    }
  }

  /// Obtener estadísticas del backup
  Future<Map<String, int>> getBackupStats() async {
    try {
      final usersCount = await _firestore.collection('users').count().get();
      final ticketsCount = await _firestore.collection('tickets').count().get();
      final alertsCount = await _firestore.collection('alerts').count().get();

      // Contar mensajes
      int messagesCount = 0;
      final ticketsSnapshot = await _firestore.collection('tickets').get();
      for (var ticketDoc in ticketsSnapshot.docs) {
        final messagesSnapshot = await ticketDoc.reference
            .collection('messages')
            .count()
            .get();
        messagesCount += messagesSnapshot.count ?? 0;
      }

      return {
        'users': usersCount.count ?? 0,
        'tickets': ticketsCount.count ?? 0,
        'alerts': alertsCount.count ?? 0,
        'messages': messagesCount,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}

