// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchasing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeWarehousesStreamHash() =>
    r'2fba045a1126edbc421c7c1b0a43b5ee3ca0c0aa';

/// See also [activeWarehousesStream].
@ProviderFor(activeWarehousesStream)
final activeWarehousesStreamProvider =
    AutoDisposeStreamProvider<List<Warehouse>>.internal(
      activeWarehousesStream,
      name: r'activeWarehousesStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeWarehousesStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveWarehousesStreamRef =
    AutoDisposeStreamProviderRef<List<Warehouse>>;
String _$availableCurrenciesFutureHash() =>
    r'1fcc137d52933fd7ad17e4bc6c9b0e0e0ea668a6';

/// See also [availableCurrenciesFuture].
@ProviderFor(availableCurrenciesFuture)
final availableCurrenciesFutureProvider =
    AutoDisposeFutureProvider<List<CurrencyEntity>>.internal(
      availableCurrenciesFuture,
      name: r'availableCurrenciesFutureProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$availableCurrenciesFutureHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableCurrenciesFutureRef =
    AutoDisposeFutureProviderRef<List<CurrencyEntity>>;
String _$availablePaymentMethodsFutureHash() =>
    r'5f2bd5235108bb6186593daa3af503bfcda4215f';

/// See also [availablePaymentMethodsFuture].
@ProviderFor(availablePaymentMethodsFuture)
final availablePaymentMethodsFutureProvider =
    AutoDisposeFutureProvider<List<PaymentMethod>>.internal(
      availablePaymentMethodsFuture,
      name: r'availablePaymentMethodsFutureProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$availablePaymentMethodsFutureHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailablePaymentMethodsFutureRef =
    AutoDisposeFutureProviderRef<List<PaymentMethod>>;
String _$purchasingNotifierHash() =>
    r'321378fde76c273380c5bea5817a871876dd0b15';

/// See also [PurchasingNotifier].
@ProviderFor(PurchasingNotifier)
final purchasingNotifierProvider =
    AutoDisposeNotifierProvider<PurchasingNotifier, PurchasingState>.internal(
      PurchasingNotifier.new,
      name: r'purchasingNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$purchasingNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PurchasingNotifier = AutoDisposeNotifier<PurchasingState>;
String _$suppliersNotifierHash() => r'3345855f9af088739b8f9f84b17a70f4f08cae9c';

/// See also [SuppliersNotifier].
@ProviderFor(SuppliersNotifier)
final suppliersNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      SuppliersNotifier,
      List<Supplier>
    >.internal(
      SuppliersNotifier.new,
      name: r'suppliersNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$suppliersNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SuppliersNotifier = AutoDisposeStreamNotifier<List<Supplier>>;
String _$purchaseInvoicesNotifierHash() =>
    r'17c90d6283f43a96c9d9511a754891ed078e2834';

/// See also [PurchaseInvoicesNotifier].
@ProviderFor(PurchaseInvoicesNotifier)
final purchaseInvoicesNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      PurchaseInvoicesNotifier,
      List<PurchaseInvoice>
    >.internal(
      PurchaseInvoicesNotifier.new,
      name: r'purchaseInvoicesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$purchaseInvoicesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PurchaseInvoicesNotifier =
    AutoDisposeStreamNotifier<List<PurchaseInvoice>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
