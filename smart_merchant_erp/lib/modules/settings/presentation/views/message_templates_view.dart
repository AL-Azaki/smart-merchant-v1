import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../domain/entities/message_template.dart';
import '../providers/message_templates_provider.dart';

class MessageTemplatesView extends ConsumerStatefulWidget {
  const MessageTemplatesView({super.key});

  @override
  ConsumerState<MessageTemplatesView> createState() => _MessageTemplatesViewState();
}

class _MessageTemplatesViewState extends ConsumerState<MessageTemplatesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(messageTemplatesProvider);
    final notifier = ref.read(messageTemplatesProvider.notifier);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('قوالب الرسائل والتنبيهات'),
        centerTitle: false,
        actions: [
          if (state.isEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showAddEditTemplateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('إضافة قالب جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
        bottom: state.isEnabled
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor:
                    isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.notifications_active_rounded),
                    text: 'قوالب المطالبة والتذكير',
                  ),
                  Tab(
                    icon: Icon(Icons.receipt_long_rounded),
                    text: 'قوالب إشعارات السداد',
                  ),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Global Enable/Disable Banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: state.isEnabled
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    state.isEnabled
                        ? Icons.mark_chat_read_rounded
                        : Icons.speaker_notes_off_rounded,
                    color: state.isEnabled ? Colors.green : Colors.grey,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفعيل نظام قوالب الرسائل والتنبيهات',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.isEnabled
                            ? 'الميزة مفعلة: يتاح إرسال تنبيهات السداد وإشعارات الدفع عبر واتساب و SMS من ملف العميل'
                            : 'الميزة متوقفة: لن تظهر أزرار إرسال الرسائل في ملفات العملاء وسيعمل النظام بشكل طبيعي',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: state.isEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    notifier.toggleEnabled(val);
                  },
                ),
              ],
            ),
          ),

          // Main Body Content
          Expanded(
            child: !state.isEnabled
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'نظام الرسائل والتنبيهات معطل حالياً',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'يمكنك تفعيل الخيار أعلاه في أي وقت لاستخدام وإدارة قوالب الرسائل',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTemplatesList(
                        context,
                        type: MessageTemplateType.paymentReminder,
                        templates: state.getByType(MessageTemplateType.paymentReminder),
                        isDark: isDark,
                      ),
                      _buildTemplatesList(
                        context,
                        type: MessageTemplateType.paymentReceipt,
                        templates: state.getByType(MessageTemplateType.paymentReceipt),
                        isDark: isDark,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(
    BuildContext context, {
    required MessageTemplateType type,
    required List<MessageTemplate> templates,
    required bool isDark,
  }) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('لا توجد قوالب مضافة لهذا التصنيف'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showAddEditTemplateDialog(context, initialType: type),
              child: const Text('إضافة قالب الآن'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, template, isDark);
      },
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    MessageTemplate template,
    bool isDark,
  ) {
    final notifier = ref.read(messageTemplatesProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: template.isDefault
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: template.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title & Badges
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (template.isSystem)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'أساسي',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (template.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 13, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'القالب المعتمد',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'تعديل القالب',
                  onPressed: () => _showAddEditTemplateDialog(
                    context,
                    template: template,
                  ),
                ),

                // Delete Button (disabled for system)
                if (!template.isSystem)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.redAccent),
                    tooltip: 'حذف القالب',
                    onPressed: () => _confirmDeleteTemplate(context, template),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Content Preview Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark.withValues(alpha: 0.5)
                      : AppColors.borderLight,
                ),
              ),
              child: SelectableText(
                template.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Set as Default Button
                if (!template.isDefault)
                  OutlinedButton.icon(
                    onPressed: () {
                      notifier.setDefault(template.id, template.type);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'تم اعتماد "${template.title}" كقالب افتراضي بنجاح'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: const Text('تعيين كقالب معتمد'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, size: 16, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'هذا هو القالب المعتمد حالياً للإرسال',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),

                // Sample Preview Button
                TextButton.icon(
                  onPressed: () => _showSamplePreview(context, template),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('معاينة تجريبية'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSamplePreview(BuildContext context, MessageTemplate template) {
    final sample = template.render(
      customerName: 'محمد أحمد السعيد',
      currentBalance: '150,000 ر.ي',
      paidAmount: '50,000 ر.ي',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.preview_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('معاينة: ${template.title}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'شكل الرسالة كما ستصل للعميل مع استبدال المتغيرات بالبيانات الحقيقية:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                sample,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTemplate(BuildContext context, MessageTemplate template) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف القالب'),
        content: Text('هل أنت متأكد من حذف قالب "${template.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(messageTemplatesProvider.notifier).deleteTemplate(template.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف القالب بنجاح'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditTemplateDialog(
    BuildContext context, {
    MessageTemplate? template,
    MessageTemplateType? initialType,
  }) {
    final isEditing = template != null;
    final titleController = TextEditingController(text: template?.title ?? '');
    final contentController = TextEditingController(text: template?.content ?? '');
    MessageTemplateType selectedType = template?.type ??
        initialType ??
        (_tabController.index == 0
            ? MessageTemplateType.paymentReminder
            : MessageTemplateType.paymentReceipt);
    bool isDefault = template?.isDefault ?? false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            void insertVariable(String varName) {
              final text = contentController.text;
              final selection = contentController.selection;
              final start = selection.start >= 0 ? selection.start : text.length;
              final end = selection.end >= 0 ? selection.end : text.length;

              final newText = text.replaceRange(start, end, varName);
              contentController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: start + varName.length),
              );
              setModalState(() {});
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'تعديل القالب' : 'إضافة قالب رسالة جديد',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Template Type (if not editing)
                    if (!isEditing) ...[
                      const Text(
                        'تصنيف القالب:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<MessageTemplateType>(
                        segments: const [
                          ButtonSegment(
                            value: MessageTemplateType.paymentReminder,
                            label: Text('تذكير بالسداد'),
                            icon: Icon(Icons.notifications_active_outlined),
                          ),
                          ButtonSegment(
                            value: MessageTemplateType.paymentReceipt,
                            label: Text('إشعار استلام دفعة'),
                            icon: Icon(Icons.receipt_long_outlined),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (val) {
                          setModalState(() {
                            selectedType = val.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Title Field
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان / اسم القالب *',
                        hintText: 'مثال: تذكير لطيف، إشعار رسمي...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Variables Chips Bar
                    const Text(
                      'المتغيرات الديناميكية (اضغط للإدراج في النص):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.person_outline, size: 16),
                          label: const Text('{اسم_العميل}'),
                          tooltip: 'اسم العميل الحقيقي من سجله',
                          onPressed: () => insertVariable('{اسم_العميل}'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                          label: const Text('{الرصيد_الحالي}'),
                          tooltip: 'إجمالي المديونية أو الرصيد المتبقي',
                          onPressed: () => insertVariable('{الرصيد_الحالي}'),
                        ),
                        if (selectedType == MessageTemplateType.paymentReceipt)
                          ActionChip(
                            avatar: const Icon(Icons.price_check_rounded, size: 16),
                            label: const Text('{المبلغ_المسدد}'),
                            tooltip: 'قيمة الدفعة الأخيرة المستلمة',
                            onPressed: () => insertVariable('{المبلغ_المسدد}'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content Multi-line Field
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'نص القالب *',
                        alignLabelWithHint: true,
                        hintText:
                            'اكتب نص الرسالة هنا مع المتغيرات مثل {اسم_العميل}...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live Preview in Modal
                    if (contentController.text.trim().isNotEmpty) ...[
                      const Text(
                        'معاينة حية للقالب:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          contentController.text
                              .replaceAll('{اسم_العميل}', 'محمد أحمد')
                              .replaceAll('{الرصيد_الحالي}', '150,000 ر.ي')
                              .replaceAll('{المبلغ_المسدد}', '50,000 ر.ي'),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Default Checkbox
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isDefault,
                      onChanged: (val) {
                        setModalState(() {
                          isDefault = val ?? false;
                        });
                      },
                      title: const Text('تعيين كـ "القالب المعتمد" لهذا التصنيف'),
                      subtitle: const Text(
                        'سيظهر هذا القالب تلقائياً عند الضغط على إرسال تذكير أو إشعار للعميل',
                        style: TextStyle(fontSize: 11),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          final content = contentController.text.trim();

                          if (title.isEmpty || content.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى كتابة عنوان القالب والنص أولاً'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (isEditing) {
                            ref
                                .read(messageTemplatesProvider.notifier)
                                .updateTemplate(
                                  id: template.id,
                                  title: title,
                                  content: content,
                                  isDefault: isDefault,
                                );
                          } else {
                            ref.read(messageTemplatesProvider.notifier).addTemplate(
                                  title: title,
                                  type: selectedType,
                                  content: content,
                                  isDefault: isDefault,
                                );
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing
                                  ? 'تم تحديث القالب بنجاح'
                                  : 'تم حفظ القالب الجديد بنجاح'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: Text(
                          isEditing ? 'حفظ التعديلات' : 'إضافة القالب',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

