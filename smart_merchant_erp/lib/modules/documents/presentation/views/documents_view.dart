import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../app/di/getit_instance.dart';
import '../providers/archive_provider.dart';
import 'widgets/document_form_sheet.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../system/application/services/archive_document_service.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';

class DocumentsView extends ConsumerStatefulWidget {
  const DocumentsView({super.key});

  @override
  ConsumerState<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends ConsumerState<DocumentsView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _activeCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bizId = getIt<ApplicationContext>().currentBusinessId ?? '';
      ref.read(archiveFilterStateProvider.notifier).setBusinessId(bizId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref
        .read(archiveFilterStateProvider.notifier)
        .updateFilter(searchQuery: query);
  }

  void _onCategorySelect(String cat) {
    setState(() => _activeCategory = cat);
    ref
        .read(archiveFilterStateProvider.notifier)
        .updateFilter(category: cat == 'all' ? null : cat);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subtleColor = isDark
        ? AppColors.surfaceDark.withOpacity(0.5)
        : AppColors.backgroundLight;

    final stats = ref.watch(archiveStatsProvider);
    final docsAsync = ref.watch(archiveDocumentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Stats
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _buildStatCard(
                  'المستندات المؤرشفة',
                  '${stats['total']}',
                  Icons.description,
                  Colors.purple,
                  surfaceColor,
                  borderColor,
                  isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _buildStatCard(
                  'الفواتير المصورة',
                  '${stats['invoices']}',
                  Icons.receipt_long,
                  Colors.green,
                  surfaceColor,
                  borderColor,
                  isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _buildStatCard(
                  'تنبيهات انتهاء الصلاحية',
                  '${stats['nearExpiry']}',
                  Icons.warning_amber_rounded,
                  Colors.red,
                  surfaceColor,
                  borderColor,
                  isDark,
                ),
              ],
            ),
          ),

          // 2. Search & Add
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      decoration: const InputDecoration(
                        hintText: 'ابحث باسم الوثيقة أو المرجع...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 160,
                  child: PrimaryButton(
                    text: 'أرشفة وثيقة',
                    icon: Icons.add,
                    onPressed: () => _showAddDocumentSheet(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _buildCatChip('الكل', 'all', subtleColor, isDark),
                _buildCatChip('فواتير مصورة', 'invoice', subtleColor, isDark),
                _buildCatChip('عقود', 'contract', subtleColor, isDark),
                _buildCatChip('تراخيص', 'license', subtleColor, isDark),
                _buildCatChip('مستندات أخرى', 'other', subtleColor, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. List
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('خطأ: \$e')),
              data: (docs) {
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد مستندات مؤرشفة'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => Divider(color: borderColor),
                  itemBuilder: (c, i) =>
                      _buildDocRow(docs[i], surfaceColor, isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color surface,
    Color border,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatChip(String label, String id, Color subtle, bool isDark) {
    final active = _activeCategory == id;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: InkWell(
        onTap: () => _onCategorySelect(id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : subtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: active
                  ? Colors.white
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocRow(ArchiveDocument doc, Color surface, bool isDark) {
    final badge = _getCategoryBadge(doc.category);
    final isExpired =
        doc.expiryDate != null && doc.expiryDate!.isBefore(DateTime.now());

    return InkWell(
      onTap: () => _showPreview(doc),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: doc.fileUrl.isNotEmpty && File(doc.fileUrl).existsSync()
                  ? Image.file(File(doc.fileUrl), fit: BoxFit.cover)
                  : const Icon(Icons.description, color: Colors.grey),
            ),
            const SizedBox(width: AppSpacing.md),
            // Details
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badge.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge.label,
                      style: TextStyle(
                        color: badge.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المرجع',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    doc.refNumber ?? '---',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إصدار: ${DateFormat('yyyy/MM/dd').format(doc.issueDate)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (doc.expiryDate != null)
                    Text(
                      'انتهاء: ${DateFormat('yyyy/MM/dd').format(doc.expiryDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? Colors.red : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            // Actions
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 22),
                  onPressed: () => _showPreview(doc),
                  tooltip: 'عرض',
                ),
                IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.download_outlined, size: 22),
                  onPressed: () => _downloadDocument(doc),
                  tooltip: 'تحميل',
                ),
                IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22,
                  ),
                  onPressed: () => _confirmDelete(doc),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDocumentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DocumentFormSheet(
          onClose: () => Navigator.pop(ctx),
          onSave: (cmd) async {
            final res = await getIt<ArchiveDocumentService>().saveDocument(cmd);
            if (res.isRight() && ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('تمت الأرشفة بنجاح')),
              );
            } else if (ctx.mounted) {
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(const SnackBar(content: Text('فشل الحفظ')));
            }
          },
        ),
      ),
    );
  }

  void _showPreview(ArchiveDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 500,
          color: Theme.of(ctx).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (doc.refNumber != null)
                          Text(
                            doc.refNumber!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (doc.fileUrl.isNotEmpty &&
                            File(doc.fileUrl).existsSync())
                          Image.file(File(doc.fileUrl), fit: BoxFit.contain)
                        else
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('ملاحظات: ${doc.notes}'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ArchiveDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا المستند من الأرشيف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await getIt<ArchiveDocumentService>().deleteDocument(doc.id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _getCategoryBadge(String cat) {
    switch (cat) {
      case 'contract':
        return (label: 'عقد', color: Colors.blue);
      case 'license':
        return (label: 'ترخيص', color: Colors.orange);
      case 'invoice':
        return (label: 'فاتورة', color: Colors.green);
      default:
        return (label: 'أخرى', color: Colors.purple);
    }
  }

  Future<void> _downloadDocument(ArchiveDocument doc) async {
    if (doc.fileUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر حفظ المستند')));
      return;
    }

    final sourceFile = File(doc.fileUrl);
    if (!sourceFile.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ملف المستند غير موجود على الجهاز')),
      );
      return;
    }

    try {
      final xFile = XFile(sourceFile.path);
      await Share.shareXFiles(
        [xFile],
        text: 'مستند: \${doc.title}',
        subject: doc.title,
      );

      // We don't show "تم حفظ المستند بنجاح" because the OS share sheet handles the UX,
      // and the user might just cancel the share sheet.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حفظ المستند')));
      }
    }
  }
}
