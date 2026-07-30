import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../domain/repositories/hr_repository.dart';

class EmployeeCommand {
  final String? id;
  final String employeeCode;
  final String name;
  final String? nameEn;
  final String? phone;
  final String? email;
  final String? jobTitle;
  final String? departmentId;
  final DateTime? hireDate;
  final bool isActive;
  final double? salary;

  const EmployeeCommand({
    this.id,
    required this.employeeCode,
    required this.name,
    this.nameEn,
    this.phone,
    this.email,
    this.jobTitle,
    this.departmentId,
    this.hireDate,
    this.isActive = true,
    this.salary,
  });
}

class EmployeeApplicationService {
  final HrRepository _hrRepository;
  final ApplicationContext _context;
  final Uuid _uuid = const Uuid();

  EmployeeApplicationService(this._hrRepository, this._context);

  Future<Either<Failure, String>> saveEmployee(EmployeeCommand command) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      final isNew = command.id == null || command.id!.isEmpty;
      final employeeId = isNew ? _uuid.v4() : command.id!;

      final companion = EmployeesCompanion(
        id: drift.Value(employeeId),
        businessId: drift.Value(businessId),
        employeeCode: drift.Value(command.employeeCode),
        firstName: drift.Value(command.name),
        lastName: drift.Value(command.nameEn ?? ''),
        phone: drift.Value(command.phone),
        email: drift.Value(command.email),
        departmentId: drift.Value(command.departmentId),
        hireDate: drift.Value(command.hireDate ?? DateTime.now()),
        currencyId: drift.Value('YER'), // Using YER as default from ProjectUI
        status: drift.Value(command.isActive ? 'Active' : 'Terminated'),
        salary: drift.Value(command.salary ?? 0.0),
        syncStatus: const drift.Value('pending'),
      );

      if (isNew) {
        await _hrRepository.insertEmployee(companion);
      } else {
        await _hrRepository.updateEmployee(companion);
      }

      return Right(employeeId);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteEmployee(String id) async {
    final businessId = _context.currentBusinessId;
    if (businessId == null) {
      return const Left(ValidationFailure('Business ID is required.'));
    }

    try {
      await _hrRepository.softDeleteEmployee(id, businessId);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
