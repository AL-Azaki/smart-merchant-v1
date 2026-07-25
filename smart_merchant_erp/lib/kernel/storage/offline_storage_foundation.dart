// Central barrel file exporting the Smart Merchant ERP Phase 2.1 Offline Storage Foundation.
// Every future module (Sales, Inventory, Customers, Accounting, HR) should import this
// foundation when building LocalDataSources, DAOs, or caching layers.

export 'storage_state.dart';
export 'storage_strategy.dart';
export 'offline_record.dart';
export 'offline_storage_service.dart';
export 'cache/cache_policy.dart';
