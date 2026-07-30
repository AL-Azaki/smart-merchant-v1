import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../purchasing/presentation/providers/purchasing_provider.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../purchasing/presentation/mappers/purchase_invoice_document_mapper.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';

class SupplierDetailsView extends ConsumerStatefulWidget {
  final Supplier supplier;

  const SupplierDetailsView({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailsView> createState() =>
      _SupplierDetailsViewState();
}

class _SupplierDetailsViewState extends ConsumerState<SupplierDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.supplier.supplierName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'كشف الحساب'),
            Tab(text: 'فواتير المشتريات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(surfaceColor, borderColor),
          _buildStatementTab(surfaceColor, borderColor),
          _buildInvoicesTab(surfaceColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Color surfaceColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          Card(
            color: surfaceColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المعلومات الأساسية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('الشخص المسؤول'),
                    subtitle: Text(
                      widget.supplier.contactPerson ?? 'غير متوفر',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('رقم الهاتف'),
                    subtitle: Text(widget.supplier.phone ?? 'غير متوفر'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('العنوان'),
                    subtitle: Text(
                      widget.supplier.supplierAddress ?? 'غير متوفر',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Financial Info
          Card(
            color: surfaceColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المعلومات المالية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox(
                          'الرصيد المستحق (الافتتاحي)',
                          '${widget.supplier.openingBalance} ${widget.supplier.openingBalanceType == 'credit' ? 'دائن' : 'مدين'}',
                          Colors.red,
                          surfaceColor,
                          borderColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoBox(
                          'الحد الائتماني',
                          widget.supplier.creditLimit.toStringAsFixed(2),
                          Colors.blue,
                          surfaceColor,
                          borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'SUPPLIER BALANCE METRICS: CAPABILITY GAP',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    String title,
    String value,
    Color color,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementTab(Color surfaceColor, Color borderColor) {
    return const Center(
      child: Text(
        'SUPPLIER ACCOUNT STATEMENT: CAPABILITY GAP',
        style: TextStyle(
          fontSize: 16,
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInvoicesTab(Color surfaceColor, Color borderColor) {
    final invoicesAsync = ref.watch(purchaseInvoicesNotifierProvider);

    return invoicesAsync.when(
      data: (invoices) {
        final supplierInvoices = invoices
            .where((i) => i.supplierId == widget.supplier.id)
            .toList();

        if (supplierInvoices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد فواتير مشتريات لهذا المورد',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: supplierInvoices.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final invoice = supplierInvoices[index];
            return ListTile(
              onTap: () async {
                try {
                  final mapper = getIt<PurchaseInvoiceDocumentMapper>();
                  final document = await mapper.mapToDocumentData(invoice.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CommercialDocumentPreviewScreen(document: document),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error loading document: $e')),
                    );
                  }
                }
              },
              leading: const Icon(Icons.receipt_rounded, color: Colors.orange),
              title: Text(
                invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${invoice.purchaseDate.toString().split(' ')[0]} - الحالة: ${invoice.paymentStatus}',
              ),
              trailing: Text(
                '${invoice.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
