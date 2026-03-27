import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  //Rs Development
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _role;
  String? _internetPlan;
  String? _selectedPlanId;
  bool _isLoading = false;
  bool _isCustomPlan = false;
  double _customMbps = 8.0; // Valor inicial del slider custom

  static const Color _primaryRed = Color(0xFFDC2626);
  static const Color _darkRed = Color(0xFFB91C1C);

  @override
  void initState() {
    super.initState();
    
    // Manejar nombre y apellido
    // Si el modelo tiene lastName, usarlo directamente
    // Si no, intentar extraerlo del nombre completo
    String firstName = widget.user.name;
    String lastNameText = widget.user.lastName ?? '';
    
    if (lastNameText.isEmpty && widget.user.name.contains(' ')) {
      final nameParts = widget.user.name.split(' ');
      firstName = nameParts.first;
      lastNameText = nameParts.skip(1).join(' ');
    }
    
    _nameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastNameText);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    
    // Asegurar que el rol sea uno de los valores válidos
    final validRoles = ['user', 'worker', 'admin'];
    _role = validRoles.contains(widget.user.role) 
        ? widget.user.role 
        : 'user';
    
    _internetPlan = widget.user.internetPlan;
    _selectedPlanId = _parsePlanIdFromText(_internetPlan);
    _isCustomPlan = _selectedPlanId == 'custom';
    
    // Si es plan personalizado, extraer los Mbps del texto
    if (_isCustomPlan && _internetPlan != null) {
      final match = RegExp(r'(\d+)\s*Mbps').firstMatch(_internetPlan!);
      if (match != null) {
        _customMbps = double.tryParse(match.group(1) ?? '8') ?? 8.0;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Combinar nombre y apellido para el campo name (compatibilidad)
      final fullName = _lastNameController.text.trim().isNotEmpty
          ? '${_nameController.text.trim()} ${_lastNameController.text.trim()}'
          : _nameController.text.trim();

      final updatedUser = widget.user.copyWith(
        name: fullName,
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        role: _role,
        internetPlan: _internetPlan,
      );

      final userService = UserService();
      await userService.updateUser(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario actualizado exitosamente'),
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

  // Verificar si el usuario actual puede eliminar usuarios
  bool _canDeleteUser() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    // Solo los administradores pueden eliminar usuarios
    return currentUser?.role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A0A0A) : Colors.white,
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
                          Icons.edit_rounded,
                          color: Color.fromARGB(255, 0, 0, 0),
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
                              'Editar Usuario',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Modifica la información del usuario',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                              ),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Nombre
                  _buildTextField(
                controller: _nameController,
                    label: 'Nombre',
                    icon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  // Apellido
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Apellido',
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dirección
                  _buildTextField(
                    controller: _addressController,
                    label: 'Dirección',
                    icon: Icons.location_on_rounded,
                    isDark: isDark,
                    maxLines: 2,
              ),
              const SizedBox(height: 16),
                  
                  // Email
                  _buildTextField(
                controller: _emailController,
                    label: 'Correo electrónico',
                    icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El correo es requerido';
                  }
                  if (!value.contains('@')) {
                    return 'Correo inválido';
                  }
                  return null;
                },
                    isDark: isDark,
              ),
              const SizedBox(height: 16),
                  
                  // Teléfono
                  _buildTextField(
                controller: _phoneController,
                    label: 'Teléfono',
                    icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  // Plan de Internet
                    Text(
                    'Plan de Internet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInternetPlanDropdown(isDark: isDark),
                  // Slider para plan custom
                  if (_isCustomPlan) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF2A1A1A)
                            : _primaryRed.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _primaryRed.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.speed_rounded,
                                size: 20,
                                color: _primaryRed,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Velocidad del Plan Personalizado',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Display del valor actual
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? const Color(0xFF3A2A2A)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _primaryRed.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_customMbps.toStringAsFixed(0)} Mbps',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryRed,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _calculateCustomPrice(_customMbps),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _primaryRed,
                              inactiveTrackColor: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                              thumbColor: _primaryRed,
                              overlayColor: _primaryRed.withValues(alpha: 0.2),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _customMbps,
                              min: 8,
                              max: 500,
                              divisions: 492, // Permite incrementos de 1 mbps
                              label: '${_customMbps.toStringAsFixed(0)} Mbps',
                              onChanged: (value) {
                                setState(() {
                                  _customMbps = value;
                                  // Actualizar el plan con la nueva velocidad
                                  _internetPlan = 'Plan personalizado ${_customMbps.toStringAsFixed(0)} Mbps - ${_calculateCustomPrice(_customMbps)}';
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Indicadores de min/max
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '8 Mbps',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black54,
                                ),
                              ),
                              Text(
                                '500 Mbps',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
              const SizedBox(height: 16),
                  
                  // Rol
                  Text(
                'Rol',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                  fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
                  _buildRoleDropdown(isDark: isDark),
                  const SizedBox(height: 32),
                  
                  // Botón actualizar
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_primaryRed, _darkRed],
                      ),
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
                        onTap: _isLoading ? null : _updateUser,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: AppTheme.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    'Actualizar Usuario',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.white,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Botón eliminar (solo para admins)
                  if (_canDeleteUser()) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
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
                          onTap: _isLoading ? null : _deleteUser,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    'Eliminar Usuario',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.error,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        style: GoogleFonts.inter(
          fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
                                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
          ),
          prefixIcon: Icon(
            icon,
                                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.error,
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
      ),
    );
  }

  String? _parsePlanIdFromText(String? planText) {
    if (planText == null || planText.isEmpty) return null;
    
    if (planText.contains('Plan residencial básico') || 
        planText.contains('plan_basico')) {
      return 'plan_basico';
    }
    
    if (planText.contains('Plan residencial Standar') || 
        planText.contains('plan_standar')) {
      return 'plan_standar';
    }
    
    if (planText.contains('Plan personalizado')) {
      return 'custom';
    }
    
    return null;
  }

  // Calcular precio basado en los planes existentes
  // Plan básico: 8 mbps = 50.000 COP
  // Plan estándar: 10 mbps = 70.000 COP
  // Incremento: 20.000 COP por cada 2 mbps = 10.000 COP por mbps adicional
  String _calculateCustomPrice(double mbps) {
    if (mbps <= 8) {
      return '50.000 COP';
    }
    // Precio base (8 mbps) + incremento proporcional
    final basePrice = 50000;
    final additionalMbps = mbps - 8;
    final pricePerMbps = 10000; // Calculado de la diferencia entre los planes
    final totalPrice = basePrice + (additionalMbps * pricePerMbps);
    
    // Formatear precio con separadores de miles
    return '${totalPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} COP';
  }

  Widget _buildInternetPlanDropdown({required bool isDark}) {
    const List<Map<String, String>> internetPlans = [
      {
        'id': 'plan_basico',
        'name': 'Plan residencial básico 8 Mbps',
        'price': '50.000 COP',
      },
      {
        'id': 'plan_standar',
        'name': 'Plan residencial Standar 10 Mbps',
        'price': '70.000 COP',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : _primaryRed.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPlanId,
        isExpanded: true,
        selectedItemBuilder: (BuildContext context) {
          final items = <Widget>[];
          items.add(Text(
            'Sin plan',
            softWrap: true,
            maxLines: 1,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
          for (final plan in internetPlans) {
            items.add(Text(
              plan['name']!,
              softWrap: true,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ));
          }
          items.add(Text(
            'Plan personalizado (${_customMbps.toStringAsFixed(0)} Mbps)',
            softWrap: true,
            maxLines: 1,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
          return items;
        },
        decoration: InputDecoration(
          hintText: 'Selecciona un plan',
          hintStyle: GoogleFonts.inter(
            color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black54,
          ),
          prefixIcon: Icon(
            Icons.wifi_rounded,
            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
        dropdownColor: isDark ? const Color(0xFF2A1A1A) : Colors.white,
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Sin plan'),
          ),
          ...internetPlans.map((plan) {
            return DropdownMenuItem(
              value: plan['id'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    plan['name']!,
                    style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    softWrap: true,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan['price']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }),
          DropdownMenuItem(
            value: 'custom',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Plan personalizado',
                      style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_customMbps.toStringAsFixed(0)} Mbps - ${_calculateCustomPrice(_customMbps)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedPlanId = value;
            _isCustomPlan = value == 'custom';
            if (value == null) {
              _internetPlan = null;
            } else if (value == 'custom') {
              _internetPlan = 'Plan personalizado ${_customMbps.toStringAsFixed(0)} Mbps - ${_calculateCustomPrice(_customMbps)}';
            } else {
              final selectedPlan = internetPlans.firstWhere(
                (plan) => plan['id'] == value,
              );
              _internetPlan = '${selectedPlan['name']} - ${selectedPlan['price']}';
            }
          });
        },
      ),
    );
  }

  Widget _buildRoleDropdown({required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : _primaryRed.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _role,
        decoration: InputDecoration(
          hintText: 'Selecciona el rol',
          hintStyle: GoogleFonts.inter(
            color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black54,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black87,
        ),
        dropdownColor: isDark ? const Color(0xFF2A1A1A) : Colors.white,
        items: [
          DropdownMenuItem(
            value: 'user',
            child: Text(
              'Usuario',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'worker',
            child: Text(
              'Trabajador',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'admin',
            child: Text(
              'Administrador',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona un rol';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _role = value);
                  }
                },
      ),
    );
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Eliminar Usuario',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
          '¿Estás seguro de que deseas eliminar a ${widget.user.name}? Esta acción no se puede deshacer.',
            style: GoogleFonts.inter(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.white,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final userService = UserService();
      await userService.deleteUser(widget.user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado exitosamente'),
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
}
