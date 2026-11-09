import 'package:drift/drift.dart' as drift;
import '../../../../../../app/di/getit_instance.dart';
import '../../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../catalog/domain/services/unit_quantity_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../kernel/storage/app_database.dart';
import '../../../../../../database/daos/inventory_dao.dart';
import '../../../../../../app/di/getit_providers.dart';
import '../../../../../catalog/presentation/views/widgets/catalog_formatters.dart';
import '../../../../application/usecases/process_warehouse_transfer_usecase.dart';
import '../../../providers/inventory_provider.dart';
import '../../../widgets/inventory_dialog_frame.dart';
import '../../../widgets/count_quantity_row.dart';

class WarehouseTransferDialog extends ConsumerStatefulWidget {
  const WarehouseTransferDialog({super.key});
  static Future<bool?> show(BuildContext context) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const WarehouseTransferDialog(),
  );
  @override
  ConsumerState<WarehouseTransferDialog> createState() =>
      _WarehouseTransferDialogState();
}

class _TransferLine {
  final StockBalanceView stock;
  final List<ProductUnit> units;
  final Map<String, String> unitNames;
  ProductUnit selectedUnit;
  String quantity;

  _TransferLine({
    required this.stock,
    required this.units,
    required this.unitNames,
    required this.selectedUnit,
    required this.quantity,
  });

  String get baseUnitName {
    final base = units.firstWhere((u) => u.isBaseUnit, orElse: () => selectedUnit);
    return unitNames[base.id] ?? 'وحدة';
  }

  String get formattedBreakdown {
    return UnitQuantityFormatter.formatBreakdown(
      baseQuantity: stock.inventory.quantity,
      units: units,
      unitNameResolver: (id) => unitNames[id] ?? 'وحدة',
    );
  }
}

class _WarehouseTransferDialogState
    extends ConsumerState<WarehouseTransferDialog> {
  final _notes = TextEditingController(), _search = TextEditingController();
  final List<_TransferLine> _lines = [];
  String? _source, _destination, _error;
  bool _busy = false;
  @override
  void dispose() {
    _notes.dispose();
    _search.dispose();
    super.dispose();
  }

  bool _askingClose = false;
  Future<void> _close() async {
    if (_busy || _askingClose) {
      return;
    }
    _askingClose = true;
    final discard =
        (_lines.isEmpty && _notes.text.trim().isEmpty) ||
        await confirmDiscardInventoryEdits(context);
    _askingClose = false;
    if (discard && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    if (_source == null ||
        _destination == null ||
        _source == _destination ||
        _lines.isEmpty) {
      setState(
        () => _error = 'اختر مستودعين مختلفين وأضف المنتجات المراد تحويلها.',
      );
      return;
    }
    for (final l in _lines) {
      final qty = parseCountQuantity(l.quantity);
      if (qty == null || qty <= 0) {
        setState(() => _error = 'أدخل كمية تحويل صالحة وأكبر من الصفر.');
        return;
      }
      final factor = l.selectedUnit.conversionFactor > 0 ? l.selectedUnit.conversionFactor : 1.0;
      final baseQty = qty * factor;
      if (baseQty > l.stock.inventory.quantity + 0.000001) {
        setState(() => _error = 'الكمية المطلوبة لتحويل «${l.stock.product.productName}» تتجاوز الرصيد المتاح بالمستودع.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(processWarehouseTransferUseCaseProvider)(
        ProcessWarehouseTransferCommand(
          sourceWarehouseId: _source!,
          destinationWarehouseId: _destination!,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          items: [
            for (final l in _lines)
              WarehouseTransferItemCommand(
                productUnitId: l.selectedUnit.id,
                quantity: parseCountQuantity(l.quantity)!,
              ),
          ],
        ),
      );
      final error = result.fold((f) => f.message, (_) => null);
      if (error != null) {
        if (mounted) {
          setState(() => _error = error);
        }
        return;
      }
      ref.invalidate(warehouseStockBalancesProvider(_source!));
      ref.invalidate(warehouseStockBalancesProvider(_destination!));
      ref.invalidate(warehouseTransfersStreamProvider);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'تعذر إتمام التحويل. بياناتك محفوظة هنا، حاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _picker(
    String label,
    String? value,
    List<Warehouse> options,
    ValueChanged<String?> onChanged,
  ) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isDense: true,
        isExpanded: true,
        value: value,
        hint: const Text('اختر المستودع'),
        items: [
          for (final w in options)
            DropdownMenuItem(
              value: w.id,
              child: Text(w.warehouseName, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final warehousesState = ref.watch(activeWarehousesProvider);
    final warehouses = warehousesState.valueOrNull ?? <Warehouse>[];
    final stocks = _source == null
        ? const AsyncData<List<StockBalanceView>>([])
        : ref.watch(warehouseStockBalancesProvider(_source!));
    final selected = _lines.map((l) => l.stock.productUnit.id).toSet();
    final query = _search.text.trim().toLowerCase();
    final matching = (stocks.valueOrNull ?? <StockBalanceView>[])
        .where(
          (s) =>
              s.productUnit.isBaseUnit &&
              s.inventory.quantity > 0 &&
              !selected.contains(s.productUnit.id) &&
              (s.product.productName.toLowerCase().contains(query) ||
                  s.product.productCode.toLowerCase().contains(query) ||
                  (s.productUnit.barcode?.contains(query) ?? false)),
        )
        .take(8)
        .toList();
    Future<void> add(StockBalanceView stock) async {
      final db = getIt<AppDatabase>();
      final rows = await (db.select(db.productUnits).join([
        drift.innerJoin(db.units, db.units.id.equalsExp(db.productUnits.unitId)),
      ])..where(
          db.productUnits.productId.equals(stock.product.id) &
          db.productUnits.isActive.equals(true) &
          db.productUnits.deletedAt.isNull(),
        ))
        .get();

      final units = <ProductUnit>[];
      final unitNames = <String, String>{};
      ProductUnit? baseUnit;
      for (final row in rows) {
        final pu = row.readTable(db.productUnits);
        final u = row.readTable(db.units);
        units.add(pu);
        unitNames[pu.id] = u.unitName;
        if (pu.isBaseUnit) {
          baseUnit = pu;
        }
      }

      final initialUnit = baseUnit ?? (units.isNotEmpty ? units.first : stock.productUnit);
      if (mounted) {
        setState(() {
          _lines.add(_TransferLine(
            stock: stock,
            units: units.isNotEmpty ? units : [stock.productUnit],
            unitNames: unitNames.isNotEmpty ? unitNames : {stock.productUnit.id: 'وحدة'},
            selectedUnit: initialUnit,
            quantity: '1',
          ));
          _search.clear();
        });
      }
    }
    return InventoryDialogFrame(
      title: 'تحويل مخزني جديد',
      icon: Icons.swap_horiz_rounded,
      actionLabel: 'تأكيد التحويل',
      onClose: _close,
      onAction: _submit,
      busy: _busy,
      error: _error,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'تنتقل الكمية وتكلفتها من المستودع المصدر إلى المستلم في عملية واحدة.',
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (_, c) {
                      final source = _picker(
                        'من المستودع',
                        _source,
                        warehouses,
                        (id) async {
                          if (id == null || id == _source) {
                            return;
                          }
                          if (_lines.isNotEmpty) {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تغيير المصدر؟'),
                                content: const Text(
                                  'سيتم مسح المنتجات المحددة للتحويل.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('رجوع'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('تغيير المصدر'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true || !mounted) {
                              return;
                            }
                          }
                          setState(() {
                            _source = id;
                            if (_destination == id) {
                              _destination = null;
                            }
                            _lines.clear();
                            _search.clear();
                          });
                        },
                      );
                      final destination = _picker(
                        'إلى المستودع',
                        _destination,
                        warehouses.where((w) => w.id != _source).toList(),
                        (id) => setState(() => _destination = id),
                      );
                      if (c.maxWidth < 650) {
                        return Column(
                          children: [
                            source,
                            const SizedBox(height: 12),
                            destination,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: source),
                          const SizedBox(width: 16),
                          const Icon(Icons.arrow_back_rounded),
                          const SizedBox(width: 16),
                          Expanded(child: destination),
                        ],
                      );
                    },
                  ),
                  if (warehousesState.hasError)
                    TextButton.icon(
                      onPressed: () => ref.invalidate(activeWarehousesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة تحميل المستودعات'),
                    ),
                  if (warehouses.length == 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('يلزم إضافة مستودع آخر قبل إجراء التحويل.'),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    enabled: _source != null,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (matching.length == 1) {
                        add(matching.single);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن منتج أو امسح الباركود',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (stocks.isLoading) const LinearProgressIndicator(),
                  if (stocks.hasError)
                    TextButton.icon(
                      onPressed: () => ref.invalidate(
                        warehouseStockBalancesProvider(_source!),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('تعذر تحميل الأرصدة، أعد المحاولة'),
                    ),
                  if (query.isNotEmpty)
                    for (final s in matching)
                      ListTile(
                        title: Text(s.product.productName),
                        subtitle: Text(
                          'متاح: ${formatCatalogNumber(s.inventory.quantity)}',
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => add(s),
                      ),
                  if (query.isNotEmpty && matching.isEmpty && !stocks.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'لا يوجد منتج مطابق متاح للتحويل خارج القائمة.',
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_lines.length} منتج في التحويل',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          if (_lines.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('اختر المصدر والمستلم ثم أضف المنتجات.'),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: _lines.length,
              itemBuilder: (_, i) {
                final l = _lines[i];
                return Padding(
                  key: ValueKey(l.stock.productUnit.id),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.stock.product.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'إزالة المنتج',
                            onPressed: () => setState(() => _lines.removeAt(i)),
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'المتاح: ${l.formattedBreakdown.isNotEmpty ? l.formattedBreakdown : formatCatalogNumber(l.stock.inventory.quantity)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text(
                                  '(${formatCatalogNumber(l.stock.inventory.quantity)} ${l.baseUnitName})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (l.units.length > 1) ...[
                            SizedBox(
                              width: 160,
                              child: DropdownButtonFormField<String>(
                                initialValue: l.selectedUnit.id,
                                isDense: true,
                                decoration: const InputDecoration(
                                  labelText: 'الوحدة المحولة',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: [
                                  for (final u in l.units)
                                    DropdownMenuItem(
                                      value: u.id,
                                      child: Text(
                                        u.isBaseUnit
                                            ? '${l.unitNames[u.id] ?? "حبة"} (أساسية)'
                                            : '${l.unitNames[u.id] ?? "كرتون"} (×${formatCatalogNumber(u.conversionFactor)})',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                                onChanged: (newUnitId) {
                                  if (newUnitId != null) {
                                    final newUnit = l.units.firstWhere((u) => u.id == newUnitId);
                                    setState(() {
                                      l.selectedUnit = newUnit;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextFormField(
                                  key: ValueKey('transfer_qty_${l.selectedUnit.id}_${l.stock.productUnit.id}'),
                                  initialValue: l.quantity,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  textDirection: TextDirection.ltr,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (v) => setState(() => l.quantity = v),
                                  decoration: InputDecoration(
                                    labelText: 'الكمية (${l.unitNames[l.selectedUnit.id] ?? "الوحدة"})',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                                if (!l.selectedUnit.isBaseUnit && (parseCountQuantity(l.quantity) ?? 0) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '= ${formatCatalogNumber((parseCountQuantity(l.quantity) ?? 0) * l.selectedUnit.conversionFactor)} ${l.baseUnitName}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: .15),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
