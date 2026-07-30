import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';

class AccountFormSheet extends StatefulWidget {
  final Map<String, dynamic>? account;
  final List<Map<String, dynamic>>? parentAccounts;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;

  const AccountFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.account,
    this.parentAccounts,
  });

  static void show(
    BuildContext context, {
    required void Function(Map<String, dynamic> data) onSave,
    Map<String, dynamic>? account,
    List<Map<String, dynamic>>? parentAccounts,
  }) {
    showAppModalSheet<void>(
      context: context,
      builder: (ctx) => AccountFormSheet(
        account: account,
        parentAccounts: parentAccounts,
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
    {'id': 'acc_1', 'code': '1000', 'name': 'الأصول'},
    {'id': 'acc_2', 'code': '1100', 'name': 'الأصول المتداولة'},
    {'id': 'acc_5', 'code': '2000', 'name': 'الخصوم'},
    {'id': 'acc_6', 'code': '2100', 'name': 'الخصوم المتداولة'},
    {'id': 'acc_7', 'code': '3000', 'name': 'حقوق الملكية'},
    {'id': 'acc_9', 'code': '4000', 'name': 'الإيرادات'},
    {'id': 'acc_11', 'code': '5000', 'name': 'المصروفات'},
    {'id': 'acc_13', 'code': '5200', 'name': 'مصروفات تشغيلية'},
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
    _nameController = TextEditingController(text: widget.account?['name']?.toString() ?? '');
    _codeController = TextEditingController(text: widget.account?['code']?.toString() ?? '');
    _accountType = widget.account?['type']?.toString() ?? 'Asset';
    _parentId = widget.account?['parentId']?.toString();
    _allowPosting = (widget.account?['allowPosting'] as bool?) ?? true;
    _normalBalance = widget.account?['normalBalance']?.toString() ?? 'Debit';
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
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final isEdit = widget.account != null;

    final parentList = widget.parentAccounts ?? _mockParentAccounts;
    final parentIds = parentList.map((a) => a['id']?.toString()).toSet();
    final String? effectiveParentId = (_parentId != null && parentIds.contains(_parentId)) ? _parentId : null;

    return AppModalSheet(
      title: isEdit ? 'تعديل حساب مالي' : 'إضافة حساب مالي جديد',
      icon: Icons.hub_outlined,
      iconColor: const Color(0xFF3B82F6),
      onClose: widget.onClose,
      primaryLabel: 'حفظ الحساب',
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppNumberField(
                  label: 'رمز الحساب *',
                  hint: '1105',
                  controller: _codeController,
                  allowDecimal: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: 'اسم الحساب *',
                  hint: 'مثال: نقدية بالصندوق',
                  controller: _nameController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'الحساب الأب (الحساب الرئيسي)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: effectiveParentId,
                hint: Text('-- لا يوجد (حساب رئيسي) --', style: TextStyle(fontSize: 13, color: textSecondary)),
                isExpanded: true,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('-- لا يوجد (حساب رئيسي) --', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                  ),
                  ...parentList.map((a) {
                    return DropdownMenuItem<String?>(
                      value: a['id']?.toString(),
                      child: Text('${a['code']} - ${a['name']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                    );
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
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
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
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
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
    );
  }
}
