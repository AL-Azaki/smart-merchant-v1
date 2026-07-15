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
import '../../kernel/security/permissions_provider.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/auth-gate' || 
                          state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register';

      switch (authState) {
        case AuthStatus.initial:
        case AuthStatus.unauthenticated:
          return isAuthRoute ? null : '/auth-gate';
        case AuthStatus.setupRequired:
          return state.matchedLocation == '/setup-business' ? null : '/setup-business';
        case AuthStatus.trialActive:
        case AuthStatus.authenticated:
          if (isAuthRoute || state.matchedLocation == '/setup-business') return '/';
          
          // --- SECURITY: Module-Level URL Guards ---
          final activeModules = ref.read(modulesNotifierProvider);
          if (state.matchedLocation.startsWith('/sales') && !activeModules.contains(ErpModule.sales)) {
            return '/'; // Deny access and send home
          }
          if (state.matchedLocation.startsWith('/inventory') && !activeModules.contains(ErpModule.inventory)) {
            return '/';
          }
          if (state.matchedLocation.startsWith('/accounting') && !activeModules.contains(ErpModule.accounting)) {
            return '/';
          }
          return null;
          
        case AuthStatus.subscriptionExpired:
          return state.matchedLocation == '/locked' ? null : '/locked';
        case AuthStatus.subscriptionPending:
          return state.matchedLocation == '/pending' ? null : '/pending';
      }
    },
    routes: [
      GoRoute(
        path: '/auth-gate',
        builder: (context, state) => const AuthGateView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
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
        builder: (context, state) => const MainLayout(
          currentIndex: 0,
          child: HomeView(),
        ),
      ),
      GoRoute(
        path: '/sales',
        builder: (context, state) => const MainLayout(
          currentIndex: 1,
          child: SalesLayout(),
        ),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const MainLayout(
          currentIndex: 2,
          child: ComingSoonView(title: 'المخزون والمستودعات'),
        ),
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
