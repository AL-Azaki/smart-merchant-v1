import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../kernel/storage/local_backup_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../widgets/settings_header_widget.dart';

class BackupAndRestoreView extends ConsumerStatefulWidget {
  const BackupAndRestoreView({super.key});

  @override
  ConsumerState<BackupAndRestoreView> createState() =>
      _BackupAndRestoreViewState();
}

class _BackupAndRestoreViewState extends ConsumerState<BackupAndRestoreView> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _notesController = TextEditingController();
  final _restorePasswordController = TextEditingController();
  final _externalPathController = TextEditingController();

  bool _obscureCreatePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureRestorePassword = true;
  bool _isCreatingBackup = false;
  bool _isLoadingList = false;
  List<BackupFileItem> _backupsList = [];
  String? _backupDirectoryPath;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _notesController.dispose();
    _restorePasswordController.dispose();
    _externalPathController.dispose();
    super.dispose();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoadingList = true);
    try {
      final dir = await LocalBackupService.getBackupsDirectory();
      final list = await LocalBackupService.listLocalBackups();
      if (mounted) {
        setState(() {
          _backupDirectoryPath = dir.path;
          _backupsList = list;
          _isLoadingList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingList = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحميل قائمة النسخ الاحتياطية: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _handleCreateBackup() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final notes = _notesController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال كلمة مرور لتشفير النسخة الاحتياطية'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور يجب ألا تقل عن 4 خانات لحماية البيانات'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمتا المرور غير متطابقتين، يرجى التحقق'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreatingBackup = true);

    try {
      final file = await LocalBackupService.createBackup(
        password: password,
        notes: notes.isNotEmpty ? notes : null,
      );

      _passwordController.clear();
      _confirmPasswordController.clear();
      _notesController.clear();

      await _loadBackups();

      if (!mounted) {
        return;
      }

      final stat = await file.stat();
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تم تشفير قاعدة البيانات بالكامل وضغطها وتأمينها بنجاح.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('اسم الملف: ${file.path.split(Platform.pathSeparator).last}'),
              const SizedBox(height: 4),
              Text('الحجم: ${_formatBytes(stat.size)}'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملاحظة هامة: احتفظ بكلمة المرور، لا يمكن استعادة النسخة إطلاقاً بدونها.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('مشاركة / تصدير'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية مشفرة من نظام تاجركم ERP');
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('تم'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إنشاء النسخة الاحتياطية: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingBackup = false);
      }
    }
  }

  Future<void> _handleRestoreBackup(File backupFile, {BackupMetadata? metadata}) async {
    _restorePasswordController.clear();
    _obscureRestorePassword = true;
    bool isSmartMerge = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.settings_backup_restore_rounded, color: Colors.blue, size: 28),
                SizedBox(width: 10),
                Text('استعادة أو دمج نسخة احتياطية'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الملف: ${backupFile.path.split(Platform.pathSeparator).last}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (metadata != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'تاريخ الإنشاء: ${DateFormat('yyyy/MM/dd - hh:mm a').format(metadata.createdAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (metadata.notes != null && metadata.notes!.isNotEmpty)
                            Text('ملاحظات: ${metadata.notes}', style: const TextStyle(fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'اختر طريقة المعالجة:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  // Option 1: Smart Merge
                  InkWell(
                    onTap: () => setDialogState(() => isSmartMerge = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSmartMerge ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSmartMerge ? const Color(0xFF10B981) : Colors.grey.shade300,
                          width: isSmartMerge ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: isSmartMerge,
                            activeColor: const Color(0xFF10B981),
                            onChanged: (val) => setDialogState(() => isSmartMerge = val ?? true),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'دمج ذكي تراكمي (موصى به)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857)),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 16),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'يحافظ على بيانات وفواتير اليوم دون حذف، ويضيف كل ما هو مفقود من النسخة، ويحدث المشترك للأحدث.',
                                  style: TextStyle(fontSize: 11.5, height: 1.4, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Option 2: Full Overwrite
                  InkWell(
                    onTap: () => setDialogState(() => isSmartMerge = false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !isSmartMerge ? Colors.red.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isSmartMerge ? Colors.red.shade400 : Colors.grey.shade300,
                          width: !isSmartMerge ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: isSmartMerge,
                            activeColor: Colors.red.shade700,
                            onChanged: (val) => setDialogState(() => isSmartMerge = val ?? false),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'استبدال كامل شامل',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'إرجاع قاعدة البيانات بالكامل لتطابق النسخة تماماً (سيتم أخذ نسخة أمان تلقائية لقاعدتك الحالية).',
                                  style: TextStyle(fontSize: 11.5, height: 1.4, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'أدخل كلمة المرور التي تم تشفير النسخة بها:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _restorePasswordController,
                    obscureText: _obscureRestorePassword,
                    decoration: InputDecoration(
                      hintText: 'كلمة مرور فك التشفير',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureRestorePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setDialogState(() {
                            _obscureRestorePassword = !_obscureRestorePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSmartMerge ? const Color(0xFF10B981) : Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(isSmartMerge ? Icons.auto_awesome_rounded : Icons.restore_rounded),
                label: Text(isSmartMerge ? 'بدء الدمج الذكي' : 'تأكيد الاستبدال الكامل'),
                onPressed: () {
                  if (_restorePasswordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال كلمة المرور')),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) {
      return;
    }

    final password = _restorePasswordController.text.trim();

    // Show loading dialog
    if (!mounted) {
      return;
    }
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  isSmartMerge
                      ? 'جاري فك التشفير ومقارنة السجلات وتنفيذ الدمج الذكي...'
                      : 'جاري فك التشفير والتحقق من سلامة البيانات والاستبدال...',
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    try {
      if (isSmartMerge) {
        final stats = await LocalBackupService.smartMergeBackup(
          backupFile: backupFile,
          password: password,
        );

        if (!mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

        await _loadBackups();

        if (!mounted) {
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('تم الدمج الذكي بنجاح!'),
              ],
            ),
            content: Text(
              'تم فك التشفير ودمج البيانات التراكمي بنجاح:\n\n'
              '✓ تم الحفاظ على كافة حركات وفواتير اليوم الحديثة دون حذفها.\n'
              '✓ تم استيراد السجلات القديمة المفقودة من النسخة الاحتياطية.\n'
              '✓ تم تحديث السجلات المشتركة للأحدث.\n'
              'عدد الجداول المعالجة: ${stats.tablesCount} جدول.\n\n'
              'تم حفظ نسخة أمان لقاعدتك قبل الدمج في مجلد النسخ الاحتياطية.',
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('موافق'),
              ),
            ],
          ),
        );
      } else {
        await LocalBackupService.restoreBackup(
          backupFile: backupFile,
          password: password,
        );

        if (!mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

        await _loadBackups();

        if (!mounted) {
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('تمت الاستعادة بنجاح!'),
              ],
            ),
            content: const Text(
              'تم فك التشفير بنجاح، واجتازت قاعدة البيانات فحص السلامة (Integrity Check)، وتم استبدال البيانات بالكامل بأمان.\n\nينصح بإعادة تشغيل التطبيق أو الانتقال للشاشات لرؤية البيانات المستعادة.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('موافق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('فشل استعادة النسخة'),
            ],
          ),
          content: Text(
            e.toString().contains('فشل التحقق من كلمة المرور') || e.toString().contains('SecretBox')
                ? 'كلمة المرور غير صحيحة، أو تم التعديل على ملف النسخة الاحتياطية وتلف التشفير.'
                : 'حدث خطأ أثناء الاستعادة: $e',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleDeleteBackup(BackupFileItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف النسخة الاحتياطية'),
        content: Text('هل أنت متأكد من حذف الملف "${item.fileName}" نهائياً من الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (await item.file.exists()) {
          await item.file.delete();
        }
        await _loadBackups();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر حذف الملف: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _handleRestoreFromCustomPath() {
    _externalPathController.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_open_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('استيراد نسخة من مسار خارجي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل المسار الكامل لملف النسخة (.smbak) المستوردة من فلاشة أو جهاز آخر:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _externalPathController,
              decoration: InputDecoration(
                hintText: 'C:\\Backups\\backup.smbak أو /storage/...',
                prefixIcon: const Icon(Icons.file_present_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final path = _externalPathController.text.trim();
              if (path.isEmpty) {
                return;
              }
              final file = File(path);
              if (!await file.exists()) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('الملف المحدد غير موجود على الجهاز'), backgroundColor: Colors.red),
                  );
                }
                return;
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              BackupMetadata? meta;
              try {
                meta = await LocalBackupService.readMetadata(file);
              } catch (_) {}
              await _handleRestoreBackup(file, metadata: meta);
            },
            child: const Text('فحص واستعادة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            SettingsHeaderWidget(
              title: 'النسخ الاحتياطي والاستعادة',
              description: 'تشفير محلي متقدم (Argon2id + AES-256-GCM) بدون انترنت مع حماية كاملة',
              onBackTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Information banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'حماية وتشفير متقدم بنسبة 100% بدون انترنت',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'يتم تشفير النسخة الاحتياطية بالكامل وحزمها في ملف مشفر وموثق (.smbak). النسخة غير مقيدة بجهاز معين ويمكن نقلها واستعادتها على أي جهاز آخر باستخدام كلمة المرور نفسها.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card 1: Create Backup
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add_moderator_rounded, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إنشاء نسخة احتياطية جديدة مشفرة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'التقاط فوري حي لقاعدة البيانات مع ضغط GZip وتشفير AES-GCM',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureCreatePassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة مرور تشفير النسخة *',
                            hintText: 'أدخل كلمة مرور قوية (احفظها جيداً)',
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureCreatePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscureCreatePassword = !_obscureCreatePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'تأكيد كلمة المرور *',
                            hintText: 'أعد كتابة كلمة المرور للتأكيد',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'ملاحظة أو وصف للنسخة (اختياري)',
                            hintText: 'مثال: نسخة قبل جرد نهاية الأسبوع',
                            prefixIcon: const Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: _isCreatingBackup ? null : _handleCreateBackup,
                            icon: _isCreatingBackup
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_alt_rounded),
                            label: Text(
                              _isCreatingBackup
                                  ? 'جاري اشتقاق المفاتيح والتشفير...'
                                  : 'إنشاء وحفظ النسخة الاحتياطية المشفرة (.smbak)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Header of list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: textPrimary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'سجل النسخ الاحتياطية على هذا الجهاز',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_backupsList.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _handleRestoreFromCustomPath,
                            icon: const Icon(Icons.file_open_rounded, size: 18),
                            label: const Text('استيراد من مسار'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'تحديث القائمة',
                            onPressed: _loadBackups,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_backupDirectoryPath != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'المسار: $_backupDirectoryPath',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Backups List
                  if (_isLoadingList)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_backupsList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off_outlined, size: 50, color: textPrimary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد نسخ احتياطية مخزنة حتى الآن',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'يمكنك إنشاء أول نسخة احتياطية مشفرة من النموذج أعلاه في أي وقت.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textPrimary.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._backupsList.map((item) {
                      final meta = item.metadata;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.lock_clock_rounded,
                                    color: Color(0xFF10B981),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.fileName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 13,
                                            color: isDark ? Colors.white60 : Colors.black45,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('yyyy/MM/dd - hh:mm a').format(item.modifiedAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : Colors.black45,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.data_usage_rounded,
                                            size: 13,
                                            color: isDark ? Colors.white60 : Colors.black45,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatBytes(item.fileSizeBytes),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (meta != null && meta.notes != null && meta.notes!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'الملاحظات: ${meta.notes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: textPrimary.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade600,
                                    side: BorderSide(color: Colors.red.shade200),
                                  ),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                  label: const Text('حذف'),
                                  onPressed: () => _handleDeleteBackup(item),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.share_outlined, size: 16),
                                  label: const Text('مشاركة'),
                                  onPressed: () {
                                    Share.shareXFiles([XFile(item.file.path)], text: 'نسخة احتياطية: ${item.fileName}');
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.restore_rounded, size: 18),
                                  label: const Text('استعادة الآن'),
                                  onPressed: () => _handleRestoreBackup(item.file, metadata: item.metadata),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}