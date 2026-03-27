import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/alert_service.dart';
import '../../services/ticket_service.dart';
import '../../services/invoice_service.dart';
import '../../models/alert_model.dart';
import '../../models/ticket_model.dart';
import '../../models/invoice_model.dart';
import '../../theme/app_theme.dart';
import '../tickets/create_ticket_screen.dart';
import '../tickets/ticket_detail_screen.dart';
import 'user_invoices_screen.dart';
import 'user_invoice_detail_screen.dart';

class UserInicioScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTickets;

  const UserInicioScreen({
    super.key,
    this.onNavigateToTickets,
  });

  @override
  State<UserInicioScreen> createState() => _UserInicioScreenState();
}

class _UserInicioScreenState extends State<UserInicioScreen> {
  //Rs Development

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ticketService = TicketService();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(context, user?.name ?? 'Usuario', isDark),
                const SizedBox(height: 32),
                
                // Sección de Alertas del Administrador
                _buildSectionTitle('Alertas importantes', Icons.notifications_active_rounded, isDark),
                const SizedBox(height: 12),
                StreamBuilder<AlertModel?>(
                  stream: AlertService().getActiveAlert(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingAlertCard(context, isDark);
                    }
                    if (snapshot.hasError) {
                      return _buildEmptyAlertCard(context, isDark);
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      final alert = snapshot.data!;
                      if (alert.shouldShow) {
                        return _AlertCard(alert: alert, isDark: isDark);
                      }
                    }
                    return _buildEmptyAlertCard(context, isDark);
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Última Factura
                _buildSectionTitle('Mi última factura', Icons.receipt_long_rounded, isDark),
                const SizedBox(height: 12),
                StreamBuilder<List<InvoiceModel>>(
                  stream: user != null ? InvoiceService().getInvoicesByUser(user.id) : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingInvoiceCard(isDark);
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyInvoiceCard(isDark);
                    }
                    final invoices = snapshot.data!;
                    final lastInvoice = invoices.first; // Ya está ordenado por createdAt desc
                    return _LastInvoiceCard(invoice: lastInvoice, isDark: isDark);
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Tickets Recientes
                _buildSectionTitle('Tickets recientes', Icons.history_rounded, isDark),
                const SizedBox(height: 12),
                StreamBuilder<List<TicketModel>>(
                  stream: user != null ? ticketService.getTicketsByUser(user.id) : null,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingTickets(isDark);
                    }
                    final tickets = snapshot.data ?? [];
                    if (tickets.isEmpty) {
                      return _buildEmptyTicketsCard(isDark);
                    }
                    // Mostrar los 3 tickets más recientes
                    final recentTickets = tickets.take(3).toList();
                    return Column(
                      children: recentTickets.map((ticket) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecentTicketCard(ticket: ticket, isDark: isDark),
                        ),
                      ).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Acciones rápidas
                _buildSectionTitle('Acciones rápidas', Icons.flash_on_rounded, isDark),
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Crear nuevo ticket',
                  subtitle: 'Solicita ayuda o reporta un problema',
                  color: AppTheme.primaryBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTicketScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: 'Ver todos mis tickets',
                  subtitle: 'Revisa el estado de todas tus solicitudes',
                  color: AppTheme.info,
                  onTap: () {
                    widget.onNavigateToTickets?.call();
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Ver mis facturas',
                  subtitle: 'Consulta todas tus facturas pagadas y pendientes',
                  color: AppTheme.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserInvoicesScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Centro de ayuda',
                  subtitle: 'Encuentra respuestas a preguntas frecuentes',
                  color: AppTheme.warning,
                  onTap: () {
                    _showHelpDialog(context, isDark);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Rs Development
  Widget _buildHeader(BuildContext context, String userName, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.darkBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: AppTheme.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $userName!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bienvenido de nuevo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  //Rs Development
  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
            softWrap: true,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  //Rs Development
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        softWrap: true,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        softWrap: true,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAlertCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyAlertCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No hay alertas',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No hay alertas importantes en este momento',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTickets(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyTicketsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No tienes tickets aún',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea tu primer ticket para comenzar',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingInvoiceCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyInvoiceCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No hay facturas',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aún no tienes facturas asignadas',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Centro de Ayuda',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                icon: Icons.add_circle_outline_rounded,
                title: 'Crear un ticket',
                description: 'Usa el botón "Crear nuevo ticket" para reportar problemas o solicitar ayuda.',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.history_rounded,
                title: 'Ver mis tickets',
                description: 'Revisa el estado de todos tus tickets en la sección "Tickets".',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.notifications_active_rounded,
                title: 'Alertas',
                description: 'Las alertas importantes del administrador aparecerán en esta pantalla.',
                isDark: isDark,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                softWrap: true,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                softWrap: true,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentTicketCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;

  const _RecentTicketCard({
    required this.ticket,
    required this.isDark,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppTheme.info;
      case 'in_progress':
        return AppTheme.warning;
      case 'resolved':
        return AppTheme.success;
      case 'closed':
        return AppTheme.gray;
      default:
        return AppTheme.gray;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'Abierto';
      case 'in_progress':
        return 'En progreso';
      case 'resolved':
        return 'Resuelto';
      case 'closed':
        return 'Cerrado';
      default:
        return status;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return AppTheme.success;
      case 'medium':
        return AppTheme.info;
      case 'high':
        return AppTheme.warning;
      case 'urgent':
        return AppTheme.error;
      default:
        return AppTheme.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticketId: ticket.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(ticket.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: _getStatusColor(ticket.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        softWrap: true,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(ticket.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(ticket.status),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(ticket.status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(ticket.priority).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ticket.priority.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(ticket.priority),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final bool isDark;

  const _AlertCard({
    required this.alert,
    required this.isDark,
  });

  Color _getTypeColor(String type) {
    switch (type) {
      case 'informacion':
        return AppTheme.success; // Verde
      case 'advertencia':
        return AppTheme.warning; // Amarillo
      case 'mantenimiento':
        return AppTheme.error; // Rojo
      case 'caida_servicio':
        return Colors.purple; // Morado
      default:
        return AppTheme.info;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'informacion':
        return Icons.info_outline_rounded;
      case 'advertencia':
        return Icons.warning_amber_rounded;
      case 'mantenimiento':
        return Icons.build_rounded;
      case 'caida_servicio':
        return Icons.cloud_off_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(alert.type);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: typeColor.withValues(alpha: 0.05),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getTypeIcon(alert.type),
                      color: typeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          softWrap: true,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Del administrador',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alert.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.5,
                  ),
                  overflow: TextOverflow.visible,
                  maxLines: 10,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastInvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isDark;

  const _LastInvoiceCard({
    required this.invoice,
    required this.isDark,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pagada':
        return AppTheme.success;
      case 'Pendiente':
        return AppTheme.warning;
      case 'Corte de Servicio':
        return AppTheme.error;
      default:
        return AppTheme.gray;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pagada':
        return 'Pagada';
      case 'Pendiente':
        return 'Pendiente';
      case 'Corte de Servicio':
        return 'Corte de Servicio';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} COP';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(invoice.status);
    final isOverdue = invoice.isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue 
              ? AppTheme.error.withValues(alpha: 0.3)
              : statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserInvoiceDetailScreen(invoiceId: invoice.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusColor,
                            statusColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppTheme.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                            softWrap: true,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(invoice.status),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                              softWrap: true,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monto',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(invoice.amount),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Vence',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(invoice.dueDate),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isOverdue 
                                  ? AppTheme.error
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta factura está vencida',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
