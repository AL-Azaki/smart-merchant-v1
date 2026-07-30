import 'dart:async';
import '../storage/app_database.dart';

/// Contract for executing application workflows within an atomic database transaction.
abstract class ApplicationTransactionRunner {
  /// Executes the given asynchronous [action] within a single transaction.
  /// If the action throws an exception, the transaction is rolled back.
  Future<T> runInTransaction<T>(Future<T> Function() action);
}

class ApplicationTransactionRunnerImpl implements ApplicationTransactionRunner {
  final AppDatabase _db;

  ApplicationTransactionRunnerImpl(this._db);

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    return _db.transaction(action);
  }
}
