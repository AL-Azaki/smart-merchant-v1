// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_orders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onlineOrdersNotifierHash() =>
    r'bf1c93e720734ea52494fc9ee2c4d0abe5ae4020';

/// Reactive stream provider for online orders from SQLite.
///
/// Copied from [OnlineOrdersNotifier].
@ProviderFor(OnlineOrdersNotifier)
final onlineOrdersNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      OnlineOrdersNotifier,
      List<OrderEntity>
    >.internal(
      OnlineOrdersNotifier.new,
      name: r'onlineOrdersNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$onlineOrdersNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnlineOrdersNotifier = AutoDisposeStreamNotifier<List<OrderEntity>>;
String _$onlineOrdersActionNotifierHash() =>
    r'f94d601ed9cd32ae310284f0784633d8adab3a98';

/// Stateful notifier for UI actions (accept, reject, select, filter, search).
///
/// Copied from [OnlineOrdersActionNotifier].
@ProviderFor(OnlineOrdersActionNotifier)
final onlineOrdersActionNotifierProvider =
    AutoDisposeNotifierProvider<
      OnlineOrdersActionNotifier,
      OnlineOrdersState
    >.internal(
      OnlineOrdersActionNotifier.new,
      name: r'onlineOrdersActionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$onlineOrdersActionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnlineOrdersActionNotifier = AutoDisposeNotifier<OnlineOrdersState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
