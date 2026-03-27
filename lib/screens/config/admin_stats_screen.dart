import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/ticket_service.dart';
import '../../services/user_service.dart';
import '../../services/alert_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  static const Color _primaryRed = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final ticketService = TicketService();
    final userService = UserService();
    final alertService = AlertService();
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: StreamBuilder(
            stream: ticketService.getAllTickets(),
            builder: (context, ticketSnapshot) {
              return StreamBuilder(
                stream: userService.getAllUsers(),
                builder: (context, userSnapshot) {
                  return StreamBuilder(
                    stream: alertService.getAllAlerts(),
                    builder: (context, alertSnapshot) {
                      if (ticketSnapshot.connectionState == ConnectionState.waiting ||
                          userSnapshot.connectionState == ConnectionState.waiting ||
                          alertSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: _primaryRed,
                          ),
                        );
                      }

                      if (ticketSnapshot.hasError || userSnapshot.hasError || alertSnapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: AppTheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar estadísticas',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final tickets = ticketSnapshot.data ?? [];
                      final users = userSnapshot.data ?? [];
                      final alerts = alertSnapshot.data ?? [];
                      
                      // Estadísticas de tickets
                      final openTickets = tickets.where((t) => t.status == 'open').length;
                      final inProgressTickets = tickets.where((t) => t.status == 'in_progress').length;
                      final closedTickets = tickets.where((t) => t.status == 'closed' || t.status == 'resolved').length;
                      
                      // Estadísticas de usuarios
                      final totalUsers = users.length;
                      final adminUsers = users.where((u) => u.role == 'admin').length;
                      final workerUsers = users.where((u) => u.role == 'worker').length;
                      final regularUsers = users.where((u) => u.role == 'user').length;
                      
                      // Estadísticas de alertas (del admin actual)
                      final myAlerts = currentUser != null 
                          ? alerts.where((a) => a.createdBy == currentUser.id).length 
                          : 0;
                      final totalAlerts = alerts.length;
                      final activeAlerts = alerts.where((a) => a.isActive).length;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _primaryRed,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryRed.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded),
                                onPressed: () => Navigator.pop(context),
                                color: Theme.of(context).cardColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estadísticas del Sistema',
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Resumen general del sistema',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Sección Tickets
                        _buildSectionTitle(context, 'Tickets', Icons.support_agent_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildTicketsChart(context, openTickets, inProgressTickets, closedTickets, tickets.length, isDark),
                        const SizedBox(height: 32),
                        
                        // Sección Usuarios
                        _buildSectionTitle(context, 'Usuarios', Icons.people_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildUsersChart(context, adminUsers, workerUsers, regularUsers, totalUsers, isDark),
                        const SizedBox(height: 32),
                        
                        // Sección Alertas
                        _buildSectionTitle(context, 'Alertas', Icons.notifications_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildAlertsChart(context, totalAlerts, activeAlerts, myAlerts, isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, bool isDark) {
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

  Widget _buildTicketsChart(BuildContext context, int open, int inProgress, int closed, int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  size: 20,
                  color: _primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Distribución de Tickets',
                style: GoogleFonts.inter(
                  fontSize: 18,
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
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        if (open > 0)
                          PieChartSectionData(
                            value: open.toDouble(),
                            title: '$open',
                            color: AppTheme.info,
                            radius: 50,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                        if (inProgress > 0)
                          PieChartSectionData(
                            value: inProgress.toDouble(),
                            title: '$inProgress',
                            color: AppTheme.warning,
                            radius: 50,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                        if (closed > 0)
                          PieChartSectionData(
                            value: closed.toDouble(),
                            title: '$closed',
                            color: AppTheme.success,
                            radius: 50,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(context, 'Abiertos', AppTheme.info, open, isDark),
                      const SizedBox(height: 8),
                      _buildLegendItem(context, 'En Progreso', AppTheme.warning, inProgress, isDark),
                      const SizedBox(height: 8),
                      _buildLegendItem(context, 'Cerrados', AppTheme.success, closed, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersChart(BuildContext context, int admins, int workers, int regular, int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  size: 20,
                  color: _primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Distribución de Usuarios',
                style: GoogleFonts.inter(
                  fontSize: 18,
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
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        if (admins > 0)
                          PieChartSectionData(
                            value: admins.toDouble(),
                            title: '$admins',
                            color: AppTheme.error,
                            radius: 50,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                        if (workers > 0)
                          PieChartSectionData(
                            value: workers.toDouble(),
                            title: '$workers',
                            color: AppTheme.warning,
                            radius: 50,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                        if (regular > 0)
                          PieChartSectionData(
                            value: regular.toDouble(),
                            title: '$regular',
                            color: AppTheme.info,
                            radius: 50,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(context, 'Admins', AppTheme.error, admins, isDark),
                      const SizedBox(height: 8),
                      _buildLegendItem(context, 'Workers', AppTheme.warning, workers, isDark),
                      const SizedBox(height: 8),
                      _buildLegendItem(context, 'Usuarios', AppTheme.info, regular, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsChart(BuildContext context, int total, int active, int my, bool isDark) {
    final maxValue = [total, active, my]
            .reduce((a, b) => a > b ? a : b)
            .toDouble() *
        1.2;
    final safeMaxValue = maxValue > 0 ? maxValue : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: _primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Estadísticas de Alertas',
                style: GoogleFonts.inter(
                  fontSize: 18,
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
                maxY: safeMaxValue,
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
                                'Total',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            );
                          case 1:
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Activas',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            );
                          case 2:
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Mías',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMaxValue / 5 > 0 ? (safeMaxValue / 5).clamp(1.0, double.infinity) : 1.0,
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
                        toY: total.toDouble(),
                        color: AppTheme.info,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: active.toDouble(),
                        color: AppTheme.warning,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: my.toDouble(),
                        color: _primaryRed,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, int value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
            softWrap: true,
          ),
        ),
        if (value > 0) ...[
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}
