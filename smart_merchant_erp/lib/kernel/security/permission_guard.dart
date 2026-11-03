import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'permissions_provider.dart';

/// A clean UI Guard widget that renders its [child] ONLY if the currently active user
/// has the required permission for [module] and [action].
class PermissionGuard extends ConsumerWidget {
  final String module;
  final String action;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    required this.module,
    required this.action,
    required this.child,
    super.key,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(activeUserProvider);
    final isAllowed = currentUser.can(module, action);

    if (isAllowed) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
