import 'package:riverpod_annotation/riverpod_annotation.dart';

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

/// Modules Provider controls the visibility of major system sections based on the Subscription Plan.
@Riverpod(keepAlive: true)
class ModulesNotifier extends _$ModulesNotifier {
  @override
  Set<ErpModule> build() {
    // For demonstration, let's say the current plan only allows Sales, Inventory, and Settings.
    // The Accounting module is EXCLUDED.
    return {
      ErpModule.sales,
      ErpModule.inventory,
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
    return {
      ErpPermission.viewSales,
      ErpPermission.createInvoice,
    };
  }

  bool hasPermission(ErpPermission permission) {
    return state.contains(permission);
  }
}
