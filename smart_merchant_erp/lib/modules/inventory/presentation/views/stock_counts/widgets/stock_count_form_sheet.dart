import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../kernel/storage/app_database.dart';
import '../../../../../catalog/presentation/views/widgets/catalog_formatters.dart';
import '../../../../application/services/stock_count_workflow.dart';
import '../../../../application/usecases/save_stock_count_usecase.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/stock_counts_provider.dart';
import '../../../widgets/inventory_dialog_frame.dart';
import '../../../widgets/count_quantity_row.dart';

class StockCountFormSheet extends ConsumerStatefulWidget {
  final StockCountDocument? document;
  const StockCountFormSheet({super.key, this.document});
  static Future<String?> show(
    BuildContext context, {
    StockCountDocument? document,
  }) => showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => StockCountFormSheet(document: document),
  );
  @override
  ConsumerState<StockCountFormSheet> createState() =>
      _StockCountFormSheetState();
}

class _Line {
  final String productId, unitId, name, unitName;
  double expected;
  String physical;
  _Line({
    required this.productId,
    required this.unitId,
    required this.name,
    required this.unitName,
    required this.expected,
    this.physical = '',
  });
}

class _StockCountFormSheetState extends ConsumerState<StockCountFormSheet> {
  final _notes = TextEditingController(), _search = TextEditingController();
  final List<_Line> _lines = [];
  String? _warehouseId, _error;
  bool _busy = false;
  int _warehouseRevision = 0;
  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    if (doc != null) {
      _warehouseId = doc.count.warehouseId;
      _notes.text = doc.count.notes ?? '';
      for (final item in doc.items) {
        _lines.add(
          _Line(
            productId: item.productId,
            unitId: item.productUnitId,
            name: doc.names[item.productId] ?? 'منتج',
            unitName: doc.unitNames[item.productUnitId] ?? 'وحدة',
            expected: item.expectedQuantity,
            physical: formatCatalogNumber(item.countedQuantity),
          ),
        );
      }
    } else {
      Future<void>(() async {
        try {
          final warehouses = await ref.read(activeWarehousesProvider.future);
          final selected = warehouses.length == 1
              ? warehouses.single
              : warehouses.where((w) => w.isDefault).firstOrNull;
          if (mounted && _warehouseId == null && selected != null) {
            setState(() => _warehouseId = selected.id);
          }
        } catch (_) {
          /* The warehouse field displays the retry state. */
        }
      });
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _search.dispose();
    super.dispose();
  }

  void _add(StockCountCandidate c) {
    if (_lines.any((l) => l.unitId == c.unit.id)) {
      return;
    }
    _lines.add(
      _Line(
        productId: c.product.id,
        unitId: c.unit.id,
        name: c.product.productName,
        unitName: c.unitName,
        expected: c.quantity,
      ),
    );
  }

  Future<void> _refresh() async {
    if (_warehouseId == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      ref.invalidate(stockCountCandidatesProvider(_warehouseId!));
      final candidates = await ref.read(
        stockCountCandidatesProvider(_warehouseId!).future,
      );
      final map = {for (final c in candidates) c.unit.id: c};
      if (!mounted) {
        return;
      }
      setState(() {
        for (final l in _lines) {
          if (map[l.unitId] != null) {
            l.expected = map[l.unitId]!.quantity;
          }
        }
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذر تحديث الرصيد، أعد المحاولة.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  bool _askingClose = false;
  Future<void> _close() async {
    if (_busy || _askingClose) {
      return;
    }
    final doc = widget.document;
    final changed = doc == null
        ? _lines.isNotEmpty || _notes.text.trim().isNotEmpty
        : _lines.length != doc.items.length ||
              _notes.text.trim() != (doc.count.notes ?? '').trim() ||
              _lines.any((l) {
                final old = doc.items
                    .where((i) => i.productUnitId == l.unitId)
                    .firstOrNull;
                return old == null ||
                    parseCountQuantity(l.physical) != old.countedQuantity ||
                    l.expected != old.expectedQuantity;
              });
    _askingClose = true;
    final discard = !changed || await confirmDiscardInventoryEdits(context);
    _askingClose = false;
    if (discard && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (_busy) {
      return;
    }
    final counted = _lines.where((l) => l.physical.trim().isNotEmpty).toList();
    if (_warehouseId == null || counted.isEmpty) {
      setState(
        () =>
            _error = 'اختر المستودع وأدخل الكمية الفعلية لمنتج واحد على الأقل.',
      );
      return;
    }
    if (counted.any((l) => parseCountQuantity(l.physical) == null)) {
      setState(
        () => _error = 'راجع الكميات؛ لا يُقبل الرقم السالب أو غير الصالح.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(stockCountsNotifierProvider.notifier)
          .saveDraft(
            SaveStockCountCommand(
              id: widget.document?.count.id,
              warehouseId: _warehouseId!,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              items: [
                for (final l in counted)
                  SaveStockCountItemCommand(
                    productId: l.productId,
                    productUnitId: l.unitId,
                    expectedQuantity: l.expected,
                    countedQuantity: parseCountQuantity(l.physical)!,
                    differenceQuantity:
                        parseCountQuantity(l.physical)! - l.expected,
                  ),
              ],
            ),
          );
      if (mounted) {
        Navigator.pop(context, id);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is InventoryWorkflowException
              ? e.message
              : 'تعذر حفظ الجرد. بياناتك محفوظة هنا، حاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retain the command controller while a standalone modal is submitting.
    ref.watch(stockCountsNotifierProvider.select((_) => null));
    final warehouses = ref.watch(activeWarehousesProvider);
    final candidatesAsync = _warehouseId == null
        ? const AsyncData<List<StockCountCandidate>>([])
        : ref.watch(stockCountCandidatesProvider(_warehouseId!));
    final candidates = candidatesAsync.valueOrNull ?? [];
    final query = _search.text.trim().toLowerCase();
    final matching = candidates
        .where(
          (c) =>
              !_lines.any((l) => l.unitId == c.unit.id) &&
              (c.product.productName.toLowerCase().contains(query) ||
                  (c.unit.barcode?.contains(query) ?? false) ||
                  c.product.productCode.toLowerCase().contains(query)),
        )
        .take(8)
        .toList();
    final counted = _lines
        .where((l) => parseCountQuantity(l.physical) != null)
        .length;
    return InventoryDialogFrame(
      title: widget.document == null ? 'جرد تصحيحي جديد' : 'تعديل مسودة الجرد',
      icon: Icons.fact_check_outlined,
      actionLabel: 'حفظ ومراجعة',
      onClose: _close,
      onAction: _save,
      busy: _busy,
      error: _error,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'أدخل الكمية الموجودة فعلياً. تُحفظ مسودة للمراجعة قبل تصحيح المخزون.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (_, c) {
                      final warehouse = DropdownButtonFormField<String>(
                        key: ValueKey('$_warehouseId-$_warehouseRevision'),
                        initialValue: _warehouseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'المستودع',
                          prefixIcon: Icon(Icons.warehouse_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          if (widget.document != null &&
                              !(warehouses.valueOrNull ?? <Warehouse>[]).any(
                                (w) => w.id == _warehouseId,
                              ))
                            DropdownMenuItem(
                              value: _warehouseId,
                              child: Text(widget.document!.warehouseName),
                            ),
                          for (final w
                              in warehouses.valueOrNull ?? <Warehouse>[])
                            DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                w.warehouseName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: widget.document != null
                            ? null
                            : (id) async {
                                if (id == null || id == _warehouseId) {
                                  return;
                                }
                                if (_lines.isNotEmpty) {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('تغيير المستودع؟'),
                                      content: const Text(
                                        'سيتم مسح قائمة العد الحالية عند اختيار مستودع آخر.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('رجوع'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('تغيير المستودع'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  if (confirmed != true) {
                                    setState(() => _warehouseRevision++);
                                    return;
                                  }
                                }
                                setState(() {
                                  _warehouseId = id;
                                  _lines.clear();
                                  _search.clear();
                                });
                              },
                      );
                      final notes = TextField(
                        controller: _notes,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      );
                      if (c.maxWidth < 650) {
                        return Column(
                          children: [
                            warehouse,
                            const SizedBox(height: 12),
                            notes,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: warehouse),
                          const SizedBox(width: 12),
                          Expanded(child: notes),
                        ],
                      );
                    },
                  ),
                  if (warehouses.hasError)
                    TextButton.icon(
                      onPressed: () => ref.invalidate(activeWarehousesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة تحميل المستودعات'),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    enabled: _warehouseId != null,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (matching.length == 1) {
                        setState(() {
                          _add(matching.single);
                          _search.clear();
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن منتج أو امسح الباركود',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (candidatesAsync.isLoading)
                    const LinearProgressIndicator(),
                  if (candidatesAsync.hasError)
                    TextButton.icon(
                      onPressed: () => ref.invalidate(
                        stockCountCandidatesProvider(_warehouseId!),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('تعذر تحميل المنتجات، أعد المحاولة'),
                    ),
                  if (query.isNotEmpty &&
                      !candidatesAsync.isLoading &&
                      matching.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('لا يوجد منتج مطابق خارج قائمة العد.'),
                    ),
                  if (query.isNotEmpty)
                    for (final c in matching)
                      ListTile(
                        dense: true,
                        title: Text(c.product.productName),
                        subtitle: Text(
                          'رصيد النظام: ${formatCatalogNumber(c.quantity)} ${catalogDisplayName(c.unitName)}',
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => setState(() {
                          _add(c);
                          _search.clear();
                        }),
                      ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        'تم عدّ $counted من ${_lines.length} منتج',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: candidates.isEmpty
                                ? null
                                : () => setState(() {
                                    for (final c in candidates) {
                                      _add(c);
                                    }
                                  }),
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('إضافة جميع المنتجات'),
                          ),
                          TextButton.icon(
                            onPressed: _warehouseId == null ? null : _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('تحديث رصيد النظام'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Text(
                    'المنتج دون كمية فعلية لا يدخل في الجرد. أدخل صفرًا إذا لم تجد منه أي كمية.',
                    style: TextStyle(fontSize: 12),
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
                  child: Text(
                    'أضف المنتجات التي تريد عدّها من البحث أو أضف القائمة كاملة.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: _lines.length,
              itemBuilder: (_, index) {
                final l = _lines[index];
                return Column(
                  key: ValueKey(l.unitId),
                  children: [
                    CountQuantityRow(
                      name: l.name,
                      unit: l.unitName,
                      expected: l.expected,
                      physical: parseCountQuantity(l.physical),
                      onRemove: () => setState(() => _lines.removeAt(index)),
                      input: TextFormField(
                        key: ValueKey('quantity_${l.unitId}'),
                        initialValue: l.physical,
                        textDirection: TextDirection.ltr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (v) => setState(() => l.physical = v),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'لم يُعدّ',
                          errorText:
                              l.physical.trim().isNotEmpty &&
                                  parseCountQuantity(l.physical) == null
                              ? 'رقم غير صالح'
                              : null,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: .15),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
