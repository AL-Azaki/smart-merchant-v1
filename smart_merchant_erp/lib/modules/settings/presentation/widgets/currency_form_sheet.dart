import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class CurrencyFormSheet extends StatefulWidget {
  final Map<String, dynamic>? currency;
  final void Function(Map<String, dynamic> data) onSave;

  const CurrencyFormSheet({
    super.key,
    required this.onSave,
    this.currency,
  });

  static void show(
    BuildContext context, {
    required void Function(Map<String, dynamic> data) onSave,
    Map<String, dynamic>? currency,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CurrencyFormSheet(
          currency: currency,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<CurrencyFormSheet> createState() => _CurrencyFormSheetState();
}

class _CurrencyFormSheetState extends State<CurrencyFormSheet> {
  late TextEditingController _codeController;
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _symbolController;
  late TextEditingController _rateController;
  bool _isBase = false;

  @override
  void initState() {
    super.initState();
    final c = widget.currency;
    _codeController = TextEditingController(text: (c?['currency_code'] as String?) ?? '');
    _nameArController = TextEditingController(text: (c?['currency_name_ar'] as String?) ?? '');
    _nameEnController = TextEditingController(text: (c?['currency_name_en'] as String?) ?? '');
    _symbolController = TextEditingController(text: (c?['currency_symbol'] as String?) ?? '');
    _rateController = TextEditingController(
      text: c?['exchange_rate'] != null ? c!['exchange_rate'].toString() : '1',
    );
    _isBase = (c?['is_base_currency'] as bool?) ?? false;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _symbolController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_codeController.text.trim().isEmpty) return;

    final data = <String, dynamic>{
      'id': widget.currency?['id'] ?? 'cur_${DateTime.now().millisecondsSinceEpoch}',
      'currency_code': _codeController.text.trim().toUpperCase(),
      'currency_name_ar': _nameArController.text.trim(),
      'currency_name_en': _nameEnController.text.trim(),
      'currency_symbol': _symbolController.text.trim(),
      'exchange_rate': double.tryParse(_rateController.text.trim()) ?? 1.0,
      'is_base_currency': _isBase,
      'is_active': widget.currency?['is_active'] ?? true,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final isEditing = widget.currency != null;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'تعديل العملة' : 'إضافة عملة جديدة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 20, color: textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form Fields
            _buildLabel('رمز العملة (مثل USD)', textSecondary),
            const SizedBox(height: 6),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDecoration(inputBg, borderColor, hint: 'YER / USD / SAR'),
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('الاسم (عربي)', textSecondary),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameArController,
                        decoration: _inputDecoration(inputBg, borderColor, hint: 'ريال يمني'),
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('الاسم (إنجليزي)', textSecondary),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameEnController,
                        decoration: _inputDecoration(inputBg, borderColor, hint: 'Yemeni Rial'),
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('الرمز (مثل \$)', textSecondary),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _symbolController,
                        decoration: _inputDecoration(inputBg, borderColor, hint: 'ر.ي'),
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('سعر الصرف للأساسية', textSecondary),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _rateController,
                        enabled: !_isBase,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(
                          _isBase ? inputBg.withOpacity(0.5) : inputBg,
                          borderColor,
                          hint: '1',
                        ),
                        style: TextStyle(
                          color: _isBase ? textSecondary : textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text(
                        'حفظ العملة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }

  InputDecoration _inputDecoration(Color fill, Color border, {String? hint}) {
    return InputDecoration(
      filled: true,
      fillColor: fill,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border.withOpacity(0.5), width: 1),
      ),
    );
  }
}
