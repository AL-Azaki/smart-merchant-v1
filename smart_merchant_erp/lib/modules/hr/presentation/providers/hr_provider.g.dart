// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hr_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$employeesListHash() => r'd14caea420b6c205d6381ea7965488c4fe7ba117';

/// See also [employeesList].
@ProviderFor(employeesList)
final employeesListProvider =
    AutoDisposeStreamProvider<List<Employee>>.internal(
      employeesList,
      name: r'employeesListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$employeesListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EmployeesListRef = AutoDisposeStreamProviderRef<List<Employee>>;
String _$employeeDetailsHash() => r'7749984c73e6bcb0c4879faf33f0fc8a9656686c';

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

/// See also [employeeDetails].
@ProviderFor(employeeDetails)
const employeeDetailsProvider = EmployeeDetailsFamily();

/// See also [employeeDetails].
class EmployeeDetailsFamily extends Family<AsyncValue<EmployeeWithDetails?>> {
  /// See also [employeeDetails].
  const EmployeeDetailsFamily();

  /// See also [employeeDetails].
  EmployeeDetailsProvider call(String id) {
    return EmployeeDetailsProvider(id);
  }

  @override
  EmployeeDetailsProvider getProviderOverride(
    covariant EmployeeDetailsProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'employeeDetailsProvider';
}

/// See also [employeeDetails].
class EmployeeDetailsProvider
    extends AutoDisposeStreamProvider<EmployeeWithDetails?> {
  /// See also [employeeDetails].
  EmployeeDetailsProvider(String id)
    : this._internal(
        (ref) => employeeDetails(ref as EmployeeDetailsRef, id),
        from: employeeDetailsProvider,
        name: r'employeeDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$employeeDetailsHash,
        dependencies: EmployeeDetailsFamily._dependencies,
        allTransitiveDependencies:
            EmployeeDetailsFamily._allTransitiveDependencies,
        id: id,
      );

  EmployeeDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    Stream<EmployeeWithDetails?> Function(EmployeeDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EmployeeDetailsProvider._internal(
        (ref) => create(ref as EmployeeDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<EmployeeWithDetails?> createElement() {
    return _EmployeeDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeDetailsProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EmployeeDetailsRef on AutoDisposeStreamProviderRef<EmployeeWithDetails?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _EmployeeDetailsProviderElement
    extends AutoDisposeStreamProviderElement<EmployeeWithDetails?>
    with EmployeeDetailsRef {
  _EmployeeDetailsProviderElement(super.provider);

  @override
  String get id => (origin as EmployeeDetailsProvider).id;
}

String _$employeeDetailsFutureHash() =>
    r'a9088eeaee7b16265eff30d1c73a13b161d22cd3';

/// See also [employeeDetailsFuture].
@ProviderFor(employeeDetailsFuture)
const employeeDetailsFutureProvider = EmployeeDetailsFutureFamily();

/// See also [employeeDetailsFuture].
class EmployeeDetailsFutureFamily
    extends Family<AsyncValue<EmployeeWithDetails?>> {
  /// See also [employeeDetailsFuture].
  const EmployeeDetailsFutureFamily();

  /// See also [employeeDetailsFuture].
  EmployeeDetailsFutureProvider call(String id) {
    return EmployeeDetailsFutureProvider(id);
  }

  @override
  EmployeeDetailsFutureProvider getProviderOverride(
    covariant EmployeeDetailsFutureProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'employeeDetailsFutureProvider';
}

/// See also [employeeDetailsFuture].
class EmployeeDetailsFutureProvider
    extends AutoDisposeFutureProvider<EmployeeWithDetails?> {
  /// See also [employeeDetailsFuture].
  EmployeeDetailsFutureProvider(String id)
    : this._internal(
        (ref) => employeeDetailsFuture(ref as EmployeeDetailsFutureRef, id),
        from: employeeDetailsFutureProvider,
        name: r'employeeDetailsFutureProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$employeeDetailsFutureHash,
        dependencies: EmployeeDetailsFutureFamily._dependencies,
        allTransitiveDependencies:
            EmployeeDetailsFutureFamily._allTransitiveDependencies,
        id: id,
      );

  EmployeeDetailsFutureProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<EmployeeWithDetails?> Function(EmployeeDetailsFutureRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EmployeeDetailsFutureProvider._internal(
        (ref) => create(ref as EmployeeDetailsFutureRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<EmployeeWithDetails?> createElement() {
    return _EmployeeDetailsFutureProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeDetailsFutureProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EmployeeDetailsFutureRef
    on AutoDisposeFutureProviderRef<EmployeeWithDetails?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _EmployeeDetailsFutureProviderElement
    extends AutoDisposeFutureProviderElement<EmployeeWithDetails?>
    with EmployeeDetailsFutureRef {
  _EmployeeDetailsFutureProviderElement(super.provider);

  @override
  String get id => (origin as EmployeeDetailsFutureProvider).id;
}

String _$hrNotifierHash() => r'9963d53921694a3072630199673c2c5f4457fdff';

/// See also [HrNotifier].
@ProviderFor(HrNotifier)
final hrNotifierProvider =
    AutoDisposeNotifierProvider<HrNotifier, void>.internal(
      HrNotifier.new,
      name: r'hrNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$hrNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HrNotifier = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
