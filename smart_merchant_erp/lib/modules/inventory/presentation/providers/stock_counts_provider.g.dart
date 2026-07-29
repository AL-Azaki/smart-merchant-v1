// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_counts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stockCountsNotifierHash() =>
    r'e3cc5c8b31a18fbca7ae1102e02a83ac5996b506';

/// See also [StockCountsNotifier].
@ProviderFor(StockCountsNotifier)
final stockCountsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      StockCountsNotifier,
      List<StockCount>
    >.internal(
      StockCountsNotifier.new,
      name: r'stockCountsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockCountsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StockCountsNotifier = AutoDisposeAsyncNotifier<List<StockCount>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
