// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$customerBalanceHash() => r'8a97cad970089c75b63a5f7cad3fe615389c2460';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [customerBalance].
@ProviderFor(customerBalance)
const customerBalanceProvider = CustomerBalanceFamily();

/// See also [customerBalance].
class CustomerBalanceFamily
    extends Family<AsyncValue<CustomerBalanceSummary?>> {
  /// See also [customerBalance].
  const CustomerBalanceFamily();

  /// See also [customerBalance].
  CustomerBalanceProvider call(String customerId) {
    return CustomerBalanceProvider(customerId);
  }

  @override
  CustomerBalanceProvider getProviderOverride(
    covariant CustomerBalanceProvider provider,
  ) {
    return call(provider.customerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'customerBalanceProvider';
}

/// See also [customerBalance].
class CustomerBalanceProvider
    extends AutoDisposeFutureProvider<CustomerBalanceSummary?> {
  /// See also [customerBalance].
  CustomerBalanceProvider(String customerId)
    : this._internal(
        (ref) => customerBalance(ref as CustomerBalanceRef, customerId),
        from: customerBalanceProvider,
        name: r'customerBalanceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$customerBalanceHash,
        dependencies: CustomerBalanceFamily._dependencies,
        allTransitiveDependencies:
            CustomerBalanceFamily._allTransitiveDependencies,
        customerId: customerId,
      );

  CustomerBalanceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.customerId,
  }) : super.internal();

  final String customerId;

  @override
  Override overrideWith(
    FutureOr<CustomerBalanceSummary?> Function(CustomerBalanceRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CustomerBalanceProvider._internal(
        (ref) => create(ref as CustomerBalanceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        customerId: customerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CustomerBalanceSummary?> createElement() {
    return _CustomerBalanceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerBalanceProvider && other.customerId == customerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, customerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CustomerBalanceRef
    on AutoDisposeFutureProviderRef<CustomerBalanceSummary?> {
  /// The parameter `customerId` of this provider.
  String get customerId;
}

class _CustomerBalanceProviderElement
    extends AutoDisposeFutureProviderElement<CustomerBalanceSummary?>
    with CustomerBalanceRef {
  _CustomerBalanceProviderElement(super.provider);

  @override
  String get customerId => (origin as CustomerBalanceProvider).customerId;
}

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
