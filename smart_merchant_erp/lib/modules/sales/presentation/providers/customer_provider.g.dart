// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$customersNotifierHash() => r'0b168fc06efbdf2cce297b8fa339b467661be3af';

/// See also [CustomersNotifier].
@ProviderFor(CustomersNotifier)
final customersNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      CustomersNotifier,
      List<Customer>
    >.internal(
      CustomersNotifier.new,
      name: r'customersNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$customersNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CustomersNotifier = AutoDisposeStreamNotifier<List<Customer>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
