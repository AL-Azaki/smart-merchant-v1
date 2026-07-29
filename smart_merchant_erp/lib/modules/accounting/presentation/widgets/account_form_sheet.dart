import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

class AccountFormSheet extends StatefulWidget {
  final Map<String, dynamic>? account;
  final VoidCallback onClose;
  final Function(Map<String, dynamic> data) onSave;

  const AccountFormSheet({
    super.key,
    this.account,
    required this.onClose,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    Map<String, dynamic>? account,
    required Function(Map<String, dynamic> data) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AccountFormSheet(
        account: account,
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (data) {
          Navigator.of(ctx).pop();
          onSave(data);
        },
      ),
    );
  }

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  String _accountType = 'Asset';
  String? _parentId;
  bool _allowPosting = true;
  String _normalBalance = 'Debit';

  final List<Map<String, String>> _mockParentAccounts = const [
    {'id': '1000', 'code': '1000', 'name': 'الأصول'},
    {'id': '1100', 'code': '1100', 'name': 'الأصول المتداولة'},
    {'id': '2000', 'code': '2000', 'name': 'الخصوم'},
    {'id': '2100', 'code': '2100', 'name': 'الخصوم المتداولة'},
    {'id': '3000', 'code': '3000', 'name': 'حقوق الملكية'},
    {'id': '4000', 'code': '4000', 'name': 'الإيرادات'},
    {'id': '5000', 'code': '5000', 'name': 'المصروفات'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?['name'] ?? '');
    _codeController = TextEditingController(text: widget.account?['code'] ?? '');
    _accountType = widget.account?['type'] ?? 'Asset';
    _parentId = widget.account?['parentId'];
    _allowPosting = widget.account?['allowPosting'] ?? true;
    _normalBalance = widget.account?['normalBalance'] ?? 'Debit';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty || _codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة الحقول الإلزامية')),
      );
      return;
    }

    widget.onSave({
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
      'type': _accountType,
      'parentId': _parentId,
      'allowPosting': _allowPosting,
      'normalBalance': _normalBalance,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final isEdit = widget.account != null;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.hub_outlined, color: Color(0xFF3B82F6), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'تعديل حساب مالي' : 'إضافة حساب مالي جديد',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
                ),
              ],
            ),
          ),

          // Scrollable Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('رمز الحساب *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _codeController,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: '1105',
                                filled: true,
                                fillColor: surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('اسم الحساب *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'مثال: نقدية بالصندوق',
                                filled: true,
                                fillColor: surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('الحساب الأب (الحساب الرئيسي)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _parentId,
                        hint: Text('-- لا يوجد (حساب رئيسي) --', style: TextStyle(fontSize: 13, color: textSecondary)),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String?>(value: null, child: Text('-- لا يوجد (حساب رئيسي) --', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary))),
                          ..._mockParentAccounts.map((a) {
                            return DropdownMenuItem<String?>(value: a['id'], child: Text('${a['code']} - ${a['name']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)));
                          }),
                        ],
                        onChanged: (v) => setState(() => _parentId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('نوع الحساب', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                            const SizedBox(height: 6),
                            Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _accountType,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'Asset', child: Text('أصول', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: 'Liability', child: Text('خصوم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: 'Equity', child: Text('حقوق ملكية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: 'Revenue', child: Text('إيرادات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: 'Expense', child: Text('مصروفات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                  ],
                                  onChanged: (v) => setState(() => _accountType = v!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الرصيد الطبيعي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                            const SizedBox(height: 6),
                            Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _normalBalance,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'Debit', child: Text('مدين', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: 'Credit', child: Text('دائن', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                  ],
                                  onChanged: (v) => setState(() => _normalBalance = v!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _allowPosting,
                          activeColor: const Color(0xFF3B82F6),
                          onChanged: (v) => setState(() => _allowPosting = v ?? true),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('حساب فرعي (يقبل القيود/التسجيل)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text('إذا لم تحدده، سيكون حساب تجميعي رئيسي فقط.', style: TextStyle(fontSize: 12, color: textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('إلغاء', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textSecondary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      label: const Text('حفظ الحساب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
