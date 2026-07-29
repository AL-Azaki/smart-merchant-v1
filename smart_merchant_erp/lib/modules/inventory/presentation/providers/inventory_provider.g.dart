// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeWarehousesHash() => r'1734041a8572fe517cb075b1bfabf353fe65dbc7';

/// See also [activeWarehouses].
@ProviderFor(activeWarehouses)
final activeWarehousesProvider =
    AutoDisposeFutureProvider<List<Warehouse>>.internal(
      activeWarehouses,
      name: r'activeWarehousesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeWarehousesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveWarehousesRef = AutoDisposeFutureProviderRef<List<Warehouse>>;
String _$warehouseStockBalancesHash() =>
    r'9afea9206b3ca9e63829412d01661188e3313f71';

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

/// See also [warehouseStockBalances].
@ProviderFor(warehouseStockBalances)
const warehouseStockBalancesProvider = WarehouseStockBalancesFamily();

/// See also [warehouseStockBalances].
class WarehouseStockBalancesFamily
    extends Family<AsyncValue<List<StockBalanceView>>> {
  /// See also [warehouseStockBalances].
  const WarehouseStockBalancesFamily();

  /// See also [warehouseStockBalances].
  WarehouseStockBalancesProvider call(String warehouseId) {
    return WarehouseStockBalancesProvider(warehouseId);
  }

  @override
  WarehouseStockBalancesProvider getProviderOverride(
    covariant WarehouseStockBalancesProvider provider,
  ) {
    return call(provider.warehouseId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'warehouseStockBalancesProvider';
}

/// See also [warehouseStockBalances].
class WarehouseStockBalancesProvider
    extends AutoDisposeFutureProvider<List<StockBalanceView>> {
  /// See also [warehouseStockBalances].
  WarehouseStockBalancesProvider(String warehouseId)
    : this._internal(
        (ref) => warehouseStockBalances(
          ref as WarehouseStockBalancesRef,
          warehouseId,
        ),
        from: warehouseStockBalancesProvider,
        name: r'warehouseStockBalancesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$warehouseStockBalancesHash,
        dependencies: WarehouseStockBalancesFamily._dependencies,
        allTransitiveDependencies:
            WarehouseStockBalancesFamily._allTransitiveDependencies,
        warehouseId: warehouseId,
      );

  WarehouseStockBalancesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.warehouseId,
  }) : super.internal();

  final String warehouseId;

  @override
  Override overrideWith(
    FutureOr<List<StockBalanceView>> Function(
      WarehouseStockBalancesRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WarehouseStockBalancesProvider._internal(
        (ref) => create(ref as WarehouseStockBalancesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        warehouseId: warehouseId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StockBalanceView>> createElement() {
    return _WarehouseStockBalancesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WarehouseStockBalancesProvider &&
        other.warehouseId == warehouseId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, warehouseId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WarehouseStockBalancesRef
    on AutoDisposeFutureProviderRef<List<StockBalanceView>> {
  /// The parameter `warehouseId` of this provider.
  String get warehouseId;
}

class _WarehouseStockBalancesProviderElement
    extends AutoDisposeFutureProviderElement<List<StockBalanceView>>
    with WarehouseStockBalancesRef {
  _WarehouseStockBalancesProviderElement(super.provider);

  @override
  String get warehouseId =>
      (origin as WarehouseStockBalancesProvider).warehouseId;
}

String _$stockAdjustmentsListHash() =>
    r'836a3cf4dc7252572af581f23a2e43168bacd524';

/// See also [stockAdjustmentsList].
@ProviderFor(stockAdjustmentsList)
final stockAdjustmentsListProvider =
    AutoDisposeStreamProvider<List<InventoryTransaction>>.internal(
      stockAdjustmentsList,
      name: r'stockAdjustmentsListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockAdjustmentsListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StockAdjustmentsListRef =
    AutoDisposeStreamProviderRef<List<InventoryTransaction>>;
String _$transferNotifierHash() => r'409283c595bc6f356ad03662d75702b4b5d94b2b';

/// See also [TransferNotifier].
@ProviderFor(TransferNotifier)
final transferNotifierProvider =
    AutoDisposeNotifierProvider<TransferNotifier, TransferState>.internal(
      TransferNotifier.new,
      name: r'transferNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transferNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TransferNotifier = AutoDisposeNotifier<TransferState>;
String _$stockAdjustmentNotifierHash() =>
    r'b25aba42a377b39a42f5b0da8610d487f480780b';

/// See also [StockAdjustmentNotifier].
@ProviderFor(StockAdjustmentNotifier)
final stockAdjustmentNotifierProvider =
    AutoDisposeNotifierProvider<
      StockAdjustmentNotifier,
      StockAdjustmentState
    >.internal(
      StockAdjustmentNotifier.new,
      name: r'stockAdjustmentNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockAdjustmentNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StockAdjustmentNotifier = AutoDisposeNotifier<StockAdjustmentState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
