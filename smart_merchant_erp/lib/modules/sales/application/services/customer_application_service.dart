import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../domain/repositories/sales_repository.dart';

class CustomerCommand {
  final String? id;
  final String name;
  final String? nameEn;
  final String? phone;
  final String? email;
  final String? taxNumber;
  final String? address;
  final double? creditLimit;
  final double? openingBalance;
  final String? openingBalanceType;
  final DateTime? openingBalanceDate;
  final bool isActive;

  const CustomerCommand({
    this.id,
    required this.name,
    this.nameEn,
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
class CustomerApplicationService {
  final SalesRepository _salesRepository;
  final ApplicationContext _context;
  final Uuid _uuid = const Uuid();

  CustomerApplicationService(this._salesRepository, this._context);

  Future<Either<Failure, String>> saveCustomer(CustomerCommand command) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final isNew = command.id == null || command.id!.isEmpty;
      final customerId = isNew ? _uuid.v4() : command.id!;

      final companion = CustomersCompanion(
        id: drift.Value(customerId),
        businessId: drift.Value(businessId),
        customerName: drift.Value(command.name),
        phone: drift.Value(command.phone),
        email: drift.Value(command.email),
        address: drift.Value(command.address),
        creditLimit: command.creditLimit != null ? drift.Value(command.creditLimit!) : const drift.Value.absent(),
        openingBalance: command.openingBalance != null ? drift.Value(command.openingBalance!) : const drift.Value.absent(),
        openingBalanceType: drift.Value(command.openingBalanceType),
        openingBalanceDate: drift.Value(command.openingBalanceDate),
        isActive: drift.Value(command.isActive),
        syncStatus: const drift.Value('pending'),
      );

      if (isNew) {
        await _salesRepository.insertCustomer(companion);
      } else {
        await _salesRepository.updateCustomer(companion);
      }

      return Right(customerId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteCustomer(String id) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      await _salesRepository.softDeleteCustomer(id, businessId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
