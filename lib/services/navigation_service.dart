import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/tickets/ticket_detail_screen.dart';
import '../screens/invoices/invoice_detail_screen.dart';
import '../screens/user/user_invoice_detail_screen.dart';
import '../screens/admin/admin_tickets_screen.dart';
import '../screens/user/user_tickets_screen.dart';
import '../screens/worker/worker_tickets_screen.dart';
import '../providers/auth_provider.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<void> navigateFromNotification({
    required String type,
    required String id,
    Map<String, dynamic>? data,
  }) async {
    final ctx = context;
    if (ctx == null) {
      await Future.delayed(const Duration(milliseconds: 1000));
      final retryCtx = context;
      if (retryCtx == null) return;
      await _performNavigation(retryCtx, type, id);
      return;
    }

    await _performNavigation(ctx, type, id);
  }

  static Future<void> _performNavigation(
    BuildContext context,
    String type,
    String id,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!context.mounted) return;

      switch (type) {
        case 'ticket':
        case 'ticket_update':
        case 'ticket_message':
          await _navigateToTicket(context, id);
          break;
        case 'invoice':
        case 'invoice_update':
          await _navigateToInvoice(context, id);
          break;
        case 'alert':
        case 'system':
          await _navigateToHome(context);
          break;
        default:
          await _navigateToHome(context);
      }
    } catch (e) {
      if (context.mounted) {
        await _navigateToHome(context);
      }
    }
  }

  static Future<void> _navigateToTicket(BuildContext context, String ticketId) async {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!context.mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(ticketId: ticketId),
      ),
    );
  }

  static Future<void> _navigateToInvoice(BuildContext context, String invoiceId) async {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!context.mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.currentUser?.role ?? 'user';
    
    if (userRole == 'admin') {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoiceId: invoiceId),
        ),
      );
    } else {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => UserInvoiceDetailScreen(invoiceId: invoiceId),
        ),
      );
    }
  }

  static Future<void> _navigateToHome(BuildContext context) async {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!context.mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.currentUser?.role;
    
    Widget homeScreen;
    switch (userRole) {
      case 'admin':
        homeScreen = const AdminTicketsScreen();
        break;
      case 'worker':
        homeScreen = const WorkerTicketsScreen();
        break;
      default:
        homeScreen = const UserTicketsScreen();
    }

    if (context.mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeScreen),
        (route) => false,
      );
    }
  }

  static void navigateToScreen(Widget screen) {
    final ctx = context;
    if (ctx == null) return;

    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

