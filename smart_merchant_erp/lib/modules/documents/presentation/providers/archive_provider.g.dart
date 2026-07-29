// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$archiveDocumentsHash() => r'f66bc4167d15b35214e610c136b8d82680476a38';

/// See also [archiveDocuments].
@ProviderFor(archiveDocuments)
final archiveDocumentsProvider =
    AutoDisposeStreamProvider<List<ArchiveDocument>>.internal(
      archiveDocuments,
      name: r'archiveDocumentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$archiveDocumentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchiveDocumentsRef =
    AutoDisposeStreamProviderRef<List<ArchiveDocument>>;
String _$archiveFilterStateHash() =>
    r'b7f858db3af3725b23ff1a8fa0444d44a860e937';

/// See also [ArchiveFilterState].
@ProviderFor(ArchiveFilterState)
final archiveFilterStateProvider =
    AutoDisposeNotifierProvider<
      ArchiveFilterState,
      ArchiveDocumentFilter
    >.internal(
      ArchiveFilterState.new,
      name: r'archiveFilterStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$archiveFilterStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ArchiveFilterState = AutoDisposeNotifier<ArchiveDocumentFilter>;
String _$archiveStatsHash() => r'289ec1d888f27931357c0936dcff766cfae1a49a';

/// See also [ArchiveStats].
@ProviderFor(ArchiveStats)
final archiveStatsProvider =
    AutoDisposeNotifierProvider<ArchiveStats, Map<String, int>>.internal(
      ArchiveStats.new,
      name: r'archiveStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$archiveStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ArchiveStats = AutoDisposeNotifier<Map<String, int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
