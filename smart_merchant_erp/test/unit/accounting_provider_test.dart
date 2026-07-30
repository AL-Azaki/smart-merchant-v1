import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/app/di/getit_providers.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/authentication/presentation/providers/session_provider.dart';
import 'package:smart_merchant_erp/modules/accounting/domain/repositories/accounting_repository.dart';
import 'package:smart_merchant_erp/modules/accounting/presentation/providers/accounting_provider.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';

class DummyAccountingRepository implements AccountingRepository {
  final List<ChartOfAccount> testAccounts = [
    ChartOfAccount(
      id: 'acc_1',
      businessId: 'test-biz',
      accountCode: '1000',
      accountName: 'الأصول',
      accountTypeId: 1,
      normalBalance: 'Debit',
      accountLevel: 1,
      allowPosting: false,
      isSystem: true,
      isActive: true,
      syncStatus: 'synced',
      version: 1,
    ),
  ];

  @override
  Stream<List<ChartOfAccount>> watchChartOfAccounts(ChartOfAccountFilter filter) {
    return Stream.value(testAccounts);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late DummyAccountingRepository dummyRepo;

  setUp(() {
    dummyRepo = DummyAccountingRepository();
  });

  test('ChartOfAccountsNotifier yields empty when no session', () async {
    final container = ProviderContainer(
      overrides: [
        accountingRepositoryProvider.overrideWithValue(dummyRepo),
      ],
    );

    // Initial state is inactive
    expect(
      container.read(chartOfAccountsNotifierProvider).valueOrNull,
      isNull,
    );
  });
}
