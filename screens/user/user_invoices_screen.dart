import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/invoice_service.dart';
import '../../models/invoice_model.dart';
import '../../theme/app_theme.dart';
import 'user_invoice_detail_screen.dart';

class UserInvoicesScreen extends StatefulWidget {
  const UserInvoicesScreen({super.key});

  @override
  State<UserInvoicesScreen> createState() => _UserInvoicesScreenState();
}

class _UserInvoicesScreenState extends State<UserInvoicesScreen> with SingleTickerProviderStateMixin {
  //Rs Development
  final InvoiceService _invoiceService = InvoiceService();
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Widget _buildInvoiceCard(InvoiceModel invoice, bool isDark) {
    final statusColor = _getStatusColor(invoice.status);
    final isOverdue = invoice.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue 
              ? AppTheme.error.withValues(alpha: 0.3)
              : statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserInvoiceDetailScreen(invoiceId: invoice.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusColor,
                            statusColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppTheme.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            softWrap: true,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getStatusText(invoice.status),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                                if (isOverdue) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 12,
                                    color: AppTheme.error,
                                  ),
                                ],
                              ],
                            ),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monto',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(invoice.amount),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Vence',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                            Text(
                            _formatDate(invoice.dueDate),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isOverdue 
                                  ? AppTheme.error
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Obtener userId del provider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    _userId = user?.id;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
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
                            'Mis Facturas',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gestiona todas tus facturas',
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
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
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
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.darkBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Pendientes'),
                    Tab(text: 'Pagadas'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Content
              Expanded(
                child: _userId == null
                    ? _buildEmptyState('No se pudo cargar tu información', Icons.error_outline_rounded, isDark)
                    : StreamBuilder<List<InvoiceModel>>(
                        stream: _invoiceService.getInvoicesByUser(_userId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return _buildEmptyState(
                              'Error al cargar facturas',
                              Icons.error_outline_rounded,
                              isDark,
                            );
                          }

                          final allInvoices = snapshot.data ?? [];
                          
                          return TabBarView(
                            controller: _tabController,
                            children: [
                              // Pendientes
                              allInvoices.where((inv) => inv.status != 'paid' && inv.status != 'cancelled').isEmpty
                                  ? _buildEmptyState(
                                      'No tienes facturas pendientes',
                                      Icons.receipt_long_outlined,
                                      isDark,
                                    )
                                  : SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Column(
                                        children: allInvoices
                                            .where((inv) => inv.status != 'paid' && inv.status != 'cancelled')
                                            .map((invoice) => _buildInvoiceCard(invoice, isDark))
                                            .toList(),
                                      ),
                                    ),

                              // Pagadas
                              allInvoices.where((inv) => inv.status == 'Pagada').isEmpty
                                  ? _buildEmptyState(
                                      'No tienes facturas pagadas',
                                      Icons.check_circle_outline_rounded,
                                      isDark,
                                    )
                                  : SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Column(
                                        children: allInvoices
                                            .where((inv) => inv.status == 'Pagada')
                                            .map((invoice) => _buildInvoiceCard(invoice, isDark))
                                            .toList(),
                                      ),
                                    ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

