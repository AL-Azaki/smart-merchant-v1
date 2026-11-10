import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/di/manual_injection.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../catalog/domain/models/catalog_product_item.dart';
import '../../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../../catalog/presentation/views/widgets/catalog_formatters.dart';
import '../../../../sales/application/services/online_order_service.dart';
import '../../../../sales/presentation/providers/product_unit_provider.dart';
import '../../providers/storefront_settings_provider.dart';
import '../business_profile_view.dart';

class _SimulatorCartItem {
  final CatalogProductItem catalogItem;
  final ProductUnit selectedUnit;
  final String unitName;
  final double unitPrice;
  final int quantity;

  const _SimulatorCartItem({
    required this.catalogItem,
    required this.selectedUnit,
    required this.unitName,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  _SimulatorCartItem copyWith({int? quantity}) {
    return _SimulatorCartItem(
      catalogItem: catalogItem,
      selectedUnit: selectedUnit,
      unitName: unitName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

class StorefrontCustomerSimulatorTab extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToOrders;
  final VoidCallback onNavigateToCatalog;

  const StorefrontCustomerSimulatorTab({
    super.key,
    required this.onNavigateToOrders,
    required this.onNavigateToCatalog,
  });

  @override
  ConsumerState<StorefrontCustomerSimulatorTab> createState() =>
      _StorefrontCustomerSimulatorTabState();
}

class _StorefrontCustomerSimulatorTabState
    extends ConsumerState<StorefrontCustomerSimulatorTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _isMobileFrameMode = false;

  // Interactive Customer Cart keyed by productUnitId
  final Map<String, _SimulatorCartItem> _cart = {};

  // Last created order for inline success banner
  CreatedStorefrontOrderResult? _lastCreatedOrder;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalCartCount =>
      _cart.values.fold<int>(0, (sum, item) => sum + item.quantity);

  double get _totalCartAmount =>
      _cart.values.fold<double>(0.0, (sum, item) => sum + item.lineTotal);

  void _addToCart(
    CatalogProductItem item,
    ProductUnit unit,
    String unitName, {
    int delta = 1,
  }) {
    final key = unit.id;
    final price = unit.sellingPrice > 0 ? unit.sellingPrice : item.sellingPrice;

    setState(() {
      _lastCreatedOrder = null;
      final existing = _cart[key];
      if (existing != null) {
        final nextQty = existing.quantity + delta;
        if (nextQty <= 0) {
          _cart.remove(key);
        } else {
          _cart[key] = existing.copyWith(quantity: nextQty);
        }
      } else if (delta > 0) {
        _cart[key] = _SimulatorCartItem(
          catalogItem: item,
          selectedUnit: unit,
          unitName: unitName,
          unitPrice: price,
          quantity: delta,
        );
      }
    });
  }

  Future<void> _openExternalWebStore(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر فتح المتصفح الخارجي حالياً. يمكنك استخدام المتجر التفاعلي المدمج أدناه بكامل المزايا.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openWhatsAppStoreContact(
    String? rawPhone,
    String storeName,
  ) async {
    if (rawPhone == null || rawPhone.trim().isEmpty) return;
    final clean = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final text = Uri.encodeComponent(
      'مرحباً $storeName، أرغب بالاستفسار عن المنتجات والطلبات المتوفرة في متجركم الإلكتروني.',
    );
    final uri = Uri.parse('https://wa.me/$clean?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Displays the rich, Salla-style Product Details "Show" modal
  void _showProductDetailsModal(
    BuildContext context,
    CatalogProductItem item,
    Map<String, String> unitNames,
    String categoryName,
    String storeName,
  ) {
    final availableUnits =
        item.units.isNotEmpty ? item.units : <ProductUnit>[item.baseUnit];
    ProductUnit selectedUnit = item.baseUnit;
    int quantity = 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final unitPrice = selectedUnit.sellingPrice > 0
                ? selectedUnit.sellingPrice
                : item.sellingPrice;
            final unitLabel =
                unitNames[selectedUnit.unitId] ?? 'قطعة';
            final isAvailable = item.stockQuantity > 0;
            final inCartCount = _cart[selectedUnit.id]?.quantity ?? 0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sheet Handle
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Top Breadcrumb & Close Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      categoryName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                  ),
                                  if (selectedUnit.sku != null &&
                                      selectedUnit.sku!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'كود: ${selectedUnit.sku}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(modalCtx),
                                icon: const Icon(Icons.close_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Product Showcase Hero Box
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        const Color(0xFF134E4A)
                                            .withValues(alpha: 0.3),
                                        const Color(0xFF0F172A),
                                      ]
                                    : [
                                        const Color(0xFFCCFBF1),
                                        const Color(0xFFF0FDFA),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFF0D9488)
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.shopping_bag_rounded,
                                    size: 72,
                                    color: const Color(0xFF0D9488)
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAvailable
                                          ? const Color(0xFF059669)
                                          : AppColors.error,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAvailable
                                              ? 'متوفر في المتجر (${item.stockQuantity.toStringAsFixed(0)} $unitLabel)'
                                              : 'نفد من المخزون',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Product Title & Price Header
                          Text(
                            item.product.productName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price Banner
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${unitPrice.toStringAsFixed(0)} ر.ي',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'لكل $unitLabel',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const Spacer(),
                              if (inCartCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$inCartCount في سلتك حالياً',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Unit of Measure Selector (if product has multiple packaging units)
                          if (availableUnits.length > 1) ...[
                            Text(
                              'اختر وحدة القياس / التعبئة:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableUnits.map((u) {
                                final isSelected = u.id == selectedUnit.id;
                                final uName = unitNames[u.unitId] ?? 'وحدة';
                                final uPrice = u.sellingPrice > 0
                                    ? u.sellingPrice
                                    : item.sellingPrice;
                                return ChoiceChip(
                                  label: Text(
                                    '$uName (${uPrice.toStringAsFixed(0)} ر.ي)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF0F172A)),
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0D9488),
                                  onSelected: (_) {
                                    setModalState(() => selectedUnit = u);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Description Section
                          if (item.product.description != null &&
                              item.product.description!.trim().isNotEmpty) ...[
                            Text(
                              'تفاصيل ومواصفات المنتج:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                item.product.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Salla / Zid Trust Guarantees
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  size: 18,
                                  color: Color(0xFF0D9488),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'معاينة وفحص المنتج قبل الدفع • دفع نقداً عند الاستلام • ضمان أصالة المنتج 100%',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Quantity Selector + Dynamic Subtotal Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'المبلغ الإجمالي للكمية:',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      '${(unitPrice * quantity).toStringAsFixed(0)} ر.ي',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton.filledTonal(
                                      onPressed: quantity > 1
                                          ? () =>
                                              setModalState(() => quantity--)
                                          : null,
                                      icon: const Icon(Icons.remove_rounded),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      onPressed: () =>
                                          setModalState(() => quantity++),
                                      icon: const Icon(Icons.add_rounded),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Add To Cart CTA Button
                          FilledButton.icon(
                            onPressed: () {
                              _addToCart(
                                item,
                                selectedUnit,
                                unitLabel,
                                delta: quantity,
                              );
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'تمت إضافة $quantity $unitLabel من "${item.product.productName}" إلى سلة المتجر!',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF0D9488),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 20,
                            ),
                            label: Text(
                              'إضافة للسلة (${(unitPrice * quantity).toStringAsFixed(0)} ر.ي)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCartAndCheckoutModal(BuildContext context, String? storeSlug) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _CustomerCheckoutDialog(
              initialCart: Map<String, _SimulatorCartItem>.from(_cart),
              storeSlug: storeSlug,
              onCartChanged: (updated) {
                setState(() {
                  _cart
                    ..clear()
                    ..addAll(updated);
                });
              },
              onOrderCompleted: (result) {
                setState(() {
                  _cart.clear();
                  _lastCreatedOrder = result;
                });
              },
              onGoToMerchantOrders: () {
                Navigator.of(dialogCtx).pop();
                widget.onNavigateToOrders();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreBrandLogo(String? logoPath, String storeName, {double size = 52}) {
    if (logoPath != null && logoPath.trim().isNotEmpty) {
      final path = logoPath.trim();
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.network(
            path,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackStoreLogo(storeName, size),
          ),
        );
      }
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackStoreLogo(storeName, size),
          ),
        );
      }
    }
    return _buildFallbackStoreLogo(storeName, size);
  }

  Widget _buildFallbackStoreLogo(String storeName, double size) {
    final initial =
        storeName.trim().isNotEmpty ? storeName.trim().substring(0, 1) : 'م';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.42,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentBusiness =
        ref.watch(currentBusinessEntityProvider).valueOrNull;
    final storefrontState = ref.watch(storefrontSettingsProvider);
    final settings = storefrontState.settings;
    final categories = ref.watch(categoriesNotifierProvider).valueOrNull ?? [];
    final units = ref.watch(unitsNotifierProvider).valueOrNull ?? [];
    final productsAsync = ref.watch(posProductsNotifierProvider);

    final categoryNames = {
      for (final c in categories) c.id: catalogDisplayName(c.categoryName),
    };
    final unitNames = {
      for (final u in units) u.id: catalogDisplayName(u.unitName),
    };

    final storeTitle = (currentBusiness?.businessName.trim().isNotEmpty ?? false)
        ? currentBusiness!.businessName.trim()
        : (settings?.storefrontDisplayName?.trim().isNotEmpty ?? false
            ? settings!.storefrontDisplayName!.trim()
            : 'متجر التاجر الذكي');

    final storeUrl = settings?.storeUrl ??
        'http://localhost:3000/store/${settings?.storefrontSlug ?? 'smart-store'}';
    final isStoreActive = settings?.storefrontActive ?? true;
    final storePhone = currentBusiness?.primaryPhone ??
        settings?.storefrontWhatsapp ??
        settings?.effectivePhone;
    final logoPath = currentBusiness?.logoPath;

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ في تحميل المتجر: $err')),
      data: (allItems) {
        final publishedItems =
            allItems.where((i) => i.product.showInStore).toList();

        var visibleProducts = publishedItems;
        if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
          visibleProducts = visibleProducts
              .where((i) => i.product.categoryId == _selectedCategoryId)
              .toList();
        }
        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          visibleProducts = visibleProducts.where((i) {
            return i.product.productName.toLowerCase().contains(q) ||
                (i.product.description?.toLowerCase().contains(q) ?? false);
          }).toList();
        }

        return Column(
          children: [
            // Top Simulator Header Bar (With Brand Identity & Quick Tools)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStoreBrandLogo(logoPath, storeTitle, size: 36),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                storeTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'معاينة حية',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'المتجر الإلكتروني المعتمد لعملائك أونلاين',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.desktop_windows_rounded, size: 16),
                            label: Text(
                              'ملء الشاشة',
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.smartphone_rounded, size: 16),
                            label: Text(
                              'إطار الجوال',
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ],
                        selected: {_isMobileFrameMode},
                        onSelectionChanged: (sel) {
                          setState(() => _isMobileFrameMode = sel.first);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openExternalWebStore(storeUrl),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text(
                          'فتح متجر الويب',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openCartAndCheckoutModal(
                          context,
                          settings?.storefrontSlug,
                        ),
                        icon: Badge(
                          isLabelVisible: _totalCartCount > 0,
                          label: Text('$_totalCartCount'),
                          child: const Icon(
                            Icons.shopping_cart_rounded,
                            size: 18,
                          ),
                        ),
                        label: Text(
                          _totalCartCount > 0
                              ? 'السلة (${_totalCartAmount.toStringAsFixed(0)} ر.ي)'
                              : 'سلة العميل (0)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Inline Order Success Notification Banner
            if (_lastCreatedOrder != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تم إنشاء الطلب (${_lastCreatedOrder!.orderNumber}) بنجاح كعميل!',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF065F46),
                              ),
                            ),
                            Text(
                              'العميل: ${_lastCreatedOrder!.customerName} • الإجمالي: ${_lastCreatedOrder!.grandTotal.toStringAsFixed(0)} ر.ي',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: widget.onNavigateToOrders,
                      icon: const Icon(Icons.receipt_long_rounded, size: 17),
                      label: const Text(
                        'عرض وقبول الطلب ككاشير الآن',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

            // Storefront Canvas (Full Width or Mobile Mockup Frame)
            Expanded(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: _isMobileFrameMode ? 410 : 1280,
                  margin: _isMobileFrameMode
                      ? const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        )
                      : EdgeInsets.zero,
                  decoration: _isMobileFrameMode
                      ? BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0B1120)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFF1E293B),
                            width: 7,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        )
                      : null,
                  clipBehavior:
                      _isMobileFrameMode ? Clip.antiAlias : Clip.none,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          _totalCartCount > 0 ? 96 : 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Storefront Hero Banner (Features Company Logo & Salla/Zid Style)
                            _buildStoreHeroBanner(
                              logoPath: logoPath,
                              storeTitle: storeTitle,
                              addressText: settings?.storefrontAddressText,
                              isStoreActive: isStoreActive,
                              storePhone: storePhone,
                            ),
                            const SizedBox(height: 18),

                            // 2. Customer Search & Category Filter Bar
                            _buildCustomerSearchAndCategories(
                              categories: categories,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 18),

                            // 3. Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Color(0xFF0D9488),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedCategoryId != null
                                          ? 'المنتجات في قسم: ${categoryNames[_selectedCategoryId] ?? ''}'
                                          : (_searchQuery.isNotEmpty
                                              ? 'نتائج البحث عن "$_searchQuery"'
                                              : 'أحدث المنتجات والعروض المتوفرة'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${visibleProducts.length} منتج',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 4. Products Grid or Empty State
                            if (publishedItems.isEmpty)
                              _buildNoPublishedProductsCard(
                                isDark,
                                allItems.isNotEmpty,
                              )
                            else if (visibleProducts.isEmpty)
                              _buildNoSearchResultsCard(isDark)
                            else
                              LayoutBuilder(
                                builder: (context, gridConstraints) {
                                  final w = gridConstraints.maxWidth;
                                  final cols = w > 940
                                      ? 4
                                      : (w > 640 ? 3 : 2);
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio:
                                          _isMobileFrameMode ? 0.65 : 0.72,
                                    ),
                                    itemCount: visibleProducts.length,
                                    itemBuilder: (context, idx) {
                                      final item = visibleProducts[idx];
                                      final unitLabel =
                                          unitNames[item.baseUnit.unitId] ??
                                              'قطعة';
                                      final catLabel = categoryNames[
                                              item.product.categoryId] ??
                                          'عام';
                                      final inCartQty =
                                          _cart[item.baseUnit.id]?.quantity ??
                                              0;

                                      return _CustomerProductCard(
                                        item: item,
                                        unitLabel: unitLabel,
                                        categoryLabel: catLabel,
                                        inCartQty: inCartQty,
                                        isDark: isDark,
                                        onTapCard: () =>
                                            _showProductDetailsModal(
                                          context,
                                          item,
                                          unitNames,
                                          catLabel,
                                          storeTitle,
                                        ),
                                        onAdd: () => _addToCart(
                                          item,
                                          item.baseUnit,
                                          unitLabel,
                                        ),
                                        onRemove: () => _addToCart(
                                          item,
                                          item.baseUnit,
                                          unitLabel,
                                          delta: -1,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),

                      // Floating Customer Cart Bar at bottom
                      if (_totalCartCount > 0)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: InkWell(
                            onTap: () => _openCartAndCheckoutModal(
                              context,
                              settings?.storefrontSlug,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0F766E),
                                    Color(0xFF0D9488),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488)
                                        .withValues(alpha: 0.38),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$_totalCartCount منتجات',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'سلة المشتريات جاهزة',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            'المجموع: ${_totalCartAmount.toStringAsFixed(0)} ر.ي',
                                            style: const TextStyle(
                                              color: Color(0xFFCCFBF1),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'إتمام الطلب',
                                          style: TextStyle(
                                            color: Color(0xFF0F766E),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Storefront Hero Banner displaying Company Logo & Salla/Zid Style Promises
  Widget _buildStoreHeroBanner({
    required String? logoPath,
    required String storeTitle,
    required String? addressText,
    required bool isStoreActive,
    required String? storePhone,
  }) {
    return Container(
      padding: EdgeInsets.all(_isMobileFrameMode ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF042F2E),
            Color(0xFF0D9488),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF042F2E).withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo (Prominently shown in the Storefront)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildStoreBrandLogo(
                  logoPath,
                  storeTitle,
                  size: _isMobileFrameMode ? 64 : 76,
                ),
              ),
              const SizedBox(width: 16),

              // Store Identity Header
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isStoreActive
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFFBBF24),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isStoreActive
                                ? 'متجر رسمي معتمد وموثق • طلب مباشر'
                                : 'المتجر في وضع المعاينة',
                            style: const TextStyle(
                              color: Color(0xFF99F6E4),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      storeTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isMobileFrameMode ? 20 : 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'تسوق باطمئنان • منتجات أصلية مضمونة 100% مع ميزة المعاينة قبل الاستلام والدفع عند التوصيل.',
                      style: TextStyle(
                        color: Color(0xFFCCFBF1),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    if (addressText != null &&
                        addressText.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Color(0xFF5EEAD4),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              addressText,
                              style: const TextStyle(
                                color: Color(0xFF99F6E4),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (storePhone != null &&
                  storePhone.trim().isNotEmpty &&
                  !_isMobileFrameMode)
                FilledButton.icon(
                  onPressed: () =>
                      _openWhatsAppStoreContact(storePhone, storeTitle),
                  icon: const Icon(Icons.chat_rounded, size: 17),
                  label: const Text(
                    'تواصل معنا واتساب',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),

          if (storePhone != null &&
              storePhone.trim().isNotEmpty &&
              _isMobileFrameMode) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _openWhatsAppStoreContact(storePhone, storeTitle),
                icon: const Icon(Icons.chat_rounded, size: 17),
                label: const Text(
                  'تواصل معنا واتساب',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF134E4A), height: 1),
          const SizedBox(height: 12),

          // Salla-style Trust Badges Strip
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _HeroTrustPill(
                icon: Icons.verified_user_outlined,
                title: 'منتجات أصلية 100%',
              ),
              _HeroTrustPill(
                icon: Icons.payments_outlined,
                title: 'دفع نقداً عند الاستلام',
              ),
              _HeroTrustPill(
                icon: Icons.local_shipping_outlined,
                title: 'توصيل سريع وموثوق',
              ),
              _HeroTrustPill(
                icon: Icons.support_agent_rounded,
                title: 'خدمة عملاء مباشرة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSearchAndCategories({
    required List<Category> categories,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن اسم المنتج، الوصف، أو الصنف...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF0D9488),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryPill(
                    id: null,
                    label: 'الكل',
                    isDark: isDark,
                  ),
                  for (final cat in categories) ...[
                    const SizedBox(width: 8),
                    _buildCategoryPill(
                      id: cat.id,
                      label: catalogDisplayName(cat.categoryName),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String? id,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D9488)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPublishedProductsCard(bool isDark, bool hasCatalogProducts) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 32,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'لا توجد منتجات منشورة في المتجر حتى الآن',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasCatalogProducts
                ? 'لديك منتجات في المخزون ولكنها مخفية عن المتجر حالياً. يمكنك تفعيلها بضغطة زر واحدة لتظهر لعملائك فوراً!'
                : 'قم بإضافة منتجاتك في الكتالوج وتفعيل خيار العرض في المتجر لتظهر لعملائك هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              if (hasCatalogProducts)
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(productsNotifierProvider.notifier)
                        .setAllStoreVisibility(true);
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text(
                    'إظهار جميع منتجاتي في المتجر الآن',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: widget.onNavigateToCatalog,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('إدارة كتالوج المتجر'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: Color(0xFF0D9488),
          ),
          const SizedBox(height: 10),
          const Text(
            'لم نتمكن من العثور على نتائج مطابقة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategoryId = null;
              });
            },
            child: const Text('إعادة تعيين الفلاتر وعرض كل المنتجات'),
          ),
        ],
      ),
    );
  }
}

class _HeroTrustPill extends StatelessWidget {
  final IconData icon;
  final String title;

  const _HeroTrustPill({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF5EEAD4)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Salla & Zid Style Product Card with clickable "Show" action & Add to Cart
class _CustomerProductCard extends StatelessWidget {
  final CatalogProductItem item;
  final String unitLabel;
  final String categoryLabel;
  final int inCartQty;
  final bool isDark;
  final VoidCallback onTapCard;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CustomerProductCard({
    required this.item,
    required this.unitLabel,
    required this.categoryLabel,
    required this.inCartQty,
    required this.isDark,
    required this.onTapCard,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.stockQuantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: inCartQty > 0
              ? const Color(0xFF0D9488)
              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          width: inCartQty > 0 ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Clickable Image / Showcase Area (Opens Product "Show" Modal)
          Expanded(
            child: InkWell(
              onTap: onTapCard,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF134E4A).withValues(alpha: 0.15),
                            const Color(0xFF0F172A),
                          ]
                        : [
                            const Color(0xFFCCFBF1).withValues(alpha: 0.45),
                            const Color(0xFFF0FDFA),
                          ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 44,
                        color: const Color(0xFF0D9488).withValues(alpha: 0.75),
                      ),
                    ),

                    // Category Pill (Top Right on RTL)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF0D9488)
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          categoryLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ),

                    // Stock Pill (Top Left on RTL)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAvailable ? 'متوفر' : 'نفد',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isAvailable
                                ? const Color(0xFF059669)
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ),

                    // Hover/Action "Show Details" Hint
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 11,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'معاينة',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Product Details & Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name (Clickable to Show Details)
                InkWell(
                  onTap: onTapCard,
                  child: Text(
                    item.product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Price & Unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${item.sellingPrice.toStringAsFixed(0)} ر.ي',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ $unitLabel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Dual Action Row: Quick Add to Cart & Inspect/Show Details
                if (inCartQty == 0)
                  Row(
                    children: [
                      // Direct "Show" Button
                      IconButton(
                        onPressed: onTapCard,
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                        tooltip: 'معاينة تفاصيل المنتج',
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Add to Cart CTA
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isAvailable ? onAdd : null,
                          icon: const Icon(
                            Icons.add_shopping_cart_rounded,
                            size: 15,
                          ),
                          label: Text(
                            isAvailable ? 'أضف للسلة' : 'غير متوفر',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: onRemove,
                          icon: const Icon(
                            Icons.remove_rounded,
                            size: 18,
                            color: Color(0xFF0D9488),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        InkWell(
                          onTap: onTapCard,
                          child: Text(
                            '$inCartQty في السلة',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onAdd,
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Color(0xFF0D9488),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCheckoutDialog extends StatefulWidget {
  final Map<String, _SimulatorCartItem> initialCart;
  final String? storeSlug;
  final ValueChanged<Map<String, _SimulatorCartItem>> onCartChanged;
  final ValueChanged<CreatedStorefrontOrderResult> onOrderCompleted;
  final VoidCallback onGoToMerchantOrders;

  const _CustomerCheckoutDialog({
    required this.initialCart,
    required this.storeSlug,
    required this.onCartChanged,
    required this.onOrderCompleted,
    required this.onGoToMerchantOrders,
  });

  @override
  State<_CustomerCheckoutDialog> createState() =>
      _CustomerCheckoutDialogState();
}

class _CustomerCheckoutDialogState extends State<_CustomerCheckoutDialog> {
  late Map<String, _SimulatorCartItem> _cart;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  CreatedStorefrontOrderResult? _completedOrder;

  @override
  void initState() {
    super.initState();
    _cart = Map<String, _SimulatorCartItem>.from(widget.initialCart);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _grandTotal =>
      _cart.values.fold<double>(0.0, (sum, item) => sum + item.lineTotal);

  void _fillDemoCustomerData() {
    setState(() {
      _nameController.text = 'محمد عبدالله الأحمدي';
      _phoneController.text = '777123456';
      _cityController.text = 'صنعاء';
      _addressController.text = 'شارع حدة - جوار جولة المصباحي - عمارة النور';
      _notesController.text = 'يرجى الاتصال قبل التوصيل بـ 15 دقيقة';
      _errorMessage = null;
    });
  }

  void _updateItemQty(String key, int delta) {
    setState(() {
      final item = _cart[key];
      if (item == null) return;
      final next = item.quantity + delta;
      if (next <= 0) {
        _cart.remove(key);
      } else {
        _cart[key] = item.copyWith(quantity: next);
      }
    });
    widget.onCartChanged(_cart);
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      setState(() => _errorMessage = 'سلة التسوق فارغة.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'يرجى كتابة الاسم الكريم للمستلم.');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'يرجى كتابة رقم الجوال لتنسيق التوصيل.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'يرجى تحديد عنوان التوصيل بالتفصيل.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final orderService = getIt<OnlineOrderService>();
    final items = _cart.values
        .map(
          (i) => StorefrontOrderItemInput(
            productId: i.catalogItem.product.id,
            productUnitId: i.selectedUnit.id,
            productName: i.catalogItem.product.productName,
            unitName: i.unitName,
            quantity: i.quantity.toDouble(),
            unitPrice: i.unitPrice,
          ),
        )
        .toList();

    final result = await orderService.createCustomerStorefrontOrder(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      shippingCity: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : 'صنعاء',
      shippingAddress: _addressController.text.trim(),
      customerNotes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      items: items,
      storeSlug: widget.storeSlug,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = failure.message;
        });
      },
      (orderResult) {
        setState(() {
          _isSubmitting = false;
          _completedOrder = orderResult;
        });
        widget.onOrderCompleted(orderResult);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: _completedOrder != null
          ? _buildSuccessView(isDark)
          : _buildCartAndFormView(isDark, border),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'تم إرسال طلبك بنجاح!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'رقم الطلب المرجعي: ${_completedOrder!.orderNumber}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D9488),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سيتم مراجعة الطلب من قبل المتجر والتواصل معك لتأكيد التوصيل والدفع عند الاستلام.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('إغلاق والعودة للتسوق'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onGoToMerchantOrders,
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text(
                  'إدارة هذا الطلب ككاشير',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartAndFormView(bool isDark, Color border) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      color: Color(0xFF0D9488),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'سلة المشتريات وإتمام الطلب',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Items in Cart List
          Text(
            'الأصناف المختارة (${_cart.length}):',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: _cart.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('سلة المشتريات فارغة حالياً'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: border, height: 1),
                    itemBuilder: (ctx, i) {
                      final key = _cart.keys.elementAt(i);
                      final item = _cart[key]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.catalogItem.product.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${item.unitPrice.toStringAsFixed(0)} ر.ي / ${item.unitName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () => _updateItemQty(key, -1),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () => _updateItemQty(key, 1),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.lineTotal.toStringAsFixed(0)} ر.ي',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0D9488),
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 10),
          // Total Amount Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي قيمة الطلب (شامل التوصيل والدفع عند الاستلام):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                '${_grandTotal.toStringAsFixed(0)} ر.ي',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D9488),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Demo Data Fill Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'بيانات المستلم وعنوان التوصيل:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              TextButton.icon(
                onPressed: _fillDemoCustomerData,
                icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                label: const Text(
                  'تعبئة بيانات تجريبية بنقرة واحدة',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Customer Inputs Grid
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المستلم *',
                    hintText: 'مثال: محمد الأحمدي',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف *',
                    hintText: '77xxxxxxx',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'المدينة',
                    hintText: 'صنعاء',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'العنوان التفصيلي للتوصيل *',
                    hintText: 'الشارع - جوار معلم بارز',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'ملاحظات إضافية على الطلب (اختياري)',
              hintText: 'مثال: موعد الاستلام المفضل، تعليمات التوصيل...',
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          // Submit Order CTA
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitOrder,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              _isSubmitting
                  ? 'جاري إرسال الطلب...'
                  : 'تأكيد الطلب والدفع عند الاستلام (${_grandTotal.toStringAsFixed(0)} ر.ي)',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
