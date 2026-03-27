import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/invoice_service.dart';
import '../../models/invoice_model.dart';
import '../../theme/app_theme.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  static const Color _primaryRed = Color(0xFFDC2626);

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
                                    invoice.invoiceNumber,
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                    softWrap: true,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                icon: const Icon(Icons.edit_rounded),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateInvoiceScreen(invoice: invoice),
                                    ),
                                  ).then((_) {
                                    setState(() {});
                                  });
                                },
                                color: Theme.of(context).cardColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

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
                        const SizedBox(height: 16),

                        // Información de la Factura
                        _buildSectionCard(
                          context,
                          'Información de la Factura',
                          Icons.receipt_long_rounded,
                          [
                            _buildInfoRow(context, 'Plan', InvoiceModel.getPlanName(invoice.internetPlan), isDark),
                            _buildInfoRow(context, 'Fecha de emisión', _formatDate(invoice.issueDate), isDark),
                            _buildInfoRow(context, 'Fecha de vencimiento', _formatDate(invoice.dueDate), isDark),
                            if (invoice.sendDate != null)
                              _buildInfoRow(context, 'Fecha de envío programada', _formatDateTime(invoice.sendDate!), isDark),
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
                                  '\$${invoice.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} COP',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          isDark,
                        ),
                        const SizedBox(height: 16),

                        // Notas
                        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
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
                                  softWrap: true,
                                ),
                              ),
                            ],
                            isDark,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Acciones
                        if (invoice.status != 'paid' && invoice.status != 'cancelled') ...[
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.success.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _markAsPaid(invoice),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: AppTheme.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Marcar como Pagada',
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
                          const SizedBox(height: 12),
                        ],

                      ],
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(InvoiceModel invoice, bool isDark) {
    final statusColor = invoice.isOverdue
        ? AppTheme.error
        : _getStatusColor(invoice.status);
    final statusText = invoice.isOverdue
        ? 'Vencida'
        : _getStatusText(invoice.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
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
        return Colors.grey.shade400;
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
                    size: 24,
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
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }


  Future<void> _markAsPaid(InvoiceModel invoice) async {
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => _PaymentMethodDialog(
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );

    if (paymentMethod != null) {
      try {
        await _invoiceService.markAsPaid(invoice.id, paymentMethod, null);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura marcada como pagada'),
            backgroundColor: AppTheme.success,
          ),
        );
        
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

class _PaymentMethodDialog extends StatelessWidget {
  final bool isDark;

  const _PaymentMethodDialog({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Método de Pago',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            _buildPaymentOption(context, 'Efectivo', 'cash'),
            const SizedBox(height: 12),
            _buildPaymentOption(context, 'Transferencia', 'transfer'),
            const SizedBox(height: 12),
            _buildPaymentOption(context, 'Nequi', 'nequi'),
            const SizedBox(height: 12),
            _buildPaymentOption(context, 'Daviplata', 'daviplata'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
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
}

