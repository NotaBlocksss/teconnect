import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/expandable_filters.dart';
import '../tickets/ticket_detail_screen.dart';

class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TicketService _ticketService = TicketService();
  String _selectedStatusFilter = 'all';
  String _selectedPriorityFilter = 'all';
  String _searchQuery = '';

  static const Color _primaryRed = Color(0xFFDC2626);
  static const Color _darkRed = Color(0xFFB91C1C);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TicketModel> _filterTickets(List<TicketModel> tickets) {
    if (tickets.isEmpty) return tickets;
    
    var filtered = tickets;

    if (_selectedStatusFilter != 'all') {
      filtered = filtered.where((ticket) => ticket.status == _selectedStatusFilter).toList();
    }

    if (_selectedPriorityFilter != 'all') {
      filtered = filtered.where((ticket) => ticket.priority == _selectedPriorityFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
      filtered = filtered.where((ticket) {
        final titleLower = ticket.title.toLowerCase();
        final descLower = ticket.description.toLowerCase();
        return queryWords.every((word) => 
          titleLower.contains(word) || descLower.contains(word)
        );
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(width: double.infinity, height: double.infinity, 
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
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
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppTheme.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tickets',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 4),
                          StreamBuilder<List<TicketModel>>(
                            stream: _ticketService.getAllTickets(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.length ?? 0;
                              return Text(
                                '$count ticket${count != 1 ? 's' : ''} en total',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                softWrap: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Barra de búsqueda y filtros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Container(
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
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por título o descripción...',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _primaryRed,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExpandableFilters(
                      title: 'Filtros',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado:',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'Todos',
                                  selected: _selectedStatusFilter == 'all',
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedStatusFilter = 'all');
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Abiertos',
                                  selected: _selectedStatusFilter == 'open',
                                  color: AppTheme.info,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedStatusFilter = 'open');
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'En Progreso',
                                  selected: _selectedStatusFilter == 'in_progress',
                                  color: AppTheme.warning,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedStatusFilter = 'in_progress');
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Cerrados',
                                  selected: _selectedStatusFilter == 'closed',
                                  color: Colors.grey.shade400,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedStatusFilter = 'closed');
                                  },
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Prioridad:',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'Todas',
                                  selected: _selectedPriorityFilter == 'all',
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'all');
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Baja',
                                  selected: _selectedPriorityFilter == 'low',
                                  color: AppTheme.success,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'low');
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Media',
                                  selected: _selectedPriorityFilter == 'medium',
                                  color: AppTheme.info,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'medium');
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Alta',
                                  selected: _selectedPriorityFilter == 'high',
                                  color: AppTheme.warning,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'high');
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Urgente',
                                  selected: _selectedPriorityFilter == 'urgent',
                                  color: AppTheme.error,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'urgent');
                                  },
                                  isDark: isDark,
                                ),
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
              // Lista de tickets
              Expanded(
                child: StreamBuilder<List<TicketModel>>(
                  stream: _ticketService.getAllTickets(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: _primaryRed,
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
                              'Error al cargar tickets',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final tickets = snapshot.data ?? [];
                    final filtered = _filterTickets(tickets);

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ||
                                      _selectedStatusFilter != 'all' ||
                                      _selectedPriorityFilter != 'all'
                                  ? Icons.search_off_rounded
                                  : Icons.support_agent_outlined,
                              size: 80,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedStatusFilter != 'all' ||
                                      _selectedPriorityFilter != 'all'
                                  ? 'No se encontraron tickets'
                                  : 'No hay tickets disponibles',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ticket = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TicketCard(ticket: ticket, isDark: isDark),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final ValueChanged<bool> onSelected;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFFDC2626);
    
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected 
            ? chipColor 
            : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final bool isDark;

  const _TicketCard({
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
        return AppTheme.success;
      case 'medium':
        return AppTheme.info;
      case 'high':
        return AppTheme.warning;
      case 'urgent':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey.shade400;
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

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high_rounded;
      case 'high':
        return Icons.trending_up_rounded;
      case 'medium':
        return Icons.remove_rounded;
      default:
        return Icons.trending_down_rounded;
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                            _getPriorityIcon(ticket.priority),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(ticket.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Hace unos momentos';
        }
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
