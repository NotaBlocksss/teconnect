import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/invoice_service.dart';
import '../../services/user_service.dart';
import '../../services/invoice_scheduler_service.dart';
import '../../models/invoice_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final InvoiceModel? invoice; // Si se proporciona, es edición

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceService = InvoiceService();
  final _userService = UserService();
  static const Color _primaryRed = Color(0xFFDC2626);

  String? _selectedUserId;
  UserModel? _selectedUser;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = InvoiceSchedulerService.calculateDueDate(DateTime.now());
  String? _notes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _selectedUserId = widget.invoice!.userId;
      _issueDate = widget.invoice!.issueDate;
      _dueDate = widget.invoice!.dueDate;
      _notes = widget.invoice!.notes;
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    if (_selectedUserId != null) {
      final user = await _userService.getUserById(_selectedUserId!);
      setState(() {
        _selectedUser = user;
      });
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
        _selectedUserId = user.id;
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isIssueDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          // Calcular automáticamente la fecha de vencimiento (día 10 del mes)
          _dueDate = InvoiceSchedulerService.calculateDueDate(picked);
        } else {
          _dueDate = picked;
        }
      });
    }
  }


  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
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
      final planId = _selectedUser!.internetPlan ?? 'plan_basico';
      final amount = InvoiceModel.getPlanPrice(planId);

      final invoice = InvoiceModel(
        id: widget.invoice?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _selectedUser!.id,
        invoiceNumber: widget.invoice?.invoiceNumber ?? '',
        customerName: _selectedUser!.name,
        customerLastName: _selectedUser!.lastName,
        customerAddress: _selectedUser!.address,
        customerPhone: _selectedUser!.phone,
        customerEmail: _selectedUser!.email,
        internetPlan: planId,
        amount: amount,
        issueDate: _issueDate,
        dueDate: _dueDate,
        notes: _notes,
        status: widget.invoice?.status ?? 'Pendiente',
        createdAt: widget.invoice?.createdAt ?? DateTime.now(),
      );

      if (widget.invoice != null) {
        await _invoiceService.updateInvoice(invoice);
      } else {
        await _invoiceService.createInvoice(invoice);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.invoice != null
                ? 'Factura actualizada'
                : 'Factura creada exitosamente',
          ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planId = _selectedUser?.internetPlan ?? 'plan_basico';
    final amount = InvoiceModel.getPlanPrice(planId);

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
            child: Form(
              key: _formKey,
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
                          Icons.receipt_long_rounded,
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
                              widget.invoice != null
                                  ? 'Editar Factura'
                                  : 'Nueva Factura',
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
                              widget.invoice != null
                                  ? 'Modifica la información de la factura'
                                  : 'Crea una nueva factura',
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

                  // Seleccionar Usuario
                  _buildSectionTitle(context, 'Cliente', Icons.person_rounded, isDark),
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
                                        'Seleccionar cliente',
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
                                          ),
                                          if (_selectedUser!.email.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _selectedUser!.email,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              ),
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
                  const SizedBox(height: 24),

                  // Información del Plan
                  if (_selectedUser != null) ...[
                    _buildSectionTitle(context, 'Plan de Internet', Icons.wifi_rounded, isDark),
                    const SizedBox(height: 12),
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
                          Text(
                            InvoiceModel.getPlanName(planId),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monto: \$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} COP',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Fechas
                  _buildSectionTitle(context, 'Fechas', Icons.calendar_today_rounded, isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          context,
                          'Fecha de emisión',
                          _issueDate,
                          () => _selectDate(context, true),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          context,
                          'Fecha de vencimiento',
                          _dueDate,
                          () => _selectDate(context, false),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notas
                  _buildSectionTitle(context, 'Notas', Icons.note_rounded, isDark),
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
                    child: TextFormField(
                      initialValue: _notes,
                      onChanged: (value) => _notes = value,
                      maxLines: 4,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Notas adicionales (opcional)',
                        hintStyle: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
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
                        contentPadding: const EdgeInsets.all(20),
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
                        onTap: _isLoading ? null : _saveInvoice,
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
                                Text(
                                  widget.invoice != null
                                      ? 'Actualizar Factura'
                                      : 'Crear Factura',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.white,
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
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime date,
    VoidCallback onTap,
    bool isDark, {
    bool showTime = false,
  }) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showTime
                      ? '${_formatDate(date)} ${_formatTime(date)}'
                      : _formatDate(date),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

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
              'Seleccionar Cliente',
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
                        ),
                        subtitle: Text(
                          user.email,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
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

