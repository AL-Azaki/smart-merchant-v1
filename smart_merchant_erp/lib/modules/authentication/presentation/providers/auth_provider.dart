import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  setupRequired, // Account created, but business/branch not setup
  trialActive,   // Free trial
  subscriptionExpired, // Subscription ended, locked
  subscriptionPending, // Requested offline payment, waiting admin approval
  authenticated, // Active subscription
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthStatus build() {
    // By default, the user is unauthenticated when they open the app.
    return AuthStatus.unauthenticated;
  }

  void login() {
    // Assume successful login leads to authenticated state (bypassing setup for now).
    state = AuthStatus.authenticated;
  }

  void register() {
    // After registration, they must setup their business.
    state = AuthStatus.setupRequired;
  }
  
  void completeSetup() {
    // Once setup is complete, they automatically get a Trial.
    state = AuthStatus.trialActive;
  }

  void expireSubscription() {
    state = AuthStatus.subscriptionExpired;
  }

  void requestSubscription() {
    state = AuthStatus.subscriptionPending;
  }

  void logout() {
    state = AuthStatus.unauthenticated;
  }
}
