import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../config/edit_profile_screen.dart';
import '../config/change_password_screen.dart';
import '../config/admin_stats_screen.dart';
import '../config/system_config_screen.dart';

class AdminConfigScreen extends StatelessWidget {
  const AdminConfigScreen({super.key});

  static const Color _primaryRed = Color(0xFFDC2626);
  static const Color _darkRed = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
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
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
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
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppTheme.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuración',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Panel de administración',
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
                
                _buildSectionTitle(context, 'Perfil', Icons.person_rounded, isDark),
                const SizedBox(height: 16),
                _buildConfigCard(
                  context,
                  icon: Icons.edit_rounded,
                  title: 'Editar Perfil',
                  subtitle: 'Actualiza tu información personal',
                  color: _primaryRed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildConfigCard(
                  context,
                  icon: Icons.lock_rounded,
                  title: 'Cambiar Contraseña',
                  subtitle: 'Actualiza tu contraseña de acceso',
                  color: _darkRed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                
                _buildSectionTitle(context, 'Administración', Icons.admin_panel_settings_rounded, isDark),
                const SizedBox(height: 16),
                _buildConfigCard(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Estadísticas del Sistema',
                  subtitle: 'Ver estadísticas generales del sistema',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminStatsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildConfigCard(
                  context,
                  icon: Icons.settings_applications_rounded,
                  title: 'Configuración del Sistema',
                  subtitle: 'Ajustes y herramientas del sistema',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SystemConfigScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                
                _buildSectionTitle(context, 'Apariencia', Icons.palette_rounded, isDark),
                const SizedBox(height: 16),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _buildThemeCard(
                      context,
                      themeProvider: themeProvider,
                      isDark: isDark,
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                _buildSectionTitle(context, 'Información', Icons.info_rounded, isDark),
                const SizedBox(height: 16),
                _buildConfigCard(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Ayuda y Soporte',
                  subtitle: 'Obtén ayuda sobre la aplicación',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    _showHelpDialog(context, isDark);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildConfigCard(
                  context,
                  icon: Icons.privacy_tip_rounded,
                  title: 'Política de Privacidad',
                  subtitle: 'Lee nuestra política de privacidad',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    _showPrivacyDialog(context, isDark);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                
                _buildSectionTitle(context, 'Sesión', Icons.account_circle_rounded, isDark),
                const SizedBox(height: 16),
                _buildConfigCard(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Cerrar Sesión',
                  subtitle: 'Cerrar sesión de tu cuenta',
                  color: _primaryRed,
                  onTap: () async {
                    await _showLogoutDialog(context, authProvider, isDark);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
              ],
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

  Widget _buildConfigCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
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
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        softWrap: true,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        softWrap: true,
                        maxLines: 1,
                      ),
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
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required ThemeProvider themeProvider,
    required bool isDark,
  }) {
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: _primaryRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo Oscuro',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  softWrap: true,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  themeProvider.isDarkMode
                      ? 'Tema oscuro activado'
                      : 'Tema claro activado',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  softWrap: true,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: _primaryRed,
            activeTrackColor: _primaryRed.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Ayuda y Soporte',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Funciones de Administrador:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(context, '• Gestionar usuarios y roles', isDark),
              const SizedBox(height: 8),
              _buildHelpItem(context, '• Ver y gestionar todos los tickets', isDark),
              const SizedBox(height: 8),
              _buildHelpItem(context, '• Enviar alertas a usuarios', isDark),
              const SizedBox(height: 8),
              _buildHelpItem(context, '• Ver estadísticas del sistema', isDark),
              const SizedBox(height: 8),
              _buildHelpItem(context, '• Configurar el sistema', isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(
                color: _primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.privacy_tip_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Política de Privacidad',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                softWrap: true,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Teconnect Support se compromete a proteger la privacidad de todos los usuarios. '
            'Toda la información personal se almacena de forma segura en Firebase y solo se utiliza para '
            'proporcionar el servicio de gestión de tickets. No compartimos información con terceros.\n\n'
            'Como administrador, tienes acceso a la información de usuarios para gestionar el sistema, '
            'pero debes mantener la confidencialidad de esta información.',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(
                color: _primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
    bool isDark,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: _primaryRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cerrar sesión',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cerrar sesión',
              style: GoogleFonts.inter(
                color: _primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildHelpItem(BuildContext context, String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }
}
