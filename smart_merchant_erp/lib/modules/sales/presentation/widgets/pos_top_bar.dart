import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_search_provider.dart';
import 'returns_modal.dart';
import 'voucher_modal.dart';

/// Top minimal action bar for POS.
/// Houses the POS brand pill, smooth expandable search bar (saving catalog space),
/// and quick access to vouchers and returns.
class PosTopBar extends ConsumerStatefulWidget {
  const PosTopBar({super.key});

  @override
  ConsumerState<PosTopBar> createState() => _PosTopBarState();
}

class _PosTopBarState extends ConsumerState<PosTopBar> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _collapseSearch() {
    setState(() {
      _isSearchExpanded = false;
    });
    _searchController.clear();
    ref.read(posSearchQueryProvider.notifier).clear();
    _searchFocusNode.unfocus();
  }

  void _expandSearch() {
    setState(() {
      _isSearchExpanded = true;
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final isNarrow = constraints.maxWidth < 500;

          // If search is expanded on narrow mobile, give the entire row to search
          if (_isSearchExpanded && isNarrow) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن صنف أو باركود...',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (val) {
                              ref
                                  .read(posSearchQueryProvider.notifier)
                                  .update(val);
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              ref.read(posSearchQueryProvider.notifier).clear();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: _collapseSearch,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              // 1. POS Title Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 8 : 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.point_of_sale_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      constraints.maxWidth >= 600
                          ? 'كاشير التجزئة السريع'
                          : 'الكاشير',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // 2. Smooth Expandable Search Bar (Right beside POS button as requested)
              if (_isSearchExpanded)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن صنف أو باركود...',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (val) {
                              ref
                                  .read(posSearchQueryProvider.notifier)
                                  .update(val);
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              ref.read(posSearchQueryProvider.notifier).clear();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: _collapseSearch,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Tooltip(
                  message: 'بحث عن صنف',
                  child: InkWell(
                    onTap: _expandSearch,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 36,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 10 : 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: textSecondary,
                          ),
                          if (isWide) ...[
                            const SizedBox(width: 6),
                            Text(
                              'بحث عن صنف...',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              const Spacer(),

              // 3. Voucher & Discount Bond (سند وقسائم)
              Tooltip(
                message: 'سند وقسائم الخصم',
                child: InkWell(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const VoucherModal(),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 8 : (isWide ? 12 : 8),
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning
                          .withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        if (!isNarrow) ...[
                          const SizedBox(width: 5),
                          Text(
                            isWide ? 'سند وقسائم' : 'السند',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.warning
                                  : const Color(0xFFB45309),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 4. Returns (مرتجع مبيعات)
              Tooltip(
                message: 'مرتجع مبيعات',
                child: InkWell(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const ReturnsModal(),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 8 : (isWide ? 12 : 8),
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error
                          .withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_return_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        if (!isNarrow) ...[
                          const SizedBox(width: 5),
                          Text(
                            isWide ? 'مرتجع مبيعات' : 'المرتجع',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

    );
  }
}
