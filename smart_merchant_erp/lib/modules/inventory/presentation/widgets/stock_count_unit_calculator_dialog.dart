import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../catalog/presentation/views/widgets/catalog_formatters.dart';

class StockCountUnitCalculatorDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final String baseUnitName;
  final double? currentCounted;

  const StockCountUnitCalculatorDialog({
    required this.productId,
    required this.productName,
    required this.baseUnitName,
    this.currentCounted,
    super.key,
  });

  static Future<double?> show(
    BuildContext context, {
    required String productId,
    required String productName,
    required String baseUnitName,
    double? currentCounted,
  }) {
    return showDialog<double>(
      context: context,
      builder: (ctx) => StockCountUnitCalculatorDialog(
        productId: productId,
        productName: productName,
        baseUnitName: baseUnitName,
        currentCounted: currentCounted,
      ),
    );
  }

  @override
  State<StockCountUnitCalculatorDialog> createState() =>
      _StockCountUnitCalculatorDialogState();
}

class _HigherUnitEntry {
  final String unitName;
  final double conversionFactor;
  final TextEditingController controller;

  _HigherUnitEntry({
    required this.unitName,
    required this.conversionFactor,
    required this.controller,
  });
}

class _StockCountUnitCalculatorDialogState
    extends State<StockCountUnitCalculatorDialog> {
  bool _loading = true;
  final List<_HigherUnitEntry> _units = [];
  final TextEditingController _loosePiecesController = TextEditingController();
  final TextEditingController _customFactorController =
      TextEditingController(text: '12');
  final TextEditingController _customCountController =
      TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    for (final u in _units) {
      u.controller.dispose();
    }
    _loosePiecesController.dispose();
    _customFactorController.dispose();
    _customCountController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    try {
      final db = getIt<AppDatabase>();
      final rows = await (db.select(db.productUnits).join([
        drift.innerJoin(db.units, db.units.id.equalsExp(db.productUnits.unitId)),
      ])..where(
          db.productUnits.productId.equals(widget.productId) &
          db.productUnits.isBaseUnit.equals(false) &
          db.productUnits.isActive.equals(true) &
          db.productUnits.deletedAt.isNull(),
        ))
        .get();

      if (mounted) {
        setState(() {
          for (final row in rows) {
            final pu = row.readTable(db.productUnits);
            final u = row.readTable(db.units);
            _units.add(
              _HigherUnitEntry(
                unitName: u.unitName,
                conversionFactor: pu.conversionFactor > 0 ? pu.conversionFactor : 1.0,
                controller: TextEditingController(text: '0'),
              ),
            );
          }

          // If currentCounted is provided, populate loose pieces by default
          if (widget.currentCounted != null && widget.currentCounted! > 0) {
            _loosePiecesController.text =
                formatCatalogNumber(widget.currentCounted!);
          } else {
            _loosePiecesController.text = '0';
          }

          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double _calculateTotal() {
    double total = 0.0;
    if (_units.isNotEmpty) {
      for (final u in _units) {
        final count = double.tryParse(u.controller.text.trim()) ?? 0.0;
        total += count * u.conversionFactor;
      }
    } else {
      final count = double.tryParse(_customCountController.text.trim()) ?? 0.0;
      final factor =
          double.tryParse(_customFactorController.text.trim()) ?? 1.0;
      total += count * factor;
    }

    final loose = double.tryParse(_loosePiecesController.text.trim()) ?? 0.0;
    total += loose;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final total = _calculateTotal();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حاسبة الجرد الذكية (كرتون + حبات)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 2. Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'أدخل عدد الكراتين أو العبوات الكبرى مع الحبات الفردية المتبقية، وسيقوم النظام بجمعها تلقائياً:',
                          style: TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 16),

                        // Higher units or Custom multiplier
                        if (_units.isNotEmpty) ...[
                          for (final u in _units) ...[
                            _buildUnitRow(
                              title: 'عدد الـ ${u.unitName} (×${formatCatalogNumber(u.conversionFactor)})',
                              unitFactorText:
                                  '= ${(double.tryParse(u.controller.text.trim()) ?? 0) * u.conversionFactor} ${widget.baseUnitName}',
                              controller: u.controller,
                              isDark: isDark,
                              borderColor: borderColor,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ] else ...[
                          // Fallback custom multiplier if no higher units are registered
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildNumberInput(
                                  label: 'عدد الكراتين / العبوات',
                                  controller: _customCountController,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('×', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildNumberInput(
                                  label: 'حبة بالكرتون',
                                  controller: _customFactorController,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Loose pieces
                        _buildUnitRow(
                          title: 'حبات فردية متبقية (${widget.baseUnitName})',
                          unitFactorText: '+ حبات فرط',
                          controller: _loosePiecesController,
                          isDark: isDark,
                          borderColor: borderColor,
                        ),

                        const SizedBox(height: 20),

                        // Total preview card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'إجمالي الكمية الفعلية المحسوبة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  Text(
                                    'بالوحدة الأساسية (${widget.baseUnitName})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${formatCatalogNumber(total)} ${widget.baseUnitName}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // 3. Footer Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'تطبيق في الجرد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(total);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitRow({
    required String title,
    required String unitFactorText,
    required TextEditingController controller,
    required bool isDark,
    required Color borderColor,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                unitFactorText,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required Color borderColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
