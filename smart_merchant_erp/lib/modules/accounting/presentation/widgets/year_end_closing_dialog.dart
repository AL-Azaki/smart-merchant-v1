import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/usecases/year_end_closing_usecase.dart';
import '../../domain/repositories/accounting_repository.dart';

/// Dialog allowing authorized accountants to trigger official Year-End Closing.
class YearEndClosingDialog extends ConsumerStatefulWidget {
  const YearEndClosingDialog({super.key});

  @override
  ConsumerState<YearEndClosingDialog> createState() => _YearEndClosingDialogState();
}

class _YearEndClosingDialogState extends ConsumerState<YearEndClosingDialog> {
  bool _isSubmitting = false;
  String? _selectedFiscalYearId;
  List<FiscalYear> _openFiscalYears = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOpenFiscalYears();
  }

  Future<void> _loadOpenFiscalYears() async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;

    final repo = getIt<AccountingRepository>();
    final years = await repo.listFiscalYears(
      FiscalYearFilter(businessId: session.businessId!),
    );
    if (!mounted) return;
    setState(() {
      _openFiscalYears = years.where((y) => y.status != 'Closed').toList();
      if (_openFiscalYears.isNotEmpty) {
        _selectedFiscalYearId = _openFiscalYears.first.id;
      }
      _isLoading = false;
    });
  }

  Future<void> _submitClosing() async {
    if (_selectedFiscalYearId == null) return;

    setState(() => _isSubmitting = true);

    final useCase = getIt<YearEndClosingUseCase>();
    final result = await useCase(
      YearEndClosingCommand(
        fiscalYearId: _selectedFiscalYearId!,
        closingDate: DateTime.now(),
        notes: 'قيد إقفال السنة المالية وترحيل الأرباح والخسائر',
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإقفال السنوي: ${failure.message}'), backgroundColor: Colors.red),
        );
      },
      (journalId) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إقفال السنة المالية بنجاح وترحيل صافي النتيجة إلى الأرباح المحتجزة'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFEF4444), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الإقفال السنوي وقفل الفترات المالية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'سيقوم النظام بالإجراءات المحاسبية التالية آلياً:\n'
                      '• تصفير جميع حسابات الإيرادات والمصروفات بقيد يومية رسمي متوازن.\n'
                      '• ترحيل صافي ربح أو خسارة السنة إلى حساب الأرباح المحتجزة / المرحلة (32).\n'
                      '• إغلاق كافة فترات السنة المالية وقفل تاريخ العمليات لمنع أي تعديل لاحق.',
                      style: TextStyle(fontSize: 13, height: 1.6, color: textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (_openFiscalYears.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('لا توجد سنوات مالية مفتوحة قابلة للإقفال حالياً.'),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedFiscalYearId,
                        decoration: const InputDecoration(
                          labelText: 'اختر السنة المالية للإقفال *',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                          border: OutlineInputBorder(),
                        ),
                        items: _openFiscalYears.map((y) {
                          return DropdownMenuItem<String>(
                            value: y.id,
                            child: Text('${y.fiscalYearName} (${y.startDate.year})'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedFiscalYearId = val),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.lock_rounded, size: 18),
                          label: const Text('تنفيذ الإقفال النهائي'),
                          onPressed: (_openFiscalYears.isEmpty || _isSubmitting) ? null : _submitClosing,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
