import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'user_permissions_model.dart';
import 'user_permissions_service.dart';

export 'user_permissions_model.dart';
export 'user_permissions_service.dart';
export 'permission_guard.dart';

part 'permissions_provider.g.dart';

/// Define all major modules in the ERP.
enum ErpModule {
  sales,
  inventory,
  accounting,
  purchasing,
  hr,
  crm,
  reports,
  settings,
}

/// Define granular permissions.
enum ErpPermission {
  viewSales,
  createInvoice,
  deleteInvoice,
  viewInventory,
  manageProducts,
  viewAccounting,
  createJournalEntry,
}

/// Active User State Notifier
class ActiveUserNotifier extends StateNotifier<AppUserModel> {
  ActiveUserNotifier() : super(AppUserModel.defaultAdmin()) {
    load();
  }

  Future<void> load() async {
    final user = await UserPermissionsService.getActiveUser();
    state = user;
  }

  Future<void> switchUser(String userId) async {
    await UserPermissionsService.setActiveUserId(userId);
    final user = await UserPermissionsService.getActiveUser();
    state = user;
  }

  Future<void> refresh() async {
    await load();
  }
}

final activeUserProvider = StateNotifierProvider<ActiveUserNotifier, AppUserModel>((ref) {
  return ActiveUserNotifier();
});

/// Users List State Notifier
class UsersListNotifier extends StateNotifier<List<AppUserModel>> {
  final Ref _ref;

  UsersListNotifier(this._ref) : super([]) {
    load();
  }

  Future<void> load() async {
    final list = await UserPermissionsService.loadUsers();
    state = list;
  }

  Future<void> saveUser(AppUserModel user) async {
    final updatedList = await UserPermissionsService.saveUser(user);
    state = updatedList;
    final activeId = await UserPermissionsService.getActiveUserId();
    if (activeId == user.id) {
      await _ref.read(activeUserProvider.notifier).refresh();
    }
  }

  Future<void> updatePermissions({
    required String userId,
    required String rolePreset,
    required Map<String, ModuleActionPermission> permissions,
  }) async {
    final updatedList = await UserPermissionsService.updateUserPermissions(
      userId: userId,
      rolePreset: rolePreset,
      permissions: permissions,
    );
    state = updatedList;
    final activeId = await UserPermissionsService.getActiveUserId();
    if (activeId == userId) {
      await _ref.read(activeUserProvider.notifier).refresh();
    }
  }

  Future<void> deleteUser(String userId) async {
    final updatedList = await UserPermissionsService.deleteUser(userId);
    state = updatedList;
    await _ref.read(activeUserProvider.notifier).refresh();
  }

  Future<void> toggleStatus(String userId) async {
    final updatedList = await UserPermissionsService.toggleUserStatus(userId);
    state = updatedList;
    await _ref.read(activeUserProvider.notifier).refresh();
  }
}

final usersListProvider = StateNotifierProvider<UsersListNotifier, List<AppUserModel>>((ref) {
  return UsersListNotifier(ref);
});

/// Modules Provider controls the visibility of major system sections based on the Subscription Plan and User Permissions.
@Riverpod(keepAlive: true)
class ModulesNotifier extends _$ModulesNotifier {
  @override
  Set<ErpModule> build() {
    return {
      ErpModule.sales,
      ErpModule.inventory,
      ErpModule.accounting,
      ErpModule.settings,
    };
  }

  void loadModulesForPlan(String planId) {
    if (planId == 'basic') {
      state = {ErpModule.sales, ErpModule.settings};
    } else if (planId == 'pro') {
      state = {ErpModule.sales, ErpModule.inventory, ErpModule.settings};
    } else if (planId == 'enterprise') {
      state = ErpModule.values.toSet();
    }
  }

  bool hasModule(ErpModule module) {
    return state.contains(module);
  }
}

/// Permissions Provider controls granular actions based on the User's Role.
@Riverpod(keepAlive: true)
class PermissionsNotifier extends _$PermissionsNotifier {
  @override
  Set<ErpPermission> build() {
    return {ErpPermission.viewSales, ErpPermission.createInvoice};
  }

  bool hasPermission(ErpPermission permission) {
    return state.contains(permission);
  }

  bool can(String module, String action) {
    final activeUser = ref.read(activeUserProvider);
    return activeUser.can(module, action);
  }
}
