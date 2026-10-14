import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart' hide Unit;
import '../../domain/repositories/accounting_repository.dart';

class CreateAccountCommand {
  final String accountCode;
  final String accountName;
  final int accountTypeId;
  final String normalBalance;
  final String? parentAccountId;
  final String? currencyId;
  final String? description;
  final String? accountCategory;
  final bool allowPosting;

  const CreateAccountCommand({
    required this.accountCode,
    required this.accountName,
    required this.accountTypeId,
    required this.normalBalance,
    this.parentAccountId,
    this.currencyId,
    this.description,
    this.accountCategory,
    this.allowPosting = true,
  });
}

class UpdateAccountCommand {
  final String id;
  final String? accountName;
  final String? description;
  final String? accountCategory;
  final bool? allowPosting;
  final bool? isActive;

  const UpdateAccountCommand({
    required this.id,
    this.accountName,
    this.description,
    this.accountCategory,
    this.allowPosting,
    this.isActive,
  });
}

class AccountingApplicationService {
  final AccountingRepository _accountingRepository;
  final ApplicationContext _context;
  final Uuid _uuid = const Uuid();

  AccountingApplicationService(this._accountingRepository, this._context);

  /// Resolves the Chart of Account ID for a given mapping key.
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

  /// Creates a new chart of account record enforcing code uniqueness,
  /// parent validation, auto level computation, and parent postability lockdown.
  Future<Either<Failure, String>> createAccount(
    CreateAccountCommand cmd,
  ) async {
    try {
      final businessId = _context.currentBusinessId;
      if (businessId.isEmpty) {
        return const Left(ValidationFailure('Business context is required.'));
      }

      final code = cmd.accountCode.trim();
      if (code.isEmpty) {
        return const Left(ValidationFailure('Account code is required.'));
      }
      final name = cmd.accountName.trim();
      if (name.isEmpty) {
        return const Left(ValidationFailure('Account name is required.'));
      }

      // 1. Check duplicate account code
      final existing = await _accountingRepository.getChartOfAccountByCode(
        code,
        businessId,
      );
      if (existing != null) {
        return Left(
          DuplicateAccountCodeFailure(
            'رقم الحساب $code موجود مسبقاً في هذه المنشأة.',
          ),
        );
      }

      int computedLevel = 1;
      if (cmd.parentAccountId != null && cmd.parentAccountId!.isNotEmpty) {
        final parent = await _accountingRepository.getChartOfAccountById(
          cmd.parentAccountId!,
          businessId,
        );
        if (parent == null) {
          return const Left(
            ParentAccountNotFoundFailure('الحساب الأب المحدد غير موجود.'),
          );
        }
        computedLevel = parent.accountLevel + 1;

        // Invariant: Parent account must not accept direct postings
        if (parent.allowPosting) {
          await _accountingRepository.updateChartOfAccount(
            parent
                .toCompanion(false)
                .copyWith(allowPosting: const drift.Value(false)),
          );
        }
      }

      final accountId = _uuid.v4();
      await _accountingRepository.insertChartOfAccount(
        ChartOfAccountsCompanion.insert(
          id: accountId,
          businessId: businessId,
          accountCode: code,
          accountName: name,
          accountTypeId: cmd.accountTypeId,
          normalBalance: cmd.normalBalance,
          parentAccountId: drift.Value(cmd.parentAccountId),
          currencyId: drift.Value(cmd.currencyId),
          description: drift.Value(cmd.description),
          accountCategory: drift.Value(cmd.accountCategory),
          accountLevel: drift.Value(computedLevel),
          allowPosting: drift.Value(cmd.allowPosting),
          isActive: const drift.Value(true),
          isSystem: const drift.Value(false),
        ),
      );

      return Right(accountId);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Updates an account record safely.
  Future<Either<Failure, Unit>> updateAccount(
    UpdateAccountCommand cmd,
  ) async {
    try {
      final businessId = _context.currentBusinessId;
      final existing = await _accountingRepository.getChartOfAccountById(
        cmd.id,
        businessId,
      );
      if (existing == null) {
        return const Left(ValidationFailure('الحساب المطلوب غير موجود.'));
      }

      var companion = existing.toCompanion(false);
      if (cmd.accountName != null) {
        companion = companion.copyWith(
          accountName: drift.Value(cmd.accountName!.trim()),
        );
      }
      if (cmd.description != null) {
        companion = companion.copyWith(
          description: drift.Value(cmd.description),
        );
      }
      if (cmd.accountCategory != null) {
        companion = companion.copyWith(
          accountCategory: drift.Value(cmd.accountCategory),
        );
      }
      if (cmd.allowPosting != null) {
        // Cannot enable posting if this account has child accounts
        if (cmd.allowPosting == true) {
          final hasChildren = await _accountingRepository.hasChildAccounts(
            cmd.id,
            businessId,
          );
          if (hasChildren) {
            return const Left(
              ValidationFailure(
                'لا يمكن السماح بالترحيل لحساب رئيسي يحتوي على حسابات فرعية.',
              ),
            );
          }
        }
        companion = companion.copyWith(
          allowPosting: drift.Value(cmd.allowPosting!),
        );
      }
      if (cmd.isActive != null) {
        companion = companion.copyWith(
          isActive: drift.Value(cmd.isActive!),
        );
      }

      await _accountingRepository.updateChartOfAccount(companion);
      return const Right(unit);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Safely deletes an account only if it has zero transactions, zero children, and is not mapped.
  Future<Either<Failure, Unit>> safeDeleteAccount(String accountId) async {
    try {
      final businessId = _context.currentBusinessId;
      final account = await _accountingRepository.getChartOfAccountById(
        accountId,
        businessId,
      );
      if (account == null) {
        return const Left(ValidationFailure('الحساب المطلوب غير موجود.'));
      }

      // Check transactions
      final hasTx = await _accountingRepository.hasJournalEntries(
        accountId,
        businessId,
      );
      if (hasTx) {
        return const Left(
          AccountHasTransactionsFailure(
            'لا يمكن حذف حساب يحتوي على حركات مالية مسجلة.',
          ),
        );
      }

      // Check account mappings
      final isMapped = await _accountingRepository.isAccountMapped(
        accountId,
        businessId,
      );
      if (isMapped) {
        return const Left(
          AccountIsMappedFailure(
            'لا يمكن حذف حساب مرتبط بحسابات النظام الأساسية.',
          ),
        );
      }

      // Check child accounts
      final hasChildren = await _accountingRepository.hasChildAccounts(
        accountId,
        businessId,
      );
      if (hasChildren) {
        return const Left(
          AccountHasChildrenFailure(
            'لا يمكن حذف حساب رئيسي يحتوي على حسابات فرعية.',
          ),
        );
      }

      await _accountingRepository.deleteChartOfAccount(accountId, businessId);
      return const Right(unit);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Retrieves the hierarchical Chart of Accounts tree structure.
  Future<List<ChartOfAccountNode>> getChartOfAccountsTree() async {
    final businessId = _context.currentBusinessId;
    return _accountingRepository.getChartOfAccountsTree(businessId);
  }

  /// Returns a reactive stream of all accounts for the current business.
  Stream<List<ChartOfAccount>> watchAccounts() {
    final businessId = _context.currentBusinessId;
    return _accountingRepository.watchChartOfAccounts(
      ChartOfAccountFilter(businessId: businessId),
    );
  }
}

class AccountingConfigurationFailure extends Failure {
  const AccountingConfigurationFailure(super.message, [super.code]);
}

class DuplicateAccountCodeFailure extends Failure {
  const DuplicateAccountCodeFailure(super.message, [super.code]);
}

class ParentAccountNotFoundFailure extends Failure {
  const ParentAccountNotFoundFailure(super.message, [super.code]);
}

class AccountHasTransactionsFailure extends Failure {
  const AccountHasTransactionsFailure(super.message, [super.code]);
}

class AccountIsMappedFailure extends Failure {
  const AccountIsMappedFailure(super.message, [super.code]);
}

class AccountHasChildrenFailure extends Failure {
  const AccountHasChildrenFailure(super.message, [super.code]);
}
