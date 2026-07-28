import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/purchase_returns_provider.dart';
import '../providers/purchasing_provider.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../database/daos/purchasing_dao.dart' show PurchaseInvoiceFilter, PurchaseInvoiceWithItems;
import '../../../authentication/presentation/providers/session_provider.dart';

class PurchaseReturnModal extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const PurchaseReturnModal({super.key, required this.onClose});

  @override
  ConsumerState<PurchaseReturnModal> createState() => _PurchaseReturnModalState();
}

class _PurchaseReturnModalState extends ConsumerState<PurchaseReturnModal> {
  int _step = 1;
  String _searchQuery = '';
  PurchaseInvoiceWithItems? _selectedInvoice;
  List<PurchaseInvoiceWithItems> _searchResults = [];
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseReturnNotifierProvider.notifier).clearForm();
    });
  }

  Future<void> _searchInvoices() async {
    if (_searchQuery.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final repo = ref.read(purchasingRepositoryProvider);
      final session = ref.read(sessionNotifierProvider);
      if (!session.isActive) return;
      
      final filter = PurchaseInvoiceFilter(businessId: session.businessId!);
      // Ideally we would filter by search query in DB, but let's just get the latest and filter in memory for simplicity
      final invoices = await repo.listInvoices(filter);
      
      final results = <PurchaseInvoiceWithItems>[];
      for (final inv in invoices) {
        if (inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase())) {
          final withItems = await repo.getInvoiceWithItemsById(inv.id, session.businessId!);
          if (withItems != null) {
            results.add(withItems);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseReturnNotifierProvider);
    final notifier = ref.read(purchaseReturnNotifierProvider.notifier);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    
    if (state.successReturnId != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: 500,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(height: 24),
            Text('تم إنشاء فاتورة المرتجع بنجاح', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'إغلاق',
              onPressed: widget.onClose,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 700,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
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
                        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.keyboard_return, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إنشاء مرتجع مشتريات', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('إرجاع بضاعة واسترداد التكلفة', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: _step == 1 ? _buildStep1(isDark, borderColor) : _buildStep2(state, notifier, isDark, borderColor),
            ),
          ),
          
          if (state.error != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              color: AppColors.error.withOpacity(0.1),
              child: Text(
                state.error!.message,
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),

          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: _step == 1
                ? PrimaryButton(
                    text: 'متابعة',
                    onPressed: _selectedInvoice != null ? () {
                      notifier.setInvoice(_selectedInvoice!);
                      setState(() => _step = 2);
                    } : null,
                  )
                : PrimaryButton(
                    text: state.isSubmitting ? 'جاري التنفيذ...' : 'تأكيد إرجاع البضاعة',
                    onPressed: state.isSubmitting || _calculateTotal(state) <= 0
                        ? null
                        : () => notifier.submitReturn(_selectedInvoice!),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: const Text(
            'الخطوة 1: ابحث عن فاتورة المشتريات الأصلية المراد إرجاع بضاعة منها.',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        Text('رقم فاتورة المشتريات *', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => _searchQuery = v,
                decoration: InputDecoration(
                  hintText: 'PINV-2024-XXXX',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _searchInvoices,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('بحث'),
            ),
          ],
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('نتائج البحث:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._searchResults.map((inv) => InkWell(
            onTap: () => setState(() => _selectedInvoice = inv),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: _selectedInvoice == inv ? Colors.green : borderColor, width: _selectedInvoice == inv ? 2 : 1),
                borderRadius: BorderRadius.circular(12),
                color: _selectedInvoice == inv ? Colors.green.withOpacity(0.05) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv.invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${inv.invoice.purchaseDate.day}/${inv.invoice.purchaseDate.month}/${inv.invoice.purchaseDate.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Text('${inv.invoice.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          )).toList(),
        ] else if (_searchQuery.isNotEmpty && !_isSearching) ...[
          const SizedBox(height: 24),
          const Center(child: Text('لا توجد نتائج')),
        ]
      ],
    );
  }

  Widget _buildStep2(PurchaseReturnState state, PurchaseReturnNotifier notifier, bool isDark, Color borderColor) {
    if (_selectedInvoice == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الفاتورة الأصلية: ${_selectedInvoice!.invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('تاريخ الشراء: ${_selectedInvoice!.invoice.purchaseDate.toString().split(' ')[0]}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        const Text('حدد الكميات المرتجعة للمورد من المستودع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        
        ..._selectedInvoice!.items.map((item) {
          final returnedQty = state.returnQuantities[item.productUnitId] ?? 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المنتج ${item.productUnitId.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)), // Ideally we have product name
                      const SizedBox(height: 4),
                      Text('السعر: ${item.unitPrice} | الكمية المشتراة: ${item.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Text('إرجاع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final qty = double.tryParse(val) ?? 0.0;
                          if (qty >= 0 && qty <= item.quantity) {
                            notifier.updateQuantity(item.productUnitId, qty);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            border: Border.all(color: Colors.orange.withOpacity(0.3), style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي المبلغ المسترد من المورد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${_calculateTotal(state).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.orange)),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateTotal(PurchaseReturnState state) {
    if (_selectedInvoice == null) return 0.0;
    double total = 0.0;
    for (final item in _selectedInvoice!.items) {
      final qty = state.returnQuantities[item.productUnitId] ?? 0.0;
      total += qty * item.unitPrice;
    }
    return total;
  }
}
