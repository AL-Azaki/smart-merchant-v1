import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'injection.dart';

// Repositories
import '../../modules/catalog/domain/repositories/catalog_repository.dart';
import '../../modules/sales/domain/repositories/sales_repository.dart';
import '../../modules/purchasing/domain/repositories/purchasing_repository.dart';
import '../../modules/inventory/domain/repositories/inventory_repository.dart';
import '../../modules/accounting/domain/repositories/accounting_repository.dart';
import '../../modules/treasury/domain/repositories/treasury_repository.dart';
import '../../modules/core/domain/repositories/core_repository.dart';
import '../../modules/system/domain/repositories/system_repository.dart';

// Use Cases
import '../../modules/sales/application/usecases/complete_sale_usecase.dart';
import '../../modules/purchasing/application/usecases/record_purchase_usecase.dart';
import '../../modules/purchasing/application/usecases/record_purchase_return_usecase.dart';
import '../../modules/inventory/application/usecases/process_warehouse_transfer_usecase.dart';
import '../../modules/accounting/application/usecases/post_journal_entry_usecase.dart';
import '../../modules/treasury/application/usecases/receive_payment_usecase.dart';

part 'getit_providers.g.dart';

// ==========================================
// REPOSITORIES (Read-Only Access via Riverpod)
// Note: As directed by architectural rules, we expose Repositories directly
// for purely read-only/reactive Stream operations because no specific
// Application Services exist for generic querying.
// ==========================================

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(CatalogRepositoryRef ref) {
  return getIt<CatalogRepository>();
}

@Riverpod(keepAlive: true)
SalesRepository salesRepository(SalesRepositoryRef ref) {
  return getIt<SalesRepository>();
}

@Riverpod(keepAlive: true)
PurchasingRepository purchasingRepository(PurchasingRepositoryRef ref) {
  return getIt<PurchasingRepository>();
}

@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(InventoryRepositoryRef ref) {
  return getIt<InventoryRepository>();
}

@Riverpod(keepAlive: true)
AccountingRepository accountingRepository(AccountingRepositoryRef ref) {
  return getIt<AccountingRepository>();
}

@Riverpod(keepAlive: true)
TreasuryRepository treasuryRepository(TreasuryRepositoryRef ref) {
  return getIt<TreasuryRepository>();
}

@Riverpod(keepAlive: true)
CoreRepository coreRepository(CoreRepositoryRef ref) {
  return getIt<CoreRepository>();
}

@Riverpod(keepAlive: true)
SystemRepository systemRepository(SystemRepositoryRef ref) {
  return getIt<SystemRepository>();
}

// ==========================================
// USE CASES (Mutations)
// ==========================================

@Riverpod(keepAlive: true)
CompleteSaleUseCase completeSaleUseCase(CompleteSaleUseCaseRef ref) {
  return getIt<CompleteSaleUseCase>();
}

@Riverpod(keepAlive: true)
RecordPurchaseUseCase recordPurchaseUseCase(RecordPurchaseUseCaseRef ref) {
  return getIt<RecordPurchaseUseCase>();
}

@Riverpod(keepAlive: true)
RecordPurchaseReturnUseCase recordPurchaseReturnUseCase(RecordPurchaseReturnUseCaseRef ref) {
  return getIt<RecordPurchaseReturnUseCase>();
}

@Riverpod(keepAlive: true)
ProcessWarehouseTransferUseCase processWarehouseTransferUseCase(
  ProcessWarehouseTransferUseCaseRef ref,
) {
  return getIt<ProcessWarehouseTransferUseCase>();
}

@Riverpod(keepAlive: true)
PostJournalEntryUseCase postJournalEntryUseCase(
  PostJournalEntryUseCaseRef ref,
) {
  return getIt<PostJournalEntryUseCase>();
}

@Riverpod(keepAlive: true)
ReceivePaymentUseCase receivePaymentUseCase(ReceivePaymentUseCaseRef ref) {
  return getIt<ReceivePaymentUseCase>();
}
