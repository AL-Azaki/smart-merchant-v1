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
  final int? accountTypeId;
  final String? normalBalance;
  final String? parentAccountId;
  final String? currencyId;
  final String? description;
  final String? accountCategory;
  final bool allowPosting;

  const CreateAccountCommand({
    this.accountCode = '',
    required this.accountName,
    this.accountTypeId,
    this.normalBalance,
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
        return const Left(ValidationFailure('يرجى اختيار المنشأة أولاً.'));
      }
      final name = cmd.accountName.trim();
      if (name.isEmpty) {
        return const Left(ValidationFailure('أدخل اسم الحساب.'));
      }
      return await _accountingRepository.runInTransaction(() async {
        final parentId = cmd.parentAccountId?.trim();
        ChartOfAccount? parent;
        if (parentId != null && parentId.isNotEmpty) {
          parent = await _accountingRepository.getChartOfAccountById(
            parentId,
            businessId,
          );
          if (parent == null) {
            return const Left(
              ParentAccountNotFoundFailure(
                'الحساب الأب المحدد غير موجود في هذه المنشأة.',
              ),
            );
          }
          if (!parent.isActive) {
            return const Left(ValidationFailure('اختر حساباً أباً نشطاً.'));
          }
          if (parent.allowPosting &&
              await _accountingRepository.isAccountMapped(
                parent.id,
                businessId,
              )) {
            return const Left(
              ValidationFailure(
                'الحساب الأب مرتبط بالعمليات الأساسية. اختر حساباً تجميعياً آخر.',
              ),
            );
          }
          if (parent.allowPosting &&
              await _accountingRepository.hasJournalEntries(
                parent.id,
                businessId,
              )) {
            return const Left(
              ValidationFailure(
                'الحساب الأب لديه حركات مالية. اختر حساباً تجميعياً آخر.',
              ),
            );
          }
        }
        final typeId = parent?.accountTypeId ?? cmd.accountTypeId;
        final normalBalance = parent?.normalBalance ?? cmd.normalBalance;
        if (typeId == null ||
            typeId < 1 ||
            typeId > 5 ||
            !['Debit', 'Credit'].contains(normalBalance)) {
          return const Left(
            ValidationFailure('اختر الحساب الأب لتحديد نوع الحساب وطبيعته.'),
          );
        }
        var code = cmd.accountCode.trim();
        if (code.isEmpty) {
          if (parent == null) {
            return const Left(
              ValidationFailure('اختر الحساب الأب لإنشاء رقم الحساب تلقائياً.'),
            );
          }
          final accounts = await _accountingRepository.listChartOfAccounts(
            ChartOfAccountFilter(businessId: businessId, limit: null),
          );
          final usedCodes = accounts.map((a) => a.accountCode).toSet();
          var largest = BigInt.zero;
          var width = 2;
          var foundSibling = false;
          for (final account in accounts.where(
            (a) => a.parentAccountId == parent!.id,
          )) {
            if (!account.accountCode.startsWith(parent.accountCode)) continue;
            final suffix = account.accountCode.substring(
              parent.accountCode.length,
            );
            final number = BigInt.tryParse(suffix);
            if (number == null || number < BigInt.zero) continue;
            if (!foundSibling) {
              width = suffix.length;
              foundSibling = true;
            } else if (suffix.length > width) {
              width = suffix.length;
            }
            if (number > largest) largest = number;
          }
          do {
            largest += BigInt.one;
            code =
                '${parent.accountCode}${largest.toString().padLeft(width, '0')}';
          } while (usedCodes.contains(code));
        } else {
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
        }
        final accountId = _uuid.v4();
        if (parent != null && parent.allowPosting) {
          await _accountingRepository.updateChartOfAccount(
            parent
                .toCompanion(false)
                .copyWith(
                  allowPosting: const drift.Value(false),
                  syncStatus: const drift.Value('pending'),
                  version: drift.Value(parent.version + 1),
                  updatedAt: drift.Value(DateTime.now()),
                ),
          );
        }
        await _accountingRepository.insertChartOfAccount(
          ChartOfAccountsCompanion.insert(
            id: accountId,
            businessId: businessId,
            accountCode: code,
            accountName: name,
            accountTypeId: typeId,
            normalBalance: normalBalance!,
            parentAccountId: drift.Value(parent?.id),
            currencyId: drift.Value(cmd.currencyId ?? parent?.currencyId),
            description: drift.Value(cmd.description),
            accountCategory: drift.Value(cmd.accountCategory),
            accountLevel: drift.Value(
              parent == null ? 1 : parent.accountLevel + 1,
            ),
            allowPosting: drift.Value(cmd.allowPosting),
            isActive: const drift.Value(true),
            isSystem: const drift.Value(false),
          ),
        );
        return Right(accountId);
      });
    } catch (e) {
      if (e is Failure) return Left(e);
      return const Left(UnexpectedFailure('تعذر حفظ الحساب. حاول مرة أخرى.'));
    }
  }

  /// Updates an account record safely.
  Future<Either<Failure, Unit>> updateAccount(UpdateAccountCommand cmd) async {
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
        companion = companion.copyWith(isActive: drift.Value(cmd.isActive!));
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
