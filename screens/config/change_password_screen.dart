import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  static const Color _primaryRed = Color(0xFFDC2626);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar contraseña actual
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Cambiar contraseña
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contraseña actualizada exitosamente'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error al cambiar contraseña';
      if (e.code == 'wrong-password') {
        message = 'La contraseña actual es incorrecta';
      } else if (e.code == 'weak-password') {
        message = 'La nueva contraseña es muy débil';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                              'Cambiar Contraseña',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Actualiza tu contraseña de acceso',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: _primaryRed,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Contraseña actual
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Contraseña actual',
                    icon: Icons.lock_rounded,
                    obscureText: _obscureCurrentPassword,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña actual es requerida';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  // Nueva contraseña
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'Nueva contraseña',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureNewPassword,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La nueva contraseña es requerida';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirmar nueva contraseña
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar nueva contraseña',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirmPassword,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirma la nueva contraseña';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón cambiar contraseña
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
                        onTap: _isLoading ? null : _changePassword,
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
                                  'Cambiar Contraseña',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
    required bool isDark,
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
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: _primaryRed,
              size: 20,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            onPressed: onToggleVisibility,
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
            borderSide: const BorderSide(
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
        validator: validator,
      ),
    );
  }
}
