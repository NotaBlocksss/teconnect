import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/expandable_filters.dart';
import '../tickets/create_ticket_screen.dart';
import '../tickets/ticket_detail_screen.dart';

class UserTicketsScreen extends StatefulWidget {
  const UserTicketsScreen({super.key});

  @override
  State<UserTicketsScreen> createState() => _UserTicketsScreenState();
}

class _UserTicketsScreenState extends State<UserTicketsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TicketService _ticketService = TicketService();
  String _selectedStatusFilter = 'all';
  String _selectedPriorityFilter = 'all';
  String _searchQuery = '';

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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
          ),
          child: const Center(
            child: Text('No hay usuario autenticado'),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                            'Mis Tickets',
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
                            stream: _ticketService.getTicketsByUser(user.id),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.length ?? 0;
                              return Text(
                                '$count ticket${count != 1 ? 's' : ''} en total',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
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
                    TextField(
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
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
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
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Abiertos',
                                  selected: _selectedStatusFilter == 'open',
                                  color: AppTheme.info,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedStatusFilter = 'open');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'En Progreso',
                                  selected: _selectedStatusFilter == 'in_progress',
                                  color: AppTheme.warning,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedStatusFilter = 'in_progress');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Cerrados',
                                  selected: _selectedStatusFilter == 'closed',
                                  color: AppTheme.gray,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedStatusFilter = 'closed');
                                  },
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
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Baja',
                                  selected: _selectedPriorityFilter == 'low',
                                  color: AppTheme.success,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'low');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Media',
                                  selected: _selectedPriorityFilter == 'medium',
                                  color: AppTheme.info,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'medium');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Alta',
                                  selected: _selectedPriorityFilter == 'high',
                                  color: AppTheme.warning,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'high');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Urgente',
                                  selected: _selectedPriorityFilter == 'urgent',
                                  color: AppTheme.error,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedPriorityFilter = 'urgent');
                                  },
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
                  stream: _ticketService.getTicketsByUser(user.id),
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
                                  : 'No tienes tickets aún',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (_searchQuery.isEmpty &&
                                _selectedStatusFilter == 'all' &&
                                _selectedPriorityFilter == 'all')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Crea tu primer ticket para comenzar',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
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
      floatingActionButton: StreamBuilder<List<TicketModel>>(
        stream: _ticketService.getTicketsByUser(user.id),
        builder: (context, snapshot) {
          final hasOpenTicket = snapshot.data?.any((t) => t.status != 'closed' && t.status != 'resolved') ?? false;
          
          return FloatingActionButton.extended(
            onPressed: hasOpenTicket
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ya tienes un ticket abierto',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Debes cerrar tu ticket actual antes de crear uno nuevo',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppTheme.warning,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTicketScreen(),
                      ),
                    );
                  },
            backgroundColor: AppTheme.primaryBlue,
            icon: Icon(
              hasOpenTicket ? Icons.lock_outline : Icons.add_rounded,
              color: Theme.of(context).cardColor,
            ),
            label: Text(
              hasOpenTicket ? 'Ticket abierto' : 'Nuevo ticket',
              style: GoogleFonts.inter(
                color: Theme.of(context).cardColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryBlue;
    
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(
        color: selected 
            ? chipColor 
            : Theme.of(context).colorScheme.onSurface,
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
          color: Colors.grey.withValues(alpha: 0.1),
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
