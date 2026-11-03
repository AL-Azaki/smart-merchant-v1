import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_permissions_model.dart';

class UserPermissionsService {
  static const String _storageKey = 'smart_merchant_erp_users_v2';
  static const String _activeUserKey = 'smart_merchant_erp_active_user_id_v2';

  /// Load all users from persistent storage, or seed defaults if empty.
  static Future<List<AppUserModel>> loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);

      if (rawJson != null && rawJson.trim().isNotEmpty) {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          final users = decoded
              .whereType<Map<dynamic, dynamic>>()
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

  /// Save the entire list of users
  static Future<void> saveAllUsers(List<AppUserModel> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
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

  /// Delete a user by ID
  static Future<List<AppUserModel>> deleteUser(String userId) async {
    final users = await loadUsers();
    users.removeWhere((u) => u.id == userId);
    await saveAllUsers(users);

    // If active user was deleted, reset active user to admin or first remaining
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

    // Default to admin or first active user
    final fallback = users.where((u) => u.isActive).firstOrNull ??
        users.firstOrNull ??
        AppUserModel.defaultAdmin();

    await setActiveUserId(fallback.id);
    return fallback;
  }
}
