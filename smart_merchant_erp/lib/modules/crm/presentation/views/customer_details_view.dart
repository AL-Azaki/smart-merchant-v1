import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../sales/presentation/providers/customer_provider.dart';
import '../../../sales/presentation/mappers/sales_invoice_document_mapper.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../../app/di/getit_instance.dart';

class CustomerDetailsView extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailsView({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailsView> createState() =>
      _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends ConsumerState<CustomerDetailsView>
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
        title: Text(widget.customer.customerName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'كشف الحساب'),
            Tab(text: 'الفواتير'),
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
                    leading: const Icon(Icons.phone),
                    title: const Text('رقم الهاتف'),
                    subtitle: Text(widget.customer.phone ?? 'غير متوفر'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('العنوان'),
                    subtitle: Text(widget.customer.address ?? 'غير متوفر'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Financial Info
          ref
              .watch(customerBalanceProvider(widget.customer.id))
              .when(
                data: (balance) {
                  if (balance == null)
                    return const Text('لا تتوفر بيانات مالية');
                  return Card(
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoBox(
                                  'الرصيد المستحق (الافتتاحي)',
                                  '${balance.openingBalance} ${balance.openingBalanceType == 'credit' ? 'دائن' : 'مدين'}',
                                  Colors.red,
                                  surfaceColor,
                                  borderColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoBox(
                                  'الحد الائتماني',
                                  balance.creditLimit.toStringAsFixed(2),
                                  Colors.blue,
                                  surfaceColor,
                                  borderColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoBox(
                                  'إجمالي المبيعات (الفواتير)',
                                  balance.totalReceivables.toStringAsFixed(2),
                                  Colors.green,
                                  surfaceColor,
                                  borderColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoBox(
                                  'إجمالي المدفوعات',
                                  balance.totalPaid.toStringAsFixed(2),
                                  Colors.purple,
                                  surfaceColor,
                                  borderColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoBox(
                                  'الرصيد المتبقي',
                                  balance.totalRemaining.toStringAsFixed(2),
                                  Colors.orange,
                                  surfaceColor,
                                  borderColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('خطأ: $e'),
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
    return const Center(child: Text('لا توجد حركات مالية حتى الآن'));
  }

  Widget _buildInvoicesTab(Color surfaceColor, Color borderColor) {
    final invoicesAsync = ref.watch(salesInvoicesNotifierProvider);

    return invoicesAsync.when(
      data: (invoices) {
        final customerInvoices = invoices
            .where((i) => i.customerId == widget.customer.id)
            .toList();

        if (customerInvoices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد فواتير لهذا العميل',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: customerInvoices.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final invoice = customerInvoices[index];
            return ListTile(
              leading: const Icon(Icons.receipt_rounded, color: Colors.blue),
              title: Text(
                invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${invoice.invoiceDate.toString().split(' ')[0]} - الحالة: ${invoice.paymentStatus}',
              ),
              trailing: Text(
                '${invoice.grandTotal.toStringAsFixed(2)} YER',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  final mapper = getIt<SalesInvoiceDocumentMapper>();
                  final docData = await mapper.mapToDocumentData(invoice.id);
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CommercialDocumentPreviewScreen(document: docData),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
