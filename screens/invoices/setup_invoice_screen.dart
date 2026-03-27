import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/invoice_schedule_model.dart';
import '../../theme/app_theme.dart';

class SetupInvoiceScreen extends StatefulWidget {
  const SetupInvoiceScreen({super.key});

  @override
  State<SetupInvoiceScreen> createState() => _SetupInvoiceScreenState();
}

class _SetupInvoiceScreenState extends State<SetupInvoiceScreen> {
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _selectedUser;
  bool _isLoading = false;
  static const Color _primaryRed = Color(0xFFDC2626);

  Future<void> _setupInvoiceSchedule() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un usuario'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validar que el usuario tenga un ID válido
      if (_selectedUser!.id.isEmpty) {
        throw Exception('El usuario seleccionado no tiene un ID válido');
      }

      // Verificar si ya existe una configuración para este usuario
      final existingSchedule = await _firestore
          .collection('invoice_schedules')
          .where('userId', isEqualTo: _selectedUser!.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingSchedule.docs.isNotEmpty) {
        // Actualizar la configuración existente
        await existingSchedule.docs.first.reference.update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Crear nueva configuración
        final scheduleId = _firestore.collection('invoice_schedules').doc().id;
        if (scheduleId.isEmpty) {
          throw Exception('Error al generar ID para la configuración');
        }
        
        final schedule = InvoiceScheduleModel(
          id: scheduleId,
          userId: _selectedUser!.id,
          isActive: true,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('invoice_schedules')
            .doc(schedule.id)
            .set(schedule.toMap());
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración de facturación automática establecida exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectUser() async {
    final user = await showDialog<UserModel>(
      context: context,
      builder: (context) => _UserSelectionDialog(
        userService: _userService,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );

    if (user != null) {
      setState(() {
        _selectedUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: AppTheme.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setear Factura',
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
                            'Configura facturación automática',
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
                const SizedBox(height: 32),

                // Información sobre el sistema
                Container(
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
                              Icons.info_outline_rounded,
                              color: _primaryRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sistema Automático de Facturación',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildScheduleItem(context, 'Día 25', 'Se envía la factura y notificación automáticamente', isDark),
                      const SizedBox(height: 12),
                      _buildScheduleItem(context, 'Día 30', 'Recordatorio de que la factura está por vencer', isDark),
                      const SizedBox(height: 12),
                      _buildScheduleItem(context, 'Día 5', 'Recordatorio de que falta poco para vencer', isDark),
                      const SizedBox(height: 12),
                      _buildScheduleItem(context, 'Día 10', 'Se marca como "Corte de Servicio" y se envía notificación', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seleccionar Usuario
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: _primaryRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Usuario',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                        softWrap: true,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectUser,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: _primaryRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _selectedUser == null
                                  ? Text(
                                      'Seleccionar usuario',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_selectedUser!.name}${_selectedUser!.lastName != null ? ' ${_selectedUser!.lastName}' : ''}',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          softWrap: true,
                                        ),
                                        if (_selectedUser!.email.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedUser!.email,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                            softWrap: true,
                                            maxLines: 1,
                                          ),
                                        ],
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
                ),
                const SizedBox(height: 32),

                // Botón guardar
                Container(
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _setupInvoiceSchedule,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                ),
                              )
                            else ...[
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppTheme.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (!_isLoading)
                              Flexible(
                                child: Text(
                                  'Configurar Facturación Automática',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.white,
                                  ),
                                  softWrap: true,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, String day, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            day,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _primaryRed,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

// Diálogo de selección de usuario (solo usuarios, con búsqueda)
class _UserSelectionDialog extends StatefulWidget {
  final UserService userService;
  final bool isDark;

  const _UserSelectionDialog({
    required this.userService,
    required this.isDark,
  });

  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  static const Color _primaryRed = Color(0xFFDC2626);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Usuario',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            // Barra de búsqueda
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar usuario...',
                  hintStyle: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _primaryRed,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: widget.userService.getAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allUsers = snapshot.data ?? [];
                  
                  // Filtrar solo usuarios (no admins ni workers)
                  final users = allUsers.where((user) => user.role == 'user').toList();
                  
                  // Filtrar por búsqueda
                  final filteredUsers = _searchQuery.isEmpty
                      ? users
                      : users.where((user) {
                          final name = '${user.name}${user.lastName != null ? ' ${user.lastName}' : ''}'.toLowerCase();
                          final email = user.email.toLowerCase();
                          return name.contains(_searchQuery) || email.contains(_searchQuery);
                        }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay usuarios disponibles',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _primaryRed.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person_rounded,
                            color: _primaryRed,
                          ),
                        ),
                        title: Text(
                          '${user.name}${user.lastName != null ? ' ${user.lastName}' : ''}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          softWrap: true,
                          maxLines: 1,
                        ),
                        subtitle: Text(
                          user.email,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          softWrap: true,
                          maxLines: 1,
                        ),
                        onTap: () {
                          Navigator.pop(context, user);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

