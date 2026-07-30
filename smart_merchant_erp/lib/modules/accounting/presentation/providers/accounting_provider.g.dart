// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$journalEntryDetailsHash() =>
    r'c281c88695cc00a82cc1667916057833ca91df34';

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

/// See also [journalEntryDetails].
@ProviderFor(journalEntryDetails)
const journalEntryDetailsProvider = JournalEntryDetailsFamily();

/// See also [journalEntryDetails].
class JournalEntryDetailsFamily
    extends Family<AsyncValue<JournalEntryWithLines?>> {
  /// See also [journalEntryDetails].
  const JournalEntryDetailsFamily();

  /// See also [journalEntryDetails].
  JournalEntryDetailsProvider call(String journalEntryId) {
    return JournalEntryDetailsProvider(journalEntryId);
  }

  @override
  JournalEntryDetailsProvider getProviderOverride(
    covariant JournalEntryDetailsProvider provider,
  ) {
    return call(provider.journalEntryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'journalEntryDetailsProvider';
}

/// See also [journalEntryDetails].
class JournalEntryDetailsProvider
    extends AutoDisposeFutureProvider<JournalEntryWithLines?> {
  /// See also [journalEntryDetails].
  JournalEntryDetailsProvider(String journalEntryId)
    : this._internal(
        (ref) =>
            journalEntryDetails(ref as JournalEntryDetailsRef, journalEntryId),
        from: journalEntryDetailsProvider,
        name: r'journalEntryDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$journalEntryDetailsHash,
        dependencies: JournalEntryDetailsFamily._dependencies,
        allTransitiveDependencies:
            JournalEntryDetailsFamily._allTransitiveDependencies,
        journalEntryId: journalEntryId,
      );

  JournalEntryDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.journalEntryId,
  }) : super.internal();

  final String journalEntryId;

  @override
  Override overrideWith(
    FutureOr<JournalEntryWithLines?> Function(JournalEntryDetailsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: JournalEntryDetailsProvider._internal(
        (ref) => create(ref as JournalEntryDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        journalEntryId: journalEntryId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<JournalEntryWithLines?> createElement() {
    return _JournalEntryDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is JournalEntryDetailsProvider &&
        other.journalEntryId == journalEntryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, journalEntryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin JournalEntryDetailsRef
    on AutoDisposeFutureProviderRef<JournalEntryWithLines?> {
  /// The parameter `journalEntryId` of this provider.
  String get journalEntryId;
}

class _JournalEntryDetailsProviderElement
    extends AutoDisposeFutureProviderElement<JournalEntryWithLines?>
    with JournalEntryDetailsRef {
  _JournalEntryDetailsProviderElement(super.provider);

  @override
  String get journalEntryId =>
      (origin as JournalEntryDetailsProvider).journalEntryId;
}

String _$chartOfAccountsNotifierHash() =>
    r'6111f57eff797fb4544ed261f901a6051e044e5f';

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
String _$journalEntriesNotifierHash() =>
    r'99ba355e9f97e97db72534be4174779f8ecc9fee';

/// See also [JournalEntriesNotifier].
@ProviderFor(JournalEntriesNotifier)
final journalEntriesNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      JournalEntriesNotifier,
      List<JournalEntry>
    >.internal(
      JournalEntriesNotifier.new,
      name: r'journalEntriesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$journalEntriesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$JournalEntriesNotifier =
    AutoDisposeStreamNotifier<List<JournalEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
