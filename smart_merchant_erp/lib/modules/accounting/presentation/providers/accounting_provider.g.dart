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

String _$trialBalanceReportHash() =>
    r'd90777e4ce95188f65eb103363484d65465041b7';

/// See also [trialBalanceReport].
@ProviderFor(trialBalanceReport)
const trialBalanceReportProvider = TrialBalanceReportFamily();

/// See also [trialBalanceReport].
class TrialBalanceReportFamily extends Family<AsyncValue<TrialBalanceReport>> {
  /// See also [trialBalanceReport].
  const TrialBalanceReportFamily();

  /// See also [trialBalanceReport].
  TrialBalanceReportProvider call({DateTime? startDate, DateTime? endDate}) {
    return TrialBalanceReportProvider(startDate: startDate, endDate: endDate);
  }

  @override
  TrialBalanceReportProvider getProviderOverride(
    covariant TrialBalanceReportProvider provider,
  ) {
    return call(startDate: provider.startDate, endDate: provider.endDate);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'trialBalanceReportProvider';
}

/// See also [trialBalanceReport].
class TrialBalanceReportProvider
    extends AutoDisposeFutureProvider<TrialBalanceReport> {
  /// See also [trialBalanceReport].
  TrialBalanceReportProvider({DateTime? startDate, DateTime? endDate})
    : this._internal(
        (ref) => trialBalanceReport(
          ref as TrialBalanceReportRef,
          startDate: startDate,
          endDate: endDate,
        ),
        from: trialBalanceReportProvider,
        name: r'trialBalanceReportProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$trialBalanceReportHash,
        dependencies: TrialBalanceReportFamily._dependencies,
        allTransitiveDependencies:
            TrialBalanceReportFamily._allTransitiveDependencies,
        startDate: startDate,
        endDate: endDate,
      );

  TrialBalanceReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  Override overrideWith(
    FutureOr<TrialBalanceReport> Function(TrialBalanceReportRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TrialBalanceReportProvider._internal(
        (ref) => create(ref as TrialBalanceReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TrialBalanceReport> createElement() {
    return _TrialBalanceReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TrialBalanceReportProvider &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TrialBalanceReportRef
    on AutoDisposeFutureProviderRef<TrialBalanceReport> {
  /// The parameter `startDate` of this provider.
  DateTime? get startDate;

  /// The parameter `endDate` of this provider.
  DateTime? get endDate;
}

class _TrialBalanceReportProviderElement
    extends AutoDisposeFutureProviderElement<TrialBalanceReport>
    with TrialBalanceReportRef {
  _TrialBalanceReportProviderElement(super.provider);

  @override
  DateTime? get startDate => (origin as TrialBalanceReportProvider).startDate;
  @override
  DateTime? get endDate => (origin as TrialBalanceReportProvider).endDate;
}

String _$profitLossReportHash() => r'4c3bc0a8b663e7c9fb9ef81f10fc1a72c98ca72c';

/// See also [profitLossReport].
@ProviderFor(profitLossReport)
const profitLossReportProvider = ProfitLossReportFamily();

/// See also [profitLossReport].
class ProfitLossReportFamily extends Family<AsyncValue<ProfitLossReport>> {
  /// See also [profitLossReport].
  const ProfitLossReportFamily();

  /// See also [profitLossReport].
  ProfitLossReportProvider call({DateTime? startDate, DateTime? endDate}) {
    return ProfitLossReportProvider(startDate: startDate, endDate: endDate);
  }

  @override
  ProfitLossReportProvider getProviderOverride(
    covariant ProfitLossReportProvider provider,
  ) {
    return call(startDate: provider.startDate, endDate: provider.endDate);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'profitLossReportProvider';
}

/// See also [profitLossReport].
class ProfitLossReportProvider
    extends AutoDisposeFutureProvider<ProfitLossReport> {
  /// See also [profitLossReport].
  ProfitLossReportProvider({DateTime? startDate, DateTime? endDate})
    : this._internal(
        (ref) => profitLossReport(
          ref as ProfitLossReportRef,
          startDate: startDate,
          endDate: endDate,
        ),
        from: profitLossReportProvider,
        name: r'profitLossReportProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$profitLossReportHash,
        dependencies: ProfitLossReportFamily._dependencies,
        allTransitiveDependencies:
            ProfitLossReportFamily._allTransitiveDependencies,
        startDate: startDate,
        endDate: endDate,
      );

  ProfitLossReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  Override overrideWith(
    FutureOr<ProfitLossReport> Function(ProfitLossReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProfitLossReportProvider._internal(
        (ref) => create(ref as ProfitLossReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProfitLossReport> createElement() {
    return _ProfitLossReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfitLossReportProvider &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfitLossReportRef on AutoDisposeFutureProviderRef<ProfitLossReport> {
  /// The parameter `startDate` of this provider.
  DateTime? get startDate;

  /// The parameter `endDate` of this provider.
  DateTime? get endDate;
}

class _ProfitLossReportProviderElement
    extends AutoDisposeFutureProviderElement<ProfitLossReport>
    with ProfitLossReportRef {
  _ProfitLossReportProviderElement(super.provider);

  @override
  DateTime? get startDate => (origin as ProfitLossReportProvider).startDate;
  @override
  DateTime? get endDate => (origin as ProfitLossReportProvider).endDate;
}

String _$accountStatementReportHash() =>
    r'6352b0aedf71b74a862f511161f0b5be3f8db3f1';

/// See also [accountStatementReport].
@ProviderFor(accountStatementReport)
const accountStatementReportProvider = AccountStatementReportFamily();

/// See also [accountStatementReport].
class AccountStatementReportFamily
    extends Family<AsyncValue<AccountStatementReport?>> {
  /// See also [accountStatementReport].
  const AccountStatementReportFamily();

  /// See also [accountStatementReport].
  AccountStatementReportProvider call({
    required String accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AccountStatementReportProvider(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  AccountStatementReportProvider getProviderOverride(
    covariant AccountStatementReportProvider provider,
  ) {
    return call(
      accountId: provider.accountId,
      startDate: provider.startDate,
      endDate: provider.endDate,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'accountStatementReportProvider';
}

/// See also [accountStatementReport].
class AccountStatementReportProvider
    extends AutoDisposeFutureProvider<AccountStatementReport?> {
  /// See also [accountStatementReport].
  AccountStatementReportProvider({
    required String accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) : this._internal(
         (ref) => accountStatementReport(
           ref as AccountStatementReportRef,
           accountId: accountId,
           startDate: startDate,
           endDate: endDate,
         ),
         from: accountStatementReportProvider,
         name: r'accountStatementReportProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$accountStatementReportHash,
         dependencies: AccountStatementReportFamily._dependencies,
         allTransitiveDependencies:
             AccountStatementReportFamily._allTransitiveDependencies,
         accountId: accountId,
         startDate: startDate,
         endDate: endDate,
       );

  AccountStatementReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.accountId,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final String accountId;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  Override overrideWith(
    FutureOr<AccountStatementReport?> Function(
      AccountStatementReportRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AccountStatementReportProvider._internal(
        (ref) => create(ref as AccountStatementReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AccountStatementReport?> createElement() {
    return _AccountStatementReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AccountStatementReportProvider &&
        other.accountId == accountId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, accountId.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AccountStatementReportRef
    on AutoDisposeFutureProviderRef<AccountStatementReport?> {
  /// The parameter `accountId` of this provider.
  String get accountId;

  /// The parameter `startDate` of this provider.
  DateTime? get startDate;

  /// The parameter `endDate` of this provider.
  DateTime? get endDate;
}

class _AccountStatementReportProviderElement
    extends AutoDisposeFutureProviderElement<AccountStatementReport?>
    with AccountStatementReportRef {
  _AccountStatementReportProviderElement(super.provider);

  @override
  String get accountId => (origin as AccountStatementReportProvider).accountId;
  @override
  DateTime? get startDate =>
      (origin as AccountStatementReportProvider).startDate;
  @override
  DateTime? get endDate => (origin as AccountStatementReportProvider).endDate;
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
