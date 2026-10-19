import 'package:flutter/material.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/utils/arabic_tafqeet.dart';
import 'voucher_print_service.dart';

class VoucherDetailsDialog extends StatefulWidget {
  final Payment voucher;

  const VoucherDetailsDialog({
    required this.voucher,
    super.key,
  });

  @override
  State<VoucherDetailsDialog> createState() => _VoucherDetailsDialogState();
}

class _VoucherDetailsDialogState extends State<VoucherDetailsDialog> {
  String _accountName = 'جاري التحميل...';
  String _paymentMethodName = 'جاري التحميل...';
  String _contactName = 'جاري التحميل...';
  String _accountantName = 'المسؤول المالي';

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    try {
      final db = getIt<AppDatabase>();
      final v = widget.voucher;
      final isReceipt = v.paymentType.toLowerCase() == 'receipt';

      // 1. الحساب الفعلي (صندوق/بنك)
      String acc = isReceipt ? 'الخزينة النقدية الرئيسية' : 'الحساب البنكي الرئيسي';
      if (v.chartOfAccountId.isNotEmpty) {
        final coa = await (db.select(db.chartOfAccounts)..where((c) => c.id.equals(v.chartOfAccountId))).getSingleOrNull();
        if (coa != null) {
          acc = '${coa.accountCode} - ${coa.accountName}';
        }
      }

      // 2. طريقة الدفع الفعلية
      String pmTitle = 'نقداً';
      if (v.paymentMethodId.isNotEmpty) {
        final pm = await (db.select(db.paymentMethods)..where((m) => m.id.equals(v.paymentMethodId))).getSingleOrNull();
        if (pm != null) {
          pmTitle = pm.methodName;
        } else {
          final byCode = await (db.select(db.paymentMethods)..where((m) => m.methodCode.equals(v.paymentMethodId))).getSingleOrNull();
          if (byCode != null) {
            pmTitle = byCode.methodName;
          } else {
            final upper = v.paymentMethodId.toUpperCase();
            if (upper == 'CASH') {
              pmTitle = 'نقداً';
            } else if (upper == 'CARD') {
              pmTitle = 'شبكة / مدى';
            } else if (upper.contains('BANK')) {
              pmTitle = 'تحويل بنكي';
            } else {
              pmTitle = v.paymentMethodId;
            }
          }
        }
      }

      // 3. اسم الطرف الفعلي (عميل/مورد/حساب مصروف)
      String contact = '';
      if (v.contactId != null && v.contactId!.isNotEmpty) {
        if (v.contactType == 'Customer') {
          final c = await (db.select(db.customers)..where((t) => t.id.equals(v.contactId!))).getSingleOrNull();
          if (c != null) {
            contact = c.customerName;
          }
        } else if (v.contactType == 'Supplier') {
          final s = await (db.select(db.suppliers)..where((t) => t.id.equals(v.contactId!))).getSingleOrNull();
          if (s != null) {
            contact = s.supplierName;
          }
        }
      }

      if (contact.isEmpty) {
        final je = await (db.select(db.journalEntries)..where((j) => j.documentId.equals(v.id))).getSingleOrNull();
        if (je != null) {
          final lines = await (db.select(db.journalEntryLines)..where((l) => l.journalEntryId.equals(je.id))).get();
          final opposing = lines.where((l) => isReceipt ? l.type == 'Credit' : l.type == 'Debit').firstOrNull;
          if (opposing != null) {
            final oppAcc = await (db.select(db.chartOfAccounts)..where((c) => c.id.equals(opposing.chartOfAccountId))).getSingleOrNull();
            if (oppAcc != null) {
              contact = oppAcc.accountName;
            }
          }
        }
      }

      if (contact.isEmpty) {
        contact = isReceipt ? 'عميل نقدي' : 'مصروفات تشغيلية عامة';
      }

      // 4. المحاسب
      String accountant = isReceipt ? 'أمين الصندوق' : 'المحاسب المالي';
      if (v.createdBy.isNotEmpty) {
        final u = await (db.select(db.usersTable)..where((user) => user.id.equals(v.createdBy))).getSingleOrNull();
        if (u != null) {
          final fullName = '${u.firstName} ${u.lastName}'.trim();
          if (fullName.isNotEmpty) {
            accountant = fullName;
          }
        }
      }

      if (mounted) {
        setState(() {
          _accountName = acc;
          _paymentMethodName = pmTitle;
          _contactName = contact;
          _accountantName = accountant;
        });
      }
    } catch (_) {}
  }

  String _formatAmount(double val) {
    return val.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final voucher = widget.voucher;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReceipt = voucher.paymentType.toLowerCase() == 'receipt';

    final themeColor = isReceipt ? const Color(0xFF10B981) : const Color(0xFF2563EB);
    final themeBg = isReceipt
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF));
    final themeBorder = isReceipt
        ? (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
        : (isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE));

    final dateStr =
        '${voucher.paymentDate.year}/${voucher.paymentDate.month.toString().padLeft(2, '0')}/${voucher.paymentDate.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${voucher.paymentDate.hour.toString().padLeft(2, '0')}:${voucher.paymentDate.minute.toString().padLeft(2, '0')}';

    final currency = voucher.currencyId == 'YER' ? 'ريال يمني' : voucher.currencyId;
    final tafqeet = ArabicTafqeet.convert(voucher.amount, currencyName: currency);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. شريط العنوان والنوع
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      tooltip: 'إغلاق',
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isReceipt ? 'سند قبض مالي' : 'سند صرف مالي',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              voucher.paymentNumber,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: themeBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: themeBorder),
                          ),
                          child: Icon(
                            isReceipt ? Icons.south_west_rounded : Icons.north_east_rounded,
                            color: themeColor,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. بطاقة المبلغ البارز مع التفقيط
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: themeBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: themeBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isReceipt ? 'إجمالي المبلغ المقبوض' : 'إجمالي المبلغ المصروف',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: themeColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatAmount(voucher.amount)} $currency',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: themeBorder.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          tafqeet,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. جدول المعلومات والتفاصيل الحقيقية
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        label: 'تاريخ ووقت السند',
                        value: '$dateStr - $timeStr',
                        icon: Icons.calendar_today_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        label: isReceipt ? 'استلمنا من الأخ / السادة' : 'صرفنا إلى الأخ / السادة',
                        value: _contactName,
                        icon: Icons.person_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        label: isReceipt ? 'الخزينة / الحساب المودع فيه' : 'الخزينة / الحساب المسحوب منه',
                        value: _accountName,
                        icon: Icons.account_balance_wallet_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        label: 'طريقة الدفع',
                        value: _paymentMethodName,
                        icon: Icons.payments_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        label: 'المحاسب المسؤول',
                        value: _accountantName,
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        label: 'البيان والملاحظات',
                        value: voucher.notes?.isNotEmpty == true ? voucher.notes! : (isReceipt ? 'قبض نقدي مقيد ومرحل' : 'صرف نقدي مقيد ومرحل'),
                        icon: Icons.notes_rounded,
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        label: 'حالة السند',
                        value: voucher.status == 'Posted' ? 'مرحل ومعتمد ✓' : voucher.status,
                        icon: Icons.check_circle_outline_rounded,
                        isDark: isDark,
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. أزرار الإجراءات والطباعة
                Row(
                  children: [
                    // زر المشاركة
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('مشاركة', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          VoucherPrintService.shareVoucher(
                            context: context,
                            voucher: voucher,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // زر الطباعة الرسمي
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.print_rounded, size: 20),
                        label: const Text(
                          'طباعة السند الرسمي',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        onPressed: () {
                          VoucherPrintService.printVoucher(
                            context: context,
                            voucher: voucher,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 16, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
          ],
        ),
      ],
    );
  }
}
