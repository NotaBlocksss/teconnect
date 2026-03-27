import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/alert_service.dart';
import '../../models/alert_model.dart';
import '../../theme/app_theme.dart';

class SendAlertScreen extends StatefulWidget {
  const SendAlertScreen({super.key});

  @override
  State<SendAlertScreen> createState() => _SendAlertScreenState();
}

class _SendAlertScreenState extends State<SendAlertScreen> {
  //Rs Development
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _type = 'informacion';
  DateTime? _expiresAt;
  bool _hasExpiration = false;
  bool _isLoading = false;

  static const Color _primaryRed = Color(0xFFDC2626);
  static const Color _darkRed = Color(0xFFB91C1C);

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _expiresAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final alert = AlertModel(
        id: '',
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        createdBy: user.id,
        createdAt: DateTime.now(),
        expiresAt: _hasExpiration ? _expiresAt : null,
        type: _type,
        isActive: true,
      );

      final alertService = AlertService();
      await alertService.createAlert(alert);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Alerta enviada exitosamente'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'informacion':
        return AppTheme.success; // Verde
      case 'advertencia':
        return AppTheme.warning; // Amarillo
      case 'mantenimiento':
        return AppTheme.error; // Rojo
      case 'caida_servicio':
        return Colors.purple; // Morado
      default:
        return AppTheme.info;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'informacion':
        return Icons.info_outline_rounded;
      case 'advertencia':
        return Icons.warning_amber_rounded;
      case 'mantenimiento':
        return Icons.build_rounded;
      case 'caida_servicio':
        return Icons.cloud_off_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'informacion':
        return 'Información';
      case 'advertencia':
        return 'Advertencia';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'caida_servicio':
        return 'Caída Servicio';
      default:
        return 'Información';
    }
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    List<Widget> children,
    bool isDark,
  ) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: _primaryRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
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
                          Icons.notifications_active_rounded,
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
                              'Enviar Alerta',
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
                              'Crea una alerta para todos los usuarios',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Información de la Alerta
                  _buildSectionCard(
                    'Información de la Alerta',
                    Icons.notifications_active_rounded,
                    [
                      // Título
                      Text(
                        'Título de la alerta',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ej: Mantenimiento programado',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.title_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _primaryRed,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El título es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Mensaje
                      Text(
                        'Mensaje',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Escribe el mensaje de la alerta...',
                          hintStyle: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 60),
                            child: Icon(
                              Icons.message_rounded,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _primaryRed,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El mensaje es requerido';
                          }
                          return null;
                        },
                      ),
                    ],
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  // Tipo de Alerta
                  _buildSectionCard(
                    'Tipo de Alerta',
                    Icons.category_rounded,
                    [
                      // Selector visual de tipo
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeOption('informacion', isDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeOption('advertencia', isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeOption('mantenimiento', isDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeOption('caida_servicio', isDark),
                          ),
                        ],
                      ),
                    ],
                    isDark,
                  ),
                  const SizedBox(height: 16),

                  // Configuración de Expiración
                  _buildSectionCard(
                    'Configuración',
                    Icons.settings_rounded,
                    [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Establecer fecha de expiración',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'La alerta se ocultará automáticamente',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _hasExpiration,
                              onChanged: (value) {
                                setState(() {
                                  _hasExpiration = value;
                                  if (!value) {
                                    _expiresAt = null;
                                  }
                                });
                              },
                              activeColor: _primaryRed,
                            ),
                          ],
                        ),
                      ),
                      if (_hasExpiration) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _selectExpirationDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _primaryRed.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        color: _primaryRed,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fecha de expiración',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                            softWrap: true,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _expiresAt != null
                                                ? _formatDate(_expiresAt!)
                                                : 'No seleccionada',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                            softWrap: true,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                    isDark,
                  ),
                  const SizedBox(height: 32),

                  // Botón Enviar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isLoading
                            ? [
                                _primaryRed.withValues(alpha: 0.6),
                                _darkRed.withValues(alpha: 0.6),
                              ]
                            : [
                                _primaryRed,
                                _darkRed,
                              ],
                      ),
                      boxShadow: _isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: _primaryRed.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                                spreadRadius: 0,
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _sendAlert,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Enviar Alerta',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.send_rounded,
                                      color: AppTheme.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, bool isDark) {
    final isSelected = _type == type;
    final typeColor = _getTypeColor(type);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? typeColor.withValues(alpha: 0.15)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? typeColor.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: typeColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _type = type;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTypeText(type),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? typeColor
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
