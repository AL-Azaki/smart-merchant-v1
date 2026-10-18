import 'package:flutter/material.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
import 'account_tree_model.dart';

class AccountFormSaveException implements Exception {
  final String message;
  const AccountFormSaveException(this.message);
}

class AccountFormSheet extends StatefulWidget {
  final List<ChartOfAccount> parentAccounts;
  final String? initialParentId;
  final VoidCallback onClose;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const AccountFormSheet({
    required this.onClose,
    required this.onSave,
    this.parentAccounts = const [],
    this.initialParentId,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(Map<String, dynamic> data) onSave,
    required List<ChartOfAccount> parentAccounts,
    String? initialParentId,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AccountFormSheet(
        parentAccounts: parentAccounts,
        initialParentId: initialParentId,
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (data) async {
          await onSave(data);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    ),
  );

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String? _parentId;
  bool _allowPosting = true;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _parentId = widget.initialParentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave({
        'name': _nameController.text.trim(),
        'parentId': _parentId,
        'allowPosting': _allowPosting,
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _saveError = error is AccountFormSaveException
              ? error.message
              : 'تعذر حفظ الحساب. بياناتك محفوظة هنا، حاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = AccountTreeModel(widget.parentAccounts).parentOptions;
    final parent = options
        .where((e) => e.account.id == _parentId)
        .firstOrNull
        ?.account;
    final nameField = AppTextField(
      label: 'اسم الحساب *',
      hint: 'مثال: مصاريف التوصيل',
      controller: _nameController,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.edit_note_rounded),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'أدخل اسم الحساب';
        if (!RegExp(r'[\u0600-\u06FF]').hasMatch(value) ||
            RegExp(r'[A-Za-z]').hasMatch(value)) {
          return 'اكتب اسم الحساب بالعربية';
        }
        return null;
      },
    );
    final parentField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الحساب الأب *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: parent?.id,
          isExpanded: true,
          menuMaxHeight: 360,
          decoration: InputDecoration(
            hintText: 'اختر الحساب الأب',
            prefixIcon: const Icon(Icons.account_tree_outlined),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          selectedItemBuilder: (_) => [
            for (final entry in options)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  accountNameAr(entry.account),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          items: [
            for (final entry in options)
              DropdownMenuItem(
                value: entry.account.id,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: (entry.depth * 18.0).clamp(0, 90),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          entry.depth == 0
                              ? AccountKind.of(entry.account.accountTypeId).icon
                              : Icons.subdirectory_arrow_left_rounded,
                          color: AccountKind.of(
                            entry.account.accountTypeId,
                          ).color(context),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            accountNameAr(entry.account),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: entry.depth == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          validator: (v) => v == null || !options.any((e) => e.account.id == v)
              ? 'اختر الحساب الأب'
              : null,
          onChanged: _saving
              ? null
              : (v) => setState(() {
                  _parentId = v;
                  _saveError = null;
                }),
        ),
      ],
    );

    return PopScope(
      canPop: !_saving,
      child: AppModalSheet(
        title: 'إضافة حساب',
        icon: Icons.account_tree_rounded,
        iconColor: AppColors.primary,
        primaryColor: AppColors.primary,
        primaryLabel: 'حفظ الحساب',
        onPrimary: options.isEmpty ? null : _submit,
        onClose: _saving ? () {} : widget.onClose,
        isLoading: _saving,
        maxWidth: 800,
        maxHeightFactor: 0.94,
        showDragHandle: false,
        alignment: Alignment.center,
        borderRadius: BorderRadius.circular(20),
        padKeyboard: false,
        child: Form(
          key: _formKey,
          child: AbsorbPointer(
            absorbing: _saving,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حساب جديد في مكانه الصحيح من الشجرة.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (_, constraints) => constraints.maxWidth >= 580
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: nameField),
                            const SizedBox(width: 16),
                            Expanded(child: parentField),
                          ],
                        )
                      : Column(
                          children: [
                            nameField,
                            const SizedBox(height: 16),
                            parentField,
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        (parent == null
                                ? AppColors.primary
                                : AccountKind.of(
                                    parent.accountTypeId,
                                  ).color(context))
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        parent == null
                            ? Icons.auto_awesome_outlined
                            : AccountKind.of(parent.accountTypeId).icon,
                        color: parent == null
                            ? theme.colorScheme.primary
                            : AccountKind.of(
                                parent.accountTypeId,
                              ).color(context),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parent == null
                                  ? 'الترقيم والتصنيف تلقائيان'
                                  : '${AccountKind.of(parent.accountTypeId).label} • ${parent.normalBalance == 'Debit' ? 'طبيعة مدينة' : 'طبيعة دائنة'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              parent == null
                                  ? 'اختر الحساب الأب، وسنحدد رقم الحساب ونوعه وطبيعته تلقائياً.'
                                  : 'يرث الحساب نوع وطبيعة «${accountNameAr(parent)}»، ويُنشأ رقمه عند الحفظ.',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.folder_copy_outlined),
                  title: const Text(
                    'حساب تجميعي',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    _allowPosting
                        ? 'حساب للتسجيل المباشر للعمليات المالية.'
                        : 'يجمع حسابات فرعية، ولا تسجل عليه عمليات مباشرة.',
                  ),
                  value: !_allowPosting,
                  onChanged: (v) => setState(() => _allowPosting = !v),
                ),
                if (options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'لا توجد حسابات تجميعية نشطة. جهّز دليل الحسابات أولاً.',
                    ),
                  ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _saveError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
