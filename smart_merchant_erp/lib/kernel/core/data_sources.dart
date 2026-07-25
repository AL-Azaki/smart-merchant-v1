/// Base marker contract for all local data sources (e.g., SQLite / Drift / SharedPreferences).
/// Ensures concrete local data sources adhere to a standardized contract across all 17 domains.
abstract class LocalDataSource {}

/// Base marker contract for all remote data sources (e.g., Dio / Laravel REST APIs).
/// Ensures concrete remote data sources adhere to a standardized contract across all 17 domains.
abstract class RemoteDataSource {}
