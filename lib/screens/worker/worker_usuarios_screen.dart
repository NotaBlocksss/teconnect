import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/expandable_filters.dart';
import '../users/create_user_screen.dart';
import '../users/edit_user_screen.dart';

class WorkerUsuariosScreen extends StatefulWidget {
  const WorkerUsuariosScreen({super.key});

  @override
  State<WorkerUsuariosScreen> createState() => _WorkerUsuariosScreenState();
}

class _WorkerUsuariosScreenState extends State<WorkerUsuariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  String _selectedFilter = 'all';
  String _searchQuery = '';

  // Colores verde/teal para diferenciar del usuario (azul)
  static const Color _primaryGreen = Color(0xFF00BFA5);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (users.isEmpty) return users;
    
    var filtered = users;

    if (_selectedFilter != 'all') {
      filtered = filtered.where((user) => user.role == _selectedFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
      filtered = filtered.where((user) {
        final nameLower = user.name.toLowerCase();
        final emailLower = user.email.toLowerCase();
        final phoneLower = user.phone?.toLowerCase() ?? '';
        return queryWords.every((word) => 
          nameLower.contains(word) || 
          emailLower.contains(word) || 
          phoneLower.contains(word)
        );
      }).toList();
    }

    return filtered;
  }

  List<UserModel> _sortUsersByCategory(List<UserModel> users) {
    if (users.isEmpty) return users;
    
    final admins = <UserModel>[];
    final workers = <UserModel>[];
    final regularUsers = <UserModel>[];
    
    for (var user in users) {
      switch (user.role) {
        case 'admin':
          admins.add(user);
          break;
        case 'worker':
          workers.add(user);
          break;
        default:
          regularUsers.add(user);
      }
    }

    return [...admins, ...workers, ...regularUsers];
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.people_rounded,
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
                            'Usuarios',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                            softWrap: true,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          StreamBuilder<List<UserModel>>(
                            stream: _userService.getAllUsers(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.length ?? 0;
                              return Text(
                                '$count usuario${count != 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
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
                    // Barra de búsqueda
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
                            color: _primaryGreen.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, email o teléfono...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
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
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _primaryGreen,
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
                    // Filtros desplegables
                    ExpandableFilters(
                      title: 'Filtrar por rol',
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Todos',
                              selected: _selectedFilter == 'all',
                              color: _primaryGreen,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedFilter = 'all');
                                }
                              },
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Administradores',
                              selected: _selectedFilter == 'admin',
                              color: AppTheme.error,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedFilter = 'admin');
                                }
                              },
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Trabajadores',
                              selected: _selectedFilter == 'worker',
                              color: AppTheme.warning,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedFilter = 'worker');
                                }
                              },
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Usuarios',
                              selected: _selectedFilter == 'user',
                              color: _primaryGreen,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedFilter = 'user');
                                }
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lista de usuarios
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: userService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: _primaryGreen,
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
                              'Error al cargar usuarios',
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
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final allUsers = snapshot.data ?? [];
                    final filteredUsers = _filterUsers(allUsers);
                    final sortedUsers = _sortUsersByCategory(filteredUsers);

                    if (sortedUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.people_outline_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                                  ? 'No se encontraron usuarios'
                                  : 'No hay usuarios registrados',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                                  ? 'Intenta con otros términos de búsqueda'
                                  : 'Crea el primer usuario para comenzar',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Separar por categorías
                    final admins = sortedUsers.where((u) => u.role == 'admin').toList();
                    final workers = sortedUsers.where((u) => u.role == 'worker').toList();
                    final regularUsers = sortedUsers
                        .where((u) => u.role != 'admin' && u.role != 'worker')
                        .toList();

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                      children: [
                        if (admins.isNotEmpty) ...[
                          _CategoryHeader(
                            title: 'Administradores',
                            count: admins.length,
                            color: AppTheme.error,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          ...admins.map((user) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _UserCard(
                                  user: user,
                                  isDark: isDark,
                                  canEdit: false,
                                ),
                              )),
                          const SizedBox(height: 24),
                        ],
                        if (workers.isNotEmpty) ...[
                          _CategoryHeader(
                            title: 'Trabajadores',
                            count: workers.length,
                            color: AppTheme.warning,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          ...workers.map((user) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _UserCard(
                                  user: user,
                                  isDark: isDark,
                                  canEdit: false,
                                ),
                              )),
                          const SizedBox(height: 24),
                        ],
                        if (regularUsers.isNotEmpty) ...[
                          _CategoryHeader(
                            title: 'Usuarios',
                            count: regularUsers.length,
                            color: _primaryGreen,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          ...regularUsers.map((user) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _UserCard(
                                  user: user,
                                  isDark: isDark,
                                  canEdit: true,
                                ),
                              )),
                        ],
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateUserScreen(isWorker: true),
            ),
          );
        },
        backgroundColor: _primaryGreen,
        icon: const Icon(Icons.add_rounded, color: AppTheme.white),
        label: Text(
          'Nuevo Usuario',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.white,
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final bool isDark;

  const _CategoryHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
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
    final chipColor = color ?? const Color(0xFF00BFA5);
    
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(
        color: selected 
            ? chipColor 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      side: BorderSide(
        color: selected 
            ? chipColor 
            : Theme.of(context).dividerColor.withOpacity(0.2),
        width: selected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final bool canEdit;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.canEdit,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.error;
      case 'worker':
        return AppTheme.warning;
      default:
        return const Color(0xFF00BFA5);
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'worker':
        return 'Trabajador';
      default:
        return 'Usuario';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'worker':
        return Icons.work_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);

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
            color: roleColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canEdit
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditUserScreen(user: user),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        roleColor,
                        roleColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        softWrap: true,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.email,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      if (user.phone != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.phone!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRoleIcon(user.role),
                              size: 14,
                              color: roleColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getRoleText(user.role),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  canEdit ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded,
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
}
