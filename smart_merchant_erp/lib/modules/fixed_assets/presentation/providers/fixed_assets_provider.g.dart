// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_assets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fixedAssetsListHash() => r'085f4644ab695ae0faefb5d33a0e445f0a5ccaac';

/// See also [fixedAssetsList].
@ProviderFor(fixedAssetsList)
final fixedAssetsListProvider =
    AutoDisposeStreamProvider<List<FixedAsset>>.internal(
      fixedAssetsList,
      name: r'fixedAssetsListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fixedAssetsListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FixedAssetsListRef = AutoDisposeStreamProviderRef<List<FixedAsset>>;
String _$fixedAssetsSearchQueryHash() =>
    r'f664a9bcd47e6467d8b174d4cf53df444a0e50b6';

/// See also [FixedAssetsSearchQuery].
@ProviderFor(FixedAssetsSearchQuery)
final fixedAssetsSearchQueryProvider =
    AutoDisposeNotifierProvider<FixedAssetsSearchQuery, String>.internal(
      FixedAssetsSearchQuery.new,
      name: r'fixedAssetsSearchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fixedAssetsSearchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FixedAssetsSearchQuery = AutoDisposeNotifier<String>;
String _$fixedAssetsNotifierHash() =>
    r'c51966431b8476ff56d2c31371076955a1e4e5ef';

/// See also [FixedAssetsNotifier].
@ProviderFor(FixedAssetsNotifier)
final fixedAssetsNotifierProvider =
    AutoDisposeNotifierProvider<FixedAssetsNotifier, void>.internal(
      FixedAssetsNotifier.new,
      name: r'fixedAssetsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fixedAssetsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FixedAssetsNotifier = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
