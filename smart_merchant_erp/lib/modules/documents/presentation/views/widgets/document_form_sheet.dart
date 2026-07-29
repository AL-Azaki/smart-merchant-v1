import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';
import '../../../../system/application/services/archive_document_service.dart';

class DocumentFormSheet extends StatefulWidget {
  final VoidCallback onClose;
  final Function(ArchiveDocumentCommand) onSave;

  const DocumentFormSheet({
    super.key,
    required this.onClose,
    required this.onSave,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التقاط الصورة: \$e')));
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
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
      final newFileName = '\${const Uuid().v4()}\$ext';
      final savedFile = await file.copy(p.join(archiveDir.path, newFileName));
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب إرفاق صورة المستند')));
      return;
    }

    setState(() => _isSaving = true);

    final localPath = await _saveFileLocally(_selectedImage!);
    if (localPath == null) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل حفظ الملف محلياً')));
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
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 500,
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.description_outlined, color: Colors.purple),
                    ),
                    const SizedBox(width: 12),
                    const Text('أرشفة مستند جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
              ],
            ),
          ),
          
          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الوثيقة / المستند *',
                        border: OutlineInputBorder(),
                        hintText: 'مثال: رخصة مزاولة المهنة',
                      ),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'تصنيف المستند *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'invoice', child: Text('فاتورة مصورة')),
                              DropdownMenuItem(value: 'contract', child: Text('عقود واتفاقيات')),
                              DropdownMenuItem(value: 'license', child: Text('تراخيص وبطاقات')),
                              DropdownMenuItem(value: 'other', child: Text('أخرى')),
                            ],
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _refNumberController,
                            decoration: const InputDecoration(
                              labelText: 'رقم المرجع / الوثيقة',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(context: context, initialDate: _issueDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                              if (d != null) setState(() => _issueDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'تاريخ الإصدار', border: OutlineInputBorder()),
                              child: Text(DateFormat('yyyy/MM/dd').format(_issueDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(context: context, initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime(2000), lastDate: DateTime(2100));
                              if (d != null) setState(() => _expiryDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'تاريخ الانتهاء (تنبيه)', border: OutlineInputBorder()),
                              child: Text(_expiryDate != null ? DateFormat('yyyy/MM/dd').format(_expiryDate!) : 'غير محدد'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Image Upload
                    const Text('صورة المستند / الفاتورة *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showImageSourceDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: _selectedImage == null ? 120 : 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(16),
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
                                  Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 32),
                                  const SizedBox(height: 8),
                                  Text('إرفاق صورة أو التقاطها', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات إضافية',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'أرشفة الآن',
                            onPressed: _isSaving ? null : _submit,
                            isLoading: _isSaving,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                              foregroundColor: isDark ? Colors.white : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
