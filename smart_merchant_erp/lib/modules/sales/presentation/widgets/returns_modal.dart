import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../database/daos/catalog_dao.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/usecases/process_sales_return_usecase.dart';
import '../providers/sales_provider.dart';

class ReturnsModal extends ConsumerStatefulWidget {
  final SalesInvoiceWithItems? initialInvoice;
  final VoidCallback? onClose;

  const ReturnsModal({
    super.key,
    this.initialInvoice,
    this.onClose,
  });

  @override
  ConsumerState<ReturnsModal> createState() => _ReturnsModalState();
}

class _ItemReturnDraft {
  final SalesInvoiceItem item;
  final String productName;
  final String unitName;
  double returnQuantity;

  _ItemReturnDraft({
    required this.item,
    required this.productName,
    required this.unitName,
    this.returnQuantity = 0.0,
  });

  double get subtotal => returnQuantity * item.unitPrice;
}

class _ReturnsModalState extends ConsumerState<ReturnsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search State for Invoices
  final TextEditingController _invoiceSearchController =
      TextEditingController();
  List<SalesInvoiceWithItems> _searchedInvoices = [];
  bool _isSearchingInvoices = false;

  // Active Selected Invoice for Return
  SalesInvoiceWithItems? _selectedInvoice;
  List<_ItemReturnDraft> _returnDraftItems = [];
  bool _isLoadingItems = false;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  // Search State for Returns List
  String _returnListSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialInvoice != null ? 1 : 0,
    );

    if (widget.initialInvoice != null) {
      _selectInvoice(widget.initialInvoice!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchInvoices(String query) async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;
    if (query.trim().isEmpty) {
      setState(() => _searchedInvoices = []);
      return;
    }

    setState(() => _isSearchingInvoices = true);

    try {
      final repo = ref.read(salesRepositoryProvider);
      final invoices = await repo.listInvoices(
        SalesInvoiceFilter(
          businessId: session.businessId!,
          limit: 50,
        ),
      );

      final queryLower = query.trim().toLowerCase();
      final results = <SalesInvoiceWithItems>[];
      for (final inv in invoices) {
        if (inv.invoiceNumber.toLowerCase().contains(queryLower)) {
          final withItems = await repo.getInvoiceWithItemsById(
            inv.id,
            session.businessId!,
          );
          if (withItems != null) {
            results.add(withItems);
          }
        }
      }

      if (mounted) {
        setState(() {
          _searchedInvoices = results;
          _isSearchingInvoices = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearchingInvoices = false);
      }
    }
  }

  Future<void> _selectInvoice(SalesInvoiceWithItems invoiceWithItems) async {
    setState(() {
      _selectedInvoice = invoiceWithItems;
      _isLoadingItems = true;
      _returnDraftItems = [];
    });

    final session = ref.read(sessionNotifierProvider);
    final businessId = session.businessId ?? '';
    final catalogDao = getIt<CatalogDao>();

    final drafts = <_ItemReturnDraft>[];
    for (final item in invoiceWithItems.items) {
      String productName = 'صنف غير معروف';
      String unitName = 'قطعة';

      try {
        final productUnit = await catalogDao.getProductUnitById(
          item.productUnitId,
          businessId,
        );
        if (productUnit != null) {
          final product = await catalogDao.getProductById(
            productUnit.productId,
            businessId,
          );
          if (product != null) {
            productName = product.productName;
          }
          final unit = await catalogDao.getUnitById(
            productUnit.unitId,
            businessId,
          );
          if (unit != null) {
            unitName = unit.unitName;
          }
        }
      } catch (_) {}

      drafts.add(
        _ItemReturnDraft(
          item: item,
          productName: productName,
          unitName: unitName,
          returnQuantity: 0.0,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _returnDraftItems = drafts;
        _isLoadingItems = false;
      });
    }
  }

  double get _totalReturnAmount => _returnDraftItems.fold(
        0.0,
        (sum, item) => sum + item.subtotal,
      );

  int get _totalReturnItemsCount => _returnDraftItems
      .where((item) => item.returnQuantity > 0)
      .length;

  Future<void> _submitReturn() async {
    if (_selectedInvoice == null) return;

    final selectedItems = _returnDraftItems
        .where((d) => d.returnQuantity > 0)
        .map(
          (d) => SalesReturnItemCommand(
            salesInvoiceItemId: d.item.id,
            productUnitId: d.item.productUnitId,
            warehouseId: d.item.warehouseId,
            quantity: d.returnQuantity,
            unitPrice: d.item.unitPrice,
          ),
        )
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد كمية صنف واحد على الأقل لإرجاعه'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final useCase = getIt<ProcessSalesReturnUseCase>();
      final command = ProcessSalesReturnCommand(
        salesInvoiceId: _selectedInvoice!.invoice.id,
        currencyId: _selectedInvoice!.invoice.currencyId,
        exchangeRate: _selectedInvoice!.invoice.exchangeRate,
        items: selectedItems,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final result = await useCase(command);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في معالجة المرتجع: ${failure.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (returnId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تسجيل مرتجع المبيعات وتحديث المخزون والقيود المحاسبية بنجاح',
              ),
              backgroundColor: Color(0xFF10B981),
            ),
          );

          // Reset creation state
          setState(() {
            _selectedInvoice = null;
            _returnDraftItems = [];
            _notesController.clear();
            _invoiceSearchController.clear();
          });

          // Switch back to returns list tab
          _tabController.animateTo(0);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء المعالجة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_return_rounded,
                          color: AppColors.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة مرتجعات المبيعات (POS & Sales Returns)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'إرجاع بضاعة إلى المستودع وعكس الأثر المالي في حساب العميل أو الصندوق',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () {
                      widget.onClose?.call();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: textSecondary,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.history_rounded, size: 18),
                      text: 'سجل المرتجعات السابقة',
                    ),
                    Tab(
                      icon: Icon(Icons.add_shopping_cart_rounded, size: 18),
                      text: 'إنشاء مرتجع مبيعات جديد',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReturnsListTab(surfaceColor, borderColor, textColor, textSecondary, isDark),
                    _buildCreateReturnTab(surfaceColor, borderColor, textColor, textSecondary, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: List of Past Returns
  Widget _buildReturnsListTab(
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color textSecondary,
    bool isDark,
  ) {
    final returnsAsync = ref.watch(salesReturnsNotifierProvider);

    return Column(
      children: [
        // Search & Count bar
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _returnListSearch = val),
                  decoration: const InputDecoration(
                    hintText: 'ابحث برقم المرتجع...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('مرتجع جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Returns Table / List
        Expanded(
          child: returnsAsync.when(
            data: (returns) {
              final filtered = returns.where((r) {
                if (_returnListSearch.trim().isEmpty) return true;
                return r.returnNumber.toLowerCase().contains(
                      _returnListSearch.toLowerCase().trim(),
                    );
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_return_outlined,
                        size: 56,
                        color: textSecondary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد عمليات مرتجع مبيعات مسجلة حتى الآن',
                        style: TextStyle(fontSize: 15, color: textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _tabController.animateTo(1),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('تسجيل أول مرتجع'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              '#',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'رقم المرتجع',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'تاريخ المرتجع',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'ملاحظات / سبب المرتجع',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'حالة الترحيل',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'إجمالي المرتجع',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // List Items
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final ret = filtered[index];
                          final isPosted = ret.status.toLowerCase() == 'posted';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.assignment_return_rounded,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        ret.returnNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(ret.returnDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    ret.notes?.isNotEmpty == true
                                        ? ret.notes!
                                        : 'مرتجع مبيعات نقدي/آجل',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPosted
                                            ? Colors.green.withOpacity(0.12)
                                            : Colors.orange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isPosted ? 'مرحل ومقيد' : 'مسودة',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isPosted
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${ret.totalAmount.toStringAsFixed(2)} ر.ي',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.error,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ في جلب المرتجعات: $e')),
          ),
        ),
      ],
    );
  }

  // TAB 2: Create Return Workflow
  Widget _buildCreateReturnTab(
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color textSecondary,
    bool isDark,
  ) {
    if (_selectedInvoice == null) {
      // Step 1: Search and Select Invoice
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الخطوة الأولى: تحديد فاتورة المبيعات المراد استرجاعها',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _invoiceSearchController,
                          onSubmitted: _searchInvoices,
                          decoration: const InputDecoration(
                            hintText: 'أدخل رقم الفاتورة للبحث (مثال: INV-...)',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _searchInvoices(_invoiceSearchController.text),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('بحث'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Results
          Expanded(
            child: _isSearchingInvoices
                ? const Center(child: CircularProgressIndicator())
                : _searchedInvoices.isEmpty
                    ? Center(
                        child: Text(
                          _invoiceSearchController.text.trim().isEmpty
                              ? 'قم بإدخال رقم الفاتورة والضغط على بحث لاختيارها'
                              : 'لم يتم العثور على أي فاتورة مبيعات مطابقة لهذا الرقم',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchedInvoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final inv = _searchedInvoices[index];
                          return Card(
                            color: surfaceColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: borderColor),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.12),
                                child: const Icon(
                                  Icons.receipt_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                'فاتورة رقم: ${inv.invoice.invoiceNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'التاريخ: ${DateFormat('yyyy-MM-dd').format(inv.invoice.invoiceDate)} • الأصناف: ${inv.items.length} • الإجمالي: ${inv.invoice.grandTotal.toStringAsFixed(2)} ر.ي',
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () => _selectInvoice(inv),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('اختيار الفاتورة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
    }

    // Step 2: Invoice Selected - Pick Items and Quantities
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected Invoice Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الفاتورة المحددة: ${_selectedInvoice!.invoice.invoiceNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '(${DateFormat('yyyy-MM-dd').format(_selectedInvoice!.invoice.invoiceDate)})',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'إجمالي الفاتورة: ${_selectedInvoice!.invoice.grandTotal.toStringAsFixed(2)} ر.ي',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedInvoice = null;
                    _returnDraftItems = [];
                  });
                },
                icon: const Icon(Icons.change_circle_outlined, size: 16),
                label: const Text('تغيير الفاتورة'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Items Return Table
        Expanded(
          child: _isLoadingItems
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'اسم الصنف',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'الوحدة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'الكمية المباعة',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'سعر البيع',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'الكمية المرتجعة',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'إجمالي المرتجع',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Items List
                      Expanded(
                        child: ListView.separated(
                          itemCount: _returnDraftItems.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: borderColor),
                          itemBuilder: (context, index) {
                            final draft = _returnDraftItems[index];
                            final maxQty = draft.item.quantity;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      draft.productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      draft.unitName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      draft.item.quantity.toStringAsFixed(
                                        draft.item.quantity % 1 == 0 ? 0 : 2,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      draft.item.unitPrice.toStringAsFixed(2),
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20,
                                          ),
                                          color: textSecondary,
                                          onPressed: draft.returnQuantity <= 0
                                              ? null
                                              : () {
                                                  setState(() {
                                                    draft.returnQuantity =
                                                        (draft.returnQuantity - 1)
                                                            .clamp(0.0, maxQty);
                                                  });
                                                },
                                        ),
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: draft.returnQuantity > 0
                                                ? AppColors.error
                                                    .withOpacity(0.12)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: draft.returnQuantity > 0
                                                  ? AppColors.error
                                                  : borderColor,
                                            ),
                                          ),
                                          child: Text(
                                            draft.returnQuantity.toStringAsFixed(
                                              draft.returnQuantity % 1 == 0
                                                  ? 0
                                                  : 2,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: draft.returnQuantity > 0
                                                  ? AppColors.error
                                                  : textColor,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20,
                                          ),
                                          color: AppColors.error,
                                          onPressed: draft.returnQuantity >= maxQty
                                              ? null
                                              : () {
                                                  setState(() {
                                                    draft.returnQuantity =
                                                        (draft.returnQuantity + 1)
                                                            .clamp(0.0, maxQty);
                                                  });
                                                },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${draft.subtotal.toStringAsFixed(2)} ر.ي',
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: draft.subtotal > 0
                                            ? AppColors.error
                                            : textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Bottom Summary & Actions
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'سبب الإرجاع أو ملاحظات إضافية...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'أصناف للإرجاع: $_totalReturnItemsCount | الإجمالي: ',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${_totalReturnAmount.toStringAsFixed(2)} ر.ي',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isSubmitting || _totalReturnAmount <= 0
                  ? null
                  : _submitReturn,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(_isSubmitting ? 'جاري المعالجة...' : 'تأكيد واسترجاع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
