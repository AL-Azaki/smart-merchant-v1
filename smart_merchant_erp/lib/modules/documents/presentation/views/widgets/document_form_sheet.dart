import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';
import '../../../../system/application/services/archive_document_service.dart';

class DocumentFormSheet extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(ArchiveDocumentCommand command) onSave;

  const DocumentFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
  });

  @override
  State<DocumentFormSheet> createState() => _DocumentFormSheetState();
}

class _DocumentFormSheetState extends State<DocumentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _refNumberController;
  late TextEditingController _notesController;

  String _category = 'invoice';
  DateTime _issueDate = DateTime.now();
  DateTime? _expiryDate;
  File? _selectedImage;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _refNumberController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _refNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التقاط الصورة: $e')));
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('تصوير بالكاميرا'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('معرض الصور'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _saveFileLocally(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final archiveDir = Directory(p.join(appDir.path, 'archive_docs'));
      if (!await archiveDir.exists()) {
        await archiveDir.create(recursive: true);
      }
      final ext = p.extension(file.path);
      final newFileName = '${const Uuid().v4()}$ext';
      final savedFile = await file.copy(p.join(archiveDir.path, newFileName));
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب إرفاق صورة المستند')));
      return;
    }

    setState(() => _isSaving = true);

    final localPath = await _saveFileLocally(_selectedImage!);
    if (localPath == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل حفظ الملف محلياً')));
      }
      return;
    }

    final command = ArchiveDocumentCommand(
      title: _titleController.text,
      category: _category,
      refNumber: _refNumberController.text.isEmpty ? null : _refNumberController.text,
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      fileUrl: localPath,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onSave(command);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppModalSheet(
      title: 'أرشفة مستند جديد',
      icon: Icons.description_outlined,
      iconColor: Colors.purple,
      onClose: widget.onClose,
      primaryLabel: 'أرشفة الآن',
      onPrimary: _isSaving ? null : _submit,
      isLoading: _isSaving,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'اسم الوثيقة / المستند *',
              hint: 'مثال: رخصة مزاولة المهنة',
              controller: _titleController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'تصنيف المستند *',
                    initialValue: _category == 'invoice'
                        ? 'فاتورة مصورة'
                        : (_category == 'contract'
                            ? 'عقود واتفاقيات'
                            : (_category == 'license' ? 'تراخيص وبطاقات' : 'أخرى')),
                    readOnly: true,
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (val) => setState(() => _category = val),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'invoice', child: Text('فاتورة مصورة')),
                        PopupMenuItem(value: 'contract', child: Text('عقود واتفاقيات')),
                        PopupMenuItem(value: 'license', child: Text('تراخيص وبطاقات')),
                        PopupMenuItem(value: 'other', child: Text('أخرى')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'رقم المرجع / الوثيقة',
                    hint: 'REF-1234',
                    controller: _refNumberController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'تاريخ الإصدار',
                    initialValue: DateFormat('yyyy/MM/dd').format(_issueDate),
                    readOnly: true,
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _issueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        setState(() => _issueDate = d);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'تاريخ الانتهاء (تنبيه)',
                    initialValue: _expiryDate != null ? DateFormat('yyyy/MM/dd').format(_expiryDate!) : 'غير محدد',
                    readOnly: true,
                    suffixIcon: const Icon(Icons.event_outlined, size: 20),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        setState(() => _expiryDate = d);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // مرفق الصورة
            Text(
              'صورة المستند / الفاتورة *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _showImageSourceDialog,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                height: _selectedImage == null ? 110 : 180,
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  borderRadius: BorderRadius.circular(14),
                  color: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_selectedImage!, fit: BoxFit.cover),
                          Container(color: Colors.black38),
                          const Center(child: Icon(Icons.edit, color: Colors.white, size: 32)),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 30),
                          const SizedBox(height: 6),
                          Text('إرفاق صورة أو التقاطها', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            AppMultilineField(
              label: 'ملاحظات إضافية',
              hint: 'أدخل أي ملاحظات حول أصل المستند أو تفاصيله',
              controller: _notesController,
              lines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
