import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/di/getit_instance.dart';
import '../storage/secure_storage/secure_storage_contract.dart';
import 'subscription_lease_guard.dart';
import 'time_integrity_guard.dart';

/// Provider exposing [SubscriptionLeaseGuard] instance.
final subscriptionLeaseGuardProvider = Provider<SubscriptionLeaseGuard>((ref) {
  final storage = getIt<SecureStorageContract>();
  final timeGuard = TimeIntegrityGuard(storage: storage);
  return SubscriptionLeaseGuard(storage: storage, timeGuard: timeGuard);
});

/// Reactive provider for the active lease status and warning banners.
final subscriptionLeaseCheckProvider = FutureProvider<SubscriptionLeaseCheck>((ref) async {
  final guard = ref.watch(subscriptionLeaseGuardProvider);
  return guard.validateLease();
});
