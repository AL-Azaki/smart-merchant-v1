import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../domain/repositories/catalog_repository.dart';
import '../../../inventory/application/usecases/process_stock_adjustment_usecase.dart';

class ProductCommand {
  final String? id;
  final String name;
  final String? nameEn;
  final String? description;
  final String? categoryId;
  final String? brandId;
  final String? sku;
  final String? barcode;
  final String? unitId;
  final double? purchasePrice;
  final double? sellingPrice;
  final bool isActive;
  final bool trackStock;
  final String? imagePath;
  final String? currencyId;
  final bool showInStore;
  final String? openingWarehouseId;
  final double? openingQuantity;

  const ProductCommand({
    this.id,
    required this.name,
    this.nameEn,
    this.description,
    this.categoryId,
    this.brandId,
    this.sku,
    this.barcode,
    this.unitId,
    this.purchasePrice,
    this.sellingPrice,
    this.isActive = true,
    this.trackStock = true,
    this.imagePath,
    this.currencyId,
    this.showInStore = false,
    this.openingWarehouseId,
    this.openingQuantity,
  });
}

class CategoryCommand {
  final String? id;
  final String name;
  final String? nameEn;
  final String? description;
  final String? parentId;
  final bool isActive;

  const CategoryCommand({
    this.id,
    required this.name,
    this.nameEn,
    this.description,
    this.parentId,
    this.isActive = true,
  });
}

class UnitCommand {
  final String? id;
  final String name;
  final String symbol;

  const UnitCommand({
    this.id,
    required this.name,
    required this.symbol,
  });
}

@injectable
class CatalogApplicationService {
  final CatalogRepository _catalogRepository;
  final ApplicationContext _context;
  final ProcessStockAdjustmentUseCase _processStockAdjustmentUseCase;
  final Uuid _uuid = const Uuid();

  CatalogApplicationService(this._catalogRepository, this._context, this._processStockAdjustmentUseCase);

  Future<Either<Failure, String>> saveProduct(ProductCommand command) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final isNew = command.id == null || command.id!.isEmpty;
      final productId = isNew ? _uuid.v4() : command.id!;

      final companion = ProductsCompanion(
        id: drift.Value(productId),
        businessId: drift.Value(businessId),
        categoryId: drift.Value(command.categoryId),
        currencyId: drift.Value(command.currencyId),
        productName: drift.Value(command.name),
        productCode: drift.Value(command.sku ?? 'PRD-${DateTime.now().millisecondsSinceEpoch}'),
        description: drift.Value(command.description),
        isActive: drift.Value(command.isActive),
        showInStore: drift.Value(command.showInStore),
        syncStatus: const drift.Value('pending'),
      );
      List<ProductImagesCompanion> images = [];
      if (command.imagePath != null && command.imagePath!.isNotEmpty) {
         images.add(ProductImagesCompanion(
           id: drift.Value(_uuid.v4()),
           productId: drift.Value(productId),
           imagePath: drift.Value(command.imagePath!),
           isPrimary: const drift.Value(true),
           syncStatus: const drift.Value('pending'),
         ));
      }

      String? createdUnitId;

      if (isNew) {
        if (command.unitId != null && command.unitId!.isNotEmpty) {
           final unitIdStr = _uuid.v4();
           createdUnitId = unitIdStr;
           final unitsCompanion = ProductUnitsCompanion(
             id: drift.Value(unitIdStr),
             businessId: drift.Value(businessId),
             productId: drift.Value(productId),
             unitId: drift.Value(command.unitId!),
             barcode: drift.Value(command.barcode),
             purchasePrice: drift.Value(command.purchasePrice ?? 0.0),
             sellingPrice: drift.Value(command.sellingPrice ?? 0.0),
             minimumPrice: const drift.Value(0.0),
             isBaseUnit: const drift.Value(true),
             isActive: const drift.Value(true),
             syncStatus: const drift.Value('pending'),
           );
           await _catalogRepository.createProductWithDetails(
             product: companion,
             units: [unitsCompanion],
             images: images,
           );
        } else {
           await _catalogRepository.createProductWithDetails(
             product: companion,
             units: [],
             images: images,
           );
        }
      } else {
        await _catalogRepository.updateProduct(companion);
        if (images.isNotEmpty) {
           final existingImages = await _catalogRepository.getProductImagesByProductId(productId);
           for (var img in existingImages) {
             await _catalogRepository.deleteProductImage(img.id);
           }
           await _catalogRepository.insertProductImage(images.first);
        }
        if (command.unitId != null && command.unitId!.isNotEmpty) {
           final existingUnits = await _catalogRepository.listProductUnitsByProductId(productId, businessId);
           final existingBase = existingUnits.where((u) => u.isBaseUnit).firstOrNull ?? existingUnits.firstOrNull;
           if (existingBase != null) {
              await _catalogRepository.updateProductUnit(ProductUnitsCompanion(
                id: drift.Value(existingBase.id),
                barcode: drift.Value(command.barcode),
                purchasePrice: drift.Value(command.purchasePrice ?? 0.0),
                sellingPrice: drift.Value(command.sellingPrice ?? 0.0),
                unitId: drift.Value(command.unitId!),
                syncStatus: const drift.Value('pending'),
              ));
           } else {
              final unitIdStr = _uuid.v4();
              await _catalogRepository.insertProductUnit(ProductUnitsCompanion(
                 id: drift.Value(unitIdStr),
                 businessId: drift.Value(businessId),
                 productId: drift.Value(productId),
                 unitId: drift.Value(command.unitId!),
                 barcode: drift.Value(command.barcode),
                 purchasePrice: drift.Value(command.purchasePrice ?? 0.0),
                 sellingPrice: drift.Value(command.sellingPrice ?? 0.0),
                 minimumPrice: const drift.Value(0.0),
                 isBaseUnit: const drift.Value(true),
                 isActive: const drift.Value(true),
                 syncStatus: const drift.Value('pending'),
              ));
           }
        }
      }

      // Record Opening Stock if applicable
      if (isNew && command.openingWarehouseId != null && command.openingQuantity != null && command.openingQuantity! > 0) {
        if (createdUnitId != null) {
          await _processStockAdjustmentUseCase(ProcessStockAdjustmentCommand(
            warehouseId: command.openingWarehouseId!,
            notes: 'Opening stock for newly created product',
            items: [
              StockAdjustmentItemCommand(
                productUnitId: createdUnitId,
                countedQuantity: command.openingQuantity!,
                expectedQuantity: 0,
                difference: command.openingQuantity!,
              )
            ]
          ));
        }
      }

      return Right(productId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteProduct(String id) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      await _catalogRepository.softDeleteProduct(id, businessId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, String>> saveCategory(CategoryCommand command) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final isNew = command.id == null || command.id!.isEmpty;
      final categoryId = isNew ? _uuid.v4() : command.id!;

      if (isNew) {
        final insertCompanion = CategoriesCompanion.insert(
          id: categoryId,
          businessId: businessId,
          parentId: drift.Value(command.parentId),
          categoryName: command.name,
          description: drift.Value(command.description),
          isActive: drift.Value(command.isActive),
          syncStatus: const drift.Value('pending'),
        );
        await _catalogRepository.insertCategory(insertCompanion);
      } else {
        final updateCompanion = CategoriesCompanion(
          id: drift.Value(categoryId),
          businessId: drift.Value(businessId),
          parentId: drift.Value(command.parentId),
          categoryName: drift.Value(command.name),
          description: drift.Value(command.description),
          isActive: drift.Value(command.isActive),
          syncStatus: const drift.Value('pending_update'),
        );
        await _catalogRepository.updateCategory(updateCompanion);
      }

      return Right(categoryId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      await _catalogRepository.softDeleteCategory(id, businessId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, String>> saveUnit(UnitCommand command) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final isNew = command.id == null || command.id!.isEmpty;
      final unitId = isNew ? _uuid.v4() : command.id!;

      final companion = UnitsCompanion(
        id: drift.Value(unitId),
        businessId: drift.Value(businessId),
        unitName: drift.Value(command.name),
        unitSymbol: drift.Value(command.symbol),
        syncStatus: const drift.Value('pending'),
      );

      if (isNew) {
        await _catalogRepository.insertUnit(companion);
      } else {
        await _catalogRepository.updateUnit(companion);
      }

      return Right(unitId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteUnit(String id) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      await _catalogRepository.softDeleteUnit(id, businessId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
