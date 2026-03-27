import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/invoice_service.dart';
import '../../models/invoice_model.dart';
import '../../theme/app_theme.dart';

class UserInvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const UserInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<UserInvoiceDetailScreen> createState() => _UserInvoiceDetailScreenState();
}

class _UserInvoiceDetailScreenState extends State<UserInvoiceDetailScreen> {
  //Rs Development
  final InvoiceService _invoiceService = InvoiceService();

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} COP';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pagada':
        return AppTheme.success;
      case 'Pendiente':
        return AppTheme.warning;
      case 'Corte de Servicio':
        return AppTheme.error;
      default:
        return AppTheme.gray;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pagada':
        return 'Pagada';
      case 'Pendiente':
        return 'Pendiente';
      case 'Corte de Servicio':
        return 'Corte de Servicio';
      default:
        return status;
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
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
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
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
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildStatusChip(InvoiceModel invoice, bool isDark) {
    final statusColor = _getStatusColor(invoice.status);
    final isOverdue = invoice.isOverdue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(invoice.status),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          if (isOverdue) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: AppTheme.error,
            ),
          ],
        ],
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
          child: FutureBuilder<InvoiceModel?>(
            future: _invoiceService.getInvoiceById(widget.invoiceId),
            builder: (context, invoiceSnapshot) {
              if (invoiceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!invoiceSnapshot.hasData || invoiceSnapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Factura no encontrada',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final invoice = invoiceSnapshot.data!;

              return SingleChildScrollView(
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
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.invoiceNumber,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Detalle de factura',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildStatusChip(invoice, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Información de la Factura
                    _buildSectionCard(
                      context,
                      'Información de la Factura',
                      Icons.receipt_long_rounded,
                      [
                        _buildInfoRow(context, 'Plan de Internet', InvoiceModel.getPlanName(invoice.internetPlan), isDark),
                        _buildInfoRow(context, 'Fecha de emisión', _formatDate(invoice.issueDate), isDark),
                        _buildInfoRow(context, 'Fecha de vencimiento', _formatDate(invoice.dueDate), isDark),
                        Divider(height: 32, color: Theme.of(context).dividerColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monto Total',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _formatCurrency(invoice.amount),
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                      isDark,
                    ),
                    const SizedBox(height: 16),

                    // Información del Cliente
                    _buildSectionCard(
                      context,
                      'Información del Cliente',
                      Icons.person_rounded,
                      [
                        _buildInfoRow(context, 'Nombre', '${invoice.customerName}${invoice.customerLastName != null ? ' ${invoice.customerLastName}' : ''}', isDark),
                        if (invoice.customerEmail != null)
                          _buildInfoRow(context, 'Email', invoice.customerEmail!, isDark),
                        if (invoice.customerPhone != null)
                          _buildInfoRow(context, 'Teléfono', invoice.customerPhone!, isDark),
                        if (invoice.customerAddress != null)
                          _buildInfoRow(context, 'Dirección', invoice.customerAddress!, isDark),
                      ],
                      isDark,
                    ),

                    // Notas
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        context,
                        'Notas',
                        Icons.note_rounded,
                        [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              invoice.notes!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                        isDark,
                      ),
                    ],

                    // Alerta si está vencida
                    if (invoice.isOverdue) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 32,
                              color: AppTheme.error,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Factura Vencida',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Esta factura ha vencido. Por favor, contacta con soporte para realizar el pago.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppTheme.error.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

