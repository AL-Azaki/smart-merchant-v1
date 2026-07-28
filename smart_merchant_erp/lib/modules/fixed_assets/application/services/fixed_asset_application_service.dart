import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../domain/repositories/fixed_assets_repository.dart';

class FixedAssetCommand {
  final String? id;
  final String assetCode;
  final String assetName;
  final String? nameEn;
  final String? assetCategoryId;
  final String? locationId;
  final String? employeeId;
  final double purchasePrice;
  final double salvageValue;
  final double currentBookValue;
  final DateTime purchaseDate;
  final DateTime? capitalizationDate;
  final int usefulLifeMonths;
  final String depreciationMethod;
  final String status;
  final bool isActive;

  const FixedAssetCommand({
    this.id,
    required this.assetCode,
    required this.assetName,
    this.nameEn,
    this.assetCategoryId,
    this.locationId,
    this.employeeId,
    required this.purchasePrice,
    this.salvageValue = 0.0,
    required this.currentBookValue,
    required this.purchaseDate,
    this.capitalizationDate,
    required this.usefulLifeMonths,
    this.depreciationMethod = 'straight_line',
    this.status = 'active',
    this.isActive = true,
  });
}

@injectable
class FixedAssetApplicationService {
  final FixedAssetsRepository _fixedAssetsRepository;
  final ApplicationContext _context;
  final Uuid _uuid = const Uuid();

  FixedAssetApplicationService(this._fixedAssetsRepository, this._context);

  Future<Either<Failure, String>> saveFixedAsset(FixedAssetCommand command) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    if (businessId.isEmpty) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final isNew = command.id == null || command.id!.isEmpty;
      final assetId = isNew ? _uuid.v4() : command.id!;

      final companion = FixedAssetsCompanion(
        id: drift.Value(assetId),
        businessId: drift.Value(businessId),
        branchId: branchId != null ? drift.Value(branchId) : const drift.Value.absent(),
        assetCode: drift.Value(command.assetCode),
        assetName: drift.Value(command.assetName),
        assetCategoryId: drift.Value(command.assetCategoryId == 'أجهزة إلكترونية' || command.assetCategoryId == 'أثاث ومعدات' || command.assetCategoryId == 'مركبات ووسائل نقل' ? null : command.assetCategoryId),
        acquisitionDate: drift.Value(command.purchaseDate),
        acquisitionCost: drift.Value(command.purchasePrice),
        baseAcquisitionCost: drift.Value(command.purchasePrice), // assuming 1:1 for simplicity
        usefulLife: drift.Value(command.usefulLifeMonths),
        residualValue: drift.Value(command.salvageValue),
        baseResidualValue: drift.Value(command.salvageValue),
        depreciationMethod: drift.Value(command.depreciationMethod),
        depreciationStartDate: drift.Value(command.capitalizationDate ?? command.purchaseDate),
        status: drift.Value(command.isActive ? 'Active' : 'Draft'),
        currencyId: const drift.Value('YER'), // Use QA default currency
        createdBy: drift.Value(_context.currentUserId),
        syncStatus: const drift.Value('pending'),
      );

      if (isNew) {
        await _fixedAssetsRepository.insertFixedAsset(companion);
      } else {
        await _fixedAssetsRepository.updateFixedAsset(companion);
      }

      return Right(assetId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
