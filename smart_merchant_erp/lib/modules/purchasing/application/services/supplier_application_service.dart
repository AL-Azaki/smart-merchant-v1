import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../domain/repositories/purchasing_repository.dart';

class SupplierCommand {
  final String? id;
  final String name;
  final String? nameEn;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? taxNumber;
  final String? address;
  final double? creditLimit;
  final double? openingBalance;
  final String? openingBalanceType;
  final DateTime? openingBalanceDate;
  final bool isActive;

  const SupplierCommand({
    this.id,
    required this.name,
    this.nameEn,
    this.contactPerson,
    this.phone,
    this.email,
    this.taxNumber,
    this.address,
    this.creditLimit,
    this.openingBalance,
    this.openingBalanceType,
    this.openingBalanceDate,
    this.isActive = true,
  });
}

@injectable
class SupplierApplicationService {
  final PurchasingRepository _purchasingRepository;
  final ApplicationContext _context;
  final Uuid _uuid = const Uuid();

  SupplierApplicationService(this._purchasingRepository, this._context);

  Future<Either<Failure, String>> saveSupplier(SupplierCommand command) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final isNew = command.id == null || command.id!.isEmpty;
      final supplierId = isNew ? _uuid.v4() : command.id!;

      final companion = SuppliersCompanion(
        id: drift.Value(supplierId),
        businessId: drift.Value(businessId),
        supplierName: drift.Value(command.name),
        contactPerson: drift.Value(command.contactPerson),
        phone: drift.Value(command.phone),
        supplierAddress: drift.Value(command.address),
        creditLimit: command.creditLimit != null ? drift.Value(command.creditLimit!) : const drift.Value.absent(),
        openingBalance: command.openingBalance != null ? drift.Value(command.openingBalance!) : const drift.Value.absent(),
        openingBalanceType: drift.Value(command.openingBalanceType),
        openingBalanceDate: drift.Value(command.openingBalanceDate),
        isActive: drift.Value(command.isActive),
        syncStatus: const drift.Value('pending'),
      );

      if (isNew) {
        await _purchasingRepository.insertSupplier(companion);
      } else {
        await _purchasingRepository.updateSupplier(companion);
      }

      return Right(supplierId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteSupplier(String id) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      await _purchasingRepository.softDeleteSupplier(id, businessId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
