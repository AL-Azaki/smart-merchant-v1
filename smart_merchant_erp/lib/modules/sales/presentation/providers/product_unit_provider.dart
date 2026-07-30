import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/catalog_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

part 'product_unit_provider.g.dart';

class PosProductItem {
  final Product product;
  final ProductUnit baseUnit;
  final double sellingPrice;

  const PosProductItem({
    required this.product,
    required this.baseUnit,
    required this.sellingPrice,
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

    // Watch active products
    final productsStream = catalogRepo.watchProducts(
      ProductFilter(businessId: session.businessId!, isActive: true),
    );

    // Yield mapped products
    await for (final products in productsStream) {
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

          items.add(
            PosProductItem(
              product: product,
              baseUnit: baseUnit,
              sellingPrice: baseUnit.sellingPrice,
            ),
          );
        }
      }
      yield items;
    }
  }
}
