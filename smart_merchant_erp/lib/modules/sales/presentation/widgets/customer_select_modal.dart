import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_provider.dart';
import '../providers/customer_provider.dart';
import 'customer_add_modal.dart';

class CustomerSelectModal extends ConsumerStatefulWidget {
  const CustomerSelectModal({super.key});

  @override
  ConsumerState<CustomerSelectModal> createState() =>
      _CustomerSelectModalState();
}

class _CustomerSelectModalState extends ConsumerState<CustomerSelectModal> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posNotifierProvider);
    final customersAsync = ref.watch(customersNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 500,
        height: 700,
        color: AppColors.backgroundLight,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.group_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'اختر العميل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'إضافة عميل جديد',
                            onPressed: () {
                              Navigator.pop(context); // إغلاق نافذة البحث
                              showDialog(
                                context: context,
                                builder: (_) => const CustomerAddModal(),
                              ); // فتح إضافة جديد
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو رقم الهاتف...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: customersAsync.when(
                data: (customers) {
                  final filtered = customers.where(
                    (c) =>
                        c.customerName.contains(searchQuery) ||
                        (c.phone != null && c.phone!.contains(searchQuery)),
                  ).toList();
                  
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Walk-in option (خيار البيع النقدي السريع)
                      _buildCustomerTile(
                        context,
                        ref,
                        title: 'عميل نقدي (Walk-in)',
                        subtitle: 'بيع نقدي بدون تسجيل بيانات عميل',
                        icon: Icons.person_rounded,
                        iconColor: AppColors.primary,
                        isSelected: posState.customerName == null,
                        onTap: () {
                          ref
                              .read(posNotifierProvider.notifier)
                              .setCustomer('', 'عميل نقدي'); // Walk-in
                          Navigator.pop(context);
                        },
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppColors.borderLight),
                      ),

                      Text(
                        'العملاء المسجلين (${filtered.length})',
                        style: const TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...filtered.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCustomerTile(
                            context,
                            ref,
                            title: c.customerName,
                            subtitle: c.phone ?? 'بدون رقم',
                            icon: Icons.person_rounded,
                            iconColor: AppColors.success,
                            balance: c.openingBalance, // Fallback to opening balance if real time balance is not loaded
                            isSelected: posState.customerName == c.customerName,
                            onTap: () {
                              ref
                                  .read(posNotifierProvider.notifier)
                                  .setCustomer(
                                    c.id,
                                    c.customerName,
                                  );
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    double? balance,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                  if (balance != null && balance != 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'الرصيد: ${balance.abs()} ${balance < 0 ? 'عليه' : 'له'}',
                        style: TextStyle(
                          color: balance < 0
                              ? AppColors.error
                              : AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            else
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.borderLight,
              ), // Arrow Left for RTL
          ],
        ),
      ),
    );
  }
}
