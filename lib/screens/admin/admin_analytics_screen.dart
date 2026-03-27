import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/ticket_service.dart';
import '../../services/user_service.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  static const Color _primaryRed = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ticketService = TicketService();
    final userService = UserService();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

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
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estadísticas y análisis',
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
                _buildSectionTitle('Evolución del Día', Icons.today_rounded, isDark),
                const SizedBox(height: 16),
                StreamBuilder<List<TicketModel>>(
                  stream: ticketService.getAllTickets(),
                  builder: (context, ticketSnapshot) {
                    return StreamBuilder(
                      stream: userService.getAllUsers(),
                      builder: (context, userSnapshot) {
                        final allTickets = ticketSnapshot.data ?? [];

                        final todayTickets = allTickets.where((ticket) {
                          final ticketDate = ticket.createdAt;
                          return ticketDate.isAfter(todayStart) && ticketDate.isBefore(todayEnd);
                        }).toList();

                        final hourlyData = _getHourlyData(todayTickets, todayStart, now);

                        return _buildDayChart(hourlyData, isDark);
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Distribución del Mes', Icons.calendar_month_rounded, isDark),
                const SizedBox(height: 16),
                StreamBuilder<List<TicketModel>>(
                  stream: ticketService.getAllTickets(),
                  builder: (context, ticketSnapshot) {
                    return StreamBuilder(
                      stream: userService.getAllUsers(),
                      builder: (context, userSnapshot) {
                        final allTickets = ticketSnapshot.data ?? [];

                        final monthTickets = allTickets.where((ticket) {
                          final ticketDate = ticket.createdAt;
                          return ticketDate.isAfter(monthStart) && ticketDate.isBefore(monthEnd);
                        }).toList();

                        final monthOpen = monthTickets.where((t) => t.status == 'open').length;
                        final monthInProgress = monthTickets.where((t) => t.status == 'in_progress').length;
                        final monthResolved = monthTickets.where((t) => t.status == 'resolved').length;
                        final monthClosed = monthTickets.where((t) => t.status == 'closed').length;

                        final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                        final weekEnd = weekStart.add(const Duration(days: 7));
                        
                        final weekTickets = allTickets.where((ticket) {
                          final ticketDate = ticket.createdAt;
                          return ticketDate.isAfter(weekStart) && ticketDate.isBefore(weekEnd);
                        }).toList();
                        
                        final weeklyData = _getWeeklyData(weekTickets, weekStart);

                        return Column(
                          children: [
                            _buildMonthChart(
                              monthOpen,
                              monthInProgress,
                              monthResolved,
                              monthClosed,
                              isDark,
                            ),
                            const SizedBox(height: 24),
                            _buildWeeklyChart(weeklyData, isDark),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
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

  List<Map<String, dynamic>> _getHourlyData(List<TicketModel> tickets, DateTime dayStart, DateTime now) {
    final hourlyData = <Map<String, dynamic>>[];
    final currentHour = now.hour;
    
    for (int hour = 0; hour <= currentHour; hour++) {
      final hourStart = DateTime(dayStart.year, dayStart.month, dayStart.day, hour);
      final hourEnd = hourStart.add(const Duration(hours: 1));
      
      final hourTickets = tickets.where((ticket) {
        final ticketDate = ticket.createdAt;
        return ticketDate.isAfter(hourStart) && ticketDate.isBefore(hourEnd);
      }).toList();
      
      hourlyData.add({
        'hour': hour,
        'open': hourTickets.where((t) => t.status == 'open').length,
        'inProgress': hourTickets.where((t) => t.status == 'in_progress').length,
        'resolved': hourTickets.where((t) => t.status == 'resolved').length,
        'closed': hourTickets.where((t) => t.status == 'closed').length,
        'total': hourTickets.length,
      });
    }
    
    return hourlyData;
  }

  List<Map<String, dynamic>> _getWeeklyData(List<TicketModel> tickets, DateTime weekStart) {
    final weeklyData = <Map<String, dynamic>>[];
    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    
    for (int day = 0; day < 7; day++) {
      final dayStart = weekStart.add(Duration(days: day));
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayTickets = tickets.where((ticket) {
        final ticketDate = ticket.createdAt;
        return ticketDate.isAfter(dayStart) && ticketDate.isBefore(dayEnd);
      }).toList();
      
      weeklyData.add({
        'day': day,
        'dayName': dayNames[day],
        'total': dayTickets.length,
        'open': dayTickets.where((t) => t.status == 'open').length,
        'inProgress': dayTickets.where((t) => t.status == 'in_progress').length,
        'resolved': dayTickets.where((t) => t.status == 'resolved').length,
        'closed': dayTickets.where((t) => t.status == 'closed').length,
      });
    }
    
    return weeklyData;
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> weeklyData, bool isDark) {
    if (weeklyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'No hay datos para mostrar',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    final maxValue = weeklyData
            .map((d) => d['total'] as int)
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
                  Icons.calendar_view_week_rounded,
                  size: 20,
                  color: _primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Distribución por Semana',
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
            height: 250,
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
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weeklyData[value.toInt()]['dayName'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0 && value > 0) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const Text('');
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
                  horizontalInterval: safeMaxValue > 0
                      ? (safeMaxValue / 5).clamp(1.0, double.infinity)
                      : 1.0,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final total = data['total'] as int;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: total.toDouble(),
                        color: _primaryRed,
                        width: 25,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: weeklyData.map((dayData) {
              return _buildLegendItem(
                dayData['dayName'] as String,
                _primaryRed,
                dayData['total'] as int,
                isDark,
              );
            }).toList(),
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
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayChart(List<Map<String, dynamic>> hourlyData, bool isDark) {
    if (hourlyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'No hay datos para mostrar',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    final maxValue = hourlyData
            .map((d) => [
                  d['open'] as int,
                  d['inProgress'] as int,
                  d['resolved'] as int,
                  d['closed'] as int,
                ])
            .expand((list) => list)
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
                  Icons.show_chart_rounded,
                  size: 20,
                  color: _primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Evolución del Día',
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
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMaxValue > 0
                      ? (safeMaxValue / 5).clamp(1.0, double.infinity)
                      : 1.0,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour >= 0 && hour < hourlyData.length && hour % 3 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0 && value > 0) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const Text('');
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
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                    left: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: hourlyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['open'] as int).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.info,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.info.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: hourlyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['inProgress'] as int).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.warning,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.warning.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: hourlyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['resolved'] as int).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.success.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: hourlyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), (entry.value['closed'] as int).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.gray,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: safeMaxValue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Abiertos', AppTheme.info, 0, isDark),
              _buildLegendItem('En Progreso', AppTheme.warning, 0, isDark),
              _buildLegendItem('Resueltos', AppTheme.success, 0, isDark),
              _buildLegendItem('Cerrados', AppTheme.gray, 0, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChart(
    int open,
    int inProgress,
    int resolved,
    int closed,
    bool isDark,
  ) {
    final maxValue = [open, inProgress, resolved, closed]
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
                'Distribución del Mes',
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
                                'Abiertos',
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
                                'En Progreso',
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
                                'Resueltos',
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
                                'Cerrados',
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
                        if (value.toInt() % 2 == 0 && value > 0) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const Text('');
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
                  horizontalInterval: safeMaxValue > 0
                      ? (safeMaxValue / 5).clamp(1.0, double.infinity)
                      : 1.0,
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
                        toY: open.toDouble(),
                        color: AppTheme.info,
                        width: 30,
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
                        toY: inProgress.toDouble(),
                        color: AppTheme.warning,
                        width: 30,
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
                        toY: resolved.toDouble(),
                        color: AppTheme.success,
                        width: 30,
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
                        toY: closed.toDouble(),
                        color: AppTheme.gray,
                        width: 30,
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
    );
  }
}

