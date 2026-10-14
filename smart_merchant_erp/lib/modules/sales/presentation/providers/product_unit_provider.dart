import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/catalog_dao.dart';
import '../../../../database/daos/inventory_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

part 'product_unit_provider.g.dart';

class PosProductItem {
  final Product product;
  final ProductUnit baseUnit;
  final double sellingPrice;
  final List<ProductUnit> units;
  final double stockQuantity;

  const PosProductItem({
    required this.product,
    required this.baseUnit,
    required this.sellingPrice,
    this.units = const [],
    this.stockQuantity = 0.0,
  });
}

@riverpod
class PosProductsNotifier extends _$PosProductsNotifier {
  @override
  Stream<List<PosProductItem>> build() async* {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) {
      yield [];
      return;
    }

    final catalogRepo = ref.watch(catalogRepositoryProvider);
    final inventoryRepo = ref.watch(inventoryRepositoryProvider);

    // Watch active products
    final productsStream = catalogRepo.watchProducts(
      ProductFilter(businessId: session.businessId!, isActive: true),
    );

    // Yield mapped products with live stock
    await for (final products in productsStream) {
      final inventories = await inventoryRepo.listInventories(
        InventoryFilter(businessId: session.businessId!),
      );
      final stockMap = <String, double>{};
      for (final inv in inventories) {
        stockMap[inv.productUnitId] =
            (stockMap[inv.productUnitId] ?? 0.0) + inv.quantity;
      }

      final List<PosProductItem> items = [];
      for (final product in products) {
        // Fetch product units for this product
        final units = await catalogRepo.listProductUnitsByProductId(
          product.id,
          session.businessId!,
        );

        if (units.isNotEmpty) {
          // Find the base unit, or just take the first one
          final baseUnit = units.firstWhere(
            (u) => u.isBaseUnit,
            orElse: () => units.first,
          );

          final stock = stockMap[baseUnit.id] ?? 0.0;

          items.add(
            PosProductItem(
              product: product,
              baseUnit: baseUnit,
              sellingPrice: baseUnit.sellingPrice,
              units: units,
              stockQuantity: stock,
            ),
          );
        } else {
          final fallbackUnit = ProductUnit(
            id: 'unit_${product.id}',
            businessId: product.businessId,
            productId: product.id,
            unitId: 'unit_piece',
            conversionFactor: 1.0,
            purchasePrice: 0.0,
            sellingPrice: 0.0,
            minimumPrice: 0.0,
            isBaseUnit: true,
            isActive: true,
            syncStatus: 'synced',
            version: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          items.add(
            PosProductItem(
              product: product,
              baseUnit: fallbackUnit,
              sellingPrice: 0.0,
              units: [fallbackUnit],
            ),
          );
        }
      }
      yield items;
    }
  }
}
