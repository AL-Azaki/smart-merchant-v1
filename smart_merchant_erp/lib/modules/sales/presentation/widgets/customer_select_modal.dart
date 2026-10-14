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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        color: backgroundColor,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.group_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'اختر العميل',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'إضافة عميل جديد',
                            onPressed: () {
                              Navigator.pop(context); // إغلاق نافذة البحث
                              CustomerAddModal.show(context);
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
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
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
                  final filtered = customers
                      .where(
                        (c) =>
                            c.customerName.contains(searchQuery) ||
                            (c.phone != null && c.phone!.contains(searchQuery)),
                      )
                      .toList();

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
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        textSecondary: textSecondary,
                        onTap: () {
                          ref
                              .read(posNotifierProvider.notifier)
                              .setCustomer('', 'عميل نقدي'); // Walk-in
                          Navigator.pop(context);
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: borderColor),
                      ),

                      Text(
                        'العملاء المسجلين (${filtered.length})',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...filtered.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Consumer(
                            builder: (context, ref, _) {
                              final balanceAsync =
                                  ref.watch(customerBalanceProvider(c.id));
                              final liveBalance = balanceAsync.maybeWhen(
                                data: (summary) =>
                                    summary?.netBalance ?? c.openingBalance,
                                orElse: () => c.openingBalance,
                              );
                              return _buildCustomerTile(
                                context,
                                ref,
                                title: c.customerName,
                                subtitle: c.phone ?? 'بدون رقم',
                                icon: Icons.person_rounded,
                                iconColor: AppColors.success,
                                surfaceColor: surfaceColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                textSecondary: textSecondary,
                                balance: liveBalance,
                                isSelected:
                                    posState.customerName == c.customerName,
                                onTap: () {
                                  ref
                                      .read(posNotifierProvider.notifier)
                                      .setCustomer(c.id, c.customerName);
                                  Navigator.pop(context);
                                },
                              );
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
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color textSecondary,
    required VoidCallback onTap,
    double? balance,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
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
                color: iconColor.withValues(alpha: 0.1),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
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
              Icon(
                Icons.chevron_left_rounded,
                color: borderColor,
              ), // Arrow Left for RTL
          ],
        ),
      ),
    );
  }
}
