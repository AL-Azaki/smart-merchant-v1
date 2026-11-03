import 'package:flutter/material.dart';

/// Represents granular CRUD action permissions for a specific module/page.
class ModuleActionPermission {
  final bool canView;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;

  const ModuleActionPermission({
    this.canView = false,
    this.canAdd = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  /// Full access (All 4 actions allowed)
  const ModuleActionPermission.all()
      : canView = true,
        canAdd = true,
        canEdit = true,
        canDelete = true;

  /// No access (All actions forbidden)
  const ModuleActionPermission.none()
      : canView = false,
        canAdd = false,
        canEdit = false,
        canDelete = false;

  /// Read-only access (View only)
  const ModuleActionPermission.viewOnly()
      : canView = true,
        canAdd = false,
        canEdit = false,
        canDelete = false;

  /// View and Add access (Typical cashier / creator)
  const ModuleActionPermission.viewAndAdd()
      : canView = true,
        canAdd = true,
        canEdit = false,
        canDelete = false;

  /// View, Add, and Edit access (No Delete)
  const ModuleActionPermission.viewAddEdit()
      : canView = true,
        canAdd = true,
        canEdit = true,
        canDelete = false;

  bool hasAction(String action) {
    switch (action.toLowerCase()) {
      case 'view':
      case 'عرض':
        return canView;
      case 'add':
      case 'create':
      case 'إضافة':
      case 'اضافة':
        return canAdd;
      case 'edit':
      case 'update':
      case 'تعديل':
        return canEdit;
      case 'delete':
      case 'حذف':
        return canDelete;
      default:
        return false;
    }
  }

  bool get hasAny => canView || canAdd || canEdit || canDelete;
  bool get isFull => canView && canAdd && canEdit && canDelete;

  ModuleActionPermission copyWith({
    bool? canView,
    bool? canAdd,
    bool? canEdit,
    bool? canDelete,
  }) {
    return ModuleActionPermission(
      canView: canView ?? this.canView,
      canAdd: canAdd ?? this.canAdd,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  Map<String, dynamic> toJson() => {
        'view': canView,
        'add': canAdd,
        'edit': canEdit,
        'delete': canDelete,
      };

  factory ModuleActionPermission.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ModuleActionPermission.none();
    }
    return ModuleActionPermission(
      canView: json['view'] == true,
      canAdd: json['add'] == true,
      canEdit: json['edit'] == true,
      canDelete: json['delete'] == true,
    );
  }
}

/// System modules definitions
class SystemModules {
  static const String sales = 'sales';
  static const String purchases = 'purchases';
  static const String inventory = 'inventory';
  static const String finance = 'finance';
  static const String hr = 'hr';
  static const String settings = 'settings';

  static const List<ModuleDefinition> all = [
    ModuleDefinition(
      id: sales,
      title: 'المبيعات',
      subtitle: 'فواتير المبيعات، عروض الأسعار والعملاء',
      icon: Icons.shopping_cart_rounded,
      color: Color(0xFF3B82F6),
    ),
    ModuleDefinition(
      id: purchases,
      title: 'المشتريات',
      subtitle: 'فواتير الشراء، الموردين وسندات الاستلام',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF8B5CF6),
    ),
    ModuleDefinition(
      id: inventory,
      title: 'المخزون والمنتجات',
      subtitle: 'بطاقات الأصناف، المستودعات والجرد',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFFF59E0B),
    ),
    ModuleDefinition(
      id: finance,
      title: 'المالية والخزينة',
      subtitle: 'سندات الصرف والقبض، الخزينة والمصروفات',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF10B981),
    ),
    ModuleDefinition(
      id: hr,
      title: 'الموظفين والرواتب',
      subtitle: 'بيانات الموظفين، السلف ومستحقات الرواتب',
      icon: Icons.badge_rounded,
      color: Color(0xFFEC4899),
    ),
    ModuleDefinition(
      id: settings,
      title: 'الإعدادات والنظام',
      subtitle: 'إدارة المستخدمين، الفروع وتهيئة النظام',
      icon: Icons.settings_rounded,
      color: Color(0xFF6366F1),
    ),
  ];
}

class ModuleDefinition {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ModuleDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

/// Represents an Application User with their granular permissions.
class AppUserModel {
  final String id;
  final String name;
  final String username;
  final String password;
  final DateTime createdAt;
  final Map<String, ModuleActionPermission> permissions;
  final String? phone;
  final String rolePreset;
  final String branch;
  final bool isActive;

  const AppUserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.createdAt,
    required this.permissions,
    this.phone,
    this.rolePreset = 'custom',
    this.branch = 'الفرع الرئيسي',
    this.isActive = true,
  });

  /// Helper to check if user has permission on a given module and action
  bool can(String moduleId, String action) {
    if (!isActive) {
      return false;
    }
    // Full admin always has access
    if (rolePreset == 'admin' && permissions[moduleId]?.canView != false) {
      return true;
    }
    final perm = permissions[moduleId];
    if (perm == null) {
      return false;
    }
    return perm.hasAction(action);
  }

  bool canView(String moduleId) => can(moduleId, 'view');
  bool canAdd(String moduleId) => can(moduleId, 'add');
  bool canEdit(String moduleId) => can(moduleId, 'edit');
  bool canDelete(String moduleId) => can(moduleId, 'delete');

  /// Human readable role title
  String get roleTitle {
    switch (rolePreset) {
      case 'admin':
        return 'مدير النظام (Admin)';
      case 'cashier':
        return 'كاشير مبيعات (Cashier)';
      case 'purchaser':
        return 'مسؤول مشتريات (Purchaser)';
      case 'inventory_keeper':
        return 'أمين مخزن (Storekeeper)';
      case 'accountant':
        return 'محاسب مالي (Accountant)';
      default:
        return 'صلاحيات مخصصة (Custom)';
    }
  }

  /// Default Admin User
  factory AppUserModel.defaultAdmin() {
    return AppUserModel(
      id: 'user_admin_001',
      name: 'مدير النظام',
      username: 'admin',
      phone: '777000000',
      password: 'admin',
      rolePreset: 'admin',
      branch: 'المركز الرئيسي',
      createdAt: DateTime(2026, 1, 1),
      permissions: {
        SystemModules.sales: const ModuleActionPermission.all(),
        SystemModules.purchases: const ModuleActionPermission.all(),
        SystemModules.inventory: const ModuleActionPermission.all(),
        SystemModules.finance: const ModuleActionPermission.all(),
        SystemModules.hr: const ModuleActionPermission.all(),
        SystemModules.settings: const ModuleActionPermission.all(),
      },
    );
  }

  /// Default Cashier User
  factory AppUserModel.defaultCashier() {
    return AppUserModel(
      id: 'user_cashier_002',
      name: 'أحمد الكاشير',
      username: 'cashier1',
      phone: '771234567',
      password: '123',
      rolePreset: 'cashier',
      branch: 'المركز الرئيسي',
      createdAt: DateTime(2026, 1, 2),
      permissions: {
        SystemModules.sales: const ModuleActionPermission.viewAndAdd(),
        SystemModules.purchases: const ModuleActionPermission.none(),
        SystemModules.inventory: const ModuleActionPermission.viewOnly(),
        SystemModules.finance: const ModuleActionPermission.none(),
        SystemModules.hr: const ModuleActionPermission.none(),
        SystemModules.settings: const ModuleActionPermission.none(),
      },
    );
  }

  /// Default Storekeeper User
  factory AppUserModel.defaultStorekeeper() {
    return AppUserModel(
      id: 'user_store_003',
      name: 'سامي أمين المخزن',
      username: 'storekeeper',
      phone: '778901234',
      password: '123',
      rolePreset: 'inventory_keeper',
      branch: 'المركز الرئيسي',
      createdAt: DateTime(2026, 1, 3),
      permissions: {
        SystemModules.sales: const ModuleActionPermission.viewOnly(),
        SystemModules.purchases: const ModuleActionPermission.viewOnly(),
        SystemModules.inventory: const ModuleActionPermission.viewAddEdit(),
        SystemModules.finance: const ModuleActionPermission.none(),
        SystemModules.hr: const ModuleActionPermission.none(),
        SystemModules.settings: const ModuleActionPermission.none(),
      },
    );
  }

  AppUserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? phone,
    String? password,
    String? rolePreset,
    String? branch,
    bool? isActive,
    DateTime? createdAt,
    Map<String, ModuleActionPermission>? permissions,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      rolePreset: rolePreset ?? this.rolePreset,
      branch: branch ?? this.branch,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toJson() {
    final permsJson = <String, dynamic>{};
    permissions.forEach((key, val) {
      permsJson[key] = val.toJson();
    });

    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'password': password,
      'rolePreset': rolePreset,
      'branch': branch,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'permissions': permsJson,
    };
  }

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    final perms = <String, ModuleActionPermission>{};
    if (json['permissions'] is Map) {
      final rawPerms = json['permissions'] as Map;
      rawPerms.forEach((k, v) {
        if (v is Map) {
          perms[k.toString()] = ModuleActionPermission.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    return AppUserModel(
      id: json['id'] as String? ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String?,
      password: json['password'] as String? ?? '',
      rolePreset: json['rolePreset'] as String? ?? 'custom',
      branch: json['branch'] as String? ?? 'الفرع الرئيسي',
      isActive: json['isActive'] == null ? true : (json['isActive'] as bool),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      permissions: perms,
    );
  }
}
