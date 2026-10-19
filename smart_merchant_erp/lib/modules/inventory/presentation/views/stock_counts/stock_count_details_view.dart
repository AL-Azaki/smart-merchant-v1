import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../database/enums/stock_count_status.dart';
import '../../../../catalog/presentation/views/widgets/catalog_formatters.dart';
import '../../../application/services/stock_count_workflow.dart';
import '../../providers/stock_counts_provider.dart';
import '../../widgets/count_quantity_row.dart';
import 'widgets/stock_count_form_sheet.dart';
import 'widgets/stock_count_settlement_dialog.dart';

class StockCountDetailsView extends ConsumerStatefulWidget {
  final String countId;
  const StockCountDetailsView({required this.countId, super.key});
  @override
  ConsumerState<StockCountDetailsView> createState() =>
      _StockCountDetailsViewState();
}

class _StockCountDetailsViewState extends ConsumerState<StockCountDetailsView> {
  bool _busy = false;
  String? _error;
  Future<void> _correct(StockCountDocument doc) async {
    if (_busy) {
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصحيح رصيد المخزون؟'),
        content: Text(
          'ستصبح أرصدة المنتجات مساوية للكميات الفعلية التي أدخلتها.\n\nقيمة العجز: ${formatCatalogPrice(doc.shortage, doc.currency)}\nقيمة الزيادة: ${formatCatalogPrice(doc.surplus, doc.currency)}\n\nتُسجّل الفروقات في حساب معلّق، وتختار المسؤول عنها لاحقاً. لا يمكن تعديل الكميات بعد الاعتماد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('مراجعة'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('اعتماد التصحيح'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(stockCountsNotifierProvider.notifier)
          .postCount(doc.count.id);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is InventoryWorkflowException
              ? e.message
              : 'تعذر اعتماد التصحيح. لم تتغير الكميات، أعد المحاولة.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancel(StockCountDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء مسودة الجرد؟'),
        content: const Text(
          'ستبقى المسودة في السجل كجرد ملغي دون تغيير المخزون أو إنشاء قيد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إلغاء الجرد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(stockCountWorkflowProvider).cancelDraft(doc.count.id);
      ref.invalidate(stockCountDocumentProvider(doc.count.id));
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is InventoryWorkflowException
              ? e.message
              : 'تعذر إلغاء المسودة، أعد المحاولة.',
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
    ref.watch(stockCountsNotifierProvider.select((_) => null));
    final async = ref.watch(stockCountDocumentProvider(widget.countId));
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الجرد التصحيحي')),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton.icon(
              onPressed: () =>
                  ref.invalidate(stockCountDocumentProvider(widget.countId)),
              icon: const Icon(Icons.refresh),
              label: const Text('تعذر تحميل الجرد، أعد المحاولة'),
            ),
          ),
          data: (doc) {
            final draft = doc.count.status == StockCountStatus.draft;
            final isSetupPending =
                doc.count.financialStatus == 'PendingFinancialSetup' &&
                doc.count.status == StockCountStatus.posted;
            final pending =
                (doc.count.financialStatus == 'Pending' || isSetupPending) &&
                doc.count.status == StockCountStatus.posted;
            final theme = Theme.of(context);
            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                doc.warehouseName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${doc.count.countNumber} · ${DateFormat('yyyy/MM/dd HH:mm').format(doc.count.countDate)}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              if (doc.count.notes?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(doc.count.notes!),
                                ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: .06,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      draft
                                          ? Icons.edit_note
                                          : pending
                                          ? Icons.pending_actions
                                          : Icons.verified_outlined,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        doc.count.status ==
                                                StockCountStatus.cancelled
                                            ? 'تم إلغاء المسودة دون تغيير المخزون أو إنشاء قيد.'
                                            : draft
                                            ? 'مسودة للمراجعة. رصيد المخزون لم يتغير بعد.'
                                            : isSetupPending
                                            ? 'تم تصحيح المخزون الفعلي بنجاح. الفروقات بانتظار فتح الفترة المحاسبية لتسجيل القيد أو معالجتها.'
                                            : pending
                                            ? 'تم تصحيح المخزون. الفروقات في الحساب المعلّق وتنتظر تحديد جهة التحميل.'
                                            : doc.count.financialStatus ==
                                                  'Settled'
                                            ? 'تم تصحيح المخزون ومعالجة الفروقات المالية.'
                                            : doc.count.financialStatus ==
                                                  'Legacy'
                                            ? 'جرد سابق: يحتاج التحقق من معالجته المالية؛ لن تُنشأ له قيود تلقائية.'
                                            : 'تم تصحيح المخزون ولا توجد فروقات مالية تحتاج إلى معالجة.',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 24,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    '${doc.items.length} منتج',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'عجز: ${formatCatalogPrice(doc.shortage, doc.currency)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'زيادة: ${formatCatalogPrice(doc.surplus, doc.currency)}',
                                    style: TextStyle(
                                      color: theme.brightness == Brightness.dark
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFF047857),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              if (draft)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'تُحتسب قيمة الفروقات بتكلفة المخزون عند الاعتماد، وتُحفظ للمراجعة اللاحقة.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: doc.items.length,
                        itemBuilder: (_, index) {
                          final i = doc.items[index];
                          return Column(
                            children: [
                              CountQuantityRow(
                                name: doc.names[i.productId] ?? 'منتج غير متاح',
                                unit: doc.unitNames[i.productUnitId] ?? 'وحدة',
                                expected: i.expectedQuantity,
                                physical: i.countedQuantity,
                              ),
                              Divider(
                                height: 1,
                                color: theme.colorScheme.outline.withValues(
                                  alpha: .15,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (draft || pending)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (draft)
                            TextButton.icon(
                              onPressed: _busy ? null : () => _cancel(doc),
                              icon: const Icon(Icons.block),
                              label: const Text('إلغاء الجرد'),
                            ),
                          if (draft)
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      final id = await StockCountFormSheet.show(
                                        context,
                                        document: doc,
                                      );
                                      if (id != null) {
                                        ref.invalidate(
                                          stockCountDocumentProvider(id),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('تعديل المسودة'),
                            ),
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () async {
                                    if (draft) {
                                      await _correct(doc);
                                    } else {
                                      final done =
                                          await StockCountSettlementDialog.show(
                                            context,
                                            doc,
                                          );
                                      if (done == true) {
                                        ref.invalidate(
                                          stockCountDocumentProvider(
                                            doc.count.id,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    draft
                                        ? Icons.fact_check_outlined
                                        : Icons.account_balance_outlined,
                                  ),
                            label: Text(
                              _busy
                                  ? 'جارٍ الاعتماد…'
                                  : draft
                                  ? 'اعتماد وتصحيح المخزون'
                                  : 'معالجة الفروقات',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(180, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
