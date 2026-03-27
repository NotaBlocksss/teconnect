import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class UserPerfilScreen extends StatelessWidget {
  //Rs Development
  const UserPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
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
                // Header con Avatar
                _buildHeader(context, user, isDark),
                const SizedBox(height: 32),
                
                // Información Personal
                _buildSectionTitle(context, 'Información Personal', Icons.person_rounded, isDark),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Nombre completo',
                  value: _getFullName(user),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.email_rounded,
                  title: 'Correo electrónico',
                  value: user?.email ?? 'No disponible',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.phone_rounded,
                  title: 'Teléfono',
                  value: user?.phone ?? 'No especificado',
                  isDark: isDark,
                  isEmpty: user?.phone == null || user!.phone!.isEmpty,
                ),
                if (user?.address != null && user!.address!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.location_on_rounded,
                    title: 'Dirección',
                    value: user.address!,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 32),
                
                // Información del Servicio
                _buildSectionTitle(context, 'Información del Servicio', Icons.wifi_rounded, isDark),
                const SizedBox(height: 12),
                if (user?.internetPlan != null && user!.internetPlan!.isNotEmpty) ...[
                  _buildInfoCard(
                    context,
                    icon: Icons.speed_rounded,
                    title: 'Plan de Internet',
                    value: user.internetPlan!,
                    isDark: isDark,
                    valueColor: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildInfoCard(
                  context,
                  icon: Icons.install_mobile_rounded,
                  title: 'Instalación',
                  value: user?.hasPaidInstallation == true ? 'Pagada' : 'Pendiente',
                  isDark: isDark,
                  valueColor: user?.hasPaidInstallation == true ? AppTheme.success : AppTheme.warning,
                  showChip: true,
                ),
                const SizedBox(height: 32),
                
                // Información de Cuenta
                _buildSectionTitle(context, 'Información de Cuenta', Icons.account_circle_rounded, isDark),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.badge_rounded,
                  title: 'Rol',
                  value: _getRoleText(user?.role ?? 'user'),
                  isDark: isDark,
                  valueColor: _getRoleColor(user?.role ?? 'user'),
                  showChip: true,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.calendar_today_rounded,
                  title: 'Cuenta creada',
                  value: user != null
                      ? _formatDate(user.createdAt)
                      : 'No disponible',
                  isDark: isDark,
                ),
                if (user?.lastLogin != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    icon: Icons.access_time_rounded,
                    title: 'Último acceso',
                    value: _formatLastLogin(user!.lastLogin!),
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, bool isDark) {
    final String userName = (user?.name ?? '').toString().trim();
    final String avatarLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Column(
      children: [
        // Avatar con gradiente
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.darkBlue,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              avatarLetter,
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          userName.isNotEmpty ? userName : 'Usuario',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getRoleColor(user?.role ?? 'user').withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getRoleColor(user?.role ?? 'user').withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            _getRoleText(user?.role ?? 'user'),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _getRoleColor(user?.role ?? 'user'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
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

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    Color? valueColor,
    bool showChip = false,
    bool isEmpty = false,
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
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlue,
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
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                if (showChip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (valueColor ?? AppTheme.primaryBlue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? AppTheme.primaryBlue,
                      ),
                      softWrap: true,
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      isEmpty ? value : value,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isEmpty
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                            : (valueColor ?? Theme.of(context).colorScheme.onSurface),
                      ),
                      softWrap: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFullName(user) {
    if (user == null) return 'No disponible';
    final name = user.name ?? '';
    final lastName = user.lastName ?? '';
    if (lastName.isEmpty) return name;
    return '$name $lastName';
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.error;
      case 'worker':
        return AppTheme.warning;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatLastLogin(DateTime lastLogin) {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace unos momentos';
    }
  }
}

