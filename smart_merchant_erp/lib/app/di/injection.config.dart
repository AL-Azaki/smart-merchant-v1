// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../database/daos/accounting_dao.dart' as _i786;
import '../../database/daos/auth_dao.dart' as _i143;
import '../../database/daos/catalog_dao.dart' as _i964;
import '../../database/daos/core_dao.dart' as _i90;
import '../../database/daos/fixed_assets_dao.dart' as _i486;
import '../../database/daos/hr_dao.dart' as _i783;
import '../../database/daos/inventory_dao.dart' as _i828;
import '../../database/daos/purchasing_dao.dart' as _i896;
import '../../database/daos/sales_dao.dart' as _i789;
import '../../database/daos/system_dao.dart' as _i381;
import '../../database/daos/treasury_dao.dart' as _i860;
import '../../kernel/core/application_context.dart' as _i477;
import '../../kernel/core/transaction_runner.dart' as _i924;
import '../../kernel/network/connectivity/network_monitor.dart' as _i1036;
import '../../kernel/storage/app_database.dart' as _i98;
import '../../kernel/storage/secure_storage/secure_storage_contract.dart'
    as _i269;
import '../../kernel/sync/api/sync_remote_api_client.dart' as _i705;
import '../../kernel/sync/coordinator/sync_coordinator.dart' as _i410;
import '../../modules/accounting/application/services/accounting_application_service.dart'
    as _i176;
import '../../modules/accounting/application/usecases/post_journal_entry_usecase.dart'
    as _i280;
import '../../modules/accounting/domain/repositories/accounting_repository.dart'
    as _i540;
import '../../modules/accounting/infrastructure/repositories/accounting_repository_impl.dart'
    as _i403;
import '../../modules/authentication/domain/repositories/auth_repository.dart'
    as _i457;
import '../../modules/authentication/infrastructure/api/auth_remote_api_client.dart'
    as _i120;
import '../../modules/authentication/infrastructure/data_sources/auth_local_data_source.dart'
    as _i370;
import '../../modules/authentication/infrastructure/repositories/auth_repository_impl.dart'
    as _i599;
import '../../modules/catalog/application/services/catalog_application_service.dart'
    as _i468;
import '../../modules/catalog/domain/repositories/catalog_repository.dart'
    as _i914;
import '../../modules/catalog/infrastructure/repositories/catalog_repository_impl.dart'
    as _i7;
import '../../modules/core/domain/repositories/core_repository.dart' as _i732;
import '../../modules/core/infrastructure/repositories/core_repository_impl.dart'
    as _i478;
import '../../modules/fixed_assets/application/services/fixed_asset_application_service.dart'
    as _i377;
import '../../modules/fixed_assets/domain/repositories/fixed_assets_repository.dart'
    as _i578;
import '../../modules/fixed_assets/infrastructure/repositories/fixed_assets_repository_impl.dart'
    as _i246;
import '../../modules/hr/application/services/employee_application_service.dart'
    as _i904;
import '../../modules/hr/domain/repositories/hr_repository.dart' as _i553;
import '../../modules/hr/infrastructure/repositories/hr_repository_impl.dart'
    as _i882;
import '../../modules/inventory/application/services/warehouse_context_service.dart'
    as _i1014;
import '../../modules/inventory/application/usecases/process_stock_adjustment_usecase.dart'
    as _i18;
import '../../modules/inventory/application/usecases/process_warehouse_transfer_usecase.dart'
    as _i912;
import '../../modules/inventory/domain/repositories/inventory_repository.dart'
    as _i525;
import '../../modules/inventory/infrastructure/repositories/inventory_repository_impl.dart'
    as _i434;
import '../../modules/purchasing/application/services/supplier_application_service.dart'
    as _i851;
import '../../modules/purchasing/application/usecases/record_purchase_usecase.dart'
    as _i948;
import '../../modules/purchasing/domain/repositories/purchasing_repository.dart'
    as _i746;
import '../../modules/purchasing/infrastructure/repositories/purchasing_repository_impl.dart'
    as _i558;
import '../../modules/sales/application/services/customer_application_service.dart'
    as _i764;
import '../../modules/sales/application/services/online_order_service.dart'
    as _i181;
import '../../modules/sales/application/usecases/complete_sale_usecase.dart'
    as _i821;
import '../../modules/sales/domain/repositories/sales_repository.dart' as _i345;
import '../../modules/sales/infrastructure/repositories/sales_repository_impl.dart'
    as _i310;
import '../../modules/system/application/services/document_application_service.dart'
    as _i1014;
import '../../modules/system/domain/repositories/system_repository.dart'
    as _i688;
import '../../modules/system/infrastructure/repositories/system_repository_impl.dart'
    as _i785;
import '../../modules/treasury/application/usecases/receive_payment_usecase.dart'
    as _i108;
import '../../modules/treasury/domain/repositories/treasury_repository.dart'
    as _i259;
import '../../modules/treasury/infrastructure/repositories/treasury_repository_impl.dart'
    as _i972;
import '../config/api_client.dart' as _i125;
import '../config/app_environment.dart' as _i426;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i477.SessionHolder>(() => registerModule.sessionHolder);
    gh.lazySingleton<_i269.SecureStorageContract>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i426.AppEnvironment>(() => registerModule.appEnvironment);
    gh.lazySingleton<_i1036.NetworkMonitorContract>(
      () => registerModule.networkMonitor,
    );
    gh.lazySingleton<_i98.AppDatabase>(() => _i98.AppDatabase.injectable());
    gh.lazySingleton<_i477.ApplicationContext>(
      () => registerModule.getApplicationContext(gh<_i477.SessionHolder>()),
    );
    gh.lazySingleton<_i143.AuthDao>(
      () => registerModule.getAuthDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i90.CoreDao>(
      () => registerModule.getCoreDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i964.CatalogDao>(
      () => registerModule.getCatalogDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i828.InventoryDao>(
      () => registerModule.getInventoryDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i789.SalesDao>(
      () => registerModule.getSalesDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i896.PurchasingDao>(
      () => registerModule.getPurchasingDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i786.AccountingDao>(
      () => registerModule.getAccountingDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i860.TreasuryDao>(
      () => registerModule.getTreasuryDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i783.HrDao>(
      () => registerModule.getHrDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i486.FixedAssetsDao>(
      () => registerModule.getFixedAssetsDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i381.SystemDao>(
      () => registerModule.getSystemDao(gh<_i98.AppDatabase>()),
    );
    gh.lazySingleton<_i578.FixedAssetsRepository>(
      () => _i246.FixedAssetsRepositoryImpl(gh<_i486.FixedAssetsDao>()),
    );
    gh.factory<_i377.FixedAssetApplicationService>(
      () => _i377.FixedAssetApplicationService(
        gh<_i578.FixedAssetsRepository>(),
        gh<_i477.ApplicationContext>(),
      ),
    );
    gh.lazySingleton<_i345.SalesRepository>(
      () => _i310.SalesRepositoryImpl(gh<_i789.SalesDao>()),
    );
    gh.lazySingleton<_i914.CatalogRepository>(
      () => _i7.CatalogRepositoryImpl(gh<_i964.CatalogDao>()),
    );
    gh.lazySingleton<_i259.TreasuryRepository>(
      () => _i972.TreasuryRepositoryImpl(gh<_i860.TreasuryDao>()),
    );
    gh.lazySingleton<_i125.ApiClient>(
      () => registerModule.getApiClient(
        gh<_i426.AppEnvironment>(),
        gh<_i269.SecureStorageContract>(),
      ),
    );
    gh.lazySingleton<_i540.AccountingRepository>(
      () => _i403.AccountingRepositoryImpl(gh<_i786.AccountingDao>()),
    );
    gh.lazySingleton<_i732.CoreRepository>(
      () => _i478.CoreRepositoryImpl(gh<_i90.CoreDao>()),
    );
    gh.lazySingleton<_i688.SystemRepository>(
      () => _i785.SystemRepositoryImpl(gh<_i381.SystemDao>()),
    );
    gh.lazySingleton<_i553.HrRepository>(
      () => _i882.HrRepositoryImpl(gh<_i783.HrDao>()),
    );
    gh.factory<_i764.CustomerApplicationService>(
      () => _i764.CustomerApplicationService(
        gh<_i345.SalesRepository>(),
        gh<_i477.ApplicationContext>(),
      ),
    );
    gh.factory<_i181.OnlineOrderService>(
      () => _i181.OnlineOrderService(
        gh<_i345.SalesRepository>(),
        gh<_i477.ApplicationContext>(),
      ),
    );
    gh.lazySingleton<_i525.InventoryRepository>(
      () => _i434.InventoryRepositoryImpl(gh<_i828.InventoryDao>()),
    );
    gh.lazySingleton<_i924.ApplicationTransactionRunner>(
      () => _i924.ApplicationTransactionRunnerImpl(gh<_i98.AppDatabase>()),
    );
    gh.factory<_i468.CatalogApplicationService>(
      () => _i468.CatalogApplicationService(
        gh<_i914.CatalogRepository>(),
        gh<_i477.ApplicationContext>(),
      ),
    );
    gh.lazySingleton<_i746.PurchasingRepository>(
      () => _i558.PurchasingRepositoryImpl(gh<_i896.PurchasingDao>()),
    );
    gh.lazySingleton<_i370.AuthLocalDataSource>(
      () => _i370.AuthLocalDataSourceImpl(gh<_i98.AppDatabase>()),
    );
    gh.factory<_i1014.DocumentApplicationService>(
      () => _i1014.DocumentApplicationService(
        gh<_i688.SystemRepository>(),
        gh<_i477.ApplicationContext>(),
      ),
    );
    gh.factory<_i280.PostJournalEntryUseCase>(
      () => _i280.PostJournalEntryUseCase(
        gh<_i540.AccountingRepository>(),
        gh<_i732.CoreRepository>(),
        gh<_i477.ApplicationContext>(),
        gh<_i924.ApplicationTransactionRunner>(),
      ),
    );
    gh.lazySingleton<_i120.AuthRemoteApiClient>(
      () => registerModule.getAuthRemoteApiClient(gh<_i125.ApiClient>()),
    );
    gh.lazySingleton<_i705.SyncRemoteApiClient>(
      () => registerModule.getSyncRemoteApiClient(gh<_i125.ApiClient>()),
    );
    gh.factory<_i851.SupplierApplicationService>(
      () => _i851.SupplierApplicationService(
        gh<_i746.PurchasingRepository>(),
        gh<_i477.ApplicationContext>(),
      ),
    );
    gh.factory<_i176.AccountingApplicationService>(
      () => _i176.AccountingApplicationService(
        gh<_i540.AccountingRepository>(),
        gh<_i477.ApplicationContext>(),
      ),
    );
    gh.lazySingleton<_i1014.WarehouseContextService>(
      () => _i1014.WarehouseContextService(gh<_i525.InventoryRepository>()),
    );
    gh.factory<_i904.EmployeeApplicationService>(
      () => _i904.EmployeeApplicationService(
        gh<_i553.HrRepository>(),
        gh<_i477.ApplicationContext>(),
      ),
    );
    gh.lazySingleton<_i410.SyncCoordinator>(
      () => registerModule.getSyncCoordinator(
        gh<_i705.SyncRemoteApiClient>(),
        gh<_i269.SecureStorageContract>(),
        gh<_i98.AppDatabase>(),
        gh<_i964.CatalogDao>(),
        gh<_i828.InventoryDao>(),
        gh<_i789.SalesDao>(),
      ),
    );
    gh.factory<_i948.RecordPurchaseUseCase>(
      () => _i948.RecordPurchaseUseCase(
        gh<_i746.PurchasingRepository>(),
        gh<_i525.InventoryRepository>(),
        gh<_i540.AccountingRepository>(),
        gh<_i176.AccountingApplicationService>(),
        gh<_i477.ApplicationContext>(),
        gh<_i924.ApplicationTransactionRunner>(),
      ),
    );
    gh.factory<_i912.ProcessWarehouseTransferUseCase>(
      () => _i912.ProcessWarehouseTransferUseCase(
        gh<_i525.InventoryRepository>(),
        gh<_i477.ApplicationContext>(),
        gh<_i924.ApplicationTransactionRunner>(),
      ),
    );
    gh.factory<_i18.ProcessStockAdjustmentUseCase>(
      () => _i18.ProcessStockAdjustmentUseCase(
        gh<_i525.InventoryRepository>(),
        gh<_i477.ApplicationContext>(),
        gh<_i924.ApplicationTransactionRunner>(),
      ),
    );
    gh.lazySingleton<_i457.AuthRepository>(
      () =>
          _i599.AuthRepositoryImpl.injectable(gh<_i370.AuthLocalDataSource>()),
    );
    gh.factory<_i821.CompleteSaleUseCase>(
      () => _i821.CompleteSaleUseCase(
        gh<_i345.SalesRepository>(),
        gh<_i525.InventoryRepository>(),
        gh<_i540.AccountingRepository>(),
        gh<_i176.AccountingApplicationService>(),
        gh<_i477.ApplicationContext>(),
        gh<_i924.ApplicationTransactionRunner>(),
      ),
    );
    gh.factory<_i108.ReceivePaymentUseCase>(
      () => _i108.ReceivePaymentUseCase(
        gh<_i259.TreasuryRepository>(),
        gh<_i345.SalesRepository>(),
        gh<_i540.AccountingRepository>(),
        gh<_i176.AccountingApplicationService>(),
        gh<_i477.ApplicationContext>(),
        gh<_i924.ApplicationTransactionRunner>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
