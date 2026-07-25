import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../domain/repositories/catalog_repository.dart';

class ProductCommand {
  final String? id;
  final String name;
  final String? nameEn;
  final String? description;
  final String? categoryId;
  final String? brandId;
  final String? sku;
  final bool isActive;
  final bool trackStock;

  const ProductCommand({
    this.id,
    required this.name,
    this.nameEn,
    this.description,
    this.categoryId,
    this.brandId,
    this.sku,
    this.isActive = true,
    this.trackStock = true,
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
  final Uuid _uuid = const Uuid();

  CatalogApplicationService(this._catalogRepository, this._context);

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
        productName: drift.Value(command.name),
        productCode: drift.Value(command.sku ?? 'PRD-${DateTime.now().millisecondsSinceEpoch}'),
        description: drift.Value(command.description),
        isActive: drift.Value(command.isActive),
        syncStatus: const drift.Value('pending'),
      );

      if (isNew) {
        await _catalogRepository.insertProduct(companion);
      } else {
        await _catalogRepository.updateProduct(companion);
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

      final companion = CategoriesCompanion(
        id: drift.Value(categoryId),
        businessId: drift.Value(businessId),
        parentId: drift.Value(command.parentId),
        categoryName: drift.Value(command.name),
        description: drift.Value(command.description),
        isActive: drift.Value(command.isActive),
        syncStatus: const drift.Value('pending'),
      );

      if (isNew) {
        await _catalogRepository.insertCategory(companion);
      } else {
        await _catalogRepository.updateCategory(companion);
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
