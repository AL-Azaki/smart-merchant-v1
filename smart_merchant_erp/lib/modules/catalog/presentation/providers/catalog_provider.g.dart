// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productsNotifierHash() => r'4989370f7c687b9d8274ac48f96cab5b514700ce';

/// See also [ProductsNotifier].
@ProviderFor(ProductsNotifier)
final productsNotifierProvider =
    AutoDisposeStreamNotifierProvider<ProductsNotifier, List<Product>>.internal(
      ProductsNotifier.new,
      name: r'productsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$productsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProductsNotifier = AutoDisposeStreamNotifier<List<Product>>;
String _$categoriesNotifierHash() =>
    r'38a3e441882f9a4c798b2f365aaa7d33fdd274e1';

/// See also [CategoriesNotifier].
@ProviderFor(CategoriesNotifier)
final categoriesNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      CategoriesNotifier,
      List<Category>
    >.internal(
      CategoriesNotifier.new,
      name: r'categoriesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoriesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CategoriesNotifier = AutoDisposeStreamNotifier<List<Category>>;
String _$unitsNotifierHash() => r'ac4e6fb026086e06857682d853a4ff0e6bff5ce0';

/// See also [UnitsNotifier].
@ProviderFor(UnitsNotifier)
final unitsNotifierProvider =
    AutoDisposeStreamNotifierProvider<UnitsNotifier, List<Unit>>.internal(
      UnitsNotifier.new,
      name: r'unitsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$unitsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UnitsNotifier = AutoDisposeStreamNotifier<List<Unit>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
