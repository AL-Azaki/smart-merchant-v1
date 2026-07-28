import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/crm_provider.dart';
import 'widgets/contact_form_sheet.dart';
import '../../../purchasing/presentation/providers/purchasing_provider.dart';
import 'supplier_details_view.dart';

class SuppliersListView extends ConsumerStatefulWidget {
  const SuppliersListView({super.key});

  @override
  ConsumerState<SuppliersListView> createState() => _SuppliersListViewState();
}

class _SuppliersListViewState extends ConsumerState<SuppliersListView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final suppliersAsync = ref.watch(suppliersNotifierProvider);

    return suppliersAsync.when(
      data: (suppliers) {
        final filteredSuppliers = suppliers.where((s) {
          final q = _searchQuery.toLowerCase();
          return s.supplierName.toLowerCase().contains(q) || (s.phone?.contains(q) ?? false) || (s.contactPerson?.toLowerCase().contains(q) ?? false);
        }).toList();

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: surfaceColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.store_outlined,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الموردين',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${suppliers.length} مورد',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: PrimaryButton(
                      text: 'إضافة مورد',
                      icon: Icons.add,
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            child: ContactFormSheet(
                              isCustomer: false,
                              onClose: () => Navigator.pop(ctx),
                                onSave: (data) async {
                                  final successId = await ref.read(crmNotifierProvider.notifier).saveSupplier(data);
                                  if (successId != null && ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Toolbar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'ابحث باسم المورد أو الشركة...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Icon(Icons.filter_list),
                  ),
                ],
              ),
            ),
            // Data Grid / Empty State
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: filteredSuppliers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_mall_directory_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'لا يوجد موردين',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'قم بإضافة مورد جديد لعرضه هنا.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: filteredSuppliers.length,
                        separatorBuilder: (_, __) => Divider(color: borderColor),
                        itemBuilder: (context, index) {
                          final s = filteredSuppliers[index];
                          return ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SupplierDetailsView(supplier: s),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: AppColors.warning.withOpacity(0.1),
                              child: Text(
                                s.supplierName.substring(0, 1),
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(s.supplierName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${s.phone ?? 'لا يوجد هاتف'} - الرصيد: ${s.openingBalance} ${s.openingBalanceType == 'credit' ? 'دائن (علينا)' : 'مدين (لنا)'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                        child: ContactFormSheet(
                                          contact: {
                                            'id': s.id,
                                            'name': s.supplierName,
                                            'contact_person': s.contactPerson,
                                            'phone': s.phone,
                                            'address': s.supplierAddress,
                                            'credit_limit': s.creditLimit,
                                            'opening_balance': s.openingBalance,
                                            'opening_balance_type': s.openingBalanceType,
                                            'opening_balance_date': s.openingBalanceDate?.toIso8601String(),
                                          },
                                          isCustomer: false,
                                          onClose: () => Navigator.pop(ctx),
                                          onSave: (data) async {
                                            final successId = await ref.read(crmNotifierProvider.notifier).saveSupplier(data);
                                            if (successId != null && ctx.mounted) {
                                              Navigator.pop(ctx);
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطأ: $err')),
    );
  }
}
