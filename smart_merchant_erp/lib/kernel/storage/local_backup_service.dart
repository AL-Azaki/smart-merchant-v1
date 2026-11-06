import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../app/di/getit_instance.dart';
import 'app_database.dart';

/// Metadata stored inside each .smbak file
class BackupMetadata {
  final String appName;
  final int schemaVersion;
  final DateTime createdAt;
  final String platform;
  final int originalSizeBytes;
  final String? notes;

  const BackupMetadata({
    required this.appName,
    required this.schemaVersion,
    required this.createdAt,
    required this.platform,
    required this.originalSizeBytes,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'platform': platform,
        'originalSizeBytes': originalSizeBytes,
        'notes': notes,
      };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
        appName: json['appName'] as String? ?? 'Smart Merchant ERP',
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 7,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        platform: json['platform'] as String? ?? Platform.operatingSystem,
        originalSizeBytes: (json['originalSizeBytes'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String?,
      );
}

/// Information about a backup file on disk
class BackupFileItem {
  final File file;
  final String fileName;
  final int fileSizeBytes;
  final DateTime modifiedAt;
  final BackupMetadata? metadata;

  const BackupFileItem({
    required this.file,
    required this.fileName,
    required this.fileSizeBytes,
    required this.modifiedAt,
    this.metadata,
  });
}

/// Statistics for smart merge execution
class SmartMergeStats {
  final int tablesCount;
  final int insertedRows;
  final int updatedRows;

  const SmartMergeStats({
    required this.tablesCount,
    this.insertedRows = 0,
    this.updatedRows = 0,
  });
}

/// Service handling military-grade encrypted local backups and safe restores.
class LocalBackupService {
  static const String fileExtension = '.smbak';
  static const String fileMagic = 'SM_ERP_BAK_V1';

  /// Get the dedicated backups directory
  static Future<Directory> getBackupsDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docDir.path, 'smart_merchant_backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Get the active SQLite database file
  static Future<File> getActiveDatabaseFile() async {
    final docDir = await getApplicationDocumentsDirectory();
    return File(p.join(docDir.path, 'smart_merchant_erp_local.sqlite'));
  }

  /// Create an atomic, encrypted backup (.smbak)
  static Future<File> createBackup({
    required String password,
    String? notes,
  }) async {
    if (password.trim().isEmpty) {
      throw ArgumentError('كلمة المرور مطلوبة لتشفير النسخة الاحتياطية.');
    }

    final dbFile = await getActiveDatabaseFile();
    if (!await dbFile.exists()) {
      throw StateError('ملف قاعدة البيانات غير موجود.');
    }

    // 1. Perform atomic live snapshot using SQLite VACUUM INTO
    final tempDir = await getTemporaryDirectory();
    final tempSnapshotPath = p.join(
      tempDir.path,
      'live_snapshot_${DateTime.now().millisecondsSinceEpoch}.sqlite',
    );
    final tempSnapshotFile = File(tempSnapshotPath);

    try {
      if (getIt.isRegistered<AppDatabase>()) {
        final db = getIt<AppDatabase>();
        try {
          await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
          // VACUUM INTO provides atomic lock-free snapshot even during concurrent writes
          await db.customStatement("VACUUM INTO '$tempSnapshotPath';");
        } catch (e) {
          debugPrint('Notice on VACUUM INTO, falling back to direct copy: $e');
          await dbFile.copy(tempSnapshotPath);
        }
      } else {
        await dbFile.copy(tempSnapshotPath);
      }

      final rawBytes = await tempSnapshotFile.readAsBytes();
      final originalSize = rawBytes.length;

      // 2. Compress with GZip to minimize size
      final compressedBytes = Uint8List.fromList(const GZipEncoder().encode(rawBytes));

      // 3. Prepare Cryptography components
      final rng = Random.secure();
      final salt = Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));
      final nonce = Uint8List.fromList(List<int>.generate(12, (_) => rng.nextInt(256)));

      // 4. Derive key using Argon2id
      final argon2id = Argon2id(
        parallelism: 1,
        memory: 19 * 1024, // 19 MiB OWASP recommended baseline
        iterations: 2,
        hashLength: 32,
      );

      final secretKey = await argon2id.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );

      // 5. Build Metadata and use as Additional Authenticated Data (AAD)
      final metadata = BackupMetadata(
        appName: 'Smart Merchant ERP',
        schemaVersion: 7,
        createdAt: DateTime.now(),
        platform: Platform.operatingSystem,
        originalSizeBytes: originalSize,
        notes: notes,
      );

      final metadataJson = jsonEncode(metadata.toJson());
      final aadBytes = utf8.encode(metadataJson);

      // 6. Encrypt with AES-256-GCM (AEAD)
      final aesGcm = AesGcm.with256bits();
      final secretBox = await aesGcm.encrypt(
        compressedBytes,
        secretKey: secretKey,
        nonce: nonce,
        aad: aadBytes,
      );

      // 7. Structure the final .smbak container package
      final container = {
        'magic': fileMagic,
        'kdf': 'Argon2id',
        'cipher': 'AES-256-GCM',
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
        'mac': base64Encode(secretBox.mac.bytes),
        'metadata': metadata.toJson(),
        'payload': base64Encode(secretBox.cipherText),
      };

      final outputFolder = await getBackupsDirectory();
      final timestampStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final finalFileName = 'SmartMerchant_Backup_$timestampStr$fileExtension';
      final finalFile = File(p.join(outputFolder.path, finalFileName));

      await finalFile.writeAsString(jsonEncode(container), flush: true);
      return finalFile;
    } finally {
      if (await tempSnapshotFile.exists()) {
        await tempSnapshotFile.delete();
      }
    }
  }

  /// Read metadata from a .smbak file without needing the password
  static Future<BackupMetadata> readMetadata(File backupFile) async {
    if (!await backupFile.exists()) {
      throw ArgumentError('الملف المحدد غير موجود.');
    }

    final rawJson = await backupFile.readAsString();
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

    final magic = decoded['magic'] as String?;
    if (magic != fileMagic) {
      throw const FormatException('الملف المحدد ليس نسخة احتياطية صالحة من نظام تاجركم.');
    }

    final metaMap = decoded['metadata'] as Map<String, dynamic>?;
    if (metaMap == null) {
      throw const FormatException('البيانات الوصفية للنسخة الاحتياطية غير متوفرة.');
    }

    return BackupMetadata.fromJson(metaMap);
  }

  /// Safely restore an encrypted backup (.smbak)
  static Future<void> restoreBackup({
    required File backupFile,
    required String password,
  }) async {
    if (!await backupFile.exists()) {
      throw ArgumentError('ملف النسخة الاحتياطية غير موجود.');
    }

    final rawString = await backupFile.readAsString();
    final container = jsonDecode(rawString) as Map<String, dynamic>;

    if (container['magic'] != fileMagic) {
      throw const FormatException('تنسيق ملف النسخة الاحتياطية غير معروف أو تالف.');
    }

    final salt = base64Decode(container['salt'] as String);
    final nonce = base64Decode(container['nonce'] as String);
    final macBytes = base64Decode(container['mac'] as String);
    final cipherBytes = base64Decode(container['payload'] as String);
    final metaMap = container['metadata'] as Map<String, dynamic>;
    final metadata = BackupMetadata.fromJson(metaMap);

    // Verify schema version compatibility
    if (metadata.schemaVersion > 7) {
      throw FormatException(
        'هذه النسخة أُنشئت بإصدار أحدث من التطبيق (إصدار المخطط ${metadata.schemaVersion}). يرجى تحديث التطبيق أولاً.',
      );
    }

    // 1. Derive key via Argon2id
    final argon2id = Argon2id(
      parallelism: 1,
      memory: 19 * 1024,
      iterations: 2,
      hashLength: 32,
    );

    final secretKey = await argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    // 2. Decrypt & Authenticate via AES-256-GCM
    final aesGcm = AesGcm.with256bits();
    final secretBox = SecretBox(
      cipherBytes,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final aadBytes = utf8.encode(jsonEncode(metaMap));

    Uint8List decryptedCompressed;
    try {
      final decrypted = await aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: aadBytes,
      );
      decryptedCompressed = Uint8List.fromList(decrypted);
    } catch (e) {
      throw const FormatException('كلمة المرور غير صحيحة، أو أن ملف النسخة قد تم التعديل عليه.');
    }

    // 3. Decompress SQLite database bytes
    final rawDbBytes = Uint8List.fromList(const GZipDecoder().decodeBytes(decryptedCompressed));

    // 4. Write to temp file and run SQLite PRAGMA integrity_check
    final tempDir = await getTemporaryDirectory();
    final tempRestoredDbPath = p.join(
      tempDir.path,
      'verify_restore_${DateTime.now().millisecondsSinceEpoch}.sqlite',
    );
    final tempRestoredFile = File(tempRestoredDbPath);

    try {
      await tempRestoredFile.writeAsBytes(rawDbBytes, flush: true);

      // Verify with sqlite3 library
      final testDb = sqlite.sqlite3.open(tempRestoredDbPath);
      final checkResult = testDb.select('PRAGMA integrity_check;');
      testDb.dispose();

      if (checkResult.isEmpty || checkResult.first.values.first != 'ok') {
        throw const FormatException('فشل فحص سلامة قاعدة البيانات؛ الملف تالف.');
      }

      // 5. Create automatic Safety Snapshot of current DB before replacing
      final activeDbFile = await getActiveDatabaseFile();
      if (await activeDbFile.exists()) {
        final backupFolder = await getBackupsDirectory();
        final safetyFileName = 'PreRestore_Safety_${DateTime.now().millisecondsSinceEpoch}.sqlite';
        await activeDbFile.copy(p.join(backupFolder.path, safetyFileName));
      }

      // 6. Stop all database users & close active Drift DB connection
      if (getIt.isRegistered<AppDatabase>()) {
        final activeDb = getIt<AppDatabase>();
        await activeDb.close();
        await getIt.unregister<AppDatabase>();
      }

      // 7. Overwrite database file directly (without deleting file to avoid Windows errno 32)
      if (await activeDbFile.exists()) {
        await activeDbFile.writeAsBytes(rawDbBytes, flush: true);
      } else {
        await tempRestoredFile.copy(activeDbFile.path);
      }

      // Also clean old WAL and SHM files if present
      final walFile = File('${activeDbFile.path}-wal');
      final shmFile = File('${activeDbFile.path}-shm');
      if (await walFile.exists()) {
        try {
          await walFile.writeAsBytes([], flush: true);
        } catch (_) {}
      }
      if (await shmFile.exists()) {
        try {
          await shmFile.writeAsBytes([], flush: true);
        } catch (_) {}
      }

      // 8. Re-register AppDatabase in GetIt
      getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
    } finally {
      if (await tempRestoredFile.exists()) {
        await tempRestoredFile.delete();
      }
    }
  }

  /// Perform Smart Incremental Merge:
  /// - New records in active DB: Kept intact.
  /// - Missing records from backup: Inserted into active DB.
  /// - Shared records: Compared via updated_at; latest is kept.
  static Future<SmartMergeStats> smartMergeBackup({
    required File backupFile,
    required String password,
  }) async {
    if (!await backupFile.exists()) {
      throw ArgumentError('ملف النسخة الاحتياطية غير موجود.');
    }

    final rawString = await backupFile.readAsString();
    final container = jsonDecode(rawString) as Map<String, dynamic>;

    if (container['magic'] != fileMagic) {
      throw const FormatException('تنسيق ملف النسخة الاحتياطية غير معروف أو تالف.');
    }

    final salt = base64Decode(container['salt'] as String);
    final nonce = base64Decode(container['nonce'] as String);
    final macBytes = base64Decode(container['mac'] as String);
    final cipherBytes = base64Decode(container['payload'] as String);
    final metaMap = container['metadata'] as Map<String, dynamic>;
    final metadata = BackupMetadata.fromJson(metaMap);

    if (metadata.schemaVersion > 7) {
      throw FormatException(
        'هذه النسخة أُنشئت بإصدار أحدث من التطبيق (إصدار المخطط ${metadata.schemaVersion}). يرجى تحديث التطبيق أولاً.',
      );
    }

    // 1. Derive key via Argon2id
    final argon2id = Argon2id(
      parallelism: 1,
      memory: 19 * 1024,
      iterations: 2,
      hashLength: 32,
    );

    final secretKey = await argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    // 2. Decrypt & Authenticate via AES-256-GCM
    final aesGcm = AesGcm.with256bits();
    final secretBox = SecretBox(
      cipherBytes,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final aadBytes = utf8.encode(jsonEncode(metaMap));

    Uint8List decryptedCompressed;
    try {
      final decrypted = await aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: aadBytes,
      );
      decryptedCompressed = Uint8List.fromList(decrypted);
    } catch (e) {
      throw const FormatException('كلمة المرور غير صحيحة، أو أن ملف النسخة قد تم التعديل عليه.');
    }

    // 3. Decompress SQLite database bytes
    final rawDbBytes = Uint8List.fromList(const GZipDecoder().decodeBytes(decryptedCompressed));

    // 4. Write to temp file and verify PRAGMA integrity_check
    final tempDir = await getTemporaryDirectory();
    final tempRestoredDbPath = p.join(
      tempDir.path,
      'verify_merge_${DateTime.now().millisecondsSinceEpoch}.sqlite',
    );
    final tempRestoredFile = File(tempRestoredDbPath);

    try {
      await tempRestoredFile.writeAsBytes(rawDbBytes, flush: true);

      final testDb = sqlite.sqlite3.open(tempRestoredDbPath);
      final checkResult = testDb.select('PRAGMA integrity_check;');
      testDb.dispose();

      if (checkResult.isEmpty || checkResult.first.values.first != 'ok') {
        throw const FormatException('فشل فحص سلامة قاعدة البيانات؛ الملف تالف.');
      }

      // 5. Automatic safety snapshot of current active DB before merge
      final activeDbFile = await getActiveDatabaseFile();
      if (await activeDbFile.exists()) {
        final backupFolder = await getBackupsDirectory();
        final safetyFileName = 'PreMerge_Safety_${DateTime.now().millisecondsSinceEpoch}.sqlite';
        await activeDbFile.copy(p.join(backupFolder.path, safetyFileName));
      }

      // 6. Execute merge using sqlite3 or Drift
      final escapedBackupPath = tempRestoredDbPath.replaceAll("'", "''");
      int processedTables = 0;

      if (getIt.isRegistered<AppDatabase>()) {
        final db = getIt<AppDatabase>();
        await db.customStatement('PRAGMA foreign_keys = OFF;');
        await db.customStatement("ATTACH DATABASE '$escapedBackupPath' AS backup_db;");

        try {
          final tablesResult = await db.customSelect(
            "SELECT name FROM backup_db.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%' AND name NOT LIKE '_drift_%';",
          ).get();

          for (final tableRow in tablesResult) {
            final tableName = tableRow.read<String>('name');
            final mainExists = await db.customSelect(
              "SELECT name FROM main.sqlite_master WHERE type='table' AND name = '$tableName';",
            ).get();

            if (mainExists.isEmpty) {
              continue;
            }

            final tableInfo = await db.customSelect('PRAGMA main.table_info("$tableName");').get();
            final cols = <String>[];
            final pks = <String>[];
            bool hasUpdatedAt = false;

            for (final colRow in tableInfo) {
              final colName = colRow.read<String>('name');
              final isPk = colRow.read<int>('pk') > 0;
              cols.add(colName);
              if (isPk) {
                pks.add(colName);
              }
              if (colName.toLowerCase() == 'updated_at') {
                hasUpdatedAt = true;
              }
            }

            if (cols.isEmpty || pks.isEmpty) {
              continue;
            }

            final colsStr = cols.map((c) => '"$c"').join(', ');
            final pkJoin = pks.map((pk) => 'main."$tableName"."$pk" = backup_db."$tableName"."$pk"').join(' AND ');

            // Step 1: Insert missing records from backup
            await db.customStatement('''
              INSERT INTO main."$tableName" ($colsStr)
              SELECT $colsStr
              FROM backup_db."$tableName"
              WHERE NOT EXISTS (
                SELECT 1 FROM main."$tableName" WHERE $pkJoin
              );
            ''');

            // Step 2: Update shared records where backup is newer
            final nonPkCols = cols.where((c) => !pks.contains(c)).toList();
            if (hasUpdatedAt && nonPkCols.isNotEmpty) {
              final setClause = nonPkCols.map((c) => '"$c" = (SELECT b."$c" FROM backup_db."$tableName" b WHERE ${pks.map((pk) => 'b."$pk" = main."$tableName"."$pk"').join(' AND ')})').join(', ');

              await db.customStatement('''
                UPDATE main."$tableName"
                SET $setClause
                WHERE EXISTS (
                  SELECT 1 FROM backup_db."$tableName" b
                  WHERE ${pks.map((pk) => 'b."$pk" = main."$tableName"."$pk"').join(' AND ')}
                    AND b."updated_at" > main."$tableName"."updated_at"
                );
              ''');
            }

            processedTables++;
          }
        } finally {
          await db.customStatement("DETACH DATABASE backup_db;");
          await db.customStatement('PRAGMA foreign_keys = ON;');
        }
      } else {
        // Fallback to direct sqlite3 connection
        final mainDb = sqlite.sqlite3.open(activeDbFile.path);
        try {
          mainDb.execute('PRAGMA foreign_keys = OFF;');
          mainDb.execute("ATTACH DATABASE '$escapedBackupPath' AS backup_db;");

          final tables = mainDb.select("SELECT name FROM backup_db.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%' AND name NOT LIKE '_drift_%';");
          for (final row in tables) {
            final tableName = row['name'] as String;
            final mainCheck = mainDb.select('SELECT name FROM main.sqlite_master WHERE type=\'table\' AND name = ?;', [tableName]);
            if (mainCheck.isEmpty) {
              continue;
            }

            final info = mainDb.select('PRAGMA main.table_info("$tableName");');
            final cols = <String>[];
            final pks = <String>[];
            bool hasUpdatedAt = false;

            for (final col in info) {
              final colName = col['name'] as String;
              final isPk = (col['pk'] as int) > 0;
              cols.add(colName);
              if (isPk) {
                pks.add(colName);
              }
              if (colName.toLowerCase() == 'updated_at') {
                hasUpdatedAt = true;
              }
            }

            if (cols.isEmpty || pks.isEmpty) {
              continue;
            }

            final colsStr = cols.map((c) => '"$c"').join(', ');
            final pkJoin = pks.map((pk) => 'main."$tableName"."$pk" = backup_db."$tableName"."$pk"').join(' AND ');

            mainDb.execute('''
              INSERT INTO main."$tableName" ($colsStr)
              SELECT $colsStr
              FROM backup_db."$tableName"
              WHERE NOT EXISTS (
                SELECT 1 FROM main."$tableName" WHERE $pkJoin
              );
            ''');

            final nonPkCols = cols.where((c) => !pks.contains(c)).toList();
            if (hasUpdatedAt && nonPkCols.isNotEmpty) {
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

            processedTables++;
          }
          mainDb.execute("DETACH DATABASE backup_db;");
          mainDb.execute('PRAGMA foreign_keys = ON;');
        } finally {
          mainDb.dispose();
        }
      }

      return SmartMergeStats(tablesCount: processedTables);
    } finally {
      if (await tempRestoredFile.exists()) {
        await tempRestoredFile.delete();
      }
    }
  }

  /// List all local .smbak files in the backups directory
  static Future<List<BackupFileItem>> listLocalBackups() async {
    final folder = await getBackupsDirectory();
    final entities = await folder.list().toList();
    final results = <BackupFileItem>[];

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith(fileExtension)) {
        final stat = await entity.stat();
        BackupMetadata? meta;
        try {
          meta = await readMetadata(entity);
        } catch (_) {}

        results.add(
          BackupFileItem(
            file: entity,
            fileName: p.basename(entity.path),
            fileSizeBytes: stat.size,
            modifiedAt: stat.modified,
            metadata: meta,
          ),
        );
      }
    }

    results.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return results;
  }
}
