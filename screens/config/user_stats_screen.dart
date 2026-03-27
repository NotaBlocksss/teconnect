import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';
import '../tickets/ticket_detail_screen.dart';

class UserStatsScreen extends StatelessWidget {
  //Rs Development
  const UserStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final ticketService = TicketService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(width: double.infinity, height: double.infinity, 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0E27),
                    const Color(0xFF1A1F3A),
                    const Color(0xFF0F1419),
                  ]
                : [
                    AppTheme.primaryBlue.withValues(alpha: 0.08),
                    const Color(0xFF2A2A2A),
                    AppTheme.lightBlue.withValues(alpha: 0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<TicketModel>>(
            stream: user != null ? ticketService.getTicketsByUser(user.id) : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryBlue,
                  ),
                );
              }

              if (snapshot.hasError) {
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final tickets = snapshot.data ?? [];
              final openTickets = tickets.where((t) => t.status == 'open').length;
              final inProgressTickets = tickets.where((t) => t.status == 'in_progress').length;
              final closedTickets = tickets.where((t) => t.status == 'closed' || t.status == 'resolved').length;
              final totalTickets = tickets.length;

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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.darkBlue,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: AppTheme.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mis Estadísticas',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Resumen de tus tickets',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Gráfica de distribución por estado
                    _buildStatusChart(openTickets, inProgressTickets, closedTickets, totalTickets, isDark),
                    const SizedBox(height: 24),
                    
                    // Gráfica de prioridades
                    _buildPriorityChart(tickets, isDark),
                    
                    // Últimos tickets
                    if (tickets.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              size: 20,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Últimos Tickets',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...tickets.take(5).map((ticket) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TicketCard(
                          ticket: ticket,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                              ),
                            );
                          },
                        ),
                      )),
                    ] else ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes tickets aún',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea tu primer ticket para comenzar',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChart(int open, int inProgress, int closed, int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Distribución por Estado',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  letterSpacing: -0.3,
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
                              color: const Color(0xFF2A2A2A),
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
                              color: const Color(0xFF2A2A2A),
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
                              color: const Color(0xFF2A2A2A),
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
                      _buildLegendItem('Abiertos', AppTheme.info, open, isDark),
                      const SizedBox(height: 8),
                      _buildLegendItem('En Progreso', AppTheme.warning, inProgress, isDark),
                      const SizedBox(height: 8),
                      _buildLegendItem('Cerrados', AppTheme.success, closed, isDark),
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

  Widget _buildPriorityChart(List<TicketModel> tickets, bool isDark) {
    final low = tickets.where((t) => t.priority == 'low').length;
    final medium = tickets.where((t) => t.priority == 'medium').length;
    final high = tickets.where((t) => t.priority == 'high').length;
    final urgent = tickets.where((t) => t.priority == 'urgent').length;

    final maxValue = [low, medium, high, urgent]
            .reduce((a, b) => a > b ? a : b)
            .toDouble() *
        1.2;
    final safeMaxValue = maxValue > 0 ? maxValue : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Distribución por Prioridad',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
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
                    getTooltipColor: (_) => isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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
                            color: Colors.white.withValues(alpha: 0.9),
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
                      color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
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
                        toY: low.toDouble(),
                        color: AppTheme.success,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: medium.toDouble(),
                        color: AppTheme.info,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: high.toDouble(),
                        color: AppTheme.warning,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: urgent.toDouble(),
                        color: AppTheme.error,
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

  Widget _buildLegendItem(String label, Color color, int value, bool isDark) {
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
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            softWrap: true,
            maxLines: 1,
          ),
        ),
        if (value > 0) ...[
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.isDark,
    required this.onTap,
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
        return Colors.white.withValues(alpha: 0.9);
      default:
        return Colors.white.withValues(alpha: 0.9);
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
        return Colors.white.withValues(alpha: 0.9);
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'low':
        return 'Baja';
      case 'medium':
        return 'Media';
      case 'high':
        return 'Alta';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.folder_open_rounded;
      case 'in_progress':
        return Icons.hourglass_empty_rounded;
      case 'closed':
      case 'resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(ticket.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(ticket.status),
                    color: _getStatusColor(ticket.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        softWrap: true,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(ticket.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: _getStatusColor(ticket.status),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getStatusText(ticket.status),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(ticket.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(ticket.priority).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.priority_high_rounded,
                                  size: 14,
                                  color: _getPriorityColor(ticket.priority),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getPriorityText(ticket.priority),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getPriorityColor(ticket.priority),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
