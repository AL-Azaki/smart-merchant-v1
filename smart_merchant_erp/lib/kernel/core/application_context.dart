import 'package:equatable/equatable.dart';

/// Provides current multi-tenant (business, branch) and user context for application operations.
abstract class ApplicationContext {
  String get currentBusinessId;
  String? get currentBranchId;
  String get currentUserId;
}

/// The ONE authoritative runtime session holder.
/// Riverpod SessionNotifier updates this; GetIt-resolved Use Cases read from it.
/// This guarantees a single source of truth for businessId/branchId/userId.
class SessionHolder {
  static final SessionHolder _instance = SessionHolder._();
  factory SessionHolder() => _instance;
  SessionHolder._();

  String? _businessId;
  String? _branchId;
  String? _userId;

  bool get isActive => _businessId != null && _userId != null;

  String get businessId {
    final id = _businessId;
    if (id == null) throw StateError('No active session: businessId is null');
    return id;
  }

  String? get branchId => _branchId;

  String get userId {
    final id = _userId;
    if (id == null) throw StateError('No active session: userId is null');
    return id;
  }

  void setSession({
    required String businessId,
    String? branchId,
    required String userId,
  }) {
    _businessId = businessId;
    _branchId = branchId;
    _userId = userId;
  }

  void clearSession() {
    _businessId = null;
    _branchId = null;
    _userId = null;
  }
}

/// Production ApplicationContext that reads from the authoritative SessionHolder.
/// Registered in GetIt as the ApplicationContext implementation.
class RuntimeApplicationContext implements ApplicationContext {
  final SessionHolder _holder;

  const RuntimeApplicationContext(this._holder);

  @override
  String get currentBusinessId => _holder.businessId;

  @override
  String? get currentBranchId => _holder.branchId;

  @override
  String get currentUserId => _holder.userId;
}

/// Test-only static context. NOT registered in production DI.
class StaticApplicationContext extends Equatable implements ApplicationContext {
  final String businessId;
  final String? branchId;
  final String userId;

  const StaticApplicationContext({
    this.businessId = 'test-business-id',
    this.branchId = 'test-branch-id',
    this.userId = 'test-user-id',
  });

  @override
  String get currentBusinessId => businessId;

  @override
  String? get currentBranchId => branchId;

  @override
  String get currentUserId => userId;

  @override
  List<Object?> get props => [businessId, branchId, userId];
}
