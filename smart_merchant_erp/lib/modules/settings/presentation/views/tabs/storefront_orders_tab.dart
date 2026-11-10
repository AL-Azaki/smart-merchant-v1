import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/di/getit_providers.dart';
import '../../../../../database/daos/sales_dao.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/tokens/spacing.dart';
import '../../../../authentication/presentation/providers/session_provider.dart';
import '../../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../../platform/presentation/providers/sync_provider.dart';
import '../../../../sales/presentation/providers/online_orders_provider.dart';
import '../../../../sales/presentation/providers/pos_provider.dart';

class StorefrontOrdersTab extends ConsumerWidget {
  final VoidCallback onOpenSimulator;
  final VoidCallback onOpenCatalog;

  const StorefrontOrdersTab({
    super.key,
    required this.onOpenSimulator,
    required this.onOpenCatalog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(onlineOrdersNotifierProvider);
    final actionState = ref.watch(onlineOrdersActionNotifierProvider);
    final productsAsync = ref.watch(productsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final publishedProductsCount = productsAsync.valueOrNull
            ?.where((p) => p.showInStore && p.isActive && p.deletedAt == null)
            .length ??
        0;

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                'حدث خطأ أثناء تحميل طلبات المتجر',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (allOrders) {
        final activeOrders =
            allOrders.where((o) => o.deletedAt == null).toList();

        final pendingCount =
            activeOrders.where((o) => o.status == 'Pending').length;
        final confirmedCount =
            activeOrders.where((o) => o.status == 'Confirmed').length;
        final deliveredOrders =
            activeOrders.where((o) => o.status == 'Delivered').toList();
        final cancelledCount =
            activeOrders.where((o) => o.status == 'Cancelled').length;

        final totalStoreRevenue = activeOrders
            .where((o) => o.status == 'Confirmed' || o.status == 'Delivered')
            .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

        var filteredOrders = activeOrders;
        if (actionState.statusFilter != null) {
          filteredOrders = filteredOrders
              .where((o) => o.status == actionState.statusFilter)
              .toList();
        }
        if (actionState.searchQuery.isNotEmpty) {
          final q = actionState.searchQuery.toLowerCase();
          filteredOrders = filteredOrders
              .where(
                (o) =>
                    o.orderNumber.toLowerCase().contains(q) ||
                    (o.notes?.toLowerCase().contains(q) ?? false),
              )
              .toList();
        }

        return Column(
          children: [
            if (actionState.successMessage != null)
              _buildMessageBanner(
                actionState.successMessage!,
                AppColors.success,
                Icons.check_circle_rounded,
                () => ref
                    .read(onlineOrdersActionNotifierProvider.notifier)
                    .clearMessages(),
              ),
            if (actionState.errorMessage != null)
              _buildMessageBanner(
                actionState.errorMessage!,
                AppColors.error,
                Icons.error_rounded,
                () => ref
                    .read(onlineOrdersActionNotifierProvider.notifier)
                    .clearMessages(),
              ),

            // KPI Summary Strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 760;
                  final cards = [
                    _buildKpiTile(
                      title: 'طلبات جديدة',
                      value: '$pendingCount',
                      subtitle: 'بانتظار المراجعة والقبول',
                      icon: Icons.notifications_active_rounded,
                      color: AppColors.warning,
                      isDark: isDark,
                      onTap: () => ref
                          .read(onlineOrdersActionNotifierProvider.notifier)
                          .setStatusFilter('Pending'),
                    ),
                    _buildKpiTile(
                      title: 'جاهزة للفوترة',
                      value: '$confirmedCount',
                      subtitle: 'مقبولة وجاهزة لنقطة البيع',
                      icon: Icons.point_of_sale_rounded,
                      color: AppColors.success,
                      isDark: isDark,
                      onTap: () => ref
                          .read(onlineOrdersActionNotifierProvider.notifier)
                          .setStatusFilter('Confirmed'),
                    ),
                    _buildKpiTile(
                      title: 'مبيعات المتجر',
                      value: '${totalStoreRevenue.toStringAsFixed(0)} ر.ي',
                      subtitle: '${deliveredOrders.length} طلب مكتمل',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.primary,
                      isDark: isDark,
                      onTap: () => ref
                          .read(onlineOrdersActionNotifierProvider.notifier)
                          .setStatusFilter(null),
                    ),
                    _buildKpiTile(
                      title: 'المنتجات المعروضة',
                      value: '$publishedProductsCount منتج',
                      subtitle: 'اضغط لإدارة كتالوج المتجر',
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFF0D9488),
                      isDark: isDark,
                      onTap: onOpenCatalog,
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: cards[i]),
                        ],
                      ],
                    );
                  }

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.35,
                    children: cards,
                  );
                },
              ),
            ),

            // Filter Chips + Simulator Action Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip(
                    ref: ref,
                    label: 'الكل',
                    status: null,
                    count: activeOrders.length,
                    currentFilter: actionState.statusFilter,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref: ref,
                    label: 'جديد',
                    status: 'Pending',
                    count: pendingCount,
                    currentFilter: actionState.statusFilter,
                    isDark: isDark,
                    badgeColor: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref: ref,
                    label: 'مقبول',
                    status: 'Confirmed',
                    count: confirmedCount,
                    currentFilter: actionState.statusFilter,
                    isDark: isDark,
                    badgeColor: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref: ref,
                    label: 'مكتمل',
                    status: 'Delivered',
                    count: deliveredOrders.length,
                    currentFilter: actionState.statusFilter,
                    isDark: isDark,
                    badgeColor: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref: ref,
                    label: 'مرفوض',
                    status: 'Cancelled',
                    count: cancelledCount,
                    currentFilter: actionState.statusFilter,
                    isDark: isDark,
                    badgeColor: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onOpenSimulator,
                    icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 17),
                    label: const Text(
                      'تجربة الطلب كعميل',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'مزامنة وتحديث الطلبات',
                    icon: const Icon(Icons.sync_rounded),
                    color: AppColors.primary,
                    onPressed: () async {
                      await ref.read(syncNotifierProvider.notifier).syncNow();
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                onChanged: (value) {
                  ref
                      .read(onlineOrdersActionNotifierProvider.notifier)
                      .setSearchQuery(value);
                },
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث برقم الطلب، اسم العميل، أو رقم الهاتف...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    size: 20,
                  ),
                  filled: true,
                  fillColor:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderSm,
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderSm,
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.borderSm,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),

            // Orders List
            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _StorefrontOrderCard(
                          order: order,
                          isDark: isDark,
                          onTap: () => _showOrderDetailsDialog(
                            context,
                            ref,
                            order,
                          ),
                          onQuickAccept: order.status == 'Pending'
                              ? () => ref
                                  .read(
                                    onlineOrdersActionNotifierProvider.notifier,
                                  )
                                  .acceptOrder(order.id)
                              : null,
                          onQuickOpenPos: order.status == 'Confirmed'
                              ? () => _handoffOrderToPos(context, ref, order)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handoffOrderToPos(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
  ) async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;

    final repo = ref.read(salesRepositoryProvider);
    final orderWithItems = await repo.getOrderWithItemsById(
      order.id,
      session.businessId!,
    );
    if (orderWithItems != null) {
      await ref
          .read(posNotifierProvider.notifier)
          .loadFromOnlineOrder(orderWithItems);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحميل الطلب (${order.orderNumber}) في سلة نقطة البيع لإصدار الفاتورة',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/sales');
      }
    }
  }

  void _showOrderDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _StorefrontOrderDetailsSheet(
              order: order,
              isDark: isDark,
              businessId: session.businessId!,
              onAccept: () {
                Navigator.of(dialogContext).pop();
                ref
                    .read(onlineOrdersActionNotifierProvider.notifier)
                    .acceptOrder(order.id);
              },
              onReject: () {
                Navigator.of(dialogContext).pop();
                ref
                    .read(onlineOrdersActionNotifierProvider.notifier)
                    .rejectOrder(order.id);
              },
              onOpenInPos: () async {
                Navigator.of(dialogContext).pop();
                await _handoffOrderToPos(context, ref, order);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBanner(
    String message,
    Color color,
    IconData icon,
    VoidCallback onDismiss,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderSm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            child: Icon(Icons.close, color: color, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required WidgetRef ref,
    required String label,
    required String? status,
    required int count,
    required String? currentFilter,
    required bool isDark,
    Color? badgeColor,
  }) {
    final isActive = currentFilter == status;
    final chipColor = isActive
        ? AppColors.primary
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final textColor = isActive
        ? Colors.white
        : (isDark ? Colors.white70 : AppColors.textPrimaryLight);

    return GestureDetector(
      onTap: () {
        ref
            .read(onlineOrdersActionNotifierProvider.notifier)
            .setStatusFilter(status);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: AppSpacing.borderSm,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : (badgeColor ?? AppColors.textSecondaryLight).withValues(
                          alpha: 0.15,
                        ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (badgeColor ?? AppColors.textSecondaryLight),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات إلكترونية مطابقة حالياً',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك الآن تجربة المتجر كعميل حقيقي وإرسال طلب تجريبي لترى كيف يصل هنا وكيف يتم تحويله لنقطة البيع!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenSimulator,
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text(
                'معاينة المتجر وتجربة الطلب كعميل الآن',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorefrontOrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onQuickAccept;
  final VoidCallback? onQuickOpenPos;

  const _StorefrontOrderCard({
    required this.order,
    required this.isDark,
    required this.onTap,
    this.onQuickAccept,
    this.onQuickOpenPos,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = _ParsedCustomerNotes.fromRaw(order.notes);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderMd,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: AppSpacing.borderMd,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                _buildStatusBadge(order.status, isDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Text(
                  '${order.grandTotal.toStringAsFixed(0)} ر.ي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (parsed.customerName != null)
                  _buildMetaItem(
                    Icons.person_outline_rounded,
                    parsed.customerName!,
                    isDark,
                  ),
                if (parsed.customerPhone != null)
                  _buildMetaItem(
                    Icons.phone_iphone_rounded,
                    parsed.customerPhone!,
                    isDark,
                  ),
                if (parsed.address != null)
                  _buildMetaItem(
                    Icons.location_on_outlined,
                    parsed.address!,
                    isDark,
                  ),
                _buildMetaItem(
                  Icons.access_time_rounded,
                  _formatDate(order.orderDate),
                  isDark,
                ),
              ],
            ),
            if (onQuickAccept != null || onQuickOpenPos != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('التفاصيل والأصناف'),
                  ),
                  const SizedBox(width: 8),
                  if (onQuickAccept != null)
                    FilledButton.icon(
                      onPressed: onQuickAccept,
                      icon: const Icon(Icons.check_rounded, size: 17),
                      label: const Text('قبول الطلب'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (onQuickOpenPos != null)
                    FilledButton.icon(
                      onPressed: onQuickOpenPos,
                      icon: const Icon(Icons.point_of_sale_rounded, size: 17),
                      label: const Text('تحويل لنقطة البيع (POS)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    String label;
    Color color;
    switch (status) {
      case 'Pending':
        label = 'طلب جديد';
        color = AppColors.warning;
        break;
      case 'Confirmed':
        label = 'مقبول';
        color = AppColors.success;
        break;
      case 'Cancelled':
        label = 'مرفوض';
        color = AppColors.error;
        break;
      case 'Delivered':
        label = 'مكتمل';
        color = AppColors.info;
        break;
      default:
        label = status;
        color = AppColors.textSecondaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ParsedCustomerNotes {
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final String? extraNotes;

  const _ParsedCustomerNotes({
    this.customerName,
    this.customerPhone,
    this.address,
    this.extraNotes,
  });

  factory _ParsedCustomerNotes.fromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _ParsedCustomerNotes();
    }
    String? name;
    String? phone;
    String? addr;
    String? extra;

    final segments = raw.split('|').map((s) => s.trim()).toList();
    for (final seg in segments) {
      if (seg.startsWith('العميل:')) {
        name = seg.replaceFirst('العميل:', '').trim();
      } else if (seg.startsWith('الهاتف:')) {
        phone = seg.replaceFirst('الهاتف:', '').trim();
      } else if (seg.startsWith('العنوان:')) {
        addr = seg.replaceFirst('العنوان:', '').trim();
      } else if (seg.startsWith('ملاحظات:')) {
        extra = seg.replaceFirst('ملاحظات:', '').trim();
      }
    }

    if (name == null && phone == null && addr == null) {
      return _ParsedCustomerNotes(extraNotes: raw);
    }

    return _ParsedCustomerNotes(
      customerName: name,
      customerPhone: phone,
      address: addr,
      extraNotes: extra,
    );
  }
}

class _StorefrontOrderDetailsSheet extends ConsumerWidget {
  final OrderEntity order;
  final bool isDark;
  final String businessId;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onOpenInPos;

  const _StorefrontOrderDetailsSheet({
    required this.order,
    required this.isDark,
    required this.businessId,
    required this.onAccept,
    required this.onReject,
    required this.onOpenInPos,
  });

  Future<void> _contactViaWhatsApp(
    BuildContext context,
    String phone,
    String? customerName,
  ) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;

    final greeting =
        customerName != null ? 'مرحباً أ. $customerName،' : 'مرحباً بك،';
    final message =
        '$greeting\nبخصوص طلبكم رقم (${order.orderNumber}) بقيمة ${order.grandTotal.toStringAsFixed(0)} ر.ي عبر متجرنا الإلكتروني، نود إبلاغكم بأنه يجري متابعة وتجهيز طلبكم.';
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final parsed = _ParsedCustomerNotes.fromRaw(order.notes);
    final salesRepo = ref.watch(salesRepositoryProvider);
    final catalogRepo = ref.watch(catalogRepositoryProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل طلب المتجر الإلكتروني',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      Text(
                        order.orderNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (parsed.customerPhone != null)
                  OutlinedButton.icon(
                    onPressed: () => _contactViaWhatsApp(
                      context,
                      parsed.customerPhone!,
                      parsed.customerName,
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                    label: const Text(
                      'مراسلة واتساب',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        if (parsed.customerName != null)
                          _infoRow(
                            'اسم العميل',
                            parsed.customerName!,
                            textColor,
                            textSecondary,
                          ),
                        if (parsed.customerPhone != null)
                          _infoRow(
                            'رقم الجوال',
                            parsed.customerPhone!,
                            textColor,
                            textSecondary,
                          ),
                        if (parsed.address != null)
                          _infoRow(
                            'عنوان التوصيل',
                            parsed.address!,
                            textColor,
                            textSecondary,
                          ),
                        if (parsed.extraNotes != null)
                          _infoRow(
                            'ملاحظات الطلب',
                            parsed.extraNotes!,
                            textColor,
                            textSecondary,
                          ),
                        _infoRow(
                          'تاريخ الطلب',
                          '${order.orderDate.year}/${order.orderDate.month}/${order.orderDate.day} ${order.orderDate.hour}:${order.orderDate.minute.toString().padLeft(2, '0')}',
                          textColor,
                          textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'الأصناف المطلوبة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<OrderWithItems?>(
                    future:
                        salesRepo.getOrderWithItemsById(order.id, businessId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final items = snapshot.data?.items ?? [];
                      if (items.isEmpty) {
                        return Text(
                          'لا توجد أصناف مسجلة',
                          style: TextStyle(color: textSecondary),
                        );
                      }
                      return Column(
                        children: items.map((item) {
                          return FutureBuilder<ProductUnit?>(
                            future: catalogRepo.getProductUnitById(
                              item.productUnitId,
                              businessId,
                            ),
                            builder: (context, unitSnap) {
                              final productId = unitSnap.data?.productId;
                              return FutureBuilder<Product?>(
                                future: productId != null
                                    ? catalogRepo.getProductById(
                                        productId,
                                        businessId,
                                      )
                                    : Future.value(null),
                                builder: (context, prodSnap) {
                                  final name = prodSnap.data?.productName ??
                                      'منتج (${item.productUnitId.substring(0, 6)})';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: textColor,
                                                ),
                                              ),
                                              Text(
                                                'الكمية: ${item.quantity.toStringAsFixed(0)} × ${item.unitPrice.toStringAsFixed(0)} ر.ي',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${item.lineTotal.toStringAsFixed(0)} ر.ي',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإجمالي الكلي للطلب',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${order.grandTotal.toStringAsFixed(2)} ر.ي',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: _buildBottomActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (order.status == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded, color: AppColors.error),
              label: const Text(
                'رفض الطلب',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text(
                'قبول وتأكيد الطلب',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      );
    }
    if (order.status == 'Confirmed') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onOpenInPos,
          icon: const Icon(Icons.point_of_sale_rounded),
          label: const Text(
            'فتح في نقطة البيع وإصدار فاتورة (POS)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    return Center(
      child: Text(
        order.status == 'Delivered'
            ? 'تم إكمال وفوترة هذا الطلب بنجاح'
            : 'هذا الطلب ملغي / مرفوض',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: order.status == 'Delivered' ? AppColors.info : AppColors.error,
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    Color textColor,
    Color secondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

