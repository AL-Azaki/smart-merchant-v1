import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../kernel/core/application_context.dart';
import '../../kernel/storage/app_database.dart';
import '../../kernel/storage/secure_storage/secure_storage_contract.dart';
import '../../kernel/storage/secure_storage/flutter_secure_storage_impl.dart';
import '../../kernel/sync/api/sync_remote_api_client.dart';
import '../../kernel/sync/coordinator/sync_coordinator.dart';
import '../../kernel/network/connectivity/network_monitor.dart';
import '../../app/config/api_client.dart';
import '../../app/config/app_environment.dart';
import '../../modules/authentication/infrastructure/api/auth_remote_api_client.dart';
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

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio();

  @lazySingleton
  SessionHolder get sessionHolder => SessionHolder();

  @lazySingleton
  ApplicationContext getApplicationContext(SessionHolder holder) =>
      RuntimeApplicationContext(holder);

  // ── Secure Storage ──────────────────────────────────────

  @lazySingleton
  SecureStorageContract get secureStorage => FlutterSecureStorageImpl();

  // ── Networking / API ────────────────────────────────────

  @lazySingleton
  AppEnvironment get appEnvironment => AppEnvironment.current;

  @lazySingleton
  ApiClient getApiClient(AppEnvironment env, SecureStorageContract storage) =>
      ApiClient(environment: env, secureStorage: storage);

  // ── Auth API ────────────────────────────────────────────

  @lazySingleton
  AuthRemoteApiClient getAuthRemoteApiClient(ApiClient apiClient) =>
      AuthRemoteApiClient(apiClient);

  // ── Sync API ────────────────────────────────────────────

  @lazySingleton
  SyncRemoteApiClient getSyncRemoteApiClient(ApiClient apiClient) =>
      SyncRemoteApiClient(apiClient);

  // ── Sync Coordinator ────────────────────────────────────

  @lazySingleton
  SyncCoordinator getSyncCoordinator(
    SyncRemoteApiClient syncApi,
    SecureStorageContract storage,
    AppDatabase db,
    CatalogDao catalogDao,
    InventoryDao inventoryDao,
    SalesDao salesDao,
  ) => SyncCoordinator(
    apiClient: syncApi,
    secureStorage: storage,
    db: db,
    catalogDao: catalogDao,
    inventoryDao: inventoryDao,
    salesDao: salesDao,
  );

  // ── Network Monitor ─────────────────────────────────────

  @lazySingleton
  NetworkMonitorContract get networkMonitor => NetworkMonitorImpl();

  // ── DAOs ────────────────────────────────────────────────

  @lazySingleton
  AuthDao getAuthDao(AppDatabase db) => AuthDao(db);

  @lazySingleton
  CoreDao getCoreDao(AppDatabase db) => CoreDao(db);

  @lazySingleton
  CatalogDao getCatalogDao(AppDatabase db) => CatalogDao(db);

  @lazySingleton
  InventoryDao getInventoryDao(AppDatabase db) => InventoryDao(db);

  @lazySingleton
  SalesDao getSalesDao(AppDatabase db) => SalesDao(db);

  @lazySingleton
  PurchasingDao getPurchasingDao(AppDatabase db) => PurchasingDao(db);

  @lazySingleton
  AccountingDao getAccountingDao(AppDatabase db) => AccountingDao(db);

  @lazySingleton
  TreasuryDao getTreasuryDao(AppDatabase db) => TreasuryDao(db);

  @lazySingleton
  HrDao getHrDao(AppDatabase db) => HrDao(db);

  @lazySingleton
  FixedAssetsDao getFixedAssetsDao(AppDatabase db) => FixedAssetsDao(db);

  @lazySingleton
  SystemDao getSystemDao(AppDatabase db) => SystemDao(db);
}
