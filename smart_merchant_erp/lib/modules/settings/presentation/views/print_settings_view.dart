import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class PrintSettingsView extends StatefulWidget {
  const PrintSettingsView({super.key});

  @override
  State<PrintSettingsView> createState() => _PrintSettingsViewState();
}

class _PrintSettingsViewState extends State<PrintSettingsView> {
  String _selectedPaperSize = '80mm';
  String _selectedPrinter = 'EPSON TM-T20III';
  final TextEditingController _copiesController = TextEditingController(text: '1');
  bool _printQr = true;
  bool _autoPrint = true;

  final TextEditingController _headerController = TextEditingController(text: 'فرع العليا - الرياض');
  final TextEditingController _footerController = TextEditingController(
    text: 'شكراً لتسوقكم معنا!\nالبضاعة المباعة لا ترد ولا تستبدل بعد 3 أيام.',
  );

  @override
  void dispose() {
    _copiesController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ التغييرات بنجاح'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B);
    final textSecondary = isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'إعدادات الطباعة',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                // Banner / Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.print_rounded, color: Color(0xFF10B981), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إعدادات الطباعة والفواتير',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'تخصيص شكل ومقاس فواتير البيع',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('معاينة الفاتورة...')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        ),
                        icon: Icon(Icons.remove_red_eye_outlined, size: 18, color: textPrimary),
                        label: Text(
                          'معاينة الفاتورة',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Main 2-Column Section
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 800;

                    // Left Column Card (Logo & Texts)
                    final leftColumnCard = Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('شعار الفاتورة', textPrimary),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('رفع شعار الفاتورة...')),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 70,
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, color: const Color(0xFF64748B), size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'رفع شعار أبيض وأسود للطباعة',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('رأس الفاتورة (النص العلوي)', textPrimary),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _headerController,
                            maxLines: 2,
                            decoration: _inputDecoration(inputBg, borderColor),
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('تذييل الفاتورة (النص السفلي)', textPrimary),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _footerController,
                            maxLines: 3,
                            decoration: _inputDecoration(inputBg, borderColor),
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'حفظ التغييرات',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    // Right Column Card (Printer & Options)
                    final rightColumnCard = Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('مقاس الورق الافتراضي', textPrimary),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedPaperSize,
                            decoration: _inputDecoration(inputBg, borderColor),
                            dropdownColor: surface,
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                            onChanged: (val) => setState(() => _selectedPaperSize = val!),
                            items: const [
                              DropdownMenuItem(value: '80mm', child: Text('طابعة إيصالات (80mm Thermal)')),
                              DropdownMenuItem(value: '58mm', child: Text('طابعة إيصالات (58mm Thermal)')),
                              DropdownMenuItem(value: 'A4', child: Text('طابعة عادية (A4 Document)')),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('الطابعة الافتراضية', textPrimary),
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<String>(
                                      value: _selectedPrinter,
                                      decoration: _inputDecoration(inputBg, borderColor),
                                      dropdownColor: surface,
                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                                      onChanged: (val) => setState(() => _selectedPrinter = val!),
                                      items: const [
                                        DropdownMenuItem(value: 'EPSON TM-T20III', child: Text('EPSON TM-T20III')),
                                        DropdownMenuItem(value: 'XP-80C Printer', child: Text('XP-80C Printer')),
                                        DropdownMenuItem(value: 'Microsoft Print to PDF', child: Text('Microsoft Print to PDF')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('عدد النسخ الافتراضي', textPrimary),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _copiesController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: _inputDecoration(inputBg, borderColor),
                                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Checkbox Card 1 (ZATCA QR)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'طباعة رمز الاستجابة السريع (QR Code) لهيئة الزكاة',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _printQr,
                                    activeColor: const Color(0xFF10B981),
                                    onChanged: (val) => setState(() => _printQr = val ?? true),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Checkbox Card 2 (Auto Print)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'طباعة الفاتورة تلقائياً عند الدفع',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _autoPrint,
                                    activeColor: const Color(0xFF10B981),
                                    onChanged: (val) => setState(() => _autoPrint = val ?? true),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        children: [
                          leftColumnCard,
                          const SizedBox(height: AppSpacing.lg),
                          rightColumnCard,
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: leftColumnCard),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(child: rightColumnCard),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  InputDecoration _inputDecoration(Color fill, Color border) {
    return InputDecoration(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
    );
  }
}
