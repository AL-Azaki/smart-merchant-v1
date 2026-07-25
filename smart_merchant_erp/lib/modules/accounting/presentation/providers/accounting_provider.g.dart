// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chartOfAccountsNotifierHash() =>
    r'e39e2b19f341c3e0e59926c4d13ab43c89965d98';

/// See also [ChartOfAccountsNotifier].
@ProviderFor(ChartOfAccountsNotifier)
final chartOfAccountsNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      ChartOfAccountsNotifier,
      List<ChartOfAccount>
    >.internal(
      ChartOfAccountsNotifier.new,
      name: r'chartOfAccountsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chartOfAccountsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ChartOfAccountsNotifier =
    AutoDisposeStreamNotifier<List<ChartOfAccount>>;
String _$journalNotifierHash() => r'1e2e62d34118ee0237ae62c19e2182a7d67c3bd5';

/// See also [JournalNotifier].
@ProviderFor(JournalNotifier)
final journalNotifierProvider =
    AutoDisposeNotifierProvider<JournalNotifier, JournalState>.internal(
      JournalNotifier.new,
      name: r'journalNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$journalNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$JournalNotifier = AutoDisposeNotifier<JournalState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
