import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../shared/design_system/layouts/main_layout.dart';
import '../../modules/platform/presentation/views/home_view.dart';
import '../../shared/design_system/widgets/coming_soon_view.dart';
import '../../modules/sales/presentation/layouts/sales_layout.dart';
import '../../modules/authentication/presentation/providers/auth_provider.dart';
import '../../modules/authentication/presentation/pages/auth_gate_view.dart';
import '../../modules/authentication/presentation/pages/login_view.dart';
import '../../modules/authentication/presentation/pages/register_view.dart';
import '../../modules/authentication/presentation/pages/business_setup_view.dart';
import '../../modules/authentication/presentation/pages/locked_subscription_view.dart';
import '../../modules/authentication/presentation/pages/pending_subscription_view.dart';
import '../../modules/authentication/presentation/pages/splash_view.dart';
import '../../kernel/security/permissions_provider.dart';
import '../../modules/inventory/presentation/views/inventory_module_view.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // Use a ValueNotifier to trigger GoRouter redirects without recreating the router instance
  final authStateNotifier = ValueNotifier<AuthStatus>(AuthStatus.initial);
  
  ref.listen(
    authNotifierProvider,
    (previous, next) {
      authStateNotifier.value = next;
    },
  );

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authStateNotifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthRoute =
          state.matchedLocation == '/auth-gate' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      final isSplash = state.matchedLocation == '/splash';

      switch (authState) {
        case AuthStatus.initial:
          return isSplash ? null : '/splash';

        case AuthStatus.unauthenticated:
          return isAuthRoute ? null : '/auth-gate';

        case AuthStatus.authenticating:
          return isAuthRoute ? null : '/auth-gate';

        case AuthStatus.setupRequired:
          return state.matchedLocation == '/setup-business'
              ? null
              : '/setup-business';

        case AuthStatus.trialActive:
        case AuthStatus.authenticated:
          if (isAuthRoute ||
              state.matchedLocation == '/setup-business' ||
              isSplash)
            return '/';

          // --- SECURITY: Module-Level URL Guards ---
          final activeModules = ref.read(modulesNotifierProvider);
          if (state.matchedLocation.startsWith('/sales') &&
              !activeModules.contains(ErpModule.sales)) {
            return '/'; // Deny access and send home
          }
          if (state.matchedLocation.startsWith('/inventory') &&
              !activeModules.contains(ErpModule.inventory)) {
            return '/';
          }
          if (state.matchedLocation.startsWith('/accounting') &&
              !activeModules.contains(ErpModule.accounting)) {
            return '/';
          }
          return null;

        case AuthStatus.subscriptionExpired:
          return state.matchedLocation == '/locked' ? null : '/locked';

        case AuthStatus.subscriptionPending:
          return state.matchedLocation == '/pending' ? null : '/pending';

        case AuthStatus.deviceRevoked:
          return state.matchedLocation == '/locked'
              ? null
              : '/locked'; // For now route device revoked to locked or a specific view
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashView()),
      GoRoute(
        path: '/auth-gate',
        builder: (context, state) => const AuthGateView(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/setup-business',
        builder: (context, state) => const BusinessSetupView(),
      ),
      GoRoute(
        path: '/locked',
        builder: (context, state) => const LockedSubscriptionView(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingSubscriptionView(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const MainLayout(currentIndex: 0, child: HomeView()),
      ),
      GoRoute(
        path: '/sales',
        builder: (context, state) =>
            const MainLayout(currentIndex: 1, child: SalesLayout()),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) =>
            const MainLayout(currentIndex: 2, child: InventoryModuleView()),
      ),
      GoRoute(
        path: '/accounting',
        builder: (context, state) => const MainLayout(
          currentIndex: 3,
          child: ComingSoonView(title: 'النظام المالي والمحاسبي'),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const MainLayout(
          currentIndex: 4,
          child: ComingSoonView(title: 'إعدادات النظام'),
        ),
      ),
    ],
  );
}
