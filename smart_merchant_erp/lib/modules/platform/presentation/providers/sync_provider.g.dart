// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncNotifierHash() => r'67d6eaf93addf6e4a71fd9c67c5e841bbc104046';

/// Riverpod provider exposing synchronization state to the UI.
///
/// Responsibilities:
/// - Trigger sync (manual or automatic)
/// - Observe sync state
/// - Expose last sync info
///
/// Must NOT:
/// - Implement HTTP protocol
/// - Calculate revisions
/// - Perform raw SQL
/// - Contain retry algorithms
///
/// Copied from [SyncNotifier].
@ProviderFor(SyncNotifier)
final syncNotifierProvider = NotifierProvider<SyncNotifier, SyncState>.internal(
  SyncNotifier.new,
  name: r'syncNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncNotifier = Notifier<SyncState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
