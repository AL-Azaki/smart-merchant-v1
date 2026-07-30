import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../providers/online_orders_provider.dart';
import '../providers/pos_provider.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/services/online_order_service.dart';
import '../../../../app/di/getit_instance.dart';
import '../layouts/sales_layout.dart';

class OrdersListView extends ConsumerWidget {
  const OrdersListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(onlineOrdersNotifierProvider);
    final actionState = ref.watch(onlineOrdersActionNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ordersAsync.when(
      data: (allOrders) {
        // Apply local filtering
        var orders = allOrders.where((o) => o.deletedAt == null).toList();

        // Status filter
        if (actionState.statusFilter != null) {
          orders = orders
              .where((o) => o.status == actionState.statusFilter)
              .toList();
        }

        // Search filter
        if (actionState.searchQuery.isNotEmpty) {
          final q = actionState.searchQuery.toLowerCase();
          orders = orders
              .where(
                (o) =>
                    o.orderNumber.toLowerCase().contains(q) ||
                    (o.notes?.toLowerCase().contains(q) ?? false),
              )
              .toList();
        }

        return Column(
          children: [
            // Snackbar-style messages
            if (actionState.successMessage != null)
              _buildMessageBanner(
                context,
                actionState.successMessage!,
                AppColors.success,
                Icons.check_circle_rounded,
                () => ref
                    .read(onlineOrdersActionNotifierProvider.notifier)
                    .clearMessages(),
              ),
            if (actionState.errorMessage != null)
              _buildMessageBanner(
                context,
                actionState.errorMessage!,
                AppColors.error,
                Icons.error_rounded,
                () => ref
                    .read(onlineOrdersActionNotifierProvider.notifier)
                    .clearMessages(),
              ),

            // Filter chips
            _buildFilterBar(context, ref, allOrders, isDark),

            // Search
            _buildSearchBar(context, ref, isDark),

            // Orders list
            Expanded(
              child: orders.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : _buildOrdersList(context, ref, orders, isDark),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'حدث خطأ في تحميل الطلبات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              err.toString(),
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBanner(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
    VoidCallback onDismiss,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                fontWeight: FontWeight.w600,
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

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    List<OrderEntity> allOrders,
    bool isDark,
  ) {
    final actionState = ref.watch(onlineOrdersActionNotifierProvider);
    final activeOrders = allOrders.where((o) => o.deletedAt == null).toList();
    final pendingCount = activeOrders
        .where((o) => o.status == 'Pending')
        .length;
    final confirmedCount = activeOrders
        .where((o) => o.status == 'Confirmed')
        .length;
    final cancelledCount = activeOrders
        .where((o) => o.status == 'Cancelled')
        .length;
    final deliveredCount = activeOrders
        .where((o) => o.status == 'Delivered')
        .length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            context,
            ref,
            'الكل',
            null,
            activeOrders.length,
            actionState.statusFilter,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            ref,
            'جديد',
            'Pending',
            pendingCount,
            actionState.statusFilter,
            isDark,
            badgeColor: AppColors.warning,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            ref,
            'مقبول',
            'Confirmed',
            confirmedCount,
            actionState.statusFilter,
            isDark,
            badgeColor: AppColors.success,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            ref,
            'مرفوض',
            'Cancelled',
            cancelledCount,
            actionState.statusFilter,
            isDark,
            badgeColor: AppColors.error,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            ref,
            'مكتمل',
            'Delivered',
            deliveredCount,
            actionState.statusFilter,
            isDark,
            badgeColor: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    String? status,
    int count,
    String? currentFilter,
    bool isDark, {
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: AppSpacing.borderSm,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        onChanged: (value) {
          ref
              .read(onlineOrdersActionNotifierProvider.notifier)
              .setSearchQuery(value);
        },
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث برقم الطلب...',
          hintStyle: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            size: 20,
          ),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderSm,
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderSm,
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات إلكترونية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الطلبات هنا تلقائياً عند المزامنة',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    WidgetRef ref,
    List<OrderEntity> orders,
    bool isDark,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          isDark: isDark,
          onTap: () => _showOrderDetails(context, ref, order),
        );
      },
    );
  }

  void _showOrderDetails(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _OrderDetailsSheet(
          order: order,
          isDark: isDark,
          businessId: session.businessId!,
          onAccept: () {
            Navigator.of(sheetContext).pop();
            ref
                .read(onlineOrdersActionNotifierProvider.notifier)
                .acceptOrder(order.id);
          },
          onReject: () {
            Navigator.of(sheetContext).pop();
            ref
                .read(onlineOrdersActionNotifierProvider.notifier)
                .rejectOrder(order.id);
          },
          onOpenInPos: () async {
            Navigator.of(sheetContext).pop();
            // Load order into POS cart
            final repo = ref.read(salesRepositoryProvider);
            final orderWithItems = await repo.getOrderWithItemsById(
              order.id,
              session.businessId!,
            );
            if (orderWithItems != null) {
              ref
                  .read(posNotifierProvider.notifier)
                  .loadFromOnlineOrder(orderWithItems);
              // Switch to POS tab (index 0) using SalesTabScope
              if (context.mounted) {
                final scope = SalesTabScope.of(context);
                scope?.tabController.animateTo(0);
              }
            }
          },
        );
      },
    );
  }
}

/// Compact order card for the list view.
class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderMd,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
        child: Row(
          children: [
            // Status indicator
            _buildStatusDot(order.status),
            const SizedBox(width: 12),
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      _buildStatusChip(order.status, isDark),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(order.orderDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.attach_money_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      Text(
                        order.grandTotal.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      order.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_left_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = AppColors.warning;
        break;
      case 'Confirmed':
        color = AppColors.success;
        break;
      case 'Cancelled':
        color = AppColors.error;
        break;
      case 'Delivered':
        color = AppColors.info;
        break;
      default:
        color = AppColors.textSecondaryLight;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isDark) {
    String label;
    Color color;
    switch (status) {
      case 'Pending':
        label = 'جديد';
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
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Order details bottom sheet with cashier actions.
class _OrderDetailsSheet extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final String businessId;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onOpenInPos;

  const _OrderDetailsSheet({
    required this.order,
    required this.isDark,
    required this.businessId,
    required this.onAccept,
    required this.onReject,
    required this.onOpenInPos,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل الطلب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        order.orderNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _OrderCard(
                  order: order,
                  isDark: isDark,
                  onTap: () {},
                )._buildStatusChip(order.status, isDark),
              ],
            ),
          ),

          Divider(color: borderColor, height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info Grid
                  _buildInfoRow(
                    'رقم الطلب',
                    order.orderNumber,
                    textColor,
                    textSecondary,
                  ),
                  _buildInfoRow(
                    'التاريخ',
                    _formatDate(order.orderDate),
                    textColor,
                    textSecondary,
                  ),
                  _buildInfoRow(
                    'الحالة',
                    _statusLabel(order.status),
                    textColor,
                    textSecondary,
                  ),
                  if (order.customerId != null)
                    _buildInfoRow(
                      'العميل',
                      order.customerId!,
                      textColor,
                      textSecondary,
                    ),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _buildInfoRow(
                      'ملاحظات',
                      order.notes!,
                      textColor,
                      textSecondary,
                    ),

                  const SizedBox(height: 16),

                  // Order Items section
                  Text(
                    'المنتجات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Items will be loaded via FutureBuilder
                  _OrderItemsList(
                    orderId: order.id,
                    businessId: businessId,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  // Totals
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: AppSpacing.borderMd,
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildTotalRow(
                          'المجموع الفرعي',
                          order.subTotal.toStringAsFixed(2),
                          textColor,
                        ),
                        if (order.discountTotal > 0)
                          _buildTotalRow(
                            'الخصم',
                            '-${order.discountTotal.toStringAsFixed(2)}',
                            AppColors.error,
                          ),
                        if (order.taxTotal > 0)
                          _buildTotalRow(
                            'الضريبة',
                            order.taxTotal.toStringAsFixed(2),
                            textSecondary,
                          ),
                        Divider(color: borderColor, height: 16),
                        _buildTotalRow(
                          'الإجمالي',
                          order.grandTotal.toStringAsFixed(2),
                          AppColors.primary,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: _buildActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (order.status) {
      case 'Pending':
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'رفض الطلب',
                AppColors.error,
                Icons.close_rounded,
                onReject,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                'قبول الطلب',
                AppColors.success,
                Icons.check_rounded,
                onAccept,
                filled: true,
              ),
            ),
          ],
        );
      case 'Confirmed':
        return SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            'فتح في نقطة البيع',
            AppColors.primary,
            Icons.point_of_sale_rounded,
            onOpenInPos,
            filled: true,
          ),
        );
      case 'Delivered':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderSm,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.info, size: 20),
              SizedBox(width: 8),
              Text(
                'تم إكمال هذا الطلب',
                style: TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        );
      case 'Cancelled':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderSm,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text(
                'تم رفض هذا الطلب',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap, {
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderSm,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: AppSpacing.borderSm,
          border: filled ? null : Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
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
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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

  Widget _buildTotalRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'جديد - بانتظار المراجعة';
      case 'Confirmed':
        return 'مقبول';
      case 'Cancelled':
        return 'مرفوض';
      case 'Delivered':
        return 'مكتمل';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Loads and displays order items from the repository.
class _OrderItemsList extends ConsumerWidget {
  final String orderId;
  final String businessId;
  final bool isDark;

  const _OrderItemsList({
    required this.orderId,
    required this.businessId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(salesRepositoryProvider);
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return FutureBuilder<OrderWithItems?>(
      future: repo.getOrderWithItemsById(orderId, businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final items = snapshot.data?.items ?? [];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'لا توجد منتجات في هذا الطلب',
              style: TextStyle(color: textSecondary),
            ),
          );
        }

        return Column(
          children: items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                borderRadius: AppSpacing.borderSm,
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderSm,
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productUnitId,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.lineTotal.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
