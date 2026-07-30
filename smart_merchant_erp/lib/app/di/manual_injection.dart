import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../config/api_client.dart';
import '../config/app_environment.dart';
import '../../kernel/core/application_context.dart';
import '../../kernel/core/transaction_runner.dart';
import '../../kernel/storage/app_database.dart';
import '../../kernel/storage/secure_storage/secure_storage_contract.dart';
import '../../kernel/storage/secure_storage/flutter_secure_storage_impl.dart';
import '../../kernel/sync/api/sync_remote_api_client.dart';
import '../../kernel/sync/coordinator/sync_coordinator.dart';
import '../../kernel/network/connectivity/network_monitor.dart';

import '../../database/daos/auth_dao.dart';
import '../../database/daos/core_dao.dart';
import '../../database/daos/catalog_dao.dart';
import '../../database/daos/inventory_dao.dart';
import '../../database/daos/sales_dao.dart';
import '../../database/daos/purchasing_dao.dart';
import '../../database/daos/accounting_dao.dart';
import '../../database/daos/treasury_dao.dart';
import '../../database/daos/hr_dao.dart';
import '../../database/daos/fixed_assets_dao.dart';
import '../../database/daos/system_dao.dart';

import '../../modules/authentication/infrastructure/api/auth_remote_api_client.dart';
import '../../modules/authentication/infrastructure/data_sources/auth_local_data_source.dart';
import '../../modules/authentication/domain/repositories/auth_repository.dart';
import '../../modules/authentication/infrastructure/repositories/auth_repository_impl.dart';

import '../../modules/core/domain/repositories/core_repository.dart';
import '../../modules/core/infrastructure/repositories/core_repository_impl.dart';

import '../../modules/catalog/domain/repositories/catalog_repository.dart';
import '../../modules/catalog/infrastructure/repositories/catalog_repository_impl.dart';
import '../../modules/catalog/application/services/catalog_application_service.dart';

import '../../modules/inventory/domain/repositories/inventory_repository.dart';
import '../../modules/inventory/infrastructure/repositories/inventory_repository_impl.dart';
import '../../modules/inventory/application/services/warehouse_context_service.dart';
import '../../modules/inventory/application/usecases/get_stock_counts_usecase.dart';
import '../../modules/inventory/application/usecases/get_stock_count_details_usecase.dart';
import '../../modules/inventory/application/usecases/post_stock_count_usecase.dart';
import '../../modules/inventory/application/usecases/process_stock_adjustment_usecase.dart';
import '../../modules/inventory/application/usecases/process_warehouse_transfer_usecase.dart';
import '../../modules/inventory/application/usecases/save_stock_count_usecase.dart';

import '../../modules/sales/domain/repositories/sales_repository.dart';
import '../../modules/sales/infrastructure/repositories/sales_repository_impl.dart';
import '../../modules/sales/application/services/customer_application_service.dart';
import '../../modules/sales/application/services/online_order_service.dart';
import '../../modules/sales/application/usecases/complete_sale_usecase.dart';
import '../../modules/sales/application/usecases/process_sales_return_usecase.dart';
import '../../modules/sales/presentation/mappers/sales_invoice_document_mapper.dart';

import '../../modules/purchasing/domain/repositories/purchasing_repository.dart';
import '../../modules/purchasing/infrastructure/repositories/purchasing_repository_impl.dart';
import '../../modules/purchasing/application/services/supplier_application_service.dart';
import '../../modules/purchasing/application/usecases/record_purchase_return_usecase.dart';
import '../../modules/purchasing/application/usecases/record_purchase_usecase.dart';
import '../../modules/purchasing/presentation/mappers/purchase_invoice_document_mapper.dart';

import '../../modules/accounting/domain/repositories/accounting_repository.dart';
import '../../modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import '../../modules/accounting/application/services/accounting_application_service.dart';
import '../../modules/accounting/application/usecases/post_journal_entry_usecase.dart';

import '../../modules/treasury/domain/repositories/treasury_repository.dart';
import '../../modules/treasury/infrastructure/repositories/treasury_repository_impl.dart';
import '../../modules/treasury/application/usecases/receive_payment_usecase.dart';

import '../../modules/hr/domain/repositories/hr_repository.dart';
import '../../modules/hr/infrastructure/repositories/hr_repository_impl.dart';
import '../../modules/hr/application/services/employee_application_service.dart';

import '../../modules/fixed_assets/domain/repositories/fixed_assets_repository.dart';
import '../../modules/fixed_assets/infrastructure/repositories/fixed_assets_repository_impl.dart';
import '../../modules/fixed_assets/application/services/fixed_asset_application_service.dart';

import '../../modules/system/domain/repositories/system_repository.dart';
import '../../modules/system/infrastructure/repositories/system_repository_impl.dart';
import '../../modules/system/application/services/archive_document_service.dart';
import '../../modules/system/application/services/document_application_service.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  getIt.registerLazySingleton(() => Dio());
  getIt.registerLazySingleton(() => SessionHolder());
  getIt.registerLazySingleton<ApplicationContext>(() => RuntimeApplicationContext(getIt()));
  getIt.registerLazySingleton<SecureStorageContract>(() => FlutterSecureStorageImpl());
  
  getIt.registerLazySingleton(() => AppEnvironment.current);
  getIt.registerLazySingleton(() => ApiClient(environment: getIt(), secureStorage: getIt()));
  getIt.registerLazySingleton(() => AuthRemoteApiClient(getIt()));
  getIt.registerLazySingleton(() => SyncRemoteApiClient(getIt()));
  
  getIt.registerLazySingleton<NetworkMonitorContract>(() => NetworkMonitorImpl());
  
  // Database & DAOs
  getIt.registerLazySingleton(() => AppDatabase());
  getIt.registerLazySingleton(() => AuthDao(getIt()));
  getIt.registerLazySingleton(() => CoreDao(getIt()));
  getIt.registerLazySingleton(() => CatalogDao(getIt()));
  getIt.registerLazySingleton(() => InventoryDao(getIt()));
  getIt.registerLazySingleton(() => SalesDao(getIt()));
  getIt.registerLazySingleton(() => PurchasingDao(getIt()));
  getIt.registerLazySingleton(() => AccountingDao(getIt()));
  getIt.registerLazySingleton(() => TreasuryDao(getIt()));
  getIt.registerLazySingleton(() => HrDao(getIt()));
  getIt.registerLazySingleton(() => FixedAssetsDao(getIt()));
  getIt.registerLazySingleton(() => SystemDao(getIt()));
  
  // Runner
  getIt.registerLazySingleton<ApplicationTransactionRunner>(() => ApplicationTransactionRunnerImpl(getIt()));

  // Sync Coordinator
  getIt.registerLazySingleton(() => SyncCoordinator(
    apiClient: getIt(),
    secureStorage: getIt(),
    db: getIt(),
    catalogDao: getIt(),
    inventoryDao: getIt(),
    salesDao: getIt(),
  ));

  // Data Sources
  getIt.registerLazySingleton(() => AuthLocalDataSourceImpl(getIt()));

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()));
  getIt.registerLazySingleton<CoreRepository>(() => CoreRepositoryImpl(getIt()));
  getIt.registerLazySingleton<CatalogRepository>(() => CatalogRepositoryImpl(getIt()));
  getIt.registerLazySingleton<InventoryRepository>(() => InventoryRepositoryImpl(getIt()));
  getIt.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl(getIt()));
  getIt.registerLazySingleton<PurchasingRepository>(() => PurchasingRepositoryImpl(getIt()));
  getIt.registerLazySingleton<AccountingRepository>(() => AccountingRepositoryImpl(getIt()));
  getIt.registerLazySingleton<TreasuryRepository>(() => TreasuryRepositoryImpl(getIt()));
  getIt.registerLazySingleton<HrRepository>(() => HrRepositoryImpl(getIt()));
  getIt.registerLazySingleton<FixedAssetsRepository>(() => FixedAssetsRepositoryImpl(getIt()));
  getIt.registerLazySingleton<SystemRepository>(() => SystemRepositoryImpl(getIt()));

  // Mappers
  getIt.registerLazySingleton(() => PurchaseInvoiceDocumentMapper(getIt(), getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => SalesInvoiceDocumentMapper(getIt(), getIt(), getIt(), getIt()));

  // UseCases & Services (Accounting)
  getIt.registerLazySingleton(() => AccountingApplicationService(getIt(), getIt()));
  getIt.registerLazySingleton(() => PostJournalEntryUseCase(getIt(), getIt(), getIt(), getIt()));

  // Catalog
  getIt.registerLazySingleton(() => CatalogApplicationService(getIt(), getIt(), getIt()));

  // Inventory
  getIt.registerLazySingleton(() => WarehouseContextService(getIt()));
  getIt.registerLazySingleton(() => GetStockCountsUseCase(getIt(), getIt()));
  getIt.registerLazySingleton(() => GetStockCountDetailsUseCase(getIt(), getIt()));
  getIt.registerLazySingleton(() => ProcessStockAdjustmentUseCase(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => ProcessWarehouseTransferUseCase(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => SaveStockCountUseCase(getIt(), getIt()));
  getIt.registerLazySingleton(() => PostStockCountUseCase(getIt(), getIt(), getIt(), getIt()));

  // Sales
  getIt.registerLazySingleton(() => CustomerApplicationService(getIt(), getIt()));
  getIt.registerLazySingleton(() => OnlineOrderService(getIt(), getIt()));
  getIt.registerLazySingleton(() => CompleteSaleUseCase(getIt(), getIt(), getIt(), getIt(), getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => ProcessSalesReturnUseCase(getIt(), getIt(), getIt(), getIt(), getIt(), getIt()));

  // Purchasing
  getIt.registerLazySingleton(() => SupplierApplicationService(getIt(), getIt()));
  getIt.registerLazySingleton(() => RecordPurchaseReturnUseCase(getIt(), getIt(), getIt(), getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => RecordPurchaseUseCase(getIt(), getIt(), getIt(), getIt(), getIt(), getIt(), getIt()));

  // Treasury
  getIt.registerLazySingleton(() => ReceivePaymentUseCase(getIt(), getIt(), getIt(), getIt(), getIt(), getIt()));

  // Hr
  getIt.registerLazySingleton(() => EmployeeApplicationService(getIt(), getIt()));

  // Fixed Assets
  getIt.registerLazySingleton(() => FixedAssetApplicationService(getIt(), getIt()));

  // System
  getIt.registerLazySingleton(() => ArchiveDocumentService(getIt(), getIt()));
  getIt.registerLazySingleton(() => DocumentApplicationService(getIt(), getIt()));
}
