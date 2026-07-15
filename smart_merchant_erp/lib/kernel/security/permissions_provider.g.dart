// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permissions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$modulesNotifierHash() => r'cf30790a75030e7416d08d999c02895af800104d';

/// Modules Provider controls the visibility of major system sections based on the Subscription Plan.
///
/// Copied from [ModulesNotifier].
@ProviderFor(ModulesNotifier)
final modulesNotifierProvider =
    NotifierProvider<ModulesNotifier, Set<ErpModule>>.internal(
      ModulesNotifier.new,
      name: r'modulesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$modulesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ModulesNotifier = Notifier<Set<ErpModule>>;
String _$permissionsNotifierHash() =>
    r'06035fd86e70188206f25c2c92fdf7fcaddf15ea';

/// Permissions Provider controls granular actions based on the User's Role.
///
/// Copied from [PermissionsNotifier].
@ProviderFor(PermissionsNotifier)
final permissionsNotifierProvider =
    NotifierProvider<PermissionsNotifier, Set<ErpPermission>>.internal(
      PermissionsNotifier.new,
      name: r'permissionsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$permissionsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PermissionsNotifier = Notifier<Set<ErpPermission>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
