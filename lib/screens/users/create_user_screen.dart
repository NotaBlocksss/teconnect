import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;

class CreateUserScreen extends StatefulWidget {
  final bool isWorker;

  const CreateUserScreen({super.key, this.isWorker = false});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  //Rs Development
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _role = 'user';
  String? _selectedPlanId; // ID del plan seleccionado en el dropdown ('plan_basico', 'plan_standar', 'custom')
  String? _internetPlan; // Valor final que se guarda en la base de datos
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isCustomPlan = false;
  double _customMbps = 8.0; // Valor inicial del slider custom
  bool _hasPaidInstallation = false; // Si el usuario pagó el servicio de instalación

  // Planes de internet disponibles
  static const List<Map<String, String>> _internetPlans = [
    {
      'id': 'plan_basico',
      'name': 'Plan residencial básico 8 Mbps',
      'price': '50.000 COP',
      'mbps': '8',
    },
    {
      'id': 'plan_standar',
      'name': 'Plan residencial Standar 10 Mbps',
      'price': '70.000 COP',
      'mbps': '10',
    },
  ];

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

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Guardar información del admin actual ANTES de crear el usuario
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      final adminUser = authProvider.currentUser;
      final adminFirebaseUser = FirebaseAuth.instance.currentUser;
      
      if (adminUser == null || adminFirebaseUser == null) {
        throw Exception('No hay sesión de administrador activa');
      }

      // CRÍTICO: Activar modo de mantenimiento Y modo de creación ANTES de crear el usuario
      // Esto previene que el listener de authStateChanges cambie la sesión
      authProvider.setUser(adminUser);
      authProvider.setCreatingUser(true); // Activar flag de creación de usuario
      
      // Esperar un momento para asegurar que los modos estén completamente activos
      await Future.delayed(const Duration(milliseconds: 200));

      // Guardar en SharedPreferences como respaldo
      final prefs = await SharedPreferences.getInstance();
      final adminEmail = adminFirebaseUser.email;
      if (adminEmail != null) {
        await prefs.setString('temp_admin_email', adminEmail);
        await prefs.setString('temp_admin_uid', adminFirebaseUser.uid);
      }

      // Crear usuario en Firebase Auth
      // NOTA: Esto automáticamente inicia sesión con el nuevo usuario
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user != null) {
        final newUserId = credential.user!.uid;

        // Crear perfil de usuario en Firestore
        final user = UserModel(
          id: newUserId,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          lastName: _lastNameController.text.trim().isNotEmpty
              ? _lastNameController.text.trim()
              : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          internetPlan: _internetPlan,
          role: _role,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          createdAt: DateTime.now(),
          hasPaidInstallation: _hasPaidInstallation,
        );

        final userService = UserService();
        await userService.updateUser(user);

        // Cerrar sesión del usuario recién creado INMEDIATAMENTE
        await FirebaseAuth.instance.signOut();

        // Esperar un momento para que Firebase procese el cierre de sesión
        await Future.delayed(const Duration(milliseconds: 200));

        // Desactivar el flag de creación de usuario
        // El modo de mantenimiento permanece activo para mantener la sesión del admin
        authProvider.setCreatingUser(false);
        
        // Limpiar los datos temporales
        await prefs.remove('temp_admin_email');
        await prefs.remove('temp_admin_uid');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      // IMPORTANTE: Desactivar los flags en caso de error
      try {
        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
        authProvider.setCreatingUser(false);
      } catch (_) {}
      
      // Limpiar datos temporales en caso de error
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('temp_admin_email');
        await prefs.remove('temp_admin_uid');
      } catch (_) {}
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      // Asegurar que el flag esté desactivado siempre
      try {
        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
        authProvider.setCreatingUser(false);
      } catch (_) {}
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Colores verde/teal para worker, rojo para admin
  Color get _primaryColor => widget.isWorker 
      ? const Color(0xFF00BFA5) 
      : const Color(0xFFDC2626);

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
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
                              'Crear Usuario',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Registra un nuevo usuario',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El apellido es requerido';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dirección
                  _buildTextField(
                    controller: _addressController,
                    label: 'Dirección',
                    icon: Icons.location_on_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La dirección es requerida';
                      }
                      return null;
                    },
                    isDark: isDark,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El teléfono es requerido';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  // Contraseña
                  _buildPasswordField(isDark: isDark),
                  const SizedBox(height: 16),
                  
                  // Confirmar Contraseña
                  _buildConfirmPasswordField(isDark: isDark),
                  const SizedBox(height: 16),
                  
                  // Plan de Internet
                  ...[
                    Text(
                      'Plan de Internet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            color: _primaryColor.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPlanId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Selecciona un plan',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.wifi_rounded,
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
                              color: _primaryColor,
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        dropdownColor: Theme.of(context).cardColor,
                        selectedItemBuilder: (BuildContext context) {
                          // Debe devolver exactamente la misma cantidad de widgets que items
                          // en el mismo orden: Sin plan, planes originales, luego el custom
                          return [
                            // Sin plan
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sin plan',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                softWrap: true,
                              ),
                            ),
                            // Planes originales
                            for (var plan in _internetPlans)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  plan['name']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            // Plan custom
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Plan personalizado (${_customMbps.toStringAsFixed(0)} Mbps)',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ];
                        },
                        items: [
                          const DropdownMenuItem(
                            value: 'no_plan',
                            child: Text('Sin plan'),
                          ),
                          ..._internetPlans.map((plan) {
                            return DropdownMenuItem(
                              value: plan['id'],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    plan['name']!,
                                    style: GoogleFonts.inter(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plan['price']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Plan personalizado',
                                      style: GoogleFonts.inter(
                                        color: Theme.of(context).colorScheme.onSurface,
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
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                            if (value == 'no_plan') {
                              _internetPlan = null;
                            } else if (_isCustomPlan) {
                              // Actualizar el plan con la información custom
                              _internetPlan = 'Plan personalizado ${_customMbps.toStringAsFixed(0)} Mbps - ${_calculateCustomPrice(_customMbps)}';
                            } else {
                              // Guardar el nombre completo del plan seleccionado
                              final selectedPlan = _internetPlans.firstWhere(
                                (plan) => plan['id'] == value,
                                orElse: () => {},
                              );
                              if (selectedPlan.isNotEmpty) {
                                _internetPlan = '${selectedPlan['name']} - ${selectedPlan['price']}';
                              } else {
                                _internetPlan = value;
                              }
                            }
                          });
                        },
                        validator: (value) {
                          // No es requerido, puede ser null (Sin plan)
                          // Asegurar que _internetPlan esté actualizado
                          if (value == 'no_plan') {
                            _internetPlan = null;
                          } else if (value == 'custom') {
                            _internetPlan = 'Plan personalizado ${_customMbps.toStringAsFixed(0)} Mbps - ${_calculateCustomPrice(_customMbps)}';
                          } else if (value != null) {
                            final selectedPlan = _internetPlans.firstWhere(
                              (plan) => plan['id'] == value,
                              orElse: () => {},
                            );
                            if (selectedPlan.isNotEmpty) {
                              _internetPlan = '${selectedPlan['name']} - ${selectedPlan['price']}';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    // Slider para plan custom
                    if (_isCustomPlan) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.3),
                            width: 1,
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
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Velocidad del Plan Personalizado',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
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
                                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _primaryColor.withValues(alpha: 0.2),
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
                                          color: _primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _calculateCustomPrice(_customMbps),
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Container(
                                  //   padding: const EdgeInsets.symmetric(
                                  //     horizontal: 12,
                                  //     vertical: 6,
                                  //   ),
                                  //   decoration: BoxDecoration(
                                  //     gradient: LinearGradient(
                                  //       colors: [_primaryColor, _darkColor],
                                  //     ),
                                  //     borderRadius: BorderRadius.circular(8),
                                  //   ),
                                  //   child: Text(
                                  //     'Rango: 8 - 500 Mbps',
                                  //     style: GoogleFonts.inter(
                                  //       fontSize: 11,
                                  //       fontWeight: FontWeight.w500,
                                  //       color: const Color(0xFF2A2A2A),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: _primaryColor,
                                inactiveTrackColor: Theme.of(context).dividerColor.withOpacity(0.3),
                                thumbColor: _primaryColor,
                                overlayColor: _primaryColor.withValues(alpha: 0.2),
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
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  '500 Mbps',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Rol
                  Text(
                    'Rol',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          color: _primaryColor.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: InputDecoration(
                        hintText: 'Selecciona el rol',
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
                            color: _primaryColor,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      dropdownColor: Theme.of(context).cardColor,
                      items: widget.isWorker
                          ? [
                              DropdownMenuItem(
                                value: 'user',
                                child: Text(
                                  'Usuario',
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ]
                          : [
                              DropdownMenuItem(
                                value: 'user',
                                child: Text(
                                  'Usuario',
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'worker',
                                child: Text(
                                  'Trabajador',
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text(
                                  'Administrador',
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                      onChanged: widget.isWorker
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _role = value);
                              }
                            },
                    ),
                  ),
                  if (widget.isWorker) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los trabajadores solo pueden crear usuarios con rol "Usuario"',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Checkbox para pago de instalación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasPaidInstallation,
                          onChanged: (value) {
                            setState(() {
                              _hasPaidInstallation = value ?? false;
                            });
                          },
                          activeColor: _primaryColor,
                          checkColor: AppTheme.white,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pago de instalación realizado',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Marca esta opción si el usuario ya pagó el servicio de instalación de los equipos',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón crear
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _createUser,
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
                                    Text(
                                      'Crear Usuario',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
            color: _primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            icon,
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
              color: _primaryColor,
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

  Widget _buildPasswordField({required bool isDark}) {
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
            color: _primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'La contraseña es requerida';
          }
          if (value.length < 6) {
            return 'La contraseña debe tener al menos 6 caracteres';
          }
          return null;
        },
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'Contraseña',
          labelStyle: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.lock_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
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
              color: _primaryColor,
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

  Widget _buildConfirmPasswordField({required bool isDark}) {
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
            color: _primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Debes confirmar la contraseña';
          }
          if (value != _passwordController.text) {
            return 'Las contraseñas no coinciden';
          }
          return null;
        },
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: 'Confirmar contraseña',
          labelStyle: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            onPressed: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
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
              color: _primaryColor,
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
}

