import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../domain/repositories/accounting_repository.dart';

@injectable
class AccountingApplicationService {
  final AccountingRepository _accountingRepository;
  final ApplicationContext _context;

  AccountingApplicationService(this._accountingRepository, this._context);

  /// Resolves the Chart of Account ID for a given mapping key (e.g., 'accounts_receivable', 'sales_revenue').
  /// Throws [AccountingConfigurationFailure] if the mapping is missing or inactive.
  Future<Either<Failure, String>> resolveAccountMapping(
    String mappingKey,
  ) async {
    try {
      final businessId = _context.currentBusinessId;
      final mapping = await _accountingRepository.getAccountMappingByKey(
        mappingKey,
        businessId,
      );

      if (mapping == null) {
        return Left(
          AccountingConfigurationFailure(
            'Required account mapping missing: $mappingKey',
          ),
        );
      }
      if (!mapping.isActive) {
        return Left(
          AccountingConfigurationFailure(
            'Account mapping is inactive: $mappingKey',
          ),
        );
      }

      // Ensure the chart of account exists and is active
      final account = await _accountingRepository.getChartOfAccountById(
        mapping.chartOfAccountId,
        businessId,
      );
      if (account == null) {
        return Left(
          AccountingConfigurationFailure(
            'Mapped account not found for key: $mappingKey',
          ),
        );
      }
      if (!account.isActive) {
        return Left(
          AccountingConfigurationFailure(
            'Mapped account is inactive: $mappingKey',
          ),
        );
      }

      return Right(mapping.chartOfAccountId);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}

class AccountingConfigurationFailure extends Failure {
  const AccountingConfigurationFailure(super.message, [super.code]);
}
