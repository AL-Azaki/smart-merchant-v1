import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'package:uuid/uuid.dart'; // Added for ID generation
import 'package:injectable/injectable.dart';
import 'tables/sales_tables.dart';
import 'tables/auth_tables.dart';

part 'app_database.g.dart'; // This file will be generated

@lazySingleton
@DriftDatabase(tables: [CustomersTable, SalesInvoicesTable, UsersTable, AccountsTable, SubscriptionsTable])
class AppDatabase extends _$AppDatabase {
  // التعديل: السماح بتمرير (Connection) وهمي للاختبارات (Unit Testing)
  // إذا لم يتم تمرير اتصال، سيقوم بفتح الاتصال الحقيقي `_openConnection()`
  AppDatabase({QueryExecutor? connection}) : super(connection ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // 1. Get the app's documents directory
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'smart_merchant_erp_local.sqlite'));

    // 2. Initialize sqlite3 specifically for Flutter platforms
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    // 3. Make sqlite3 use the temp directory for the system
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
