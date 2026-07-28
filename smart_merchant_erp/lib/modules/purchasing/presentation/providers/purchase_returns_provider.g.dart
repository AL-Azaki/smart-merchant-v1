// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_returns_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$purchaseReturnsFutureHash() =>
    r'90387227bbd69557d38ed4628aba78dee4e3bdd1';

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

/// See also [purchaseReturnsFuture].
@ProviderFor(purchaseReturnsFuture)
const purchaseReturnsFutureProvider = PurchaseReturnsFutureFamily();

/// See also [purchaseReturnsFuture].
class PurchaseReturnsFutureFamily
    extends Family<AsyncValue<List<PurchaseReturn>>> {
  /// See also [purchaseReturnsFuture].
  const PurchaseReturnsFutureFamily();

  /// See also [purchaseReturnsFuture].
  PurchaseReturnsFutureProvider call({String? searchQuery}) {
    return PurchaseReturnsFutureProvider(searchQuery: searchQuery);
  }

  @override
  PurchaseReturnsFutureProvider getProviderOverride(
    covariant PurchaseReturnsFutureProvider provider,
  ) {
    return call(searchQuery: provider.searchQuery);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'purchaseReturnsFutureProvider';
}

/// See also [purchaseReturnsFuture].
class PurchaseReturnsFutureProvider
    extends AutoDisposeFutureProvider<List<PurchaseReturn>> {
  /// See also [purchaseReturnsFuture].
  PurchaseReturnsFutureProvider({String? searchQuery})
    : this._internal(
        (ref) => purchaseReturnsFuture(
          ref as PurchaseReturnsFutureRef,
          searchQuery: searchQuery,
        ),
        from: purchaseReturnsFutureProvider,
        name: r'purchaseReturnsFutureProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$purchaseReturnsFutureHash,
        dependencies: PurchaseReturnsFutureFamily._dependencies,
        allTransitiveDependencies:
            PurchaseReturnsFutureFamily._allTransitiveDependencies,
        searchQuery: searchQuery,
      );

  PurchaseReturnsFutureProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.searchQuery,
  }) : super.internal();

  final String? searchQuery;

  @override
  Override overrideWith(
    FutureOr<List<PurchaseReturn>> Function(PurchaseReturnsFutureRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PurchaseReturnsFutureProvider._internal(
        (ref) => create(ref as PurchaseReturnsFutureRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        searchQuery: searchQuery,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PurchaseReturn>> createElement() {
    return _PurchaseReturnsFutureProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PurchaseReturnsFutureProvider &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, searchQuery.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PurchaseReturnsFutureRef
    on AutoDisposeFutureProviderRef<List<PurchaseReturn>> {
  /// The parameter `searchQuery` of this provider.
  String? get searchQuery;
}

class _PurchaseReturnsFutureProviderElement
    extends AutoDisposeFutureProviderElement<List<PurchaseReturn>>
    with PurchaseReturnsFutureRef {
  _PurchaseReturnsFutureProviderElement(super.provider);

  @override
  String? get searchQuery =>
      (origin as PurchaseReturnsFutureProvider).searchQuery;
}

String _$purchaseReturnNotifierHash() =>
    r'd1b8b19062a04cbd241410e5bb66b421dc0a710b';

/// See also [PurchaseReturnNotifier].
@ProviderFor(PurchaseReturnNotifier)
final purchaseReturnNotifierProvider =
    AutoDisposeNotifierProvider<
      PurchaseReturnNotifier,
      PurchaseReturnState
    >.internal(
      PurchaseReturnNotifier.new,
      name: r'purchaseReturnNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$purchaseReturnNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PurchaseReturnNotifier = AutoDisposeNotifier<PurchaseReturnState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
