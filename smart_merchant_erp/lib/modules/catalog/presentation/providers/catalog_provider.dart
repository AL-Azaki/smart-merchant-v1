import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../app/di/injection.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../application/services/catalog_application_service.dart';
import '../../../../kernel/storage/app_database.dart' show Product, Category;
import '../../../../database/daos/catalog_dao.dart' show ProductFilter;
import '../../../authentication/presentation/providers/session_provider.dart';

import 'package:drift/drift.dart' show Value;

part 'catalog_provider.g.dart';

@riverpod
class ProductsNotifier extends _$ProductsNotifier {
  @override
  Stream<List<Product>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) return const Stream.empty();

    final repo = ref.watch(catalogRepositoryProvider);

    // Watch active, non-deleted products for this business
    return repo.watchProducts(
      ProductFilter(businessId: session.businessId!, isActive: true),
    );
  }

  Future<void> saveProduct(Map<String, dynamic> data) async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive) return;

    final service = getIt<CatalogApplicationService>();
    final id = data['id'] as String?;
    
    final command = ProductCommand(
      id: id,
      name: data['product_name'] ?? '',
      nameEn: data['name_en'],
      description: data['description'],
      categoryId: data['category_id'],
      brandId: data['brand_id'],
      isActive: data['is_active'] ?? true,
      trackStock: data['track_stock'] ?? true,
    );

    final result = await service.saveProduct(command);
    result.fold(
      (l) => throw Exception(l.message), // In a real app, handle failure properly
      (r) => null,
    );
  }

  Future<void> deleteProduct(String id) async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive) return;

    final service = getIt<CatalogApplicationService>();
    await service.deleteProduct(id);
  }
}

@riverpod
class CategoriesNotifier extends _$CategoriesNotifier {
  @override
  Stream<List<Category>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) return const Stream.empty();

    final repo = ref.watch(catalogRepositoryProvider);

    // Watch active, non-deleted categories for this business
    return repo.watchCategories(session.businessId!, isActive: true);
  }

  Future<void> saveCategory(Map<String, dynamic> data) async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive) return;

    final service = getIt<CatalogApplicationService>();
    final id = data['id'] as String?;
    
    final command = CategoryCommand(
      id: id,
      name: data['category_name'] ?? '',
      nameEn: data['name_en'],
      isActive: data['is_active'] ?? true,
    );

    final result = await service.saveCategory(command);
    result.fold(
      (l) => throw Exception(l.message),
      (r) => null,
    );
  }

  Future<void> deleteCategory(String id) async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive) return;

    final service = getIt<CatalogApplicationService>();
    await service.deleteCategory(id);
  }
}
