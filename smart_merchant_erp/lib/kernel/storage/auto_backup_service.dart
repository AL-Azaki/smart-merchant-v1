import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_backup_service.dart';

class AutoBackupService {
  static const String _keyEnabled = 'sp_auto_backup_enabled';
  static const String _keyFrequency = 'sp_auto_backup_frequency';
  static const String _keyRetention = 'sp_auto_backup_retention';
  static const String _keyLastRun = 'sp_auto_backup_last_run';
  static const String _secKeyPassword = 'sec_auto_backup_password';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  static Future<String> getFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFrequency) ?? 'daily';
  }

  static Future<void> setFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFrequency, frequency);
  }

  static Future<int> getRetentionLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRetention) ?? 7;
  }

  static Future<void> setRetentionLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRetention, limit);
  }

  static Future<DateTime?> getLastRunTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_keyLastRun);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<bool> hasPassword() async {
    final pwd = await _secureStorage.read(key: _secKeyPassword);
    return pwd != null && pwd.trim().isNotEmpty;
  }

  static Future<void> setPassword(String password) async {
    await _secureStorage.write(key: _secKeyPassword, value: password.trim());
  }

  static Future<String?> getPassword() async {
    return _secureStorage.read(key: _secKeyPassword);
  }

  static Future<void> clearPassword() async {
    await _secureStorage.delete(key: _secKeyPassword);
  }

  /// Checks conditions and triggers automated background backup if due
  static Future<File?> checkAndRunAutoBackup({bool force = false}) async {
    final enabled = await isEnabled();
    if (!enabled && !force) {
      return null;
    }

    final password = await getPassword();
    if (password == null || password.trim().isEmpty) {
      debugPrint('AutoBackup: Skipping, password is not configured.');
      return null;
    }

    if (!force) {
      final lastRun = await getLastRunTime();
      final frequency = await getFrequency();

      if (lastRun != null) {
        final elapsed = DateTime.now().difference(lastRun);
        if (frequency == 'daily' && elapsed.inHours < 24) {
          return null; // Not due yet
        }
        if (frequency == 'weekly' && elapsed.inDays < 7) {
          return null; // Not due yet
        }
      }
    }

    try {
      debugPrint('AutoBackup: Triggering automated snapshot...');
      final file = await LocalBackupService.createBackup(
        password: password,
        notes: 'نسخة تلقائية مجدولة',
        fileNamePrefix: 'AutoBackup_',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastRun, DateTime.now().millisecondsSinceEpoch);

      // Perform retention rotation (delete oldest auto backups beyond retention limit)
      await _rotateRetentionBackups();

      debugPrint('AutoBackup: Successfully completed -> ${file.path}');
      return file;
    } catch (e) {
      debugPrint('AutoBackup: Error during execution: $e');
      return null;
    }
  }

  /// Keeps only the last [retentionLimit] auto-backup files
  static Future<void> _rotateRetentionBackups() async {
    try {
      final limit = await getRetentionLimit();
      final backupDir = await LocalBackupService.getBackupsDirectory();
      final files = await backupDir.list().toList();

      final autoBackups = <File>[];
      for (final entity in files) {
        if (entity is File && p.basename(entity.path).startsWith('AutoBackup_')) {
          autoBackups.add(entity);
        }
      }

      // Sort newest first
      autoBackups.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Delete older ones exceeding limit
      if (autoBackups.length > limit) {
        final toDelete = autoBackups.sublist(limit);
        for (final oldFile in toDelete) {
          if (await oldFile.exists()) {
            await oldFile.delete();
            debugPrint('AutoBackup: Rotated/deleted older backup: ${oldFile.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('AutoBackup: Retention cleanup error: $e');
    }
  }
}
