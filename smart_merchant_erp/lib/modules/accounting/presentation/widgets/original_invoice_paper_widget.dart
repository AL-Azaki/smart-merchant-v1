import 'package:flutter/material.dart';

class OriginalInvoicePaperWidget extends StatelessWidget {
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final String journalNumber;
  final String dateStr;
  final double totalDebit;
  final bool isMobile;

  const OriginalInvoicePaperWidget({
    super.key,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.journalNumber,
    required this.dateStr,
    required this.totalDebit,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('متجر النور', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('هاتف: +967771234567  •  العنوان: صنعاء، اليمن', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('فاتورة مبيعات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('مدفوعة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text('معلومات الفاتورة والعميل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          const SizedBox(height: 6),
          if (isMobile) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('اسم العميل:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('محمد علي سالم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('طريقة الدفع:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('آجل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('اسم العميل:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('محمد علي سالم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('طريقة الدفع:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('آجل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFCBD5E1)),
                  columnWidths: const {
                    0: FixedColumnWidth(36),
                    1: FixedColumnWidth(140),
                    2: FixedColumnWidth(90),
                    3: FixedColumnWidth(64),
                    4: FixedColumnWidth(56),
                    5: FixedColumnWidth(80),
                    6: FixedColumnWidth(56),
                    7: FixedColumnWidth(62),
                    8: FixedColumnWidth(70),
                    9: FixedColumnWidth(66),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
                      children: [
                        _cell('رقم', isHeader: true),
                        _cell('وصف المنتج', isHeader: true),
                        _cell('الباركود/SKU', isHeader: true),
                        _cell('الوحدة', isHeader: true),
                        _cell('الكمية', isHeader: true),
                        _cell('سعر الوحدة', isHeader: true),
                        _cell('الخصم', isHeader: true),
                        _cell('الضريبة', isHeader: true),
                        _cell('الإجمالي', isHeader: true),
                        _cell('الصافي', isHeader: true),
                      ],
                    ),
                    TableRow(
                      children: [
                        _cell('1'),
                        _cell('منتج مباع', isBold: true),
                        _cell('---'),
                        _cell('---'),
                        _cell('10'),
                        _cell('80'),
                        _cell('0'),
                        _cell('0'),
                        _cell('800', isBold: true),
                        _cell('800', color: const Color(0xFF10B981), isBold: true),
                      ],
                    ),
                    TableRow(
                      children: [
                        _cell('2'),
                        _cell('منتج مباع', isBold: true),
                        _cell('---'),
                        _cell('---'),
                        _cell('5'),
                        _cell('180'),
                        _cell('0'),
                        _cell('0'),
                        _cell('900', isBold: true),
                        _cell('900', color: const Color(0xFF10B981), isBold: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isMobile) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي المنتجات:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('2 (15 وحدة)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المجموع الفرعي:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('1,700 ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الإجمالي النهائي:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('1,700 ر.ي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ملاحظات الفاتورة والشروط:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('لا توجد ملاحظات إضافية.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الإجمالي الفرعي:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('1,700 ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الإجمالي:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('1,700 ر.ي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16,
            runSpacing: 12,
            children: [
              _SigCol(title: 'توقيع البائع/المندوب'),
              _SigCol(title: 'توقيع المستلم/العميل'),
              _SigCol(title: 'اعتماد الإدارة'),
              _SigCol(title: 'ختم الشركة'),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _cell(String text, {bool isHeader = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight: (isHeader || isBold) ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? Colors.white : (color ?? const Color(0xFF1E293B)),
          height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SigCol extends StatelessWidget {
  final String title;
  const _SigCol({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        const Text('...........................', style: TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
