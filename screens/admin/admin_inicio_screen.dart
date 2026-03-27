import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../services/ticket_service.dart';
import '../../services/user_service.dart';
import '../../services/invoice_scheduler_service.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';
import '../tickets/ticket_detail_screen.dart';
import 'send_alert_screen.dart';
import 'admin_analytics_screen.dart';

class AdminInicioScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTickets;
  final VoidCallback? onNavigateToUsers;

  const AdminInicioScreen({
    super.key,
    this.onNavigateToTickets,
    this.onNavigateToUsers,
  });

  @override
  State<AdminInicioScreen> createState() => _AdminInicioScreenState();
}

class _AdminInicioScreenState extends State<AdminInicioScreen> {
  static const Color _primaryRed = Color(0xFFDC2626);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Verificar facturas pendientes cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InvoiceSchedulerService.checkAndSendPendingInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ticketService = TicketService();
    final userService = UserService();

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildDrawer(context, user, isDark),
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
                _buildHeader(context, user?.name ?? 'Administrador', isDark),
                const SizedBox(height: 32),
                
                // Estadísticas rápidas
                _buildSectionTitle('Estadísticas del Sistema', Icons.analytics_rounded, isDark),
                const SizedBox(height: 12),
                StreamBuilder<List<TicketModel>>(
                  stream: ticketService.getAllTickets(),
                  builder: (context, ticketSnapshot) {
                    return StreamBuilder(
                      stream: userService.getAllUsers(),
                      builder: (context, userSnapshot) {
                        final allTickets = ticketSnapshot.data ?? [];
                        final allUsers = userSnapshot.data ?? [];
                        final totalUsers = allUsers.length;
                        
                        return _buildChartsSection(
                          context,
                          allTickets,
                          totalUsers,
                          isDark,
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Tickets Recientes
                _buildSectionTitle('Tickets recientes', Icons.history_rounded, isDark),
                const SizedBox(height: 12),
                StreamBuilder<List<TicketModel>>(
                  stream: ticketService.getAllTickets(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingTickets(context, isDark);
                    }
                    final tickets = snapshot.data ?? [];
                    if (tickets.isEmpty) {
                      return _buildEmptyTicketsCard(context, isDark);
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
                  icon: Icons.support_agent_rounded,
                  title: 'Gestionar tickets',
                  subtitle: 'Administra todos los tickets del sistema',
                  color: _primaryRed,
                  onTap: () {
                    widget.onNavigateToTickets?.call();
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.people_rounded,
                  title: 'Gestionar usuarios',
                  subtitle: 'Administra los usuarios del sistema',
                  color: AppTheme.primaryBlue,
                  onTap: () {
                    widget.onNavigateToUsers?.call();
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Centro de ayuda',
                  subtitle: 'Encuentra respuestas a preguntas frecuentes',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    _showHelpDialog(context, isDark);
                  },
                  isDark: isDark,
                ),
                
                const SizedBox(height: 32),
                
                // Alertas
                _buildSectionTitle('Alertas', Icons.notifications_active_rounded, isDark),
                const SizedBox(height: 12),
                _buildActionCard(
                  context,
                  icon: Icons.notifications_active_rounded,
                  title: 'Enviar alerta personalizada',
                  subtitle: 'Envía una alerta a todos los usuarios',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SendAlertScreen(),
                      ),
                    );
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
                        color: _primaryRed,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryRed.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppTheme.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                    'Panel de administración',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              icon: Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, user, bool isDark) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryRed,
                boxShadow: [
                  BoxShadow(
                    color: _primaryRed.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppTheme.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Administrador',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                          softWrap: true,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Administrador',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Sección: Análisis
                  _buildDrawerSectionTitle(context, 'Análisis'),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.analytics_rounded,
                    title: 'Analytics',
                    subtitle: 'Estadísticas y gráficos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAnalyticsScreen(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección: Gestión
                  _buildDrawerSectionTitle(context, 'Gestión'),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.support_agent_rounded,
                    title: 'Gestionar tickets',
                    subtitle: 'Administra todos los tickets',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToTickets?.call();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people_rounded,
                    title: 'Gestionar usuarios',
                    subtitle: 'Administra los usuarios',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToUsers?.call();
                    },
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección: Comunicación
                  _buildDrawerSectionTitle(context, 'Comunicación'),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications_active_rounded,
                    title: 'Enviar alerta',
                    subtitle: 'Alertas personalizadas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SendAlertScreen(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sección: Ayuda
                  _buildDrawerSectionTitle(context, 'Ayuda'),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Centro de ayuda',
                    subtitle: 'Preguntas frecuentes',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context, isDark);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: _primaryRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
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

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: _primaryRed,
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

  Widget _buildChartsSection(
    BuildContext context,
    List<TicketModel> allTickets,
    int totalUsers,
    bool isDark,
  ) {
    // Calcular datos para las gráficas
    final openTickets = allTickets.where((t) => t.status == 'open').length;
    final inProgressTickets = allTickets.where((t) => t.status == 'in_progress').length;
    final resolvedTickets = allTickets.where((t) => t.status == 'resolved').length;
    final closedTickets = allTickets.where((t) => t.status == 'closed').length;
    
    final lowPriority = allTickets.where((t) => t.priority == 'low').length;
    final mediumPriority = allTickets.where((t) => t.priority == 'medium').length;
    final highPriority = allTickets.where((t) => t.priority == 'high').length;
    final urgentPriority = allTickets.where((t) => t.priority == 'urgent').length;

    return Column(
      children: [
        // Gráfica de estado de tickets (Pie Chart)
        Container(
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
                color: _primaryRed.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      size: 20,
                      color: _primaryRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tickets por Estado',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Builder(
                        builder: (chartContext) => PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              if (openTickets > 0)
                                PieChartSectionData(
                                  value: openTickets.toDouble(),
                                  title: '$openTickets',
                                  color: const Color(0xFF3B82F6),
                                  radius: 50,
                                  titleStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(chartContext).cardColor,
                                  ),
                                ),
                              if (inProgressTickets > 0)
                                PieChartSectionData(
                                  value: inProgressTickets.toDouble(),
                                  title: '$inProgressTickets',
                                  color: const Color(0xFFF59E0B),
                                  radius: 50,
                                  titleStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(chartContext).cardColor,
                                  ),
                                ),
                              if (resolvedTickets > 0)
                                PieChartSectionData(
                                  value: resolvedTickets.toDouble(),
                                  title: '$resolvedTickets',
                                  color: const Color(0xFF10B981),
                                  radius: 50,
                                  titleStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(chartContext).cardColor,
                                  ),
                                ),
                              if (closedTickets > 0)
                                PieChartSectionData(
                                  value: closedTickets.toDouble(),
                                  title: '$closedTickets',
                                  color: Colors.grey.shade400,
                                  radius: 50,
                                  titleStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(chartContext).cardColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(context, 'Abiertos', const Color(0xFF3B82F6), openTickets, isDark),
                          const SizedBox(height: 8),
                          _buildLegendItem(context, 'En Progreso', const Color(0xFFF59E0B), inProgressTickets, isDark),
                          const SizedBox(height: 8),
                          _buildLegendItem(context, 'Resueltos', const Color(0xFF10B981), resolvedTickets, isDark),
                          const SizedBox(height: 8),
                          _buildLegendItem(context, 'Cerrados', Colors.grey.shade400, closedTickets, isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Gráfica de prioridad de tickets (Bar Chart)
        Container(
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
                color: _primaryRed.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 20,
                      color: _primaryRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tickets por Prioridad',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: [
                      lowPriority,
                      mediumPriority,
                      highPriority,
                      urgentPriority,
                    ].reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Theme.of(context).cardColor,
                        tooltipRoundedRadius: 8,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Baja',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              case 1:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Media',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              case 2:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Alta',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              case 3:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Urgente',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).dividerColor.withOpacity(0.15),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: lowPriority.toDouble(),
                            color: const Color(0xFF10B981),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: mediumPriority.toDouble(),
                            color: const Color(0xFF3B82F6),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: highPriority.toDouble(),
                            color: const Color(0xFFF59E0B),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 3,
                        barRods: [
                          BarChartRodData(
                            toY: urgentPriority.toDouble(),
                            color: _primaryRed,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Resumen rápido
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _primaryRed.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      allTickets.length.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _primaryRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Tickets',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      totalUsers.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Usuarios',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, int value, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
            maxLines: 1,
            softWrap: true,
          ),
        ),
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

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
            color: _primaryRed.withValues(alpha: 0.08),
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

  Widget _buildLoadingTickets(BuildContext context, bool isDark) {
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

  Widget _buildEmptyTicketsCard(BuildContext context, bool isDark) {
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
            color: _primaryRed.withValues(alpha: 0.08),
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
            'No hay tickets aún',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Los tickets aparecerán aquí cuando se creen',
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
                color: _primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: _primaryRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Centro de Ayuda',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                context,
                icon: Icons.support_agent_rounded,
                title: 'Gestionar tickets',
                description: 'Administra todos los tickets del sistema, asígnalos a trabajadores y resuélvelos.',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                context,
                icon: Icons.people_rounded,
                title: 'Gestionar usuarios',
                description: 'Administra los usuarios del sistema, crea nuevos usuarios y edita información.',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                context,
                icon: Icons.notifications_active_rounded,
                title: 'Enviar alertas',
                description: 'Envía alertas personalizadas a todos los usuarios del sistema.',
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
              style: GoogleFonts.inter(
                color: _primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
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
            color: _primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryRed, size: 20),
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
                maxLines: 2,
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
        return const Color(0xFF3B82F6);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'closed':
        return Colors.grey.shade400;
      default:
        return Colors.grey.shade400;
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
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFF3B82F6);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'urgent':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey.shade400;
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
            color: const Color(0xFFDC2626).withValues(alpha: 0.08),
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
