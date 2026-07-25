// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productsNotifierHash() => r'1a6321f95bf3e15e0b458d089c41c91c85f777cd';

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
    r'175fcafa20a15c7c05453b666b35299a9959df6b';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
