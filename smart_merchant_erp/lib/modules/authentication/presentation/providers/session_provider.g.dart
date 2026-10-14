// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionNotifierHash() => r'394b5a0eee2672d1d173d2cead52035c774dd52c';

/// The Riverpod session controller.
/// Updates the authoritative [SessionHolder] singleton so that
/// GetIt-resolved Use Cases always see the current context.
///
/// Flow:
///   AuthNotifier.login() -> SessionNotifier.setSession()
///   -> SessionHolder.setSession() -> RuntimeApplicationContext reads SessionHolder
///   -> Use Cases read ApplicationContext
///
/// Copied from [SessionNotifier].
@ProviderFor(SessionNotifier)
final sessionNotifierProvider =
    NotifierProvider<SessionNotifier, SessionState>.internal(
      SessionNotifier.new,
      name: r'sessionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SessionNotifier = Notifier<SessionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
