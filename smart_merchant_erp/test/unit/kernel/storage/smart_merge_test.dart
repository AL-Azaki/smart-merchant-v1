import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('Dynamic table smart merge with multiple columns and PK', () async {
    final tempDir = Directory.systemTemp.createTempSync('merge_dynamic_test_');

    final mainDbPath = p.join(tempDir.path, 'main.sqlite');
    final backupDbPath = p.join(tempDir.path, 'backup.sqlite');

    final mainDb = sqlite.sqlite3.open(mainDbPath);
    final backupDb = sqlite.sqlite3.open(backupDbPath);

    // Products table
    mainDb.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT,
        price REAL,
        stock INTEGER,
        updated_at TEXT
      );
    ''');
    backupDb.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT,
        price REAL,
        stock INTEGER,
        updated_at TEXT
      );
    ''');

    // Invoices table (no updated_at, just immutable history)
    mainDb.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        number TEXT,
        total REAL
      );
    ''');
    backupDb.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        number TEXT,
        total REAL
      );
    ''');

    // 1. Products:
    // Main has Prod 1 (newer, updated at 15:00)
    // Main has Prod 2 (created today, only in main)
    mainDb.execute("INSERT INTO products VALUES ('p1', 'Phone 15 Pro', 1200, 10, '2026-11-06T15:00:00Z');");
    mainDb.execute("INSERT INTO products VALUES ('p2', 'Today Product', 50, 100, '2026-11-06T12:00:00Z');");

    // Backup has Prod 1 (older, updated at 10:00)
    // Backup has Prod 3 (old product missing in main)
    backupDb.execute("INSERT INTO products VALUES ('p1', 'Phone 15 Pro (Old)', 1100, 5, '2026-11-06T10:00:00Z');");
    backupDb.execute("INSERT INTO products VALUES ('p3', 'Laptop Missing', 800, 3, '2026-11-05T10:00:00Z');");

    // 2. Invoices:
    // Main has invoice inv_today
    // Backup has invoice inv_yesterday
    mainDb.execute("INSERT INTO invoices VALUES ('inv2', 'INV-002', 500);");
    backupDb.execute("INSERT INTO invoices VALUES ('inv1', 'INV-001', 300);");

    backupDb.dispose();

    // Attach backup
    mainDb.execute("ATTACH DATABASE '${backupDbPath.replaceAll("'", "''")}' AS backup_db;");

    // Test dynamic merge routine
    final tables = mainDb.select("SELECT name FROM backup_db.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");
    for (final row in tables) {
      final tableName = row['name'] as String;
      final info = mainDb.select('PRAGMA table_info("$tableName");');
      final cols = <String>[];
      final pks = <String>[];
      bool hasUpdatedAt = false;

      for (final col in info) {
        final colName = col['name'] as String;
        final isPk = (col['pk'] as int) > 0;
        cols.add(colName);
        if (isPk) pks.add(colName);
        if (colName.toLowerCase() == 'updated_at') hasUpdatedAt = true;
      }

      if (cols.isEmpty || pks.isEmpty) continue;

      final colsStr = cols.map((c) => '"$c"').join(', ');
      final pkJoin = pks.map((pk) => 'main."$tableName"."$pk" = backup_db."$tableName"."$pk"').join(' AND ');

      // Step 1: Insert missing rows
      mainDb.execute('''
        INSERT INTO main."$tableName" ($colsStr)
        SELECT $colsStr
        FROM backup_db."$tableName"
        WHERE NOT EXISTS (
          SELECT 1 FROM main."$tableName" WHERE $pkJoin
        );
      ''');

      // Step 2: Update shared rows where backup is newer
      if (hasUpdatedAt && cols.any((c) => !pks.contains(c))) {
        final nonPkCols = cols.where((c) => !pks.contains(c)).toList();
        final setClause = nonPkCols.map((c) => '"$c" = (SELECT b."$c" FROM backup_db."$tableName" b WHERE ${pks.map((pk) => 'b."$pk" = main."$tableName"."$pk"').join(' AND ')})').join(', ');

        mainDb.execute('''
          UPDATE main."$tableName"
          SET $setClause
          WHERE EXISTS (
            SELECT 1 FROM backup_db."$tableName" b
            WHERE ${pks.map((pk) => 'b."$pk" = main."$tableName"."$pk"').join(' AND ')}
              AND b."updated_at" > main."$tableName"."updated_at"
          );
        ''');
      }
    }

    mainDb.execute("DETACH DATABASE backup_db;");

    // Check products
    final prods = mainDb.select('SELECT id, name, price, stock FROM products ORDER BY id;');
    expect(prods.length, 3);
    // p1: retained newer main value (1200, Phone 15 Pro)
    expect(prods[0]['id'], 'p1');
    expect(prods[0]['name'], 'Phone 15 Pro');
    expect(prods[0]['price'], 1200);

    // p2: today's product retained
    expect(prods[1]['id'], 'p2');
    expect(prods[1]['name'], 'Today Product');

    // p3: restored from backup
    expect(prods[2]['id'], 'p3');
    expect(prods[2]['name'], 'Laptop Missing');

    // Check invoices
    final invs = mainDb.select('SELECT id, number FROM invoices ORDER BY id;');
    expect(invs.length, 2);
    expect(invs[0]['id'], 'inv1');
    expect(invs[1]['id'], 'inv2');

    mainDb.dispose();
    tempDir.deleteSync(recursive: true);
  });
}