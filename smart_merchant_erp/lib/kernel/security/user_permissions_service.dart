

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/di/getit_instance.dart';
import '../storage/app_database.dart';
import 'user_permissions_model.dart';

class UserPermissionsService {
  static const String _storageKey = 'smart_merchant_erp_users_v2';
  static const String _activeUserKey = 'smart_merchant_erp_active_user_id_v2';
  static bool _sqliteTableInitialized = false;

  /// Ensure real SQLite 'user_permissions' table exists in AppDatabase
  static Future<void> _ensureSqliteTable() async {
    if (_sqliteTableInitialized) {
      return;
    }
    try {
      if (getIt.isRegistered<AppDatabase>()) {
        final db = getIt<AppDatabase>();
        await db.customStatement('''
          CREATE TABLE IF NOT EXISTS user_permissions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            module TEXT NOT NULL,
            can_view INTEGER NOT NULL DEFAULT 0,
            can_add INTEGER NOT NULL DEFAULT 0,
            can_edit INTEGER NOT NULL DEFAULT 0,
            can_delete INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT
          );
        ''');
        _sqliteTableInitialized = true;
      }
    } catch (e) {
      debugPrint('Notice on ensuring user_permissions table: $e');
    }
  }

  /// Sync user permissions to the SQLite 'user_permissions' table
  static Future<void> _syncToSqlite(AppUserModel user) async {
    try {
      await _ensureSqliteTable();
      if (!getIt.isRegistered<AppDatabase>()) {
        return;
      }
      final db = getIt<AppDatabase>();

      for (final entry in user.permissions.entries) {
        final permId = '${user.id}_${entry.key}';
        final p = entry.value;
        final nowStr = DateTime.now().toIso8601String();

        await db.customStatement('''
          INSERT OR REPLACE INTO user_permissions (id, user_id, module, can_view, can_add, can_edit, can_delete, updated_at)
          VALUES ('$permId', '${user.id}', '${entry.key}', ${p.canView ? 1 : 0}, ${p.canAdd ? 1 : 0}, ${p.canEdit ? 1 : 0}, ${p.canDelete ? 1 : 0}, '$nowStr');
        ''');
      }
    } catch (e) {
      debugPrint('Notice syncing permissions to SQLite: $e');
    }
  }

  /// Load all users from persistent storage and sync with SQLite
  static Future<List<AppUserModel>> loadUsers() async {
    await _ensureSqliteTable();
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);

      if (rawJson != null && rawJson.trim().isNotEmpty) {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          final users = decoded
              .whereType<Map>()
              .map((item) => AppUserModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          if (users.isNotEmpty) {
            return users;
          }
        }
      }
    } catch (e, st) {
      debugPrint('Error loading users from storage: $e\n$st');
    }

    // Default Seed Users (Admin + Cashier + Storekeeper)
    final defaultUsers = [
      AppUserModel.defaultAdmin(),
      AppUserModel.defaultCashier(),
      AppUserModel.defaultStorekeeper(),
    ];

    await saveAllUsers(defaultUsers);
    await setActiveUserId(defaultUsers.first.id);
    return defaultUsers;
  }

  /// Save the entire list of users and sync each to SQLite
  static Future<void> saveAllUsers(List<AppUserModel> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_storageKey, encoded);

      for (final u in users) {
        await _syncToSqlite(u);
      }
    } catch (e, st) {
      debugPrint('Error saving all users: $e\n$st');
    }
  }

  /// Save or update a single user
  static Future<List<AppUserModel>> saveUser(AppUserModel user) async {
    final users = await loadUsers();
    final index = users.indexWhere((u) => u.id == user.id);

    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }

    await saveAllUsers(users);
    return users;
  }

  /// Update only the permissions of a specific user
  static Future<List<AppUserModel>> updateUserPermissions({
    required String userId,
    required String rolePreset,
    required Map<String, ModuleActionPermission> permissions,
  }) async {
    final users = await loadUsers();
    final index = users.indexWhere((u) => u.id == userId);

    if (index >= 0) {
      final current = users[index];
      final updated = current.copyWith(
        rolePreset: rolePreset,
        permissions: permissions,
      );
      users[index] = updated;
      await saveAllUsers(users);
    }

    return users;
  }

  /// Delete a user by ID and delete from SQLite permissions table
  static Future<List<AppUserModel>> deleteUser(String userId) async {
    final users = await loadUsers();
    users.removeWhere((u) => u.id == userId);
    await saveAllUsers(users);

    try {
      await _ensureSqliteTable();
      if (getIt.isRegistered<AppDatabase>()) {
        final db = getIt<AppDatabase>();
        await db.customStatement(
          "DELETE FROM user_permissions WHERE user_id = '$userId';",
        );
      }
    } catch (e) {
      debugPrint('Notice deleting user permissions from SQLite: $e');
    }

    final currentActive = await getActiveUserId();
    if (currentActive == userId) {
      if (users.isNotEmpty) {
        await setActiveUserId(users.first.id);
      }
    }

    return users;
  }

  /// Toggle user active status
  static Future<List<AppUserModel>> toggleUserStatus(String userId) async {
    final users = await loadUsers();
    final index = users.indexWhere((u) => u.id == userId);
    if (index >= 0) {
      final current = users[index];
      users[index] = current.copyWith(isActive: !current.isActive);
      await saveAllUsers(users);
    }
    return users;
  }

  /// Get active user ID
  static Future<String?> getActiveUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeUserKey);
    } catch (_) {
      return null;
    }
  }

  /// Set active user ID
  static Future<void> setActiveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeUserKey, userId);
    } catch (e) {
      debugPrint('Error setting active user ID: $e');
    }
  }

  /// Get current active user object
  static Future<AppUserModel> getActiveUser() async {
    final users = await loadUsers();
    final activeId = await getActiveUserId();

    if (activeId != null) {
      final found = users.where((u) => u.id == activeId).firstOrNull;
      if (found != null && found.isActive) {
        return found;
      }
    }

    final fallback = users.where((u) => u.isActive).firstOrNull ??
        users.firstOrNull ??
        AppUserModel.defaultAdmin();

    await setActiveUserId(fallback.id);
    return fallback;
  }

  /// Direct SQL query to verify permissions table rows for any user
  static Future<List<Map<String, dynamic>>> querySqliteUserPermissions(String userId) async {
    try {
      await _ensureSqliteTable();
      if (getIt.isRegistered<AppDatabase>()) {
        final db = getIt<AppDatabase>();
        final rows = await db.customSelect(
          'SELECT * FROM user_permissions WHERE user_id = ? ORDER BY module ASC',
          variables: [drift.Variable.withString(userId)],
        ).get();
        return rows.map((r) => r.data).toList();
      }
    } catch (e) {
      debugPrint('Error querying user_permissions SQL: $e');
    }
    return [];
  }
}
