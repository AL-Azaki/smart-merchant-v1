import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

/// تمثيل موحد لأي طرف أو حساب مالي يمكن اختياره في سندات القبض والصرف
class VoucherAccountItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? code;
  final bool isCustomer;
  final bool isSupplier;
  final String? phone;

  const VoucherAccountItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.code,
    this.isCustomer = false,
    this.isSupplier = false,
    this.phone,
  });

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    if (title.toLowerCase().contains(q)) {
      return true;
    }
    if (code != null && code!.toLowerCase().contains(q)) {
      return true;
    }
    if (subtitle != null && subtitle!.toLowerCase().contains(q)) {
      return true;
    }
    if (phone != null && phone!.contains(q)) {
      return true;
    }
    return false;
  }
}

/// نافذة بحث منبثقة وسريعة لاختيار أي حساب أو طرف
Future<VoucherAccountItem?> showVoucherAccountSearchPicker({
  required BuildContext context,
  required String title,
  required List<VoucherAccountItem> items,
  String? selectedId,
}) {
  return showDialog<VoucherAccountItem>(
    context: context,
    builder: (ctx) => _VoucherAccountSearchDialog(
      title: title,
      items: items,
      selectedId: selectedId,
    ),
  );
}

class _VoucherAccountSearchDialog extends StatefulWidget {
  final String title;
  final List<VoucherAccountItem> items;
  final String? selectedId;

  const _VoucherAccountSearchDialog({
    required this.title,
    required this.items,
    this.selectedId,
  });

  @override
  State<_VoucherAccountSearchDialog> createState() =>
      _VoucherAccountSearchDialogState();
}

class _VoucherAccountSearchDialogState
    extends State<_VoucherAccountSearchDialog> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filterCategory = 'all'; // 'all', 'accounts', 'parties'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VoucherAccountItem> get _filteredItems {
    return widget.items.where((item) {
      // Category filter
      if (_filterCategory == 'accounts' && (item.isCustomer || item.isSupplier)) {
        return false;
      }
      if (_filterCategory == 'parties' && (!item.isCustomer && !item.isSupplier)) {
        return false;
      }
      // Query filter
      return item.matches(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    final results = _filteredItems;
    final bool hasParties = widget.items.any((i) => i.isCustomer || i.isSupplier);

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.manage_search_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Input Field
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _query = val),
                decoration: InputDecoration(
                  hintText: 'ابحث برقم الحساب أو الاسم أو الهاتف...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Filter Chips (All, Accounts, Parties) if applicable
              if (hasParties) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('دليل الحسابات', 'accounts'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        widget.items.any((i) => i.isCustomer) ? 'العملاء' : 'الموردين',
                        'parties',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Results Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'النتائج المتاحة: ${results.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (_query.isNotEmpty)
                      Text(
                        'تصفية حسب: "$_query"',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                  ],
                ),
              ),
              const Divider(height: 16),

              // List of Accounts
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد حسابات أو أطراف مطابقة للبحث',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                        itemBuilder: (ctx, index) {
                          final item = results[index];
                          final isSelected = item.id == widget.selectedId;

                          return InkWell(
                            onTap: () => Navigator.of(context).pop(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Row(
                                children: [
                                  // Leading Badge / Icon
                                  _buildItemLeading(item),
                                  const SizedBox(width: 12),

                                  // Name and Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w900
                                                      : FontWeight.w700,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : textColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (item.isCustomer)
                                              _buildBadge('عميل', Colors.blue)
                                            else if (item.isSupplier)
                                              _buildBadge('مورد', Colors.orange),
                                          ],
                                        ),
                                        if (item.subtitle != null &&
                                            item.subtitle!.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            item.subtitle!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Trailing Selected Check
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String category) {
    final isSelected = _filterCategory == category;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterCategory = category),
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : null,
      ),
    );
  }

  Widget _buildItemLeading(VoucherAccountItem item) {
    if (item.code != null && item.code!.isNotEmpty) {
      return Container(
        constraints: const BoxConstraints(minWidth: 54),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: Text(
          item.code!,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (item.isCustomer) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withValues(alpha: 0.12),
        ),
        child: const Icon(Icons.person_rounded, color: Colors.blue, size: 20),
      );
    }

    if (item.isSupplier) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.orange.withValues(alpha: 0.12),
        ),
        child: const Icon(Icons.business_rounded, color: Colors.orange, size: 20),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withValues(alpha: 0.12),
      ),
      child: const Icon(Icons.account_balance_wallet_outlined, size: 20),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// حقل النموذج التفاعلي لاختيار الحساب أو الطرف
class VoucherAccountSelectField extends StatelessWidget {
  final String label;
  final VoucherAccountItem? selectedItem;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final String? errorText;

  const VoucherAccountSelectField({
    required this.label,
    required this.selectedItem,
    required this.onTap,
    required this.onClear,
    this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedItem != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            isSelected
                ? (selectedItem!.isCustomer
                    ? Icons.person_rounded
                    : (selectedItem!.isSupplier
                        ? Icons.business_rounded
                        : Icons.account_balance_wallet_outlined))
                : Icons.search_rounded,
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
          suffixIcon: isSelected
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  tooltip: 'إلغاء التحديد',
                  onPressed: onClear,
                )
              : const Icon(Icons.arrow_drop_down_rounded, size: 28),
          border: const OutlineInputBorder(),
          errorText: errorText,
        ),
        child: isSelected
            ? Row(
                children: [
                  if (selectedItem!.code != null && selectedItem!.code!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        selectedItem!.code!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      selectedItem!.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selectedItem!.isCustomer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('عميل',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                  if (selectedItem!.isSupplier)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('مورد',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              )
            : Text(
                'اضغط للبحث واختيار أي حساب أو طرف...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
              ),
      ),
    );
  }
}

